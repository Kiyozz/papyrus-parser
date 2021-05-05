import 'package:charcode/ascii.dart';
import 'package:collection/collection.dart';

import 'exception.dart';
import 'types.dart';
import 'node.dart';
import 'tree/tree.dart';
import 'property.dart';

class Context {
  List<NodeType> tokens = [];
  List<Node> nodes = [];

  NodeType get lastToken => tokens.last;
  Node get lastNode => nodes.last;

  void addToken(NodeType type) => tokens.add(type);
  void addNode(Node node) => nodes.add(node);
}

/// Parse an entire Papyrus source code
///
/// Emits a AST format Program.
class Tree {
  final String? _filename;
  final String _content;
  final TreeOptions _options;

  /// The current position of the tokenizer in the _content
  int _pos = 0;

  /// Type of current token
  NodeType _type = NodeType.eof;

  /// Is first word read
  bool _isFirstRead = true;

  /// For tokens that include more information than their type, the value
  dynamic? _value;

  /// Current token start offset
  int _start = 0;

  /// Current token end offset
  int _end = 0;

  /// Position information for the previous token
  int _lastTokenStart = 0;

  /// Position information for the previous token
  int _lastTokenEnd = 0;

  /// Skip parens read. Useful for parsing if, elseif, while,
  /// ... statement because parens are optional
  bool _shouldSkipParens = false;

  /// Useful to know if _goNext() has skipParens()
  bool _foundParens = false;

  /// Useful to know if parsing inside of FunctionStatement
  bool _inFunction = false;

  /// Useful to know if parsing inside of EventStatement
  bool _inEvent = false;

  /// The context stack is used to superficially track syntactic
  /// context to predict whether a regular expression is allowed in a
  /// given position
  final _context = Context();

  /// Checks any keyword presence
  final _keywords = RegExp(
    r'^(?:as|auto|autoreadonly|conditional|hidden|bool|else|elseif|endevent|endfunction|endif|endproperty|endstate|endwhile|event|extends|false|float|function|global|if|import|int|native|new|none|parent|property|return|scriptname|self|state|string|true|while)$',
    caseSensitive: false,
  );

  /// Checks presence of endproperty keyword
  final _endProperty = RegExp(r'endproperty', caseSensitive: false);

  int get _next => _content.codeUnitAt(_pos + 1);

  ScriptNameStatement? _scriptName;

  Tree({
    required String content,
    TreeOptions options = const TreeOptions(),
    String? filename,
  })  : _content = content,
        _options = options,
        _filename = filename;

  Program parse() {
    final program = _startNode().toProgram();

    _nextToken();

    return _parseTopLevel(program);
  }

  Node _startNode() {
    return Node(start: _start);
  }

  Node _startNodeAt(int pos) {
    return Node(start: pos);
  }

  Program _parseTopLevel(Program program) {
    while (_type != NodeType.eof) {
      final statement = _parseStatement();

      program.body.add(statement);
    }

    _goNext();

    return _finishNode(program);
  }

  int? _currentCodeUnit({int? pos}) {
    try {
      return _content.codeUnitAt(pos ?? _pos);
    } on RangeError catch (_) {
      return null;
    }
  }

  void _goNext() {
    _lastTokenEnd = _end;
    _lastTokenStart = _start;
    _nextToken();
  }

  Node _parseStatement({
    List<NodeType>? context,
    bool initialNext = false,
  }) {
    final startType = _type;
    final node = _startNode();

    switch (startType) {
      case NodeType.scriptNameKw:
        return _parseScriptNameStatement(node.toScriptNameStatement());
      case NodeType.functionKw:
        return _parseFunctionStatement(node.toFunctionStatement());
      case NodeType.ifKw:
      case NodeType.elseIfKw:
        return _parseIfStatement(node.toIfStatement());
      case NodeType.whileKw:
        return _parseWhileStatement(node.toWhileStatement());
      case NodeType.stateKw:
        return _parseStateStatement(node.toStateStatement());
      case NodeType.returnKw:
        return _parseReturnStatement(node.toReturnStatement());
      case NodeType.eventKw:
        return _parseEventStatement(node.toEventStatement());
      default:
        final startPos = _start;

        if (_type == NodeType.autoKw) {
          final autoType = _type;

          _goNext();

          if (_type == NodeType.stateKw) {
            return _parseStateStatement(
              node.toStateStatement(),
              startPos: startPos,
              flag: autoType,
            );
          }
        }

        if (startType == NodeType.name) {
          final potentialVariableType = _value;

          _goNext();

          if (_type == NodeType.asKw) {
            final identifier = _startNodeAt(startPos).toIdentifier();
            identifier.name = potentialVariableType;

            return _parseCastExpression(
              node.toCastExpression(),
              startPos: startPos,
              id: _finishNode(identifier),
            );
          }

          if (_type == NodeType.functionKw) {
            final functionNode = node.toFunctionStatement();

            functionNode.start = startPos;
            functionNode.kind = potentialVariableType;

            return _parseFunctionStatement(functionNode);
          }

          if (_type == NodeType.parenL) {
            final id = node.toIdentifier();
            id.name = potentialVariableType;

            return _parseSubscripts(id, startPos);
          }

          if (_type == NodeType.propertyKw) {
            return _parsePropertyDeclaration(
              kind: potentialVariableType,
              start: startPos,
            );
          }

          if (_type == NodeType.name) {
            return _parseVariableDeclaration(
              kind: potentialVariableType,
              start: startPos,
            );
          }
        }

        if (_isNewLine(_currentCodeUnit())) {
          return _parseBlock(
            node.toBlockStatement(),
            context ?? [_close(startType)],
            initialNext: initialNext,
            next: true,
          );
        }

        // final maybeName = _value;
        final expr = _parseExpression();

        return _parseExpressionStatement(
          node: node.toExpressionStatement(),
          expr: expr,
        );
    }
  }

