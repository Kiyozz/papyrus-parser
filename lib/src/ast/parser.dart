import 'package:charcode/ascii.dart';
import 'package:collection/collection.dart';

import 'exception.dart';
import 'node.dart';
import 'options.dart';
import 'position.dart';
import 'property.dart';
import 'types.dart';

class _Context {
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
class Parser {
  Parser({
    required String content,
    ParserOptions options = const ParserOptions(),
    String? filename,
    int start = 0,
    Position startPos = const Position(line: 0, character: 0),
  })  : _content = content,
        _options = options,
        _filename = filename,
        _start = start,
        _startPos = startPos;

  final String? _filename;
  final String _content;
  final ParserOptions _options;
  Position _startPos = Position(line: 0, character: 0);
  Position _endPos = Position(line: 0, character: 0);

  Position get _currentPos {
    return Position(line: _currentLine, character: _currentCharacter);
  }

  /// The current position of the tokenizer in the _content
  int _effectivePos = 0;

  set _pos(int v) {
    var diff = _pos;

    while (diff < v) {
      if (_currentCodeUnitAt(pos: diff) == $lf) {
        ++_currentLine;
        _currentCharacter = 0;
      } else {
        ++_currentCharacter;
      }
      diff++;
    }

    _effectivePos = v;
  }

  int get _pos => _effectivePos;

  int _currentLine = 0;
  int _currentCharacter = 0;

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

  /// Position information for the previous token
  Position _lastTokenStartPos = Position(line: 0, character: 0);

  /// Position information for the previous token
  Position _lastTokenEndPos = Position(line: 0, character: 0);

  /// Is parsing inside of FunctionStatement
  bool _isInFunction = false;

  /// Is parsing inside of EventStatement
  bool _isInEvent = false;

  /// Is parsing inside of StateStatement
  bool _isInState = false;

  bool get _isInFunctionContext => _isInFunction || _isInEvent;
  bool get _isInValidContext => _isInFunctionContext || _isInState;

  /// The context stack is used to superficially track syntactic
  /// context to predict whether a regular expression is allowed in a
  /// given position
  final _context = _Context();

  /// Checks any keyword presence
  final _keywords = RegExp(
    r'^(?:as|auto|autoreadonly|conditional|hidden|bool|else|elseif|endevent|endfunction|endif|endproperty|endstate|endwhile|event|extends|false|float|function|global|if|import|int|native|new|none|parent|property|return|scriptname|self|state|string|true|while)$',
    caseSensitive: false,
  );

  /// Checks presence of endproperty keyword
  final _endProperty = RegExp(r'endproperty', caseSensitive: false);

  int get _next => _content.codeUnitAt(_pos + 1);

  ScriptNameStatement? _scriptName;

  Program parse() {
    final program = _startNode().toProgram();

    _nextToken();

    return _parseTopLevel(program);
  }

  Node _startNode() {
    return Node(start: _start, startPos: _startPos);
  }

  Node _startNodeAt(int pos, Position startPos) {
    return Node(start: pos, startPos: startPos);
  }

  Program _parseTopLevel(Program program) {
    while (_type != NodeType.eof) {
      final statement = _parseStatement();

      program.body.add(statement);
    }

    if (_options.throwScriptnameMissing && !program.hasScriptName) {
      throw ScriptNameException(
        message: 'ScriptName statement is not complete',
        start: program.start,
        end: program.start,
        startPos: program.startPos,
        endPos: program.startPos,
      );
    }

    _goNext();

    return _finishNode(program);
  }

  int? _currentCodeUnitAt({int? pos}) {
    try {
      return _content.codeUnitAt(pos ?? _pos);
    } on RangeError catch (_) {
      return null;
    }
  }

