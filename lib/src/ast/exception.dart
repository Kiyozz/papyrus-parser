class NodeException {
  final int _start;
  final int _end;

  final int? _pos;

  NodeException({
    required int start,
    required int end,
    int? pos,
  })  : _start = start,
        _end = end,
        _pos = pos;
}

class ScriptNameException extends NodeException {
  ScriptNameException({
    required int start,
    required int end,
    int? pos,
  }) : super(start: start, end: end, pos: pos);

  @override
  String toString() {
    return 'ScriptNameException: Unexpected token at $_pos. ScriptName statement is not complete';
  }
}

class UnexpectedTokenException extends NodeException {
  final String? _expected;

  UnexpectedTokenException({
    required int start,
    required int end,
    int? pos,
    String? expected,
  })  : _expected = expected,
        super(start: start, end: end, pos: pos);

  @override
  String toString() {
    final buffer = StringBuffer('Unexpected token at $_pos.');

    if (_expected != null) {
      buffer.write(' Expected $_expected');
    }

    return 'UnexpectedTokenException: ${buffer.toString()}';
  }
}

class PropertyException extends NodeException {
  final String _message;

  PropertyException(
    String message, {
    required int start,
    required int end,
    int? pos,
  })  : _message = message,
        super(start: start, end: end, pos: pos);

  @override
  String toString() {
    return 'PropertyException: $_message';
  }
}

class BlockStatementException extends NodeException {
  final String _message;

  BlockStatementException(
    String message, {
    required int start,
    required int end,
    int? pos,
  })  : _message = message,
        super(start: start, end: end, pos: pos);

  @override
  String toString() {
    return 'BlockStatementException: $_message';
  }
}