  EventStatement _parseEventStatement(EventStatement node) {
    _inEvent = true;
    _goNext();
    node.id = _parseIdentifier();
    _expect(NodeType.parenL);
    node.params = _parseBindingList(NodeType.parenR, false);

    var hasNative = false;

    EventFlagException throwError() {
      return EventFlagException(
        flag: _value,
        start: _start,
        end: _end,
      );
    }

    EventFlagDeclaration createFlag(EventFlag flag) {
      final declaration = _startNode().toEventFlagDeclaration();
      declaration.flag = flag;

      return _finishNode(declaration);
    }

    if (_hasNewLineBetweenLastToken() && _type == NodeType.nativeKw) {
      throw throwError();
    }

    while (!_hasNewLineBetweenLastToken() && _type != NodeType.eof) {
      if (_type != NodeType.nativeKw) {
        throw throwError();
      }

      if (_type == NodeType.nativeKw && hasNative) {
        throw throwError();
      }

      if (_type == NodeType.nativeKw) {
        node.flags.add(createFlag(EventFlag.native));
        hasNative = true;
        _goNext();
      } else {
        throw throwError();
      }
    }

    if (!node.isNative) {
      node.body = _parseBlock(null, [NodeType.endEventKw]);
    }

    node = _finishNode(node);
    _inEvent = false;

    return node;
  }

  Node _parseStateStatement(
    StateStatement node, {
    NodeType? flag,
    int? startPos,
  }) {
    node.flag = flag == NodeType.autoKw ? StateFlag.auto : null;

    if (node.isAuto && startPos != null) {
      node.start = startPos;
    }

    _goNext();

    node.id = _parseIdentifier();
    node.body = _parseBlock(null, [NodeType.endStateKw]);

    if (!node.isValid) {
      throw StateStatementException(
        'StateStatement can only contains FunctionStatement or EventStatement',
        start: node.start,
        end: _lastTokenEnd,
      );
    }

    return _finishNode(node);
  }

  CastExpression _parseCastExpression(
    CastExpression node, {
    required int startPos,
    required Node id,
  }) {
    final castNode = node.toCastExpression();

    castNode.id = id;

    if (_type == NodeType.asKw) {
      _goNext();
    }

    castNode.kind = _parseIdentifier();

    return _finishNode(castNode);
  }

  Node _parseReturnStatement(ReturnStatement node) {
    if (_options.throwWhenReturnOutsideOfFunctionOrEvent &&
        !_inFunction &&
        !_inEvent) {
      throw UnexpectedTokenException(
        start: node.start,
        end: _lastTokenEnd,
        message: 'Return statement can only be used in Function or Event',
      );
    }

    _shouldSkipParens = true;
    _goNext();
    _shouldSkipParens = false;
    final foundParens = _foundParens;

    if (!_hasNewLineBetweenLastToken()) {
      node.argument = _parseExpression();
    }

    if (foundParens) {
      _goNext();
    }

    return _finishNode(node);
  }

  Node _parsePropertyDeclaration({
    required int start,
    required String kind,
  }) {
    var node = _startNodeAt(start).toPropertyDeclaration();

    _goNext();

    node.id = _parseIdentifier();
    node.kind = kind;

    if (_eat(NodeType.assign)) {
      node.init = _parseMaybeAssign();

      if (node.init?.type != NodeType.literal) {
        throw PropertyException(
          'Property init declaration should be a constant',
          start: node.start,
          end: _lastTokenEnd,
        );
      }
    }

    while (_type == NodeType.hiddenKw ||
        _type == NodeType.autoKw ||
        _type == NodeType.conditionalKw ||
        _type == NodeType.autoReadOnlyKw) {
      final flagDeclaration = _startNode().toPropertyFlagDeclaration();

      if ((_scriptName?.isConditional ?? false) && !node.isConditional) {
        throw PropertyException(
          'A Conditional Property must appears in ScriptName flagged Conditional',
          start: node.start,
          end: _lastTokenEnd,
        );
      }

      flagDeclaration.flag = flagDeclaration.flagFromType(_type);

      node.flags.add(flagDeclaration);

      _goNext();
    }

    if (node.isAutoReadonly && node.init == null) {
      throw PropertyException(
        'A AutoReadOnly should have a constant init declaration',
        start: node.start,
        end: _lastTokenEnd,
      );
    }

    if (node.isConditional && !node.isAutoOrAutoReadonly) {
      throw PropertyException(
        'A Conditional Property must be Auto or AutoReadOnly',
        start: node.start,
        end: _lastTokenEnd,
      );
    }

    if (node.isConditional && node.init == null) {
      throw PropertyException(
        'A Conditional Property must have an constant init declaration',
        start: node.start,
        end: _lastTokenEnd,
      );
    }

    if (node.isHidden) {
      final hasEndProperty = _content.contains(_endProperty, _start);

      if (!hasEndProperty) {
        final name = node.id?.name ?? 'unknown';

        throw PropertyException(
          'Full property "$name" must be closed by "endproperty"',
          start: node.start,
          end: _lastTokenEnd,
        );
      }

      final fullNode = node.toPropertyFullDeclaration();
      final hiddenFlag = _startNodeAt(start).toPropertyFlagDeclaration();

      hiddenFlag.flag = PropertyFlag.hidden;

      fullNode.flags.add(hiddenFlag);

      var block = _parseBlock(
        _startNode().toBlockStatement(),
        [NodeType.endPropertyKw],
      );

      if (block.body.isEmpty) {
        throw PropertyException(
          'A full property must have a getter and/or a setter',
          start: node.start,
          end: _lastTokenEnd,
        );
      }

      final getter = block.body.firstWhereOrNull(
          (element) => PropertyParser(element: element).isGetter);
      final setter = block.body.firstWhereOrNull(
          (element) => PropertyParser(element: element).isSetter);

      if (setter != null) {
        fullNode.setter = setter as FunctionStatement;

        if (setter.params.isEmpty && setter.params.length > 1) {
          throw PropertyException(
            'Setter should have one parameter with the same type as the Property',
            start: node.start,
            end: _lastTokenEnd,
          );
        }
      }

      if (getter != null) {
        fullNode.getter = getter as FunctionStatement;

        if (getter.kind != node.kind) {
          throw PropertyException(
            'Getter should return the same type as the Property',
            start: node.start,
            end: _lastTokenEnd,
          );
        }

        if (getter.params.isNotEmpty) {
          throw PropertyException(
            'Property getter cannot have parameters',
            start: getter.start,
            end: _pos,
          );
        }
      }

      node = fullNode;
    }

    return _finishNode(node);
  }

