abstract class NodeException {
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
  String? message;

  ScriptNameException({
    this.message,
    required int start,
    required int end,
    int? pos,
  }) : super(start: start, end: end, pos: pos);

  @override
  String toString() {
    if (message != null) {
      return 'ScriptNameException: [$_start:$_end] $message';
    }

    return 'ScriptNameException: [$_start:$_end] Unexpected token at $_pos. ScriptName statement is not complete';
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

    return 'UnexpectedTokenException: [$_start:$_end] ${buffer.toString()}';
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
    return 'PropertyException: [$_start:$_end] $_message';
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
    return 'BlockStatementException: [$_start:$_end] $_message';
  }
}

class FunctionFlagException extends NodeException {
  final String _flag;

  FunctionFlagException({
    required String flag,
    required int start,
    required int end,
    int? pos,
  })  : _flag = flag,
        super(start: start, end: end, pos: pos);

  @override
  String toString() {
    return 'FunctionFlagException: [$_start:$_end] unexpected flag $_flag';
  }
}

class StateStatementException extends NodeException {
  final String _message;

  StateStatementException(
    String message, {
    required int start,
    required int end,
    int? pos,
  })  : _message = message,
        super(start: start, end: end, pos: pos);

  @override
  String toString() {
    return 'StateStatementException: [$_start:$_end] $_message';
  }
}

class EventFlagException extends NodeException {
  final String _flag;

  EventFlagException({
    required String flag,
    required int start,
    required int end,
    int? pos,
  })  : _flag = flag,
        super(start: start, end: end, pos: pos);

  @override
  String toString() {
    return 'EventFlagException: [$_start:$_end] unexpected flag $_flag';
  }
}

class ParentMemberException extends NodeException {
  final String _message;

  ParentMemberException(
    String message, {
    required int start,
    required int end,
    int? pos,
  })  : _message = message,
        super(start: start, end: end, pos: pos);

  @override
  String toString() {
    return 'ParentMemberException: [$_start:$_end] $_message';
  }
}
