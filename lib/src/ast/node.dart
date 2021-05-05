import 'package:collection/collection.dart';
import 'package:papyrus_parser/papyrus_parser.dart';
import 'types.dart';

class Node {
  NodeType? type;
  int start;
  int end;

  Node({
    required this.start,
    this.end = 0,
  });

  Program toProgram() {
    return Program(start: start, end: end);
  }

  ScriptNameStatement toScriptNameStatement() {
    return ScriptNameStatement(start: start, end: end);
  }

  ScriptNameFlagDeclaration toScriptNameFlagDeclaration() {
    return ScriptNameFlagDeclaration(start: start, end: end);
  }

  ExtendsDeclaration toExtendsDeclaration() {
    return ExtendsDeclaration(start: start, end: end);
  }

  ExpressionStatement toExpressionStatement() {
    return ExpressionStatement(start: start, end: end);
  }

  IfStatement toIfStatement() {
    return IfStatement(start: start, end: end);
  }

  FunctionStatement toFunctionStatement() {
    return FunctionStatement(start: start, end: end);
  }

  FunctionFlagDeclaration toFunctionFlagDeclaration() {
    return FunctionFlagDeclaration(start: start, end: end);
  }

  BlockStatement toBlockStatement() {
    return BlockStatement(start: start, end: end);
  }

  AssignExpression toAssignExpression() {
    return AssignExpression(start: start, end: end);
  }

  Literal toLiteral() {
    return Literal(start: start, end: end);
  }

  Name toName() {
    return Name(start: start, end: end);
  }

  Identifier toIdentifier() {
    return Identifier(start: start, end: end);
  }

  LogicalExpression toLogical() {
    return LogicalExpression(start: start, end: end);
  }

  Import toImport() {
    return Import(start: start, end: end);
  }

  NewExpression toNewExpression() {
    return NewExpression(start: start, end: end);
  }

  MemberExpression toMemberExpression() {
    return MemberExpression(start: start, end: end);
  }

  VariableDeclaration toVariableDeclaration() {
    return VariableDeclaration(start: start, end: end);
  }

  Variable toVariable() {
    return Variable(start: start, end: end);
  }

  CallExpression toCallExpression() {
    return CallExpression(start: start, end: end);
  }

  PropertyDeclaration toPropertyDeclaration() {
    return PropertyDeclaration(start: start, end: end);
  }

  PropertyFlagDeclaration toPropertyFlagDeclaration() {
    return PropertyFlagDeclaration(start: start, end: end);
  }

  ReturnStatement toReturnStatement() {
    return ReturnStatement(start: start, end: end);
  }

  CastExpression toCastExpression() {
    return CastExpression(start: start, end: end);
  }

  UnaryExpression toUnaryExpression() {
    return UnaryExpression(start: start, end: end);
  }

  WhileStatement toWhileStatement() {
    return WhileStatement(start: start, end: end);
  }

  StateStatement toStateStatement() {
    return StateStatement(start: start, end: end);
  }

  EventStatement toEventStatement() {
    return EventStatement(start: start, end: end);
  }

  EventFlagDeclaration toEventFlagDeclaration() {
    return EventFlagDeclaration(start: start, end: end);
  }
}

class Program extends Node {
  List<Node> body = [];

  @override
  NodeType? type = NodeType.program;