  Node _parseScriptNameStatement(ScriptNameStatement node) {
    if (_scriptName != null) {
      throw ScriptNameException(
        message: 'ScriptName cannot appears more than once in a script',
        start: _pos,
        end: _pos,
      );
    }

    _goNext();

    if (_type != NodeType.name) {
      throw UnexpectedTokenException(
        start: node.start,
        end: _end,
        pos: _start,
      );
    }

    node.id = _parseIdentifier();

    final filename = _filename;
    if (_options.throwWhenScriptnameMismatchFilename && filename != null) {
      final id = node.id as Identifier;

      if (id.name.toLowerCase() != filename.toLowerCase()) {
        throw ScriptNameException(
          start: node.start,
          end: _lastTokenEnd,
          message:
              'ScriptNameStatement Identifier must be the same as the filename ($filename)',
        );
      }
    }

    node.extendsDeclaration = _parseExtends();
    node.flags = _parseScriptNameFlags();

    final scriptName = _finishNode(node);

    _scriptName = scriptName;

    return node;
  }

  List<ScriptNameFlagDeclaration> _parseScriptNameFlags() {
    final flags = <ScriptNameFlagDeclaration>[];

    while (_type == NodeType.conditionalKw || _type == NodeType.hiddenKw) {
      final node = _startNode().toScriptNameFlagDeclaration();

      _goNext();

      node.flag = _type == NodeType.conditionalKw
          ? ScriptNameFlag.conditional
          : ScriptNameFlag.hidden;

      flags.add(_finishNode(node));
    }

    return flags;
  }

  ExtendsDeclaration? _parseExtends() {
    final node = _startNode().toExtendsDeclaration();

    if (_type != NodeType.extendsKw) return null;

    _goNext();

    if (_hasNewLineBetweenLastToken()) {
      throw ScriptNameException(
        start: node.start,
        end: _end,
        pos: _start,
      );
    }

    node.extended = _parseIdentifier();

    return _finishNode(node);
  }

  VariableDeclaration _parseVariableDeclaration({
    required int start,
    required String kind,
  }) {
    final node = _startNodeAt(start).toVariableDeclaration();
    final variable = _startNodeAt(start).toVariable();

    variable.id = _parseIdentifier();
    variable.kind = kind;

    if (_eat(NodeType.assign)) {
      variable.init = _parseMaybeAssign();
    } else if (variable.id?.type != NodeType.id) {
      throw UnexpectedTokenException(
        message: 'Cannot find variable name',
        start: variable.start,
        end: _pos,
      );
    }

    node.variable = _finishNode(variable);

    return _finishNode(node);
  }

  Node _parseExpressionStatement({
    required ExpressionStatement node,
    required Node expr,
  }) {
    node.expression = expr;

    return _finishNode(node);
  }

  Node _parseWhileStatement(WhileStatement node) {
    _shouldSkipParens = true;
    _goNext();
    _shouldSkipParens = false;
    final foundParens = _foundParens;

    node.test = _parseExpression();

    if (foundParens) {
      _goNext();
    }

    node.consequent = _parseBlock(null, [NodeType.endWhileKw]);

    return _finishNode(node);
  }

  Node _parseIfStatement(IfStatement node) {
    _shouldSkipParens = true;
    _goNext();
    _shouldSkipParens = false;
    final foundParens = _foundParens;

    node.test = _parseExpression();

    if (foundParens) {
      _goNext();
    }

    node.consequent = _parseBlock(
      null,
      [
        NodeType.elseKw,
        NodeType.elseIfKw,
        NodeType.endIfKw,
      ],
      next: false,
    );

    if (_type == NodeType.elseKw) {
      _goNext();

      node.alternate = _parseBlock(null, [NodeType.endIfKw]);
    } else if (_type == NodeType.elseIfKw) {
      node.alternate = _parseIfStatement(_startNode().toIfStatement());
    } else {
      _goNext();
    }

    return _finishNode(node);
  }

