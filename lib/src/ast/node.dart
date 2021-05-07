import 'package:collection/collection.dart';
import 'package:papyrus_parser/papyrus_parser.dart';
import 'package:papyrus_parser/src/ast/position.dart';
import 'types.dart';

class Node {
  late NodeType type;
  int start;
  int end;
  final String _content;

  Position get startPos {
    return Position.fromIndex(start, content: _content);
  }

  Position get endPos {
    return Position.fromIndex(end, content: _content);
  }

  Node({
    required this.start,
    this.end = 0,
    required String content,
  }) : _content = content;

  Program toProgram() {
    return Program(start: start, end: end, content: _content);
  }

  ScriptNameStatement toScriptNameStatement() {
    return ScriptNameStatement(start: start, end: end, content: _content);
  }

  ScriptNameFlagDeclaration toScriptNameFlagDeclaration() {
    return ScriptNameFlagDeclaration(start: start, end: end, content: _content);
  }

  ExtendsDeclaration toExtendsDeclaration() {
    return ExtendsDeclaration(start: start, end: end, content: _content);
  }

  ExpressionStatement toExpressionStatement() {
    return ExpressionStatement(start: start, end: end, content: _content);
  }

  IfStatement toIfStatement() {
    return IfStatement(start: start, end: end, content: _content);
  }

  FunctionStatement toFunctionStatement() {
    return FunctionStatement(start: start, end: end, content: _content);
  }

  FunctionFlagDeclaration toFunctionFlagDeclaration() {
    return FunctionFlagDeclaration(start: start, end: end, content: _content);
  }

  BlockStatement toBlockStatement() {
    return BlockStatement(start: start, end: end, content: _content);
  }

  AssignExpression toAssignExpression() {
    return AssignExpression(start: start, end: end, content: _content);
  }

  Literal toLiteral() {
    return Literal(start: start, end: end, content: _content);
  }

  Identifier toIdentifier() {
    return Identifier(start: start, end: end, content: _content);
  }

  BinaryExpression toBinaryExpression() {
    return BinaryExpression(start: start, end: end, content: _content);
  }

  NewExpression toNewExpression() {
    return NewExpression(start: start, end: end, content: _content);
  }

  MemberExpression toMemberExpression() {
    return MemberExpression(start: start, end: end, content: _content);
  }

  VariableDeclaration toVariableDeclaration() {
    return VariableDeclaration(start: start, end: end, content: _content);
  }

  Variable toVariable() {
    return Variable(start: start, end: end, content: _content);
  }

  CallExpression toCallExpression() {
    return CallExpression(start: start, end: end, content: _content);
  }

  PropertyDeclaration toPropertyDeclaration() {
    return PropertyDeclaration(start: start, end: end, content: _content);
  }

  PropertyFlagDeclaration toPropertyFlagDeclaration() {
    return PropertyFlagDeclaration(start: start, end: end, content: _content);
  }

  ReturnStatement toReturnStatement() {
    return ReturnStatement(start: start, end: end, content: _content);
  }

  CastExpression toCastExpression() {
    return CastExpression(start: start, end: end, content: _content);
  }

  UnaryExpression toUnaryExpression() {
    return UnaryExpression(start: start, end: end, content: _content);
  }

  WhileStatement toWhileStatement() {
    return WhileStatement(start: start, end: end, content: _content);
  }

  StateStatement toStateStatement() {
    return StateStatement(start: start, end: end, content: _content);
  }

  EventStatement toEventStatement() {
    return EventStatement(start: start, end: end, content: _content);
  }

  EventFlagDeclaration toEventFlagDeclaration() {
    return EventFlagDeclaration(start: start, end: end, content: _content);
  }

  ImportStatement toImportStatement() {
    return ImportStatement(start: start, end: end, content: _content);
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
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'body': body.map((elem) => elem.toJson()).toList(),
    };

    return json;
  }
}

class ScriptNameStatement extends Node {
  late Identifier id;
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
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'id': id.toJson(),
      'extends': extendsDeclaration?.toJson(),
      'flags': flags.map((flag) => flag.toJson()).toList(),
    };

    return json;
  }
}

class ScriptNameFlagDeclaration extends Node {
  @override
  NodeType type = NodeType.flagKw;

  late ScriptNameFlag flag;

  ScriptNameFlagDeclaration({
    required int start,
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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

  late Node test;
  late Node consequent;
  Node? alternate;

  IfStatement({
    required int start,
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'endType': endType.name,
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

  late Identifier id;
  BlockStatement? body;
  List<Node> params = [];
  List<FunctionFlagDeclaration> flags = [];

  String kind = '';

  FunctionStatement({
    required int start,
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
      'params': params.map((elem) => elem.toJson()).toList(),
      'flags': flags.map((flag) => flag.toJson()).toList(),
      'kind': kind,
      'body': body?.toJson(),
    };

    return json;
  }
}

class FunctionFlagDeclaration extends Node {
  @override
  NodeType type = NodeType.flagKw;

  late FunctionFlag flag;

  FunctionFlagDeclaration({
    required int start,
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
  Node? init;
  bool isArray = false;

  Variable({
    required int start,
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
  @override
  NodeType type = NodeType.callExpression;

  late Node callee;
  List<Node> arguments = [];

  CallExpression({
    required int start,
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
  @override
  NodeType type = NodeType.propertyKw;

  late Identifier id;
  late String kind;
  Node? init;
  List<PropertyFlagDeclaration> flags = [];

  PropertyDeclaration({
    required int start,
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

  PropertyFullDeclaration toPropertyFullDeclaration() {
    return PropertyFullDeclaration(start: start, end: end, content: _content)
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
  bool get isHidden => hasFlag(PropertyFlag.hidden);
  bool get hasNoFlags => flags.isEmpty;

  bool hasFlag(PropertyFlag propertyFlag) {
    return flags.any((flag) => flag.flag == propertyFlag);
  }

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'id': id.toJson(),
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

  PropertyFullDeclaration({
    required int start,
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'getter': getter?.toJson(),
      'setter': setter?.toJson(),
    };
  }
}

class PropertyFlagDeclaration extends Node {
  @override
  NodeType type = NodeType.flagKw;

  late PropertyFlag flag;

  PropertyFlagDeclaration({
    required int start,
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
  Node? argument;

  @override
  NodeType type = NodeType.returnKw;

  ReturnStatement({
    required int start,
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
  late Node consequent;

  WhileStatement({
    required int start,
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
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
  StateFlag? flag;
  late BlockStatement body;

  bool get isAuto => flag == StateFlag.auto;

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
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'endType': endType.name,
      'id': id.toJson(),
      'flag': flag?.name,
      'body': body.toJson(),
    };

    return json;
  }
}

class EventStatement extends Node {
  @override
  NodeType type = NodeType.eventKw;
  NodeType endType = NodeType.endEventKw;

  late Identifier id;
  BlockStatement? body;
  List<Node> params = [];
  List<EventFlagDeclaration> flags = [];

  EventStatement({
    required int start,
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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

class EventFlagDeclaration extends Node {
  @override
  NodeType type = NodeType.flagKw;

  EventFlag? flag;

  EventFlagDeclaration({
    required int start,
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

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
      'flag': flag?.name,
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
    required String content,
    int end = 0,
  }) : super(start: start, end: end, content: content);

  @override
  Map<String, dynamic> toJson() {
    final json = {
      ...super.toJson(),
      'id': id.toJson(),
    };

    return json;
  }
}