  Program({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class ScriptNameStatement extends Node {
  Identifier? id;
  ExtendsDeclaration? extendsDeclaration;
  List<ScriptNameFlagDeclaration> flags = [];

  @override
  NodeType? type = NodeType.scriptNameKw;

  bool get isConditional {
    final flag = flags
        .firstWhereOrNull((elem) => elem.flag == ScriptNameFlag.conditional);

    return flag != null;
  }

  ScriptNameStatement({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class ScriptNameFlagDeclaration extends Node {
  @override
  NodeType? type = NodeType.flagKw;

  ScriptNameFlag? flag;

  ScriptNameFlagDeclaration({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class ExtendsDeclaration extends Node {
  Identifier? extended;

  @override
  NodeType? type = NodeType.extendsKw;

  ExtendsDeclaration({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class ExpressionStatement extends Node {
  @override
  NodeType? type = NodeType.expressionStatement;

  Node? expression;

  ExpressionStatement({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class IfStatement extends Node {
  @override
  NodeType? type = NodeType.ifKw;
  NodeType? endType = NodeType.endIfKw;

  Node? test;
  Node? consequent;
  Node? alternate;

  IfStatement({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class FunctionStatement extends Node {
  @override
  NodeType? type = NodeType.functionKw;
  NodeType? endType = NodeType.endFunctionKw;

  Identifier? id;
  List<Node> body = [];
  List<Node> params = [];
  List<FunctionFlagDeclaration> flags = [];

  String kind = '';

  FunctionStatement({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);

  bool get isNative {
    final flag = flags.firstWhereOrNull((elem) {
      return elem.flag == FunctionFlag.native;
    });

    return flag != null;
  }
}

class FunctionFlagDeclaration extends Node {
  @override
  NodeType? type = NodeType.flagKw;

  FunctionFlag? flag;

  FunctionFlagDeclaration({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);

  FunctionFlag flagFromType(NodeType type) {
    switch (type) {
      case NodeType.globalKw:
        return FunctionFlag.global;
      case NodeType.nativeKw:
        return FunctionFlag.native;
      default:
        throw UnexpectedTokenException(
          message: 'Unexpected flag',
          start: start,
          end: end,
        );
    }
  }
}

class BlockStatement extends Node {
  @override
  NodeType? type = NodeType.block;

  List<Node> body = [];

  BlockStatement({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class AssignExpression extends Node {
  @override
  NodeType? type = NodeType.assign;

  Node? left;
  Node? right;

  AssignExpression({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class Literal extends Node {
  @override
  NodeType? type = NodeType.literal;

  dynamic value;
  String raw = '';

  Literal({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class Name extends Node {
  @override
  NodeType? type = NodeType.name;

  String name = '';

  Name({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class Identifier extends Node {
  @override
  NodeType? type = NodeType.id;

  String name = '';

  Identifier({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class LogicalExpression extends Node {
  Node? left;
  Node? right;
  String operator = '';

  LogicalExpression({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class Import extends Node {
  @override
  NodeType? type = NodeType.importKw;

  Name? imported;

  Import({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class NewExpression extends Node {
  @override
  NodeType? type = NodeType.newKw;

  Node? callee;

  Node? argument;

  NewExpression({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class MemberExpression extends Node {
  @override
  NodeType? type = NodeType.member;

  Node? property;
  Node? object;

  bool computed = false;

  MemberExpression({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class VariableDeclaration extends Node {
  @override
  NodeType? type = NodeType.variableDeclaration;

  Variable? variable;

  VariableDeclaration({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class Variable extends Node {
  @override
  NodeType? type = NodeType.variable;

  String kind = '';

  Identifier? id;
  Node? init;

  Variable({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class CallExpression extends Node {
  @override
  NodeType? type = NodeType.callExpression;

  Node? callee;

  List<Node> arguments = [];

  CallExpression({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class PropertyDeclaration extends Node {
  @override
  NodeType? type = NodeType.propertyKw;

  Identifier? id;
  Node? init;
  String? kind;
  List<PropertyFlagDeclaration> flags = [];

  PropertyDeclaration({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);

  PropertyFullDeclaration toPropertyFullDeclaration() {
    return PropertyFullDeclaration(start: start, end: end)
      ..flags = flags
      ..id = id
      ..init = init
      ..kind = kind;
  }

  bool get isFull => this is PropertyFullDeclaration;

  bool get isAutoOrAutoReadonly => isAuto || isAutoReadonly;
  bool get isAuto => hasFlag(PropertyFlag.auto);
  bool get isAutoReadonly => hasFlag(PropertyFlag.autoReadonly);
  bool get isConditional => hasFlag(PropertyFlag.conditional);
  bool get isHidden {
    final hasHidden = hasFlag(PropertyFlag.hidden);

    return hasHidden || (!isAuto && !isAutoReadonly && !isConditional);
  }

  bool hasFlag(PropertyFlag propertyFlag) {
    return flags.any((flag) => flag.flag == propertyFlag);
  }
}

class PropertyFullDeclaration extends PropertyDeclaration {
  FunctionStatement? getter;
  FunctionStatement? setter;

  PropertyFullDeclaration({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class PropertyFlagDeclaration extends Node {
  @override
  NodeType? type = NodeType.flagKw;

  PropertyFlag? flag;

  PropertyFlagDeclaration({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);

  PropertyFlag flagFromType(NodeType type) {
    switch (type) {
      case NodeType.conditionalKw:
        return PropertyFlag.conditional;
      case NodeType.autoKw:
        return PropertyFlag.auto;
      case NodeType.autoReadOnlyKw:
        return PropertyFlag.autoReadonly;
      case NodeType.hiddenKw:
        return PropertyFlag.hidden;
      default:
        throw UnexpectedTokenException(
          message: 'Unexpected flag',
          start: start,
          end: end,
        );
    }
  }
}

class ReturnStatement extends Node {
  Node? argument;

  @override
  NodeType? type = NodeType.returnKw;

  ReturnStatement({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class CastExpression extends Node {
  @override
  NodeType? type = NodeType.castExpression;

  Node? id;
  Node? kind;

  CastExpression({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class UnaryExpression extends Node {
  @override
  NodeType? type = NodeType.unary;

  String operator = '';

  Node? argument;

  bool isPrefix = false;

  UnaryExpression({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class WhileStatement extends Node {
  @override
  NodeType? type = NodeType.whileKw;
  NodeType? endType = NodeType.endWhileKw;

  Node? test;
  Node? consequent;

  WhileStatement({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class StateStatement extends Node {
  @override
  NodeType? type = NodeType.stateKw;
  NodeType? endType = NodeType.endStateKw;
  Identifier? id;
  StateFlag? flag;
  BlockStatement? body;

  bool get isAuto => flag == StateFlag.auto;

  bool get isValid {
    final body = this.body;
    if (body == null) return true;

    final elements = body.body;

    if (elements.isEmpty) return true;

    final state = elements.where((elem) {
      return elem is! FunctionStatement && elem is! EventStatement;
    });

    if (state.isEmpty) return true;

    return false;
  }

  StateStatement({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class EventStatement extends Node {
  @override
  NodeType? type = NodeType.eventKw;
  NodeType? endType = NodeType.endEventKw;

  Identifier? id;
  BlockStatement? body;
  List<Node> params = [];
  List<EventFlagDeclaration> flags = [];

  EventStatement({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);

  bool get isNative {
    final flag = flags.firstWhereOrNull((elem) {
      return elem.flag == EventFlag.native;
    });

    return flag != null;
  }
}

class EventFlagDeclaration extends Node {
  @override
  NodeType? type = NodeType.flagKw;

  EventFlag? flag;

  EventFlagDeclaration({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);

  EventFlag flagFromType(NodeType type) {
    switch (type) {
      case NodeType.nativeKw:
        return EventFlag.native;
      default:
        throw UnexpectedTokenException(
          message: 'Unexpected flag',
          start: start,
          end: end,
        );
    }
  }
}