  Node _parseFunctionStatement(FunctionStatement node) {
    _inFunction = true;
    _goNext();
    node = _parseFunction(node);
    _inFunction = false;

    return node;
  }

  FunctionStatement _parseFunction(FunctionStatement node) {
    node.id = _parseIdentifier();

    _parseFunctionParams(node);
    _parseFunctionFlags(node);
    _parseFunctionBody(node);

    return _finishNode(node);
  }

  void _parseFunctionFlags(FunctionStatement node) {
    var hasGlobal = false;
    var hasNative = false;

    FunctionFlagException throwError() {
      return FunctionFlagException(
        flag: _value,
        start: _start,
        end: _end,
      );
    }

    FunctionFlagDeclaration createFlag(FunctionFlag flag) {
      final declaration = _startNode().toFunctionFlagDeclaration();
      declaration.flag = flag;

      return _finishNode(declaration);
    }

    if (_hasNewLineBetweenLastToken() &&
        (_type == NodeType.globalKw || _type == NodeType.nativeKw)) {
      throw throwError();
    }

    while (!_hasNewLineBetweenLastToken() && _type != NodeType.eof) {
      if (_type != NodeType.globalKw && _type != NodeType.nativeKw) {
        throw throwError();
      }

      if (_type == NodeType.globalKw && hasGlobal) {
        throw throwError();
      }

      if (_type == NodeType.nativeKw && hasNative) {
        throw throwError();
      }

      switch (_type) {
        case NodeType.globalKw:
          node.flags.add(createFlag(FunctionFlag.global));
          hasGlobal = true;
          _goNext();
          break;
        case NodeType.nativeKw:
          node.flags.add(createFlag(FunctionFlag.native));
          hasNative = true;
          _goNext();
          break;
        default:
          throw throwError();
      }
    }
  }

  void _parseFunctionBody(FunctionStatement node) {
    if (node.isNative) return;

    node.body = [
      _parseBlock(null, [NodeType.endFunctionKw])
    ];
  }

  BlockStatement _parseBlock(
    BlockStatement? usedNode,
    List<NodeType> closingTypes, {
    bool initialNext = false,
    bool next = true,
  }) {
    final node = usedNode ?? _startNode().toBlockStatement();

    if (_type == NodeType.eof) {
      final missingTypes = closingTypes.map((t) => t.name).join('/');

      throw BlockStatementException(
        'Missing "$missingTypes"',
        start: node.start,
        end: _end,
      );
    }

    if (initialNext) {
      _goNext();
    }

    while (!closingTypes.contains(_type)) {
      final statement = _parseStatement();

      node.body.add(statement);
    }

    if (next) {
      _goNext();
    }

    return _finishNode(node);
  }

  Node _parseExpression() {
    final expr = _parseMaybeAssign();

    if (_type == NodeType.lineTerminator) {
      // TODO: handle line terminator

      throw UnimplementedError();
    }

    return expr;
  }

  VariableDeclaration _parseFunctionParamMaybeDefault(
    int startPos,
    Node? left,
  ) {
    if (_type != NodeType.name) {
      throw UnexpectedTokenException(start: startPos, end: _pos);
    }

    final paramKind = _value;

    _goNext();

    return _parseVariableDeclaration(
      kind: paramKind,
      start: startPos,
    );
  }

  Node _parseMaybeAssign() {
    final left = _parseExprOps();

    if (_type == NodeType.assign) {
      final n = _startNode().toAssignExpression();

      n.left = left;

      _goNext();

      n.right = _parseExprAtom();

      return _finishNode(n);
    }

    return left;
  }

  Node _parseExprOps() {
    final startPos = _start;
    final expr = _parseMaybeUnary();

    return _parseExprOp(expr, startPos);
  }

  Node _parseMaybeUnary() {
    if (_type.isPrefix) {
      final node = _startNode().toUnaryExpression();

      node.operator = _value;
      _goNext();
      node.argument = _parseMaybeUnary();
      node.isPrefix = true;

      return _finishNode(node);
    }

    return _parseExprSubscripts();
  }

  Node _parseExprOp(Node left, int leftStartPos) {
    if (_type == NodeType.logicalOr ||
        _type == NodeType.logicalAnd ||
        _type == NodeType.binary ||
        _type == NodeType.equality) {
      final logical =
          _type == NodeType.logicalOr || _type == NodeType.logicalAnd;
      final op = _value;
      _goNext();
      final startPos = _start;
      final right = _parseExprOp(_parseMaybeUnary(), startPos);
      final node = _buildBinary(
        leftStartPos,
        left,
        right,
        op,
        logical: logical,
      );

      return _parseExprOp(node, leftStartPos);
    }

    return left;
  }

  LogicalExpression _buildBinary(
    int startPos,
    Node left,
    Node right,
    String op, {
    bool logical = false,
  }) {
    final node = _startNodeAt(startPos).toLogical();

    node.left = left;
    node.operator = op;
    node.right = right;

    return _finishNode(
      node,
      type: logical ? NodeType.logical : NodeType.binary,
    );
  }

  Node _parseExprSubscripts() {
    final startPos = _start;
    final expr = _parseExprAtom();

    return _parseSubscripts(expr, startPos);
  }

