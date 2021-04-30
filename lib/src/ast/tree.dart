import 'package:charcode/ascii.dart';

enum NodeType {
  eof,
  name,
  asKw,
  autoKw,
  autoReadOnlyKw,
  boolKw,
  elseKw,
  elseIfKw,
  endEventKw,
  endFunctionKw,
  endIfKw,
  endPropertyKw,
  endStateKw,
  endWhileKw,
  eventKw,
  extendsKw,
  falseKw,
  floatKw,
  functionKw,
  globalKw,
  ifKw,
  importKw,
  intKw,
  lengthKw,
  nativeKw,
  newKw,
  noneKw,
  parentKw,
  propertyKw,
  returnKw,
  scriptNameKw,
  selfKw,
  stateKw,
  stringKw,
  trueKw,
  whileKw,
  parenL,
  parenR,
  comma,
  bracketL,
  bracketR,
  braceL,
  braceR,
  colon,
  prefix,
  equality,
  assign,
  num,
  slash,
  string,
  binary,
  logical,
  logicalOR,
  logicalAND,
  incrementDecrement,
  plusMinus,
  relational,
  char,
  star,
  starstar,
  modulo,
  dot,
  id,
  literal,
  block,
  member,
  variable,
  program,
  lineTerminator
}

const keywordsMap = {
  'as': NodeType.asKw,
  'auto': NodeType.autoKw,
  'autoreadonly': NodeType.autoReadOnlyKw,
  'bool': NodeType.boolKw,
  'else': NodeType.elseKw,
  'elseif': NodeType.elseIfKw,
  'endevent': NodeType.endEventKw,
  'endfunction': NodeType.endFunctionKw,
  'endif': NodeType.endIfKw,
  'endproperty': NodeType.endPropertyKw,
  'endstate': NodeType.endStateKw,
  'endwhile': NodeType.endWhileKw,
  'event': NodeType.eventKw,
  'extends': NodeType.extendsKw,
  'false': NodeType.falseKw,
  'float': NodeType.floatKw,
  'function': NodeType.functionKw,
  'global': NodeType.globalKw,
  'if': NodeType.ifKw,
  'import': NodeType.importKw,
  'int': NodeType.intKw,
  'length': NodeType.lengthKw,
  'native': NodeType.nativeKw,
  'new': NodeType.newKw,
  'none': NodeType.noneKw,
  'parent': NodeType.parentKw,
  'property': NodeType.propertyKw,
  'return': NodeType.returnKw,
  'scriptname': NodeType.scriptNameKw,
  'self': NodeType.selfKw,
  'state': NodeType.stateKw,
  'string': NodeType.stringKw,
  'true': NodeType.trueKw,
  'while': NodeType.whileKw,
};

class Identifier {
  int start;
  int end;
  String name;

  final type = NodeType.id;

  Identifier({
    required this.start,
    required this.end,
    required this.name,
  });
}

class Node {
  NodeType? type;
  int start;
  int end;
  String? name;

  Node? id;
  List<dynamic> body = [];
  List<dynamic> params = [];

  Node? left;
  Node? right;
  String? operator;

  dynamic value;

  dynamic raw;

  Node? property;
  bool? computed;

  Node? test;
  Node? consequent;
  Node? alternate;

  Node? callee;
  List<Node?> arguments = [];

  Node({
    required this.start,
    this.end = 0,
  });
}

class Context {
  void update(NodeType prevType) {
    // Update the context
  }
}

/*
    - Retenir l'emplacement actuel. Garder une liste des char codes quotes, spaces, EOF, ...
    - Parcer un string -> `"` début, jusqu'à `"` fin. Utiliser des chatCode.
    - Parcer un char -> `'` début, jusqu'à `'` fin. Utiliser des chatCode.
  */
class Tree {
  final String _content;

  /// The current position of the tokenizer in the _content
  int _pos = 0;

  /// Type of current token
  NodeType _type = NodeType.eof;

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

  /// The context stack is used to superficially track syntactic
  /// context to predict whether a regular expression is allowed in a
  /// given position
  final _context = Context();

  bool _containsEscape = false;

  final _keywords = RegExp(
    r'^(?:as|auto|autoreadonly|bool|else|elseif|endevent|endfunction|endif|endproperty|endstate|endwhile|event|extends|false|float|function|global|if|import|int|length|native|new|none|parent|property|return|scriptname|self|state|string|true|while)$',
    caseSensitive: false,
  );

  int get _next => _content.codeUnitAt(_pos + 1);

  int get _current => _content.codeUnitAt(_pos);

  Tree({
    required String content,
  }) : _content = content;

  Node parse() {
    final program = _startNode();

    _nextToken();

    return _parseTopLevel(program);
  }

  Node _startNode() {
    return Node(start: _start);
  }

  Node _startNodeAt(int pos) {
    return Node(start: pos);
  }

  Node _parseTopLevel(Node program) {
    while (_type != NodeType.eof) {
      final statement = _parseStatement();

      program.body.add(statement);
    }

    _goNext();

    return _finishNode(program, NodeType.program, null);
  }

