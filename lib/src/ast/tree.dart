import 'package:charcode/ascii.dart';

import 'exception.dart';
import 'types.dart';
import 'node.dart';

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
  final String _content;
  final bool _throwWhenMissingScriptname;

  /// The current position of the tokenizer in the _content
  int _pos = 0;

  /// Type of current token
  NodeType _type = NodeType.eof;

  bool _firstRead = true;

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

  /// The context stack is used to superficially track syntactic
  /// context to predict whether a regular expression is allowed in a
  /// given position
  final _context = Context();

  final _keywords = RegExp(
    r'^(?:as|auto|autoreadonly|conditional|hidden|writeonly|readonly|locked|bool|else|elseif|endevent|endfunction|endif|endproperty|endstate|endwhile|event|extends|false|float|function|global|if|import|int|length|native|new|none|parent|property|return|scriptname|self|state|string|true|while)$',
    caseSensitive: false,
  );

  int get _next => _content.codeUnitAt(_pos + 1);

  Tree({
    required String content,
    bool throwWhenMissingScriptname = true,
  })  : _content = content,
        _throwWhenMissingScriptname = throwWhenMissingScriptname;

  Program parse() {
    // TODO: return statement parse
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

    return _finishNode(program) as Program;
  }

  int _currentCodeUnit({int? pos}) => _content.codeUnitAt(pos ?? _pos);

  void _goNext() {
    _lastTokenEnd = _end;
    _lastTokenStart = _start;
    _nextToken();
  }

  Node _parseStatement({NodeType? context}) {
    final startType = _type;
    final node = _startNode();

    switch (startType) {
      case NodeType.scriptNameKw:
        return _parseScriptNameStatement(node.toScriptName());
      case NodeType.functionKw:
        return _parseFunctionStatement(node.toFunctionStatement());
      case NodeType.ifKw:
        return _parseIfStatement(node.toIfStatement());
      case NodeType.returnKw:
        return _parseReturnStatement(node.toReturnStatement());
      default:
        if (startType == NodeType.name) {
          final potentialVariableType = _value;
          final startPos = _start;

          _goNext();

          if (_type == NodeType.parenL) {
            return _parseSubscripts(node, startPos);
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
          return _parseBlock(node.toBlockStatement(), startType);
        }

        // final maybeName = _value;
        final expr = _parseExpression();

        return _parseExpressionStatement(
          node: node.toExpressionStatement(),
          expr: expr,
        );
    }
  }

  Node _parseReturnStatement(ReturnStatement node) {
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

    node.id = _parseBindingAtom();
    node.kind = kind;

    if (_eat(NodeType.assign)) {
      node.init = _parseMaybeAssign();

      if (node.init?.type != NodeType.literal) {
        // TODO: error, property init should be constant

        throw Exception();
      }
    }

    while (_type == NodeType.hiddenKw ||
        _type == NodeType.autoKw ||
        _type == NodeType.conditionalKw ||
        _type == NodeType.autoReadOnlyKw) {
      final flagDeclaration = _startNode().toPropertyFlagDeclaration();

      flagDeclaration.flag = flagDeclaration.flagFromType(_type);

      node.flags.add(flagDeclaration);

      _goNext();
    }

    if (_hasNewLineBetweenLastToken() &&
        RegExp(r'endproperty', caseSensitive: false)
            .hasMatch(_content.substring(_start))) {
      print('end property');

      node = node.toPropertyFullDeclaration();
    }

    return _finishNode(node);
  }

  Node _parseScriptNameStatement(ScriptName node) {
    _goNext();

    if (_type != NodeType.name) {
      throw UnexpectedTokenException(pos: _start);
    }

    node.id = _parseIdentifier();
    node.extendsDeclaration = _parseExtends();
    node.flags = _parseScriptNameFlags();

    return _finishNode(node);
  }

  List<ScriptNameFlagDeclaration> _parseScriptNameFlags() {
    final flags = <ScriptNameFlagDeclaration>[];

    while (_type == NodeType.conditionalKw || _type == NodeType.hiddenKw) {
      final node = _startNode().toScriptNameFlagDeclaration();

      _goNext();

      node.flag = _type == NodeType.conditionalKw
          ? ScriptNameFlag.conditional
          : ScriptNameFlag.hidden;

      flags.add(_finishNode(node) as ScriptNameFlagDeclaration);
    }

    return flags;
  }

  ExtendsDeclaration? _parseExtends() {
    final node = _startNode().toExtendsDeclaration();

    if (_type != NodeType.extendsKw) {
      return null;
    }

    _goNext();

    if (_hasNewLineBetweenLastToken()) {
      throw ScriptnameException(pos: _start);
    }

    node.extended = _parseIdentifier();

    return _finishNode(node) as ExtendsDeclaration;
  }

  VariableDeclaration _parseVariableDeclaration({
    required int start,
    required String kind,
  }) {
    final node = _startNodeAt(start).toVariableDeclaration();
    final variable = _startNode().toVariable();

    variable.id = _parseBindingAtom();
    variable.kind = kind;

    if (_eat(NodeType.assign)) {
      variable.init = _parseMaybeAssign();
    } else if (variable.id?.type != NodeType.id) {
      // TODO: error unexpected

      throw Exception();
    }

    node.variable = _finishNode(variable) as Variable;

    return _finishNode(node) as VariableDeclaration;
  }

  Node _parseExpressionStatement({
    required ExpressionStatement node,
    required Node expr,
  }) {
    node.expression = expr;

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

    node.consequent = _parseBlock(null, NodeType.ifKw);
    node.alternate = _eat(NodeType.elseKw) || _eat(NodeType.elseIfKw)
        ? _parseStatement(
            context:
                _eat(NodeType.elseKw) ? NodeType.elseKw : NodeType.elseIfKw,
          )
        : null;

    return _finishNode(node);
  }

  Node _parseFunctionStatement(FunctionStatement node) {
    _goNext();

    return _parseFunction(node);
  }

  Node _parseFunction(FunctionStatement node) {
    node.id = _parseIdentifier();

    _parseFunctionParams(node);
    _parseFunctionBody(node);

    return _finishNode(node);
  }

  void _parseFunctionBody(FunctionStatement node) {
    node.body = [_parseBlock(null, NodeType.functionKw)];
  }

  Node _parseBlock(BlockStatement? usedNode, NodeType type) {
    final node = usedNode ?? _startNode().toBlockStatement();

    final closeType = _close(type);

    if (_type == NodeType.eof) {
      // TODO: error missing end

      throw Exception();
    }

    while (_type != closeType) {
      final statement = _parseStatement();

      node.body.add(statement);
    }

    _goNext();

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

  Assign _parseMaybeDefault(int startPos, Node? left) {
    left = left ?? _parseBindingAtom();

    final node = _startNodeAt(startPos).toAssign();

    node.left = left;
    node.right = _parseMaybeAssign();

    return _finishNode(node) as Assign;
  }

  Node _parseMaybeAssign() {
    final left = _parseMaybeConditional();

    if (_type == NodeType.assign) {
      // TODO: is assign
    }

    return left;
  }

  Node _parseMaybeConditional() {
    final expr = _parseExprOps();

    return expr;
  }

  Identifier _parseBindingAtom() {
    return _parseIdentifier();
  }

  Node _parseExprOps() {
    final startPos = _start;
    final expr = _parseMaybeUnary();

    return _parseExprOp(expr, startPos);
  }

  Node _parseExprOp(Node left, int leftStartPos) {
    if (_type == NodeType.logicalOR ||
        _type == NodeType.logicalAND ||
        _type == NodeType.binary ||
        _type == NodeType.equality) {
      final logical =
          _type == NodeType.logicalOR || _type == NodeType.logicalAND;
      final op = _value;
      _goNext();
      final startPos = _start;
      final right = _parseExprOp(_parseMaybeUnary(), startPos);
      final node =
          _buildBinary(leftStartPos, left, right, op, logical: logical);

      return _parseExprOp(node, leftStartPos);
    }

    return left;
  }

  Logical _buildBinary(
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
    ) as Logical;
  }

  Node _parseMaybeUnary() {
    final expr = _parseExprSubscripts();

    return expr;
  }

  Node _parseExprSubscripts() {
    final startPos = _start;
    final expr = _parseExprAtom();

    return _parseSubscripts(expr, startPos);
  }

  Node _parseExprAtom() {
    dynamic node;

    switch (_type) {
      case NodeType.parentKw:
        node = _startNode();
        _goNext();

        return _finishNode(
          node,
          type: NodeType.parentKw,
        );
      case NodeType.selfKw:
        node = _startNode();
        _goNext();

        return _finishNode(
          node,
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
        node = _startNode().toLiteral()
          ..value = _type == NodeType.noneKw ? 'None' : _type == NodeType.trueKw
          ..raw = _keywordName(_type);

        _goNext();

        return _finishNode(node);
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
      // TODO: missing import name

      throw Exception();
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
      // TODO: error cannot use new without bracket

      throw Exception();
    }

    final nodeSize = _startNode().toLiteral();

    _goNext();

    if (!_eat(NodeType.num)) {
      // TODO: error missing array size int

      throw Exception();
    }

    nodeSize.type = _type;
    nodeSize.value = _value;
    nodeSize.raw = '$_value';

    if (!_eat(NodeType.bracketR)) {
      // TODO: error missing closed bracket

      throw Exception();
    }

    node.argument = _finishNode(nodeSize);

    return _finishNode(node);
  }

  Node _parseSubscripts(Node base, int startPos) {
    while (true) {
      final element = _parseSubscript(base, startPos);

      if (element == base) {
        return element;
      }

      base = element;
    }
  }

  Node _parseSubscript(Node base, int startPos) {
    final computed = _eat(NodeType.bracketL);

    if (computed || _eat(NodeType.dot)) {
      final node = _startNodeAt(startPos).toMemberExpression();

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

      base = _finishNode(exprNode, type: NodeType.callExpression);
    }

    // TODO: maybe here for variable/property parse ?
    // Variable = deux NodeType.name qui s'enchaîne
    // Property = un name + property + name + flags?
    // Utiliser Map<String, dynamic> en alias au lieu de Node class ou voir alternative

    return base;
  }

  List<Node> _parseExprList({required NodeType close, bool allowEmpty = true}) {
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

    return _finishNode(node) as Literal;
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
        // TODO: end this
      }

      final elem = _parseMaybeDefault(_start, null);

      elements.add(elem);
    }

    return elements;
  }

  void _expect(NodeType type) {
    if (!_eat(type)) {
      // TODO: error unexpected token

      throw Exception();
    }
  }

  bool _eat(NodeType type) {
    if (_type == type) {
      _goNext();

      return true;
    } else {
      return false;
    }
  }

  Identifier _parseIdentifier() {
    final node = _startNode().toIdentifier();

    if (_type == NodeType.name) {
      node.name = _value.toString();
    } else if (_isKeyword(_type)) {
      node.name = _keywordName(_type);
    } else {
      // TODO: error unexpected token

      throw Exception();
    }

    _goNext();

    return _finishNode(node) as Identifier;
  }

  void _nextToken() {
    _pos = _skipSpace();
    _start = _pos;

    if (_pos >= _content.length) {
      return _finishToken(NodeType.eof);
    }

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

    if (_pos >= _content.length) {
      return _finishToken(NodeType.eof);
    }

    return _readToken(_fullCodeUnitAtPos());
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

  Node _finishNode(Node node, {int? pos, NodeType? type}) {
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

    if (_throwWhenMissingScriptname &&
        _firstRead &&
        word.toLowerCase() != 'scriptname') {
      throw ScriptnameException(pos: _pos);
    }

    if (_keywords.hasMatch(word)) {
      type = keywordsMap[word.toLowerCase()] ?? type;
    }

    _firstRead = false;
    _finishToken(type, val: word);
  }

  String _readWord1() {
    var chunkStart = _pos;

    while (_pos < _content.length) {
      final ch = _fullCodeUnitAtPos();

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

    // TODO: error unexpected char
  }

  int _fullCodeUnitAtPos({int? pos}) {
    final code = _currentCodeUnit(pos: pos ?? _pos);

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
          if (ch > $bs && ch < $cr) {
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
    final end = _content.indexOf(r'}', pos += 1);

    if (end == -1) {
      // TODO: error doc comment not finished

      throw Exception();
    }

    pos = end + 1;

    return pos;
  }

  int _skipBlockComment({required int pos}) {
    final end = _content.indexOf('/;', pos += 2);

    if (end == -1) {
      // TODO: error comment not finished

      throw Exception();
    }

    pos = end + 2;

    return pos;
  }

  bool _isNewLine(int code) {
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

    if (next == $equal) {
      return _finishOp(NodeType.assign, size + 1);
    }

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

    if (next == $equal) {
      return _finishOp(NodeType.equality, 2);
    }

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
        code == $pipe ? NodeType.logicalOR : NodeType.logicalAND,
        2,
      );
    }

    if (code == $equal) {
      return _finishOp(NodeType.assign, 2);
    }
  }

  void _readTokenPlusMin(int code) {
    final next = _next;

    if (next == code) {
      return _finishOp(NodeType.incrementDecrement, 2);
    }

    if (next == $equal) return _finishOp(NodeType.assign, 2);

    _finishOp(NodeType.plusMinus, 1);
  }

  void _readNumber(bool startsWithDot) {
    final start = _pos;

    if (!startsWithDot && _readInt(10, null) == null) {
      // TODO: error invalid number
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
        // TODO: error invalid number
      }
    }

    if (_isIdentifierStart(_fullCodeUnitAtPos())) {
      // TODO: error identifier directly after number
    }

    final val = _stringToNumber(_content.substring(start, _pos));

    _finishToken(NodeType.num, val: val);
  }

  String _readString(int code) {
    var out = '';
    var chunkStart = ++_pos;

    while (true) {
      if (_pos >= _content.length) {
        // TODO: error string not closed

        throw Exception();
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
          // TODO: error string not closed
          throw Exception();
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
        // TODO: error char not closed

        throw Exception();
      }

      final ch = _currentCodeUnit();

      if (ch == $single_quote) {
        break;
      }

      if (_isNewLine(ch) || (_pos - chunkStart) == 2) {
        // TODO: error char not closed

        throw Exception();
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
      final code = _currentCodeUnit();
      int? val;

      if (code >= $a) {
        val = code - $a + 10;
      } else if (code >= $A) {
        val = code - $A + 10;
      } else if (code >= $0 && code <= $9) {
        val = code - $0;
      } else {
        val = null;
      }

      if ((val ?? 0) >= radix) {
        break;
      }

      total = total * radix + (val ?? 0);
    }

    if (_pos == start || len != null && _pos - start != len) return null;

    return total;
  }

  double _stringToNumber(String str) => double.parse(str);

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
        if (_isNewLine(ch)) {
          return '';
        }

        return String.fromCharCode(ch);
    }
  }

  int _readHexChar(double size) {
    final codePos = _pos;
    final n = _readInt(16, size);

    if (n == null) {
      // TODO: error invalid \x sequence
      //
      print(codePos);
      throw Exception();
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