  Node _parseExprAtom() {
    switch (_type) {
      case NodeType.parentKw:
        final parentNode = _startNode().toIdentifier();

        parentNode.name = _value;

        if (_currentCodeUnit() == $open_paren) {
          throw ParentMemberException(
            'Parent cannot be used as a function',
            start: parentNode.start,
            end: _lastTokenEnd,
          );
        }

        _goNext();

        return _finishNode(
          parentNode,
          type: NodeType.parentKw,
        );
      case NodeType.selfKw:
        final selfNode = _startNode();
        _goNext();

        return _finishNode(
          selfNode,
          type: NodeType.selfKw,
        );
      case NodeType.name:
        return _parseIdentifier();

      case NodeType.num:
      case NodeType.string:
      case NodeType.char:
        return _parseLiteral(_value);

      case NodeType.noneKw:
      case NodeType.falseKw:
      case NodeType.trueKw:
        final literalNode = _startNode().toLiteral()
          ..value = _type == NodeType.noneKw ? null : _type == NodeType.trueKw
          ..raw = _content.substring(_start, _end);

        _goNext();

        return _finishNode(literalNode);
      case NodeType.newKw:
        return _parseNew();
      case NodeType.importKw:
        return _parseImport();
      default:
        // TODO: unexpected I think
        throw Exception();
    }
  }

  Node _parseImport() {
    final node = _startNode().toImport();

    _goNext();

    if (_type != NodeType.name) {
      throw UnexpectedTokenException(
        message: 'Expected Identifier',
        start: _pos,
        end: _pos,
      );
    }

    final imported = _startNode().toName();
    imported.name = _value;

    node.imported = _finishNode(node) as Name;

    return _finishNode(node);
  }

  Node _parseNew() {
    final node = _startNode().toNewExpression();
    final startPos = _start;

    node.callee = _parseSubscripts(_parseExprAtom(), startPos);

    if (!_eat(NodeType.bracketL)) {
      throw UnexpectedTokenException(
        message: 'Expected opening bracket',
        start: _pos,
        end: _pos,
      );
    }

    final nodeSize = _startNode().toLiteral();

    _goNext();

    if (!_eat(NodeType.num)) {
      throw UnexpectedTokenException(
        message: 'Expected Number Literal',
        start: _pos,
        end: _pos,
      );
    }

    nodeSize.type = _type;
    nodeSize.value = _value;
    nodeSize.raw = '$_value';

    if (!_eat(NodeType.bracketR)) {
      throw UnexpectedTokenException(
        message: 'Expected closing bracket',
        start: _pos,
        end: _pos,
      );
    }

    node.argument = _finishNode(nodeSize);

    return _finishNode(node);
  }

  Node _parseSubscripts(Node base, int startPos) {
    while (true) {
      final element = _parseSubscript(base, startPos);

      if (element == base) return element;

      base = element;
    }
  }

  Node _parseSubscript(Node base, int startPos) {
    final computed = _eat(NodeType.bracketL);

    if (computed || _eat(NodeType.dot)) {
      if (base is Identifier && base.type == NodeType.parentKw) {
        final scriptName = _scriptName;

        if (scriptName != null && scriptName.extendsDeclaration == null) {
          throw ParentMemberException(
            'Cannot use Parent in ScriptName that do not extends Object',
            start: base.start,
            end: _lastTokenEnd,
          );
        }
      }

      if (base is MemberExpression &&
          base.object is Identifier &&
          base.object?.type == NodeType.parentKw) {
        final object = base.object as Identifier;

        throw ParentMemberException(
          'Property ${object.name} cannot be used as a MemberExpression',
          start: base.start,
          end: _lastTokenEnd,
        );
      }

      final node = _startNodeAt(startPos).toMemberExpression();
      node.object = base;

      if (computed) {
        node.property = _parseExpression();
        _expect(NodeType.bracketR);
      } else {
        node.property = _parseIdentifier();
      }

      node.computed = computed;

      base = _finishNode(node);
    } else if (_eat(NodeType.parenL)) {
      final exprList = _parseExprList(close: NodeType.parenR);

      final exprNode = _startNodeAt(startPos).toCallExpression();
      exprNode.callee = _finishNode(base);
      exprNode.arguments = exprList;

      base = _finishNode(exprNode);
    } else if (_eat(NodeType.asKw)) {
      final castNode = _startNodeAt(startPos).toCastExpression();

      base = _parseCastExpression(
        castNode,
        startPos: startPos,
        id: _finishNode(base),
      );
    }

    return base;
  }

  List<Node> _parseExprList({required NodeType close}) {
    final elements = <Node>[];
    var first = true;

    while (!_eat(close)) {
      if (!first) {
        _expect(NodeType.comma);
      } else {
        first = false;
      }

      elements.add(_parseMaybeAssign());
    }

    return elements;
  }

  Literal _parseLiteral(dynamic value) {
    final node = _startNode().toLiteral();
    node.value = value;

    node.raw = _content.substring(_start, _end);

    _goNext();

    return _finishNode(node);
  }

  void _parseFunctionParams(FunctionStatement node) {
    _expect(NodeType.parenL);
    node.params = _parseBindingList(NodeType.parenR, false);
  }