  void _goNext() {
    _lastTokenEnd = _end;
    _lastTokenStart = _start;
    _nextToken();
  }

  Node _parseStatement({dynamic? context}) {
    final startType = _type;
    final node = _startNode();

    switch (startType) {
      case NodeType.functionKw:
        return _parseFunctionStatement(node);
      case NodeType.ifKw:
        return _parseIfStatement(node, context: context);
      case NodeType.variable:
        return _parseVariable(node);
      default:
        if (_isNewLine(_current)) {
          return _parseBlock(node, startType);
        }

        final maybeName = _value;
        final expr = _parseExpression();

        return _parseExpressionStatement(node, expr);
    }
  }

  Node _parseIfStatement(Node node, {NodeType? context}) {
    _goNext();

    node.test = _parseParenExpression();
    node.consequent = _parseStatement(context: context);
    node.alternate = _eat(NodeType.elseKw) || _eat(NodeType.elseIfKw)
        ? _parseStatement(
            context:
                _eat(NodeType.elseKw) ? NodeType.elseKw : NodeType.elseIfKw,
          )
        : null;

    return _finishNode(node, NodeType.ifKw, null);
  }

  Node _parseParenExpression() {
    _expectOrNot(NodeType.parenL);

    final val = _parseExpression();

    _expectOrNot(NodeType.parenR);

    return val;
  }

  Node _parseFunctionStatement(Node node) {
    _goNext();

    return _parseFunction(node);
  }

  Node _parseFunction(Node node) {
    node.id = _type != NodeType.name ? null : _parseIdent();

    _parseFunctionParams(node);
    _parseFunctionBody(node);

    return node;
  }

  void _parseFunctionBody(Node node) {
    node.body = [_parseBlock(null, NodeType.functionKw)];
  }

  Node _parseBlock(Node? usedNode, NodeType type) {
    final node = usedNode ?? _startNode();

    node.type = type;

    while (_type != _close(type)) {
      final statement = _parseStatement();

      node.body.add(statement);
    }

    _goNext();

    return _finishNode(node, NodeType.block, null);
  }

  Node _parseExpression() {
    final expr = _parseMaybeAssign();

    if (_type == NodeType.lineTerminator) {
      // TODO: handle line terminator

      throw UnimplementedError();
    }

    return expr;
  }