  void _goNext() {
    _lastTokenEnd = _end;
    _lastTokenStart = _start;
    _lastTokenEndPos = _endPos;
    _lastTokenStartPos = _startPos;
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
      case NodeType.importKw:
        return _parseImport();
      default:
        final start = _start;
        final startPos = _startPos;

        if (_type == NodeType.autoKw) {
          final autoType = _type;
          final autoRaw = _value;

          _goNext();

          if (_type == NodeType.stateKw) {
            return _parseStateStatement(
              node.toStateStatement(),
              start: start,
              startPos: startPos,
              flag: autoType,
              raw: autoRaw,
            );
          }
        }

        final currentPos = _skipSpace();
        final currentCode = _fullCodeUnitAtPos(pos: currentPos);
        final isName = startType == NodeType.name;
        final nextPos = _skipSpace(startPos: currentPos + 1);
        final nextCode = _fullCodeUnitAtPos(pos: nextPos);
        final isDot = currentCode == $dot;
        final isOpenBracket = currentCode == $open_bracket;
        final isNextCloseBracket = nextCode == $close_bracket;
        final isNotMember =
            isOpenBracket ? isOpenBracket && isNextCloseBracket : true;

        if (isName && !isDot && isNotMember) {
          var potentialVariableType = _value;
          var isArray = false;
          var nextPos = _skipSpace();
          var nextCode = _fullCodeUnitAtPos(pos: nextPos);

          switch (nextCode) {
            case $equal:
            case $plus:
            case $minus:
            case $asterisk:
            case $slash:
            case $percent:
              return _parseExpression();
            case $open_bracket:
              _goNext();
              nextPos = _skipSpace();
              nextCode = _fullCodeUnitAtPos(pos: nextPos);

              if (nextCode == $close_bracket) {
                _goNext();
                potentialVariableType += '[]';
                isArray = true;
              }
          }

          _goNext();

          if (_type == NodeType.asKw) {
            final identifier = _startNodeAt(start, startPos).toIdentifier();
            identifier.name = potentialVariableType;

            return _parseCastExpression(
              node.toCastExpression(),
              id: _finishNode(identifier),
            );
          }

          if (_type == NodeType.functionKw) {
            final functionNode = node.toFunctionStatement();

            functionNode.start = start;
            functionNode.startPos = startPos;
            functionNode.kind = potentialVariableType;

            return _parseFunctionStatement(functionNode);
          }

          if (_type == NodeType.parenL) {
            final id = node.toIdentifier();
            id.name = potentialVariableType;

            return _parseSubscripts(id, start, startPos);
          }

          if (_type == NodeType.propertyKw) {
            return _parsePropertyDeclaration(
              kind: potentialVariableType,
              start: start,
              startPos: startPos,
            );
          }

          if (_type == NodeType.name) {
            return _parseVariableDeclaration(
              kind: potentialVariableType,
              start: start,
              startPos: startPos,
              isArray: isArray,
            );
          }
        }

        if (_isNewLine(_currentCodeUnitAt())) {
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
    if (_isInEvent || _isInFunction) {
      throw UnexpectedTokenException(
        message: 'A ${_isInFunction ? 'Function' : 'Event'}'
            'Statement cannot have '
            'Functions, States, or Events inside his BlockStatement',
        start: node.start,
        end: node.end,
        startPos: node.startPos,
        endPos: node.endPos,
      );
    }

    _isInEvent = true;
    node.meta = _parseIdentifier();
    node.id = _parseIdentifier();
    _expect(NodeType.parenL);
    node.params = _parseBindingList(NodeType.parenR, false);

    var hasNative = false;

    EventFlagException throwError() {
      return EventFlagException(
        flag: _value,
        start: _start,
        end: _pos,
        startPos: _startPos,
        endPos: _currentPos,
      );
    }

    EventFlagDeclaration createFlag(EventFlag flag, String raw) {
      final declaration = _startNode().toEventFlagDeclaration();
      declaration.flag = flag;
      declaration.raw = raw;

      return _finishNode(declaration, end: _pos, endPos: _currentPos);
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
        node.flags.add(createFlag(EventFlag.native, _value));
        hasNative = true;
        _goNext();
      } else {
        throw throwError();
      }
    }

    if (!node.isNative) {
      node.body = _parseBlock(null, [NodeType.endEventKw], next: false);
      node.endMeta = _parseIdentifier();
    }

    node = _finishNode(node);
    _isInEvent = false;

    return node;
  }

  Node _parseStateStatement(
    StateStatement node, {
    NodeType? flag,
    String? raw,
    int? start,
    Position? startPos,
  }) {
    if (_isInFunction || _isInEvent) {
      throw UnexpectedTokenException(
        message: 'A ${_isInFunction ? 'Function' : 'Event'}'
            'Statement cannot have '
            'Functions, States, or Events inside his BlockStatement',
        start: node.start,
        end: _pos,
        startPos: node.startPos,
        endPos: _currentPos,
      );
    }

    _isInState = true;
    if (flag == NodeType.autoKw &&
        raw != null &&
        start != null &&
        startPos != null) {
      final flagDeclaration =
          _startNodeAt(start, startPos).toStateFlagDeclaration();

      flagDeclaration.flag = StateFlag.auto;
      flagDeclaration.raw = raw;

      node.flag = _finishNode(flagDeclaration);
    }

    if (node.isAuto && start != null) {
      node.start = start;
    }

    if (node.isAuto && startPos != null) {
      node.startPos = startPos;
    }

    _goNext();

    node.id = _parseIdentifier();
    node.body = _parseBlock(null, [NodeType.endStateKw]);

    if (!node.isValid) {
      throw StateStatementException(
        'StateStatement can only contains FunctionStatement or EventStatement',
        start: node.start,
        end: node.id.end,
        startPos: node.startPos,
        endPos: node.id.endPos,
      );
    }

    _isInState = false;

    return _finishNode(node);
  }