  List<Node> _parseBindingList(NodeType type, bool allowEmpty) {
    final elements = <Node>[];
    var first = true;

    while (!_eat(type)) {
      if (first) {
        first = false;
      } else {
        _expect(NodeType.comma);
      }

      final elem = _parseFunctionParamMaybeDefault(_start, null);

      elements.add(elem);
    }

    return elements;
  }

  void _expect(NodeType type) {
    if (!_eat(type)) {
      throw UnexpectedTokenException(
        start: _pos,
        end: _pos,
      );
    }
  }

  bool _eat(NodeType type) {
    if (_type == type) {
      _goNext();

      return true;
    }

    return false;
  }

  Identifier _parseIdentifier() {
    final node = _startNode().toIdentifier();

    if (_type == NodeType.name) {
      node.name = _value.toString();
    } else if (_isKeyword(_type)) {
      node.name = _keywordName(_type);
    } else {
      throw UnexpectedTokenException(
        start: _pos,
        end: _pos,
      );
    }

    _goNext();

    return _finishNode(node);
  }

  void _nextToken() {
    _pos = _skipSpace();
    _start = _pos;

    if (_pos >= _content.length) return _finishToken(NodeType.eof);

    if (_shouldSkipParens) {
      final startPos = _pos;
      _pos = _skipParens();

      if (_pos > startPos) {
        _foundParens = true;
      }

      _start = _pos;
    } else {
      _foundParens = false;
    }

    if (_pos >= _content.length) return _finishToken(NodeType.eof);

    final code = _fullCodeUnitAtPos();

    if (code == null) return;

    return _readToken(code);
  }

  void _readToken(int code) {
    if (_isIdentifierStart(code) || code == $backslash) {
      return _readWord();
    }

    return _tokenFromCode(code);
  }

  void _finishToken(NodeType type, {dynamic? val}) {
    _end = _pos;
    final prevType = _type;
    _type = type;
    _value = val;

    _context.addToken(prevType);
  }

  T _finishNode<T extends Node>(T node, {int? pos, NodeType? type}) {
    final usedPos = pos ?? _lastTokenEnd;

    node.type = type ?? node.type;
    node.end = usedPos;

    _context.addNode(node);

    return node;
  }

  bool _isIdentifierStart(int code) {
    if (code < $A) return code == $$;
    if (code < $open_bracket) return true;
    if (code < $a) return code == $underscore;
    if (code < $open_brace) return true;
    if (code <= 0xffff /* 65535 */) return code >= 0xaa /* 170 */;

    return false;
  }

  bool _isIdentifierChar(int code) {
    if (code < $0) return code == $$;
    if (code < $colon) return true;
    if (code < $A) return false;
    if (code < $open_bracket) return true;
    if (code < $a) return code == $underscore;
    if (code < $open_brace) return true;
    if (code < 0xffff) return code > 0xaa;

    return false;
  }

  void _readWord() {
    final word = _readWord1();

    var type = NodeType.name;

    if (_options.throwWhenMissingScriptname &&
        _isFirstRead &&
        word.toLowerCase() != 'scriptname') {
      throw ScriptNameException(start: _start, end: _lastTokenEnd, pos: _pos);
    }

    if (_keywords.hasMatch(word)) {
      type = keywordsMap[word.toLowerCase()] ?? type;
    }

    _isFirstRead = false;
    _finishToken(type, val: word);
  }

  String _readWord1() {
    var chunkStart = _pos;

    while (_pos < _content.length) {
      final ch = _fullCodeUnitAtPos();

      if (ch == null) {
        break;
      }

      if (_isIdentifierChar(ch)) {
        _pos += ch <= 0xffff ? 1 : 2;
      } else {
        break;
      }
    }

    return _content.substring(chunkStart, _pos);
  }

  dynamic _tokenFromCode(int code) {
    switch (code) {
      case $dot:
        return _readTokenDot();
      case $open_paren:
        ++_pos;
        return _finishToken(NodeType.parenL);
      case $close_paren:
        ++_pos;
        return _finishToken(NodeType.parenR);
      case $comma:
        ++_pos;
        return _finishToken(NodeType.comma);
      case $open_bracket:
        ++_pos;
        return _finishToken(NodeType.bracketL);
      case $close_bracket:
        ++_pos;
        return _finishToken(NodeType.bracketR);
      case $colon:
        ++_pos;
        return _finishToken(NodeType.colon);
      case $0:
        final next = _next;

        if (next == $x || next == $X) return _readRadixNumber(16);

        continue number;
      number:
      case $1:
      case $2:
      case $3:
      case $4:
      case $5:
      case $6:
      case $7:
      case $8:
      case $9:
        return _readNumber(false);
      case $double_quote:
        return _readString(code);
      case $single_quote:
        return _readChar(code);
      case $slash:
        return _readTokenSlash();
      case $percent:
      case $asterisk:
        return _readTokenMultModule(code);
      case $pipe:
      case $amp:
        return _readTokenPipeAmp(code);
      case $plus:
      case $minus:
        return _readTokenPlusMin(code);
      case $greater_than:
      case $less_than:
        return _readTokenGtLt(code);
      case $equal:
      case $exclamation:
        return _readTokenEqualExclamation(code);
      case $tilde:
        return _finishOp(NodeType.prefix, 1);
    }

    throw UnexpectedTokenException(
      start: _pos,
      end: _pos,
    );
  }

