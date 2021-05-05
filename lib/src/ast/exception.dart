abstract class NodeException {
  final int _start;
  final int _end;

  const NodeException({
    required int start,
    required int end,
  })   : _start = start,
        _end = end;
}

class ScriptNameException extends NodeException {
  final String? message;

  const ScriptNameException({
    this.message,
    required int start,
    required int end,
  }) : super(start: start, end: end);

  @override
  String toString() {
    if (message != null) {
      return 'ScriptNameException: [$_start:$_end] $message';
    }

    return 'ScriptNameException: [$_start:$_end] Unexpected token. ScriptName statement is not complete';
  }
}

class UnexpectedTokenException extends NodeException {
  final String? _message;

  const UnexpectedTokenException({
    required int start,
    required int end,
    String? message,
  })  : _message = message,
        super(start: start, end: end);

  @override
  String toString() {
    if (_message != null) {
      return 'UnexpectedTokenException: [$_start:$_end] $_message';
    }

    return 'UnexpectedTokenException: [$_start:$_end] Unexpected token.';
  }
}

class PropertyException extends NodeException {
  final String _message;

  const PropertyException(
    String message, {
    required int start,
    required int end,
  })   : _message = message,
        super(start: start, end: end);

  @override
  String toString() {
    return 'PropertyException: [$_start:$_end] $_message';
  }
}

class BlockStatementException extends NodeException {
  final String _message;

  const BlockStatementException(
    String message, {
    required int start,
    required int end,
  })   : _message = message,
        super(start: start, end: end);

  @override
  String toString() {
    return 'BlockStatementException: [$_start:$_end] $_message';
  }
}

class FunctionFlagException extends NodeException {
  final String _flag;

  const FunctionFlagException({
    required String flag,
    required int start,
    required int end,
  })   : _flag = flag,
        super(start: start, end: end);

  @override
  String toString() {
    return 'FunctionFlagException: [$_start:$_end] unexpected flag $_flag';
  }
}

class StateStatementException extends NodeException {
  final String _message;

  const StateStatementException(
    String message, {
    required int start,
    required int end,
  })   : _message = message,
        super(start: start, end: end);

  @override
  String toString() {
    return 'StateStatementException: [$_start:$_end] $_message';
  }
}

class EventFlagException extends NodeException {
  final String _flag;

  const EventFlagException({
    required String flag,
    required int start,
    required int end,
    int? pos,
  })  : _flag = flag,
        super(start: start, end: end);

  @override
  String toString() {
    return 'EventFlagException: [$_start:$_end] unexpected flag $_flag';
  }
}

class ParentMemberException extends NodeException {
  final String _message;

  const ParentMemberException(
    String message, {
    required int start,
    required int end,
    int? pos,
  })  : _message = message,
        super(start: start, end: end);

  @override
  String toString() {
    return 'ParentMemberException: [$_start:$_end] $_message';
  }
}