  CastExpression _parseCastExpression(
    CastExpression node, {
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
    if (_options.throwReturnOutside && !_isInFunction) {
      throw UnexpectedTokenException(
        start: node.start,
        end: _pos,
        startPos: node.startPos,
        endPos: _currentPos,
        message: 'Return statement can only be used in Function',
      );
    }

    _goNext();

    if (!_hasNewLineBetweenLastToken()) {
      node.argument = _parseExpression();
    }

    return _finishNode(node);
  }

  Node _parsePropertyDeclaration({
    required int start,
    required Position startPos,
    required String kind,
  }) {
    var node = _startNodeAt(start, startPos).toPropertyDeclaration();

    if (_isInFunctionContext) {
      throw PropertyException(
        'Cannot use a property inside of Function/Event',
        start: node.start,
        end: _pos,
        startPos: node.startPos,
        endPos: _currentPos,
      );
    }

    node.meta = _parseIdentifier();
    node.id = _parseIdentifier();
    node.kind = kind;

    final name = node.id.name;

    if (_eat(NodeType.assign)) {
      node.init = _parseMaybeAssign();

      if (node.init?.type != NodeType.literal) {
        throw PropertyException(
          '"$name" Property init declaration should be a constant',
          start: _pos,
          end: _pos,
          startPos: _currentPos,
          endPos: _currentPos,
        );
      }
    }

    var lastFlagEnd = _pos;
    var lastFlagEndPos = _currentPos;

    while (_type == NodeType.hiddenKw ||
        _type == NodeType.autoKw ||
        _type == NodeType.conditionalKw ||
        _type == NodeType.autoReadOnlyKw) {
      final flagDeclaration = _startNode().toPropertyFlagDeclaration();

      flagDeclaration.flag = flagDeclaration.flagFromType(_type);
      flagDeclaration.raw = _value;

      node.flags.add(
        _finishNode(
          flagDeclaration,
          end: lastFlagEnd,
          endPos: lastFlagEndPos,
        ),
      );

      lastFlagEnd = _pos;
      lastFlagEndPos = _currentPos;

      _goNext();
    }

    final isScriptNameConditional = _scriptName?.isConditional ?? false;

    if (node.isConditional && !isScriptNameConditional) {
      throw PropertyException(
        'Conditional Property "$name" must appears in ScriptName flagged Conditional',
        start: node.start,
        end: lastFlagEnd,
        startPos: node.startPos,
        endPos: lastFlagEndPos,
      );
    }

    if (node.isAutoReadonly && node.init == null) {
      throw PropertyException(
        'AutoReadOnly Property "$name" should have a constant init declaration',
        start: node.start,
        end: _pos,
        startPos: node.startPos,
        endPos: _currentPos,
      );
    }

    if (node.isConditional && !node.isAutoOrAutoReadonly) {
      throw PropertyException(
        'Conditional Property "$name" must be Auto or AutoReadOnly',
        start: node.start,
        end: _pos,
        startPos: node.startPos,
        endPos: _currentPos,
      );
    }

    if (node.isConditional && node.init == null) {
      throw PropertyException(
        'A Conditional Property must have an constant init declaration',
        start: node.start,
        end: _pos,
        startPos: node.startPos,
        endPos: _currentPos,
      );
    }

    if (node.hasNoFlags || node.isHidden) {
      if (node.hasNoFlags) {
        throw PropertyException(
          'Missing Hidden flag for Full Property "$name"',
          start: node.start,
          end: _pos,
          startPos: node.startPos,
          endPos: _currentPos,
        );
      }

      final hasEndProperty = _content.contains(_endProperty, _start);

      if (!hasEndProperty) {
        throw PropertyException(
          'Missing "EndProperty" for "$name" Property',
          start: node.start,
          end: _pos,
          startPos: node.startPos,
          endPos: _currentPos,
        );
      }

      final fullNode = node.toPropertyFullDeclaration();

      var block = _parseBlock(
        _startNode().toBlockStatement(),
        [NodeType.endPropertyKw],
        next: false,
      );

      fullNode.endMeta = _parseIdentifier();

      if (block.body.isEmpty) {
        throw PropertyException(
          'Full property "$name" must have a getter and/or a setter',
          start: node.start,
          end: block.end,
          startPos: node.startPos,
          endPos: block.endPos,
        );
      }

      try {
        final getter = block.body.firstWhereOrNull(
            (element) => PropertyParser(element: element).isGetter);
        final setter = block.body.firstWhereOrNull(
            (element) => PropertyParser(element: element).isSetter);
        if (setter != null) {
          fullNode.setter = setter as FunctionStatement;

          final isEmpty = setter.params.isEmpty;
          final hasMoreOneParams = setter.params.length > 1;
          final isNotSameKind = setter.params.isNotEmpty &&
              setter.params.first.variable.kind != node.kind;

          if (isEmpty || hasMoreOneParams || isNotSameKind) {
            throw PropertyException(
              'Setter should have one parameter '
              'with the same type as the Property "$name"',
              start: setter.start,
              end: setter.end,
              startPos: setter.startPos,
              endPos: setter.endPos,
            );
          }
        }

        if (getter != null) {
          fullNode.getter = getter as FunctionStatement;

          if (getter.kind != node.kind) {
            throw PropertyException(
              'Getter should return the same type as the Property "$name"',
              start: getter.start,
              end: getter.end,
              startPos: getter.startPos,
              endPos: getter.endPos,
            );
          }

          if (getter.params.isNotEmpty) {
            throw PropertyException(
              'Property "$name" getter cannot have parameters',
              start: getter.start,
              end: getter.end,
              startPos: getter.startPos,
              endPos: getter.endPos,
            );
          }
        }

        node = fullNode;
      } on Exception catch (e) {
        throw PropertyException(
          e.toString(),
          start: start,
          end: _end,
          startPos: startPos,
          endPos: _endPos,
        );
      }
    }

    return _finishNode(node);
  }

  Node _parseScriptNameStatement(ScriptNameStatement node) {
    if (_scriptName != null) {
      throw ScriptNameException(
        message: 'ScriptName cannot appears more than once in a script',
        start: _pos,
        end: _pos,
        startPos: _currentPos,
        endPos: _currentPos,
      );
    }

    node.meta = _parseIdentifier();

    if (_type != NodeType.name) {
      throw UnexpectedTokenException(
        start: node.start,
        end: _pos,
        startPos: node.startPos,
        endPos: _currentPos,
      );
    }

    final startPos = _startPos;
    final start = _start;
    node.id = _parseIdentifier();

    final filename = _filename;
    if (_options.throwScriptnameMismatch && filename != null) {
      if (node.id.name.toLowerCase() != filename.toLowerCase()) {
        throw ScriptNameException(
          start: start,
          end: start,
          startPos: startPos,
          endPos: startPos,
          message: 'ScriptNameStatement Identifier must be the same '
              'as the filename ($filename)',
        );
      }
    }

    node.extendsDeclaration = _parseExtends(
      start: node.start,
      startPos: node.startPos,
    );
    node.flags = _parseScriptNameFlags();

    final scriptName = _finishNode(node);

    _scriptName = scriptName;

    return node;
  }

  List<ScriptNameFlagDeclaration> _parseScriptNameFlags() {
    final flags = <ScriptNameFlagDeclaration>[];

    while (_type == NodeType.conditionalKw || _type == NodeType.hiddenKw) {
      final startType = _type;
      final startValue = _value;
      final node = _startNode().toScriptNameFlagDeclaration();

      _goNext();

      node.flag = startType == NodeType.conditionalKw
          ? ScriptNameFlag.conditional
          : ScriptNameFlag.hidden;
      node.raw = startValue;

      flags.add(_finishNode(node));
    }

    return flags;
  }

  ExtendsDeclaration? _parseExtends({
    required int start,
    required Position startPos,
  }) {
    if (_type != NodeType.extendsKw) return null;

    final node = _startNode().toExtendsDeclaration();
    node.meta = _parseIdentifier();

    if (_hasNewLineBetweenLastToken()) {
      throw ScriptNameException(
        message: 'ScriptName statement is not complete',
        start: start,
        end: node.meta.end,
        startPos: startPos,
        endPos: node.meta.endPos,
      );
    }

    node.extended = _parseIdentifier();

    return _finishNode(node);
  }

  VariableDeclaration _parseVariableDeclaration({
    required int start,
    required Position startPos,
    required String kind,
    required bool isArray,
  }) {
    final node = _startNodeAt(start, startPos).toVariableDeclaration();
    final variable = _startNodeAt(start, startPos).toVariable();

    variable.id = _parseIdentifier();
    variable.start = variable.id.start;
    variable.startPos = variable.id.startPos;
    variable.kind = kind;
    variable.isArray = isArray;

    if (_eat(NodeType.assign)) {
      variable.init = _parseMaybeAssign();
    } else if (variable.id.type != NodeType.id) {
      throw UnexpectedTokenException(
        message: 'Cannot find variable name',
        start: variable.start,
        end: _pos,
        startPos: variable.startPos,
        endPos: _currentPos,
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
    if (_options.throwWhileOutside && !_isInFunctionContext) {
      throw UnexpectedTokenException(
        message: 'Cannot use WhileStatement outside of a Function/Event',
        start: node.start,
        end: _pos,
        startPos: node.startPos,
        endPos: _currentPos,
      );
    }

    node.meta = _parseIdentifier();
    node.test = _parseExpression();
    node.consequent = _parseBlock(null, [NodeType.endWhileKw], next: false);
    node.endMeta = _parseIdentifier();

    return _finishNode(node);
  }

  IfStatement _parseIfStatement(IfStatement node) {
    node.meta = _parseIdentifier();

    if (_options.throwIfOutside && !_isInFunctionContext) {
      throw UnexpectedTokenException(
        message: 'Cannot use IfStatement outside of a Function/Event',
        start: node.start,
        end: _pos,
        startPos: node.startPos,
        endPos: _currentPos,
      );
    }

    node.test = _parseExpression();

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
      node.alternateMeta = _parseIdentifier();

      node.alternate = _parseBlock(null, [NodeType.endIfKw], next: false);
      node.endMeta = _parseIdentifier();
    } else if (_type == NodeType.elseIfKw) {
      final alternate = _parseIfStatement(_startNode().toIfStatement());
      node.alternate = alternate;
      node.endMeta = alternate.endMeta;
    } else {
      node.endMeta = _parseIdentifier();
    }

    return _finishNode(node);
  }

  Node _parseFunctionStatement(FunctionStatement node) {
    if (_isInFunction || _isInEvent) {
      throw UnexpectedTokenException(
        message: 'A ${_isInFunction ? 'Function' : 'Event'}Statement '
            'cannot have Functions, States, or Events '
            'inside his BlockStatement',
        start: node.start,
        end: node.end,
        startPos: node.startPos,
        endPos: node.endPos,
      );
    }

    _isInFunction = true;
    node = _parseFunction(node);

    if (!_isInState) {
      _isInFunction = false;
    }

    return node;
  }

  FunctionStatement _parseFunction(FunctionStatement node) {
    node.meta = _parseIdentifier();
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
        end: _pos,
        startPos: _startPos,
        endPos: _currentPos,
      );
    }

    FunctionFlagDeclaration createFlag(FunctionFlag flag, String raw) {
      final declaration = _startNode().toFunctionFlagDeclaration();
      declaration.flag = flag;
      declaration.raw = raw;

      return _finishNode(declaration, end: _pos, endPos: _currentPos);
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
          node.flags.add(createFlag(FunctionFlag.global, _value));
          hasGlobal = true;
          _goNext();
          break;
        case NodeType.nativeKw:
          node.flags.add(createFlag(FunctionFlag.native, _value));
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

    node.body = _parseBlock(null, [NodeType.endFunctionKw], next: false);
    node.endMeta = _parseIdentifier();
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
        end: _pos,
        startPos: node.startPos,
        endPos: _currentPos,
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
    return _parseMaybeAssign();
  }

  VariableDeclaration _parseFunctionParamMaybeDefault(
    int start,
    Position startPos, [
    Node? left,
  ]) {
    if (_type != NodeType.name) {
      throw UnexpectedTokenException(
        start: start,
        end: _pos,
        startPos: startPos,
        endPos: _currentPos,
      );
    }
    var isArray = false;
    var paramKind = _value;

    _goNext();

    if (_type == NodeType.bracketL) {
      final nextPos = _skipSpace();
      final nextCode = _fullCodeUnitAtPos(pos: nextPos);

      if (nextCode == $close_bracket) {
        paramKind += '[]';
        isArray = true;
        _goNext();
        _goNext();
      }
    }

    return _parseVariableDeclaration(
      kind: paramKind,
      start: start,
      startPos: startPos,
      isArray: isArray,
    );
  }

  Node _parseMaybeAssign() {
    final left = _parseExprOps();

    if (_type == NodeType.assign) {
      final n = _startNode().toAssignExpression();

      n.left = left;
      n.operator = _value;

      _goNext();

      n.right = _parseMaybeAssign();

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

  Node _parseExprOp(Node left, int leftStart) {
    if (_type == NodeType.logicalOr ||
        _type == NodeType.logicalAnd ||
        _type == NodeType.binary ||
        _type == NodeType.plusMinus ||
        _type == NodeType.relational ||
        _type == NodeType.star ||
        _type == NodeType.slash ||
        _type == NodeType.modulo ||
        _type == NodeType.equality) {
      final isLogical =
          _type == NodeType.logicalOr || _type == NodeType.logicalAnd;

      if (_options.throwBinaryOutside && !_isInFunctionContext) {
        throw UnexpectedTokenException(
          message: 'Cannot use a '
              '${isLogical ? 'Logical' : 'Binary'}'
              'Expression outside of Function/Event',
          start: _pos,
          end: _pos,
          startPos: _currentPos,
          endPos: _currentPos,
        );
      }

      final op = _value;
      _goNext();
      final start = _start;
      final startPos = _startPos;
      final right = _parseExprOp(_parseMaybeUnary(), start);
      final node = _buildBinary(
        start: leftStart,
        startPos: startPos,
        left: left,
        right: right,
        operator: op,
        logical: isLogical,
      );

      return _parseExprOp(node, leftStart);
    }

    return left;
  }

  BinaryExpression _buildBinary({
    required int start,
    required Position startPos,
    required Node left,
    required Node right,
    required String operator,
    bool logical = false,
  }) {
    final node = _startNodeAt(start, startPos).toBinaryExpression();

    node.left = left;
    node.operator = operator;
    node.right = right;

    return _finishNode(
      node,
      type: logical ? NodeType.logical : NodeType.binary,
    );
  }

  Node _parseExprSubscripts() {
    final start = _start;
    final startPos = _startPos;
    final expr = _parseExprAtom();

    return _parseSubscripts(expr, start, startPos);
  }

  Node _parseExprAtom() {
    switch (_type) {
      case NodeType.parentKw:
        final parentNode = _startNode().toIdentifier();

        parentNode.name = _value;

        if (_currentCodeUnitAt() == $open_paren) {
          throw ParentMemberException(
            'Parent cannot be used as a function',
            start: parentNode.start,
            end: _pos,
            startPos: parentNode.startPos,
            endPos: _currentPos,
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

      case NodeType.parenL:
        return _parseParenAndDistinguishExpression();

      case NodeType.noneKw:
      case NodeType.falseKw:
      case NodeType.trueKw:
        final literalNode = _startNode().toLiteral()
          ..value = _type == NodeType.noneKw ? null : _type == NodeType.trueKw
          ..raw = _content.substring(_start, _end);

        _goNext();

        return _finishNode(literalNode);
      case NodeType.newKw:
        return _parseNewExpression();
      default:
        throw UnexpectedTokenException(
          start: _pos,
          end: _pos,
          startPos: _currentPos,
          endPos: _currentPos,
        );
    }
  }

  Node _parseParenAndDistinguishExpression() {
    Node? expr;
    var first = true;
    _goNext();

    while (_type != NodeType.parenR) {
      first ? first = false : _expect(NodeType.comma);
      expr = _parseMaybeAssign();
    }

    _expect(NodeType.parenR);

    if (expr == null) {
      throw UnexpectedTokenException(
        start: _lastTokenEnd,
        end: _lastTokenEnd,
        startPos: _startPos,
        endPos: _startPos,
      );
    }

    return expr;
  }

  Node _parseImport() {
    if (_isInValidContext) {
      throw UnexpectedTokenException(
        message: 'ImportStatement cannot appears inside any Statement',
        start: _pos,
        end: _pos,
        startPos: _currentPos,
        endPos: _currentPos,
      );
    }

    final node = _startNode().toImportStatement();

    _goNext();

    if (_type != NodeType.name) {
      throw UnexpectedTokenException(
        message: 'Expected Identifier',
        start: _pos,
        end: _pos,
        startPos: _currentPos,
        endPos: _currentPos,
      );
    }

    node.id = _parseIdentifier();

    return _finishNode(node);
  }

  Node _parseNewExpression() {
    final node = _startNode().toNewExpression();
    final meta = _parseIdentifier();

    if (_options.throwNewOutside && !_isInFunctionContext) {
      throw UnexpectedTokenException(
        message: 'Cannot create arrays outside of Function/Event',
        start: node.start,
        end: _pos,
        startPos: node.startPos,
        endPos: _currentPos,
      );
    }

    node.meta = meta;
    node.argument = _parseExprSubscripts();
    final argument = node.argument;

    if (argument is! MemberExpression) {
      throw UnexpectedTokenException(
        start: argument.start,
        end: argument.end,
        startPos: argument.startPos,
        endPos: argument.endPos,
      );
    }

    if (argument.property is! Literal) {
      throw UnexpectedTokenException(
        message:
            'NewExpression array size must be an Int Literal. Got ${argument.property.runtimeType}',
        start: argument.start,
        end: argument.end,
        startPos: argument.startPos,
        endPos: argument.endPos,
      );
    }

    return _finishNode(node);
  }

  Node _parseSubscripts(Node base, int start, Position startPos) {
    while (true) {
      final element = _parseSubscript(base, start, startPos);

      if (element == base) return element;

      base = element;
    }
  }

  Node _parseSubscript(Node base, int start, Position startPos) {
    final computed = _eat(NodeType.bracketL);

    if (computed || _eat(NodeType.dot)) {
      if (base is Identifier && base.type == NodeType.parentKw) {
        final scriptName = _scriptName;

        if (scriptName != null && scriptName.extendsDeclaration == null) {
          throw ParentMemberException(
            'Cannot use Parent in ScriptName that do not extends Object',
            start: base.start,
            end: _pos,
            startPos: base.startPos,
            endPos: _currentPos,
          );
        }
      }

      if (base is MemberExpression &&
          base.object is Identifier &&
          base.object.type == NodeType.parentKw) {
        final object = base.object as Identifier;

        throw ParentMemberException(
          'Property ${object.name} cannot be used as a MemberExpression',
          start: base.start,
          end: _pos,
          startPos: base.startPos,
          endPos: _currentPos,
        );
      }

      final node = _startNodeAt(start, startPos).toMemberExpression();
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
      if (_options.throwCallOutside && !_isInFunctionContext) {
        throw UnexpectedTokenException(
          message: 'Cannot call a Function outside of a Function/Event',
          start: start,
          end: _pos,
          startPos: startPos,
          endPos: _currentPos,
        );
      }

      final exprList = _parseExprList(close: NodeType.parenR);

      final exprNode = _startNodeAt(start, startPos).toCallExpression();
      exprNode.callee = _finishNode(base);
      exprNode.arguments = exprList;

      base = _finishNode(exprNode);
    } else if (_eat(NodeType.asKw)) {
      if (_options.throwCastOutside && !_isInFunctionContext) {
        throw UnexpectedTokenException(
          message: 'Cannot use CastExpression outside of Function/Event',
          start: start,
          end: _pos,
          startPos: startPos,
          endPos: _currentPos,
        );
      }

      final castNode = _startNodeAt(start, startPos).toCastExpression();

      base = _parseCastExpression(
        castNode,
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

  List<VariableDeclaration> _parseBindingList(NodeType type, bool allowEmpty) {
    final elements = <VariableDeclaration>[];
    var first = true;

    while (!_eat(type)) {
      if (first) {
        first = false;
      } else {
        _expect(NodeType.comma);
      }

      final elem = _parseFunctionParamMaybeDefault(_start, _startPos);

      elements.add(elem);
    }

    return elements;
  }

  void _expect(NodeType type) {
    if (!_eat(type)) {
      throw UnexpectedTokenException(
        start: _pos,
        end: _pos,
        startPos: _currentPos,
        endPos: _currentPos,
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
      node.name = _value.toString();
    } else {
      throw UnexpectedTokenException(
        start: _pos,
        end: _pos,
        startPos: _currentPos,
        endPos: _currentPos,
      );
    }

    _goNext();

    return _finishNode(node);
  }

  void _nextToken() {
    final newPos = _skipSpace();
    _pos = newPos;
    _start = _pos;
    _startPos = _currentPos;

    if (_pos >= _content.length) return _finishToken(NodeType.eof);

    final code = _fullCodeUnitAtPos();

    if (code == null) return;

    _readToken(code);
  }

  void _readToken(int code) {
    if (code == $backslash) {
      ++_pos;
      _goNext();
      final posFirstBackslash = _content.codeUnits.indexOf(
        $backslash,
        _lastTokenEnd,
      );

      if (posFirstBackslash != -1) {
        final position = _numberOfLinesBetweenAt(
          posFirstBackslash,
          to: _end,
        );

        throw UnexpectedTokenException(
          message: 'Unexpected token. '
              'Expected a new line after a LineTerminator',
          start: posFirstBackslash,
          end: _end,
          startPos: position,
          endPos: _endPos,
        );
      }

      return;
    }

    final isThrowScriptName = _options.throwScriptnameMissing && _isFirstRead;

    if (_isIdentifierStart(code)) {
      return _readWord();
    } else if (isThrowScriptName) {
      throw ScriptNameException(
        message: 'ScriptName statement is not complete',
        start: _start,
        end: _pos,
        startPos: _startPos,
        endPos: _currentPos,
      );
    }

    return _tokenFromCode(code);
  }

  void _finishToken(NodeType type, {dynamic? val}) {
    _end = _pos;
    _endPos = _currentPos;
    final prevType = _type;
    _type = type;
    _value = val;

    _context.addToken(prevType);
  }

  T _finishNode<T extends Node>(
    T node, {
    int? end,
    Position? endPos,
    NodeType? type,
  }) {
    node.type = type ?? node.type;
    node.end = end ?? _lastTokenEnd;
    node.endPos = endPos ?? _lastTokenEndPos;

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

    final isThrowScriptName = _options.throwScriptnameMissing && _isFirstRead;

    if (isThrowScriptName && word.toLowerCase() != 'scriptname') {
      throw ScriptNameException(
        message: 'ScriptName statement is not complete',
        start: _start,
        end: _pos,
        startPos: _startPos,
        endPos: _currentPos,
      );
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
      startPos: _currentPos,
      endPos: _currentPos,
    );
  }

  int? _fullCodeUnitAtPos({int? pos}) {
    final code = _currentCodeUnitAt(pos: pos ?? _pos);

    if (code == null) return null;

    if (code < 0xd7ff /* 55295 */ || code >= 0xe000 /* 57344 */) {
      return code;
    }

    final next = _next;

    return (code << 10) + next - 0x35fdc00 /* 56613888 */;
  }

  int _skipSpace({int? startPos}) {
    var pos = startPos ?? _pos;

    loop:
    while (pos < _content.length) {
      final ch = _currentCodeUnitAt(pos: pos);
      final next = _currentCodeUnitAt(pos: pos + 1);

      switch (ch) {
        case $space:
          ++pos;
          break;
        case $cr:
          if (next == $lf) {
            ++pos;
          }
          continue lf;
        lf:
        case $lf:
          ++pos;
          break;
        case $semicolon:
          if (next == $slash) {
            final newPos = _skipBlockComment(
              pos: pos,
            );

            pos = newPos;
          } else {
            final newPos = _skipLineComment(pos: pos, skip: 1);

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
    final start = pos;
    final end = _content.indexOf(r'}', pos += 1);

    if (end == -1) {
      final position = _numberOfLinesBetweenAt(
        start,
        to: end,
      );

      throw UnexpectedTokenException(
        message: 'Doc comment is not closed',
        start: start,
        end: _pos,
        startPos: position,
        endPos: _currentPos,
      );
    }

    pos = end + 1;

    return pos;
  }

  int _skipBlockComment({required int pos}) {
    final start = pos;
    final end = _content.indexOf('/;', pos += 2);

    if (end == -1) {
      final position = _numberOfLinesBetweenAt(
        start,
        to: end,
      );

      throw UnexpectedTokenException(
        message: 'Block comment is not closed',
        start: start,
        end: _pos,
        startPos: position,
        endPos: _currentPos,
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
      throw UnexpectedTokenException(
        message: '"++" and "--" operator is not supported in Papyrus',
        start: _pos,
        end: _pos,
        startPos: _currentPos,
        endPos: _currentPos,
      );
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
        startPos: _currentPos,
        endPos: _currentPos,
      );
    }

    final code = _fullCodeUnitAtPos();

    if (code != null && _isIdentifierStart(code)) {
      throw UnexpectedTokenException(
        message: 'Unexpected Identifier',
        start: _pos,
        end: _pos,
        startPos: _currentPos,
        endPos: _currentPos,
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
        startPos: _currentPos,
        endPos: _currentPos,
      );
    }

    var next = _currentCodeUnitAt();

    if (next == $dot) {
      ++_pos;
      _readInt(10, null);
      next = _currentCodeUnitAt();
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
          startPos: _currentPos,
          endPos: _currentPos,
        );
      }
    }

    final code = _fullCodeUnitAtPos();

    if (code != null && _isIdentifierStart(code)) {
      throw UnexpectedTokenException(
        message: 'Unexpected Identifier',
        start: _pos,
        end: _pos,
        startPos: _currentPos,
        endPos: _currentPos,
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
    var chunkStartPos = _currentPos;

    while (true) {
      if (_pos >= _content.length) {
        throw UnexpectedTokenException(
          message: 'String is not closed',
          start: chunkStart,
          end: _pos,
          startPos: chunkStartPos,
          endPos: _currentPos,
        );
      }

      final ch = _currentCodeUnitAt();

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
            startPos: _currentPos,
            endPos: _currentPos,
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
    var chunkStartPos = _currentPos;

    while (true) {
      if (_pos >= _content.length) {
        throw UnexpectedTokenException(
          message: 'Unexpected Identifier',
          start: chunkStart,
          end: _pos,
          startPos: chunkStartPos,
          endPos: _currentPos,
        );
      }

      final ch = _currentCodeUnitAt();

      if (ch == $single_quote) {
        break;
      }

      if (_isNewLine(ch) || (_pos - chunkStart) == 2) {
        throw UnexpectedTokenException(
          message: 'Char is not closed',
          start: _pos,
          end: _pos,
          startPos: _currentPos,
          endPos: _currentPos,
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
        final code = _currentCodeUnitAt();
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
        if (_currentCodeUnitAt() == $lf) {
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
        startPos: _currentPos,
        endPos: _currentPos,
      );
    }

    return n;
  }

  bool _isKeyword(NodeType type) {
    return keywordsMap.containsValue(type);
  }

  bool _hasNewLineBetweenLastToken() {
    final contentLastToken = _content.substring(_lastTokenEnd, _end);
    final units = contentLastToken.codeUnits;

    return units.contains($lf) || units.contains($cr);
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
        throw UnexpectedTokenException(
          message: 'Unexpected token ${type.name}',
          start: _start,
          end: _end,
          startPos: _startPos,
          endPos: _endPos,
        );
    }
  }

  Position _numberOfLinesBetweenAt(
    int from, {
    required int to,
  }) {
    final lines = _content.substring(from, to).split('\n');
    final lengthLastLine = lines.last.length;

    return Position(
      line: lines.length - 1,
      character: lengthLastLine,
    );
  }
}