  int? _fullCodeUnitAtPos({int? pos}) {
    final code = _currentCodeUnit(pos: pos ?? _pos);

    if (code == null) return null;

    if (code < 0xd7ff /* 55295 */ || code >= 0xe000 /* 57344 */) {
      return code;
    }

    final next = _next;

    return (code << 10) + next - 0x35fdc00 /* 56613888 */;
  }

  int _skipParens() {
    var pos = _pos;

    loop:
    while (pos < _content.length) {
      final ch = _currentCodeUnit(pos: pos);

      switch (ch) {
        case $open_paren:
          ++pos;
          break;
        case $close_paren:
          ++pos;
          break;
        default:
          break loop;
      }
    }

    return pos;
  }

  int _skipSpace() {
    var pos = _pos;

    loop:
    while (pos < _content.length) {
      final ch = _currentCodeUnit(pos: pos);

      switch (ch) {
        case $space:
          ++pos;
          break;
        case $cr:
          if (_next == $lf) {
            ++pos;
          }
          continue lf;
        lf:
        case $lf:
          ++pos;
          break;
        case $semicolon:
          if (_next == $slash) {
            final newPos = _skipBlockComment(pos: pos);

            pos = newPos;
          } else {
            final newPos = _skipLineComment(pos: pos, skip: 2);

            pos = newPos;
          }
          break;
        case $open_brace:
          final newPos = _skipDocComment(pos: pos);

          pos = newPos;
          break;
        default:
          if (ch != null && ch > $bs && ch < $cr) {
            ++pos;
            break;
          } else {
            break loop;
          }
      }
    }

    return pos;
  }

  int _skipLineComment({required int pos, required int skip}) {
    var ch = _content.codeUnitAt(pos += skip);

    while (pos < _content.length && !_isNewLine(ch)) {
      ch = _content.codeUnitAt(++pos);
    }

    return pos;
  }

  int _skipDocComment({required int pos}) {
    final startPos = pos;
    final end = _content.indexOf(r'}', pos += 1);

    if (end == -1) {
      throw UnexpectedTokenException(
        message: 'Doc comment is not closed',
        start: startPos,
        end: _pos,
      );
    }

    pos = end + 1;

    return pos;
  }

  int _skipBlockComment({required int pos}) {
    final startPos = pos;
    final end = _content.indexOf('/;', pos += 2);

    if (end == -1) {
      throw UnexpectedTokenException(
        message: 'Block comment is not closed',
        start: startPos,
        end: _content.length,
      );
    }

    pos = end + 2;

    return pos;
  }

  bool _isNewLine(int? code) {
    return code == $lf || code == $cr;
  }

  void _finishOp(NodeType type, int size) {
    final str = _content.substring(_pos, _pos + size);
    _pos += size;

    _finishToken(type, val: str);
  }

  void _readTokenDot() {
    final next = _next;

    if (next >= $0 && next <= $9) return _readNumber(true);

    ++_pos;

    return _finishToken(NodeType.dot);
  }

  void _readTokenMultModule(int code) {
    var next = _next;
    var size = 1;
    var tokenType = code == $asterisk ? NodeType.star : NodeType.modulo;

    if (code == $asterisk && next == $asterisk) {
      ++size;
      tokenType = NodeType.starstar;

      next = _content.codeUnitAt(_pos + 2);
    }

    if (next == $equal) return _finishOp(NodeType.assign, size + 1);

    _finishOp(tokenType, size);
  }

  void _readTokenGtLt(int code) {
    final next = _next;
    var size = 1;

    if (next == $equal) {
      size = 2;
    }

    _finishOp(NodeType.relational, size);
  }

  void _readTokenEqualExclamation(int code) {
    final next = _next;

    if (next == $equal) return _finishOp(NodeType.equality, 2);

    return _finishOp(code == $equal ? NodeType.assign : NodeType.prefix, 1);
  }

  void _readTokenSlash() {
    final next = _next;

    if (next == $equal) return _finishOp(NodeType.assign, 2);

    _finishOp(NodeType.slash, 1);
  }

  void _readTokenPipeAmp(int code) {
    final next = _next;

    if (next == code) {
      return _finishOp(
        code == $pipe ? NodeType.logicalOr : NodeType.logicalAnd,
        2,
      );
    }

    if (code == $equal) return _finishOp(NodeType.assign, 2);
  }

  void _readTokenPlusMin(int code) {
    final next = _next;

    if (next == code) {
      return _finishOp(NodeType.incrementDecrement, 2);
    }

    if (next == $equal) return _finishOp(NodeType.assign, 2);

    _finishOp(NodeType.plusMinus, 1);
  }

  void _readRadixNumber(int base) {
    _pos += 2;
    final val = _readInt(base, null);

    if (val == null) {
      throw UnexpectedTokenException(
        message: 'Invalid number',
        start: _pos,
        end: _pos,
      );
    }

    final code = _fullCodeUnitAtPos();

    if (code != null && _isIdentifierStart(code)) {
      throw UnexpectedTokenException(
        message: 'Unexpected Identifier',
        start: _pos,
        end: _pos,
      );
    }

    return _finishToken(NodeType.num, val: val);
  }

