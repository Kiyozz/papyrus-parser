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
  equal
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

class NodeFactory {
  int start;
  Tree tree;

  NodeFactory({required this.start, required this.tree});
}

class Node {
  NodeType type;
  int start;
  int end;

  Node({
    required this.type,
    required this.start,
    required this.end,
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

  /// The context stack is used to superficially track syntactic
  /// context to predict whether a regular expression is allowed in a
  /// given position
  final _context = Context();

  bool _containsEscape = false;

  final _keywords = RegExp(
    r'^(?:as|auto|autoreadonly|bool|else|elseif|endevent|endfunction|endif|endproperty|endstate|endwhile|event|extends|false|float|function|global|if|import|int|length|native|new|none|parent|property|return|scriptname|self|state|string|true|while)$',
    caseSensitive: false,
  );

  Tree({
    required String content,
  }) : _content = content;

  Node parse() {
    final program = _startNode();

    _nextToken();

    return Node(start: 0, end: 0, type: NodeType.asKw);
  }

  NodeFactory _startNode() {
    return NodeFactory(start: _start, tree: this);
  }

  void _nextToken() {
    _skipSpace();
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

  void _finishToken(NodeType type, String? val) {
    _end = _pos;
    final prevType = _type;
    _type = type;
    _value = val;

    _context.update(prevType);
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
      case $caret:
        return _readTokenCaret();
      case $plus:
      case $minus:
        return _readTokenPlusMin(code);
      case $greater_than:
      case $less_than:
        return _readTokenGtLt(code);
      case $equal:
      case $exclamation:
        return _readTokenEqualExclamation(code);
      case $question:
        return _readTokenQuestion();
      case $tilde:
        return _finishOp(NodeType.prefix, 1);
    }

    // TODO: error unexpected char
  }

  int _fullCodeUnitAtPos() {
    final code = _content.codeUnitAt(_pos);

    if (code < 0xd7ff /* 55295 */ || code >= 0xe000 /* 57344 */) {
      return code;
    }

    final next = _content.codeUnitAt(_pos + 1);

    return (code << 10) + next - 0x35fdc00 /* 56613888 */;
  }

  void _skipSpace() {
    loop:
    while (_pos < _content.length) {
      final ch = _content.codeUnitAt(_pos);

      print('ch $ch');

      switch (ch) {
        case $space:
          ++_pos;
          break;
        case $cr:
          if (_content.codeUnitAt(_pos + 1) == $lf) {
            ++_pos;
          }
          continue lf;
        lf:
        case $lf:
          ++_pos;
          break;
        case $semicolon:
          if (_content.codeUnitAt(_pos + 1) == $slash) {
            _skipBlockComment();
          } else {
            _skipLineComment(2);
          }
          break;
        default:
          if (ch > 8 && ch < 14) {
            ++_pos;
            break;
          } else {
            break loop;
          }
      }
    }
  }

  void _skipLineComment(int startSkip) {
    var ch = _content.codeUnitAt(_pos += startSkip);

    while (_pos < _content.length && !_isNewLine(ch)) {
      ch = _content.codeUnitAt(++_pos);
    }
  }

  void _skipBlockComment() {
    final end = _content.indexOf('/;', _pos += 2);

    if (end == -1) {
      // error comment not finished
    }

    _pos = end + 2;
  }

  bool _isNewLine(int code) {
    return code == $lf || code == $cr;
  }

  void _readTokenEqualExclamation(int code) {
    final next = _content.codeUnitAt(_pos + 1);

    if (next == $equal) {
      return _finishOp(NodeType.equality, 2);
    }

    return _finishOp(code == $equal ? NodeType.equal : NodeType.prefix, 1);
  }

  void _finishOp(NodeType type, int size) {
    final str = _content.substring(_pos, _pos + size);
    _pos += size;

    _finishToken(type, str);
  }
}
