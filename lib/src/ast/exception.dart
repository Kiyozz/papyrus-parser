import 'package:papyrus_parser/src/ast/position.dart';

abstract class NodeException {
  final int start;
  final int end;
  final Position startPos;
  final Position endPos;

  const NodeException({
    required this.start,
    required this.end,
    required this.startPos,
    required this.endPos,
  });
}

class ScriptNameException extends NodeException {
  final String message;

  const ScriptNameException({
    required this.message,
    required int start,
    required int end,
    required Position startPos,
    required Position endPos,
  }) : super(start: start, end: end, startPos: startPos, endPos: endPos);

  @override
  String toString() {
    return message;
  }
}

class UnexpectedTokenException extends NodeException {
  final String? message;

  const UnexpectedTokenException({
    required int start,
    required int end,
    required Position startPos,
    required Position endPos,
    this.message,
  }) : super(start: start, end: end, startPos: startPos, endPos: endPos);

  @override
  String toString() {
    final message = this.message;

    if (message != null) {
      return message;
    }

    return 'Unexpected token.';
  }
}

class PropertyException extends NodeException {
  final String message;

  const PropertyException(
    this.message, {
    required int start,
    required int end,
    required Position startPos,
    required Position endPos,
  }) : super(start: start, end: end, startPos: startPos, endPos: endPos);

  @override
  String toString() {
    return message;
  }
}

class BlockStatementException extends NodeException {
  final String message;

  const BlockStatementException(
    this.message, {
    required int start,
    required int end,
    required Position startPos,
    required Position endPos,
  }) : super(start: start, end: end, startPos: startPos, endPos: endPos);

  @override
  String toString() {
    return message;
  }
}

class FunctionFlagException extends NodeException {
  final String _flag;

  const FunctionFlagException({
    required String flag,
    required int start,
    required int end,
    required Position startPos,
    required Position endPos,
  })   : _flag = flag,
        super(start: start, end: end, startPos: startPos, endPos: endPos);

  @override
  String toString() {
    return 'Unexpected flag $_flag';
  }
}

class StateStatementException extends NodeException {
  final String message;

  const StateStatementException(
    this.message, {
    required int start,
    required int end,
    required Position startPos,
    required Position endPos,
  }) : super(start: start, end: end, startPos: startPos, endPos: endPos);

  @override
  String toString() {
    return message;
  }
}

class EventFlagException extends NodeException {
  final String _flag;

  const EventFlagException({
    required String flag,
    required int start,
    required int end,
    required Position startPos,
    required Position endPos,
    int? pos,
  })  : _flag = flag,
        super(start: start, end: end, startPos: startPos, endPos: endPos);

  @override
  String toString() {
    return 'Unexpected flag $_flag';
  }
}

class ParentMemberException extends NodeException {
  final String message;

  const ParentMemberException(
    this.message, {
    required int start,
    required int end,
    required Position startPos,
    required Position endPos,
    int? pos,
  }) : super(start: start, end: end, startPos: startPos, endPos: endPos);

  @override
  String toString() {
    return message;
  }
}