  void _readNumber(bool startsWithDot) {
    final start = _pos;

    if (!startsWithDot && _readInt(10, null) == null) {
      throw UnexpectedTokenException(
        message: 'Invalid number',
        start: _pos,
        end: _pos,
      );
    }

    var next = _currentCodeUnit();

    if (next == $dot) {
      ++_pos;
      _readInt(10, null);
      next = _currentCodeUnit();
    }

    if (next == $E || next == $e) {
      next = _content.codeUnitAt(++_pos);

      if (next == $plus || next == $minus) {
        ++_pos;
      }

      if (_readInt(10, null) == null) {
        throw UnexpectedTokenException(
          message: 'Invalid number',
          start: _pos,
          end: _pos,
        );
      }
    }

    final code = _fullCodeUnitAtPos();

    if (code != null && _isIdentifierStart(code)) {
      throw UnexpectedTokenException(
        message: 'Unexpected Identifier',
        start: _pos,
        end: _pos,
      );
    }

    final raw = _content.substring(start, _pos);
    num val;

    if (raw.codeUnits.contains($dot)) {
      val = _stringToDouble(raw);
    } else {
      val = _stringToInt(raw);
    }

    _finishToken(NodeType.num, val: val);
  }

  String _readString(int code) {
    var out = '';
    var chunkStart = ++_pos;

    while (true) {
      if (_pos >= _content.length) {
        throw UnexpectedTokenException(
          message: 'String is not closed',
          start: chunkStart,
          end: _pos,
        );
      }

      final ch = _currentCodeUnit();

      if (ch == $double_quote) {
        break;
      }

      if (ch == $backslash) {
        out += _content.substring(chunkStart, _pos);
        out += _readEscapedChar();
        chunkStart = _pos;
      } else {
        if (_isNewLine(ch)) {
          throw UnexpectedTokenException(
            message: 'String is not closed',
            start: _pos,
            end: _pos,
          );
        }

        ++_pos;
      }
    }

    out += _content.substring(chunkStart, _pos++);

    _finishToken(NodeType.string, val: out);

    return out;
  }

  String _readChar(int code) {
    var out = '';
    var chunkStart = ++_pos;

    while (true) {
      if (_pos >= _content.length) {
        throw UnexpectedTokenException(
          message: 'Unexpected Identifier',
          start: chunkStart,
          end: _pos,
        );
      }

      final ch = _currentCodeUnit();

      if (ch == $single_quote) {
        break;
      }

      if (_isNewLine(ch) || (_pos - chunkStart) == 2) {
        throw UnexpectedTokenException(
          message: 'Char is not closed',
          start: _pos,
          end: _pos,
        );
      }

      ++_pos;
    }

    out += _content.substring(chunkStart, _pos++);

    _finishToken(NodeType.char, val: out);

    return out;
  }

  int? _readInt(int radix, double? len) {
    final start = _pos;
    var total = 0;

    for (var i = 0; i < (len ?? double.infinity); ++i, ++_pos) {
      try {
        final code = _currentCodeUnit();
        int? val;

        if (code == null) break;

        if (code >= $a) {
          val = code - $a + 10;
        } else if (code >= $A) {
          val = code - $A + 10;
        } else if (code >= $0 && code <= $9) {
          val = code - $0;
        } else {
          val = null;
        }

        if ((val ?? double.infinity) >= radix) {
          break;
        }

        total = total * radix + (val ?? 0);
      } on RangeError catch (_) {
        return total;
      }
    }

    if (_pos == start || len != null && _pos - start != len) return null;

    return total;
  }

  int _stringToInt(String str) => int.parse(str);
  double _stringToDouble(String str) => double.parse(str);

  String _readEscapedChar() {
    final ch = _content.codeUnitAt(++_pos);
    ++_pos;

    switch (ch) {
      case $n:
        return '\n';
      case $r:
        return '\r';
      case $x:
        return String.fromCharCode(_readHexChar(2));
      case $t:
        return '\t';
      case $b:
        return '\b';
      case $v:
        return '\u000b';
      case $f:
        return '\f';
      case $cr:
        if (_currentCodeUnit() == $lf) {
          ++_pos;
        }
        continue lf;
      lf:
      case $lf:
        return '';
      default:
        if (_isNewLine(ch)) return '';

        return String.fromCharCode(ch);
    }
  }

  int _readHexChar(double size) {
    final codePos = _pos;
    final n = _readInt(16, size);

    if (n == null) {
      print(codePos);
      throw UnexpectedTokenException(
        start: _pos,
        end: _pos,
      );
    }

    return n;
  }

  bool _isKeyword(NodeType type) {
    return keywordsMap.containsValue(type);
  }

  String _keywordName(NodeType type) {
    return keywordsMap.entries
        .firstWhere((element) => element.value == type)
        .key;
  }

  bool _hasNewLineBetweenLastToken() {
    final contentBetweenExtendsAndNextToken =
        _content.substring(_lastTokenEnd, _end);

    return contentBetweenExtendsAndNextToken.codeUnits.contains($lf) ||
        contentBetweenExtendsAndNextToken.codeUnits.contains($cr);
  }

  NodeType _close(NodeType type) {
    switch (type) {
      case NodeType.functionKw:
        return NodeType.endFunctionKw;
      case NodeType.ifKw:
      case NodeType.elseIfKw:
      case NodeType.elseKw:
        return NodeType.endIfKw;
      case NodeType.whileKw:
        return NodeType.endWhileKw;
      case NodeType.stateKw:
        return NodeType.endStateKw;
      case NodeType.eventKw:
        return NodeType.endEventKw;
      case NodeType.propertyKw:
        return NodeType.endPropertyKw;
      default:
        // TODO: error type has no close type

        throw Exception();
    }
  }
}
