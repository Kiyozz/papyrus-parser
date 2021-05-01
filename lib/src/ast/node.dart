import 'types.dart';

class Node {
  NodeType? type;
  NodeType? endType;
  int start;
  int end;

  Node({
    required this.start,
    this.end = 0,
  });

  Program toProgram() {
    return Program(start: start, end: end);
  }

  ScriptName toScriptName() {
    return ScriptName(start: start, end: end);
  }

  ScriptNameFlag toScriptNameFlag() {
    return ScriptNameFlag(start: start, end: end);
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

  BlockStatement toBlockStatement() {
    return BlockStatement(start: start, end: end);
  }

  Assign toAssign() {
    return Assign(start: start, end: end);
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

  Logical toLogical() {
    return Logical(start: start, end: end);
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
}

class Program extends Node {
  List<dynamic> body = [];

  @override
  NodeType? type = NodeType.program;

  Program({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class ScriptName extends Node {
  Node? id;
  ExtendsDeclaration? extendsDeclaration;
  List<ScriptNameFlag> flags = [];

  @override
  NodeType? type = NodeType.scriptNameKw;

  ScriptName({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
}

class ScriptNameFlag extends Node {
  @override
  NodeType? type = NodeType.flagKw;

  Flag? flag;

  ScriptNameFlag({
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

  @override
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

  @override
  NodeType? endType = NodeType.endFunctionKw;

  Identifier? id;
  List<Node> body = [];
  List<Node> params = [];

  FunctionStatement({
    required int start,
    int end = 0,
  }) : super(start: start, end: end);
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

class Assign extends Node {
  @override
  NodeType? type = NodeType.assign;

  Node? left;
  Node? right;

  Assign({
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

class Logical extends Node {
  Node? left;
  Node? right;
  String operator = '';

  Logical({
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