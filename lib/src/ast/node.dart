import 'package:collection/collection.dart';

import 'exception.dart';
import 'position.dart';
import 'types.dart';

class Node {
  late NodeType type;
  int start;
  int end;
  Position startPos;
  Position endPos;

  Node({
    required this.start,
    required this.startPos,
    this.end = 0,
    Position? endPos,
  }) : endPos = endPos ?? Position(line: 0, character: 0);

  Program toProgram() {
    return Program(start: start, startPos: startPos, end: end, endPos: endPos);
  }

  ScriptNameStatement toScriptNameStatement() {
    return ScriptNameStatement(
        start: start, startPos: startPos, end: end, endPos: endPos);
  }

  ScriptNameFlagDeclaration toScriptNameFlagDeclaration() {
    return ScriptNameFlagDeclaration(
        start: start, startPos: startPos, end: end, endPos: endPos);
  }

  ExtendsDeclaration toExtendsDeclaration() {
    return ExtendsDeclaration(
        start: start, startPos: startPos, end: end, endPos: endPos);
  }

  ExpressionStatement toExpressionStatement() {
    return ExpressionStatement(
        start: start, startPos: startPos, end: end, endPos: endPos);
  }

  IfStatement toIfStatement() {
    return IfStatement(
        start: start, startPos: startPos, end: end, endPos: endPos);
  }

  FunctionStatement toFunctionStatement() {
    return FunctionStatement(
        start: start, startPos: startPos, end: end, endPos: endPos);
  }

  FunctionFlagDeclaration toFunctionFlagDeclaration() {
    return FunctionFlagDeclaration(
        start: start, startPos: startPos, end: end, endPos: endPos);
  }

  BlockStatement toBlockStatement() {
    return BlockStatement(
        start: start, startPos: startPos, end: end, endPos: endPos);
  }

  AssignExpression toAssignExpression() {
    return AssignExpression(
        start: start, startPos: startPos, end: end, endPos: endPos);
  }

  Literal toLiteral() {
    return Literal(start: start, startPos: startPos, end: end, endPos: endPos);
  }

  Identifier toIdentifier() {
    return Identifier(
      start: start,
      startPos: startPos,
      end: end,
      endPos: endPos,
    );
  }

  BinaryExpression toBinaryExpression() {
    return BinaryExpression(
        start: start, startPos: startPos, end: end, endPos: endPos);
  }

  NewExpression toNewExpression() {
    return NewExpression(
        start: start, startPos: startPos, end: end, endPos: endPos);
  }

  MemberExpression toMemberExpression() {
    return MemberExpression(
        start: start, startPos: startPos, end: end, endPos: endPos);
  }

  VariableDeclaration toVariableDeclaration() {
    return VariableDeclaration(
        start: start, startPos: startPos, end: end, endPos: endPos);
  }

  Variable toVariable() {
    return Variable(start: start, startPos: startPos, end: end, endPos: endPos);
  }

  CallExpression toCallExpression() {
    return CallExpression(
      start: start,
      startPos: startPos,
      end: end,
      endPos: endPos,
    );
  }

  PropertyDeclaration toPropertyDeclaration() {
    return PropertyDeclaration(
      start: start,
      startPos: startPos,
      end: end,
      endPos: endPos,
    );
  }

  PropertyFlagDeclaration toPropertyFlagDeclaration() {
    return PropertyFlagDeclaration(
      start: start,
      startPos: startPos,
      end: end,
      endPos: endPos,
    );
  }

  ReturnStatement toReturnStatement() {
    return ReturnStatement(
      start: start,
      startPos: startPos,
      end: end,
      endPos: endPos,
    );
  }

  CastExpression toCastExpression() {
    return CastExpression(
      start: start,
      startPos: startPos,
      end: end,
      endPos: endPos,
    );
  }

  UnaryExpression toUnaryExpression() {
    return UnaryExpression(
      start: start,
      startPos: startPos,
      end: end,
      endPos: endPos,
    );
  }

  WhileStatement toWhileStatement() {
    return WhileStatement(
      start: start,
      startPos: startPos,
      end: end,
      endPos: endPos,
    );
  }

  StateStatement toStateStatement() {
    return StateStatement(
      start: start,
      startPos: startPos,
      end: end,
      endPos: endPos,
    );
  }

  StateFlagDeclaration toStateFlagDeclaration() {
    return StateFlagDeclaration(
      start: start,
      startPos: startPos,
      end: end,
      endPos: endPos,
    );
  }

  EventStatement toEventStatement() {
    return EventStatement(
      start: start,
      startPos: startPos,
      end: end,
      endPos: endPos,
    );
  }

  EventFlagDeclaration toEventFlagDeclaration() {
    return EventFlagDeclaration(
      start: start,
      startPos: startPos,
      end: end,
      endPos: endPos,
    );
  }

  ImportStatement toImportStatement() {
    return ImportStatement(
      start: start,
      startPos: startPos,
      end: end,
      endPos: endPos,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'type': type.name,
      'start': startPos.toJson(),
      'end': endPos.toJson(),
    };

    return json;
  }
}

class Program extends Node {
  List<Node> body = [];

  @override
  NodeType type = NodeType.program;

  bool get hasScriptName {
    if (body.isEmpty) return false;

    final scriptName =
        body.firstWhereOrNull((elem) => elem is ScriptNameStatement);

    if (scriptName == null) return false;

    return true;
  }

  Program({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'body': body.map((elem) => elem.toJson()).toList(),
    };

    return json;
  }
}

class FlagDeclaration<T> extends Node {
  late T flag;
  late String raw;

  FlagDeclaration({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);
}

class ScriptNameStatement extends Node {
  late Identifier id;
  late Identifier meta;
  ExtendsDeclaration? extendsDeclaration;
  List<ScriptNameFlagDeclaration> flags = [];

  @override
  NodeType type = NodeType.scriptNameKw;

  bool get isConditional {
    final flag = flags
        .firstWhereOrNull((elem) => elem.flag == ScriptNameFlag.conditional);

    return flag != null;
  }

  ScriptNameStatement({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'id': id.toJson(),
      'meta': meta.toJson(),
      'extends': extendsDeclaration?.toJson(),
      'flags': flags.map((flag) => flag.toJson()).toList(),
    };

    return json;
  }
}

class ScriptNameFlagDeclaration extends FlagDeclaration<ScriptNameFlag> {
  @override
  NodeType type = NodeType.flagKw;

  ScriptNameFlagDeclaration({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'flag': flag.name,
    };

    return json;
  }
}

class ExtendsDeclaration extends Node {
  late Identifier extended;
  late Identifier meta;

  @override
  NodeType type = NodeType.extendsKw;

  ExtendsDeclaration({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'meta': meta.toJson(),
      'extended': extended.toJson(),
    };

    return json;
  }
}

class ExpressionStatement extends Node {
  @override
  NodeType type = NodeType.expressionStatement;

  late Node expression;

  ExpressionStatement({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'expression': expression.toJson(),
    };

    return json;
  }
}

class IfStatement extends Node {
  @override
  NodeType type = NodeType.ifKw;
  NodeType endType = NodeType.endIfKw;

  late Identifier meta;
  late Identifier endMeta;
  late Node test;
  late BlockStatement consequent;
  Node? alternate;
  Identifier? alternateMeta;

  IfStatement({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'endType': endType.name,
      'meta': meta.toJson(),
      'endMeta': endMeta.toJson(),
      'test': test.toJson(),
      'consequent': test.toJson(),
      'alternate': alternate?.toJson(),
    };

    return json;
  }
}

class FunctionStatement extends Node {
  @override
  NodeType type = NodeType.functionKw;
  NodeType endType = NodeType.endFunctionKw;

  late Identifier meta;
  Identifier? endMeta;
  late Identifier id;
  BlockStatement? body;
  List<VariableDeclaration> params = [];
  List<FunctionFlagDeclaration> flags = [];

  String kind = '';

  FunctionStatement({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  bool get isNative {
    final flag = flags.firstWhereOrNull((elem) {
      return elem.flag == FunctionFlag.native;
    });

    return flag != null;
  }

  bool get hasFunctionContext {
    final block = body;

    if (block == null) return false;

    final elems = block.body;

    return elems.any(
      (elem) =>
          elem is FunctionStatement ||
          elem is EventStatement ||
          elem is StateStatement,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'id': id.toJson(),
      'meta': meta.toJson(),
      'endMeta': endMeta?.toJson(),
      'params': params.map((elem) => elem.toJson()).toList(),
      'flags': flags.map((flag) => flag.toJson()).toList(),
      'kind': kind,
      'body': body?.toJson(),
    };

    return json;
  }
}

class FunctionFlagDeclaration extends FlagDeclaration<FunctionFlag> {
  @override
  NodeType type = NodeType.flagKw;

  FunctionFlagDeclaration({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

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
          startPos: startPos,
          endPos: endPos,
        );
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'flag': flag.name,
    };

    return json;
  }
}

class BlockStatement extends Node {
  @override
  NodeType type = NodeType.block;

  List<Node> body = [];

  BlockStatement({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'body': body.map((elem) => elem.toJson()).toList(),
    };

    return json;
  }
}

class AssignExpression extends Node {
  @override
  NodeType type = NodeType.assign;

  late Node left;
  late Node right;
  late String operator;

  AssignExpression({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'operator': operator,
      'left': left.toJson(),
      'right': right.toJson(),
    };

    return json;
  }
}

class Literal extends Node {
  @override
  NodeType type = NodeType.literal;

  dynamic value;
  String raw = '';

  Literal({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'value': value.toString(),
      'raw': raw,
    };

    return json;
  }
}

class Identifier extends Node {
  @override
  NodeType type = NodeType.id;

  String name = '';

  Identifier({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'name': name,
    };

    return json;
  }
}

class BinaryExpression extends Node {
  @override
  NodeType type = NodeType.binary;

  late Node left;
  late String operator;
  late Node right;

  BinaryExpression({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'operator': operator,
      'left': left.toJson(),
      'right': right.toJson(),
    };

    return json;
  }
}

class NewExpression extends Node {
  @override
  NodeType type = NodeType.newKw;

  late Node argument;
  late Identifier meta;

  NewExpression({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'argument': argument.toJson(),
      'meta': meta.toJson()
    };

    return json;
  }
}

class MemberExpression extends Node {
  @override
  NodeType type = NodeType.member;

  late Node property;
  late Node object;
  bool computed = false;

  MemberExpression({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'object': object.toJson(),
      'property': property.toJson(),
      'computed': computed,
    };

    return json;
  }
}

class VariableDeclaration extends Node {
  @override
  NodeType type = NodeType.variableDeclaration;

  late Variable variable;

  VariableDeclaration({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'variable': variable.toJson(),
    };

    return json;
  }
}

class Variable extends Node {
  @override
  NodeType type = NodeType.variable;

  String kind = '';

  late Identifier id;
  Node? initMeta;
  Node? init;
  bool isArray = false;

  Variable({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'id': id.toJson(),
      'init': init?.toJson(),
      'kind': kind,
      'isArray': isArray,
    };

    return json;
  }
}

class CallExpression extends Node {
  CallExpression({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  NodeType type = NodeType.callExpression;

  late Node callee;
  List<Node> arguments = [];

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'callee': callee.toJson(),
      'arguments': arguments.map((arg) => arg.toJson()).toList(),
    };

    return json;
  }
}

class PropertyDeclaration extends Node {
  PropertyDeclaration({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  NodeType type = NodeType.propertyKw;

  late Identifier meta;
  late Identifier id;
  late String kind;
  Node? init;
  List<PropertyFlagDeclaration> flags = [];

  bool get isFull => this is PropertyFullDeclaration;
  bool get isAutoOrAutoReadonly => isAuto || isAutoReadonly;
  bool get isAuto => hasFlag(PropertyFlag.auto);
  bool get isAutoReadonly => hasFlag(PropertyFlag.autoReadonly);
  bool get isConditional => hasFlag(PropertyFlag.conditional);
  bool get isHidden => hasFlag(PropertyFlag.hidden);
  bool get hasNoFlags => flags.isEmpty;

  bool hasFlag(PropertyFlag propertyFlag) {
    return flags.any((flag) => flag.flag == propertyFlag);
  }

  PropertyFullDeclaration toPropertyFullDeclaration() {
    return PropertyFullDeclaration(
      start: start,
      startPos: startPos,
      end: end,
      endPos: endPos,
    )
      ..flags = flags
      ..id = id
      ..init = init
      ..kind = kind
      ..meta = meta;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'id': id.toJson(),
      'meta': meta.toJson(),
      'init': init?.toJson(),
      'kind': kind,
      'flags': flags.map((flag) => flag.toJson()).toList(),
    };

    return json;
  }
}

class PropertyFullDeclaration extends PropertyDeclaration {
  FunctionStatement? getter;
  FunctionStatement? setter;
  late Identifier endMeta;

  PropertyFullDeclaration({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'endMeta': endMeta.toJson(),
      'getter': getter?.toJson(),
      'setter': setter?.toJson(),
    };
  }
}

class PropertyFlagDeclaration extends FlagDeclaration<PropertyFlag> {
  @override
  NodeType type = NodeType.flagKw;

  late PropertyFlag flag;

  PropertyFlagDeclaration({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

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
          startPos: startPos,
          endPos: endPos,
        );
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'flag': flag.name,
    };

    return json;
  }
}

class ReturnStatement extends Node {
  ReturnStatement({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  Node? argument;
  late Identifier meta;

  @override
  NodeType type = NodeType.returnKw;

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'argument': argument?.toJson(),
    };

    return json;
  }
}

class CastExpression extends Node {
  @override
  NodeType type = NodeType.castExpression;

  late Node id;
  late Node kind;

  CastExpression({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'id': id.toJson(),
      'kind': kind.toJson(),
    };

    return json;
  }
}

class UnaryExpression extends Node {
  @override
  NodeType type = NodeType.unary;

  String operator = '';
  late Node argument;
  bool isPrefix = false;

  UnaryExpression({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'operator': operator,
      'isPrefix': isPrefix,
      'argument': argument.toJson(),
    };

    return json;
  }
}

class WhileStatement extends Node {
  @override
  NodeType type = NodeType.whileKw;
  NodeType endType = NodeType.endWhileKw;

  late Node test;
  late BlockStatement consequent;
  late Identifier meta;
  late Identifier endMeta;

  WhileStatement({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'meta': meta.toJson(),
      'endMeta': endMeta.toJson(),
      'endType': endType.name,
      'test': test.toJson(),
      'consequent': consequent.toJson(),
    };

    return json;
  }
}

class StateStatement extends Node {
  @override
  NodeType type = NodeType.stateKw;
  NodeType endType = NodeType.endStateKw;
  late Identifier id;
  StateFlagDeclaration? flag;
  late BlockStatement body;

  bool get isAuto => flag?.flag == StateFlag.auto;

  bool get isValid {
    final body = this.body;
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
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'endType': endType.name,
      'id': id.toJson(),
      'flag': flag?.toJson(),
      'body': body.toJson(),
    };

    return json;
  }
}

class StateFlagDeclaration extends FlagDeclaration<StateFlag> {
  @override
  NodeType type = NodeType.flagKw;

  StateFlagDeclaration({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'flag': flag.name,
    };

    return json;
  }
}

class EventStatement extends Node {
  @override
  NodeType type = NodeType.eventKw;
  NodeType endType = NodeType.endEventKw;

  late Identifier meta;
  Identifier? endMeta;

  late Identifier id;
  BlockStatement? body;
  List<Node> params = [];
  List<EventFlagDeclaration> flags = [];

  EventStatement({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  bool get isNative {
    final flag = flags.firstWhereOrNull((elem) {
      return elem.flag == EventFlag.native;
    });

    return flag != null;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'endType': endType.name,
      'flags': flags.map((flag) => flag.toJson()).toList(),
      'params': params.map((param) => param.toJson()).toList(),
      'body': body?.toJson(),
    };

    return json;
  }
}

class EventFlagDeclaration extends FlagDeclaration<EventFlag> {
  @override
  NodeType type = NodeType.flagKw;

  EventFlagDeclaration({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  EventFlag flagFromType(NodeType type) {
    switch (type) {
      case NodeType.nativeKw:
        return EventFlag.native;
      default:
        throw UnexpectedTokenException(
          message: 'Unexpected flag',
          start: start,
          end: end,
          startPos: startPos,
          endPos: endPos,
        );
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'flag': flag.name,
    };

    return json;
  }
}

class ImportStatement extends Node {
  @override
  NodeType type = NodeType.importKw;

  late Identifier id;

  ImportStatement({
    required int start,
    required Position startPos,
    int end = 0,
    Position? endPos,
  }) : super(start: start, startPos: startPos, end: end, endPos: endPos);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'id': id.toJson(),
    };

    return json;
  }
}