  Node _parseMaybeDefault(int startPos, Node? left) {
    left = left ?? _parseBindingAtom();

    final node = _startNodeAt(startPos);

    node.left = left;
    node.right = _parseMaybeAssign();

    return _finishNode(node, NodeType.assign, null);
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

  Node _parseBindingAtom() {
    return _parseIdent();
  }

  Node _parseExprOps() {
    final startPos = _start;
    final expr = _parseMaybeUnary();

    return _parseExprOp(expr, startPos);
  }

  Node _parseExprOp(Node left, int leftStartPos) {
    if (_type == NodeType.logicalOR ||
        _type == NodeType.logicalAND ||
        _type == NodeType.binary) {
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

  Node _buildBinary(int startPos, Node left, Node right, String op,
      {bool logical = false}) {
    final node = _startNodeAt(startPos);

    node.left = left;
    node.operator = op;
    node.right = right;

    return _finishNode(
        node, logical ? NodeType.logical : NodeType.binary, null);
  }

  Node _parseMaybeUnary() {
    final expr = _parseExprSubscripts();

    return expr;
  }

  Node _parseExprSubscripts() {
    final startPos = _start;
    final expr = _parseExprAtom();

    return _parseSubsripts(expr, startPos);
  }

  Node _parseExprAtom() {
    Node node;

    switch (_type) {
      case NodeType.parentKw:
        node = _startNode();
        _goNext();

        return _finishNode(node, NodeType.parentKw, null);

      case NodeType.name:
        return _parseIdent();

      case NodeType.num:
      case NodeType.string:
      case NodeType.char:
        return _parseLiteral(_value);

      case NodeType.noneKw:
      case NodeType.falseKw:
      case NodeType.trueKw:
        node = _startNode();
        _goNext();

        node.value =
            _type == NodeType.noneKw ? 'None' : _type == NodeType.trueKw;
        node.raw = _keywordName(_type);

        _goNext();

        return _finishNode(node, NodeType.literal, null);
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
    final node = _startNode();

    _goNext();

    if (_type != NodeType.name) {
      // TODO: missing import name

      throw Exception();
    }

    final imported = _startNode();
    imported.name = _value;

    node.body.add(_finishNode(imported, _type, null));

    return _finishNode(node, NodeType.importKw, null);
  }

  Node _parseNew() {
    final node = _startNode();
    final startPos = _start;

    node.callee = _parseSubsripts(_parseExprAtom(), startPos);

    if (!_eat(NodeType.bracketL)) {
      // TODO: error cannot use new without bracket

      throw Exception();
    }

    final nodeSize = _startNode();

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

    node.arguments = [nodeSize];

    return _finishNode(node, NodeType.newKw, null);
  }

  Node _parseSubsripts(Node base, int startPos) {
    while (true) {
      final element = _parseSubsript(base, startPos);

      if (element == base) {
        return element;
      }

      base = element;
    }
  }

  Node _parseSubsript(Node base, int startPos) {
    final computed = _eat(NodeType.bracketL);

    if (computed || _eat(NodeType.dot)) {
      final node = _startNodeAt(startPos);

      if (computed) {
        node.property = _parseExpression();
        _expect(NodeType.bracketR);
      } else {
        node.property = _parseIdent();
      }

      node.computed = computed;

      base = _finishNode(node, NodeType.member, null);
    }

    return base;
  }

  Node _parseLiteral(dynamic value) {
    final node = _startNode();
    node.value = _value;
    node.raw = _content.substring(_start, _end);

    _goNext();

    return _finishNode(node, NodeType.literal, null);
  }

  bool _isSimpleParamList(Node node) {
    // TODO: type params
    final list = node.params;

    for (var i = 0; i < list.length; i++) {
      final param = list[i];

      if (param.type != NodeType.id) return false;
    }

    return true;
  }

  void _parseFunctionParams(Node node) {
    _expect(NodeType.parenL);
    node.params = _parseBindingList(NodeType.parenR, false);
  }

  List<dynamic> _parseBindingList(NodeType type, bool allowEmpty) {
    final elements = [];
    var first = true;

    while (!_eat(_close(type))) {
      if (!_eat(NodeType.parenR)) {
        if (first) {
          first = false;
        } else {
          _expect(NodeType.comma);
          // TODO: end this
        }

        final elem = _parseMaybeDefault(_start, null);

        elements.add(elem);
      }
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

  Node _parseIdent() {
    final node = _startNode();

    if (_type == NodeType.name) {
      node.name = _value;
    } else if (_isKeyword(_type)) {
      node.name = _keywordName(_type);
    } else {
      // TODO: error unexpected token

      throw Exception();
    }

    _goNext();
    _finishNode(node, NodeType.id, null);

    return node;
  }

  void _nextToken() {
    _pos += _skipSpace();
    _start = _pos;

    if (_pos >= _content.length) {
      _finishToken(NodeType.eof, null);
    }

    return _readToken(_fullCodeUnitAtPos());
  }

  void _readToken(int code) {
    if (_isIdentifierStart(code) || code == $backslash) {
      return _readWord();
    }

    return _tokenFromCode(code);
  }

  void _finishToken(NodeType type, dynamic? val) {
    _end = _pos;
    final prevType = _type;
    _type = type;
    _value = val;

    _context.update(prevType);
  }

  Node _finishNode(Node node, NodeType type, int? pos) {
    final usedPos = pos ?? _lastTokenEnd;

    node.type = type;
    node.end = usedPos;

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

    if (_keywords.hasMatch(word)) {
      type = keywordsMap[word] ?? type;
    }

    _finishToken(type, word);
  }

  String _readWord1() {
    var chunkStart = _pos;
    _containsEscape = false;

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
        return _finishToken(NodeType.parenL, null);
      case $close_paren:
        ++_pos;
        return _finishToken(NodeType.parenR, null);
      case $comma:
        ++_pos;
        return _finishToken(NodeType.comma, null);
      case $open_bracket:
        ++_pos;
        return _finishToken(NodeType.bracketL, null);
      case $close_bracket:
        ++_pos;
        return _finishToken(NodeType.bracketR, null);
      case $colon:
        ++_pos;
        return _finishToken(NodeType.colon, null);
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

  int _fullCodeUnitAtPos() {
    final code = _current;

    if (code < 0xd7ff /* 55295 */ || code >= 0xe000 /* 57344 */) {
      return code;
    }

    final next = _next;

    return (code << 10) + next - 0x35fdc00 /* 56613888 */;
  }

  int _skipSpace() {
    var pos = _pos;

    loop:
    while (pos < _content.length) {
      final ch = _current;

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

            pos += newPos;
          } else {
            final newPos = _skipLineComment(pos: pos, skip: 2);

            pos += newPos;
          }
          break;
        case $open_brace:
          final newPos = _skipDocComment(pos: pos);

          pos += newPos;
          break;
        default:
          if (ch > 8 && ch < 14) {
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

    _finishToken(type, str);
  }

  void _readTokenDot() {
    final next = _next;

    if (next >= $0 && next <= $9) return _readNumber(true);

    return _finishToken(NodeType.dot, null);
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

    var next = _current;

    if (next == $dot) {
      ++_pos;
      _readInt(10, null);
      next = _current;
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

    _finishToken(NodeType.num, val);
  }

  String _readString(int code) {
    var out = '';
    var chunkStart = ++_pos;

    while (true) {
      if (_pos >= _content.length) {
        // TODO: error string not closed

        throw Exception();
      }

      final ch = _current;

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

    _finishToken(NodeType.string, out);

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

      final ch = _current;

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

    _finishToken(NodeType.char, out);

    return out;
  }

  int? _readInt(int radix, double? len) {
    final start = _pos;
    var total = 0;

    for (var i = 0; i < (len ?? double.infinity); ++i, ++_pos) {
      final code = _current;
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
        if (_current == $lf) {
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
