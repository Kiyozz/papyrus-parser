import 'package:papyrus_parser/papyrus_parser.dart';
import 'package:test/test.dart';

void main() {
  group('ScriptName', () {
    test(
      'should have a name, Extends a script, and have Hidden and Conditional flags',
      () {
        final tree = Tree(
          content: 'ScriptName Test Extends Form Hidden Conditional',
        );

        final program = tree.parse();
        expect(program.body.isNotEmpty, isTrue);
        final firstNode = program.body.first;
        expect(firstNode, TypeMatcher<ScriptName>());
        final scriptName = firstNode as ScriptName;
        expect(scriptName, TypeMatcher<ScriptName>());
        expect(scriptName.type, equals(NodeType.scriptNameKw));
        expect(scriptName.flags, hasLength(2));
        expect(
          scriptName.extendsDeclaration?.extended?.name,
          equals('Form'),
        );
      },
    );

    test(
      'should have a name and Hidden flag',
      () {
        final tree = Tree(
          content: 'ScriptName Test Hidden',
        );

        final program = tree.parse();
        expect(program.body.isNotEmpty, isTrue);
        final firstNode = program.body.first;
        expect(firstNode, TypeMatcher<ScriptName>());
        final scriptName = firstNode as ScriptName;
        expect(scriptName, TypeMatcher<ScriptName>());
        expect(scriptName.type, equals(NodeType.scriptNameKw));
        expect(scriptName.flags, hasLength(1));
        expect(scriptName.extendsDeclaration, isNull);
      },
    );

    test(
      'without ScriptName should throws an error',
      () {
        final tree = Tree(content: 'function toto()\nendfunction');

        expect(() => tree.parse(), throwsA(TypeMatcher<ScriptNameException>()));
      },
    );
  });

  group('FunctionStatement', () {
    test(
      'should have a name and no arguments',
      () {
        final tree = Tree(
          content: 'Function toto()\nEndFunction',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final secondNode = program.body.first;
        expect(secondNode, TypeMatcher<FunctionStatement>());
        final functionBody = secondNode as FunctionStatement;
        expect(functionBody.id?.name, equals('toto'));
        expect(functionBody.body, hasLength(1));
        expect(functionBody.type, equals(NodeType.functionKw));
        final functionBlock = functionBody.body[0];
        expect(functionBlock, TypeMatcher<BlockStatement>());
        final block = functionBlock as BlockStatement;
        expect(block.type, equals(NodeType.block));
      },
    );

    test(
      'should have a name and one argument without an init declaration',
      () {
        final tree = Tree(
          content: 'Function toto(String n)\nEndFunction',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final body = program.body.first;
        expect(body, TypeMatcher<FunctionStatement>());
        body as FunctionStatement;
        expect(body.id?.name, equals('toto'));
        expect(body.body, hasLength(1));
        expect(body.type, equals(NodeType.functionKw));
        expect(body.params, hasLength(1));
        final param = body.params.first;
        expect(param, TypeMatcher<VariableDeclaration>());
        final variable = (param as VariableDeclaration).variable;
        expect(variable, TypeMatcher<Variable>());
        variable as Variable;
        expect(variable.kind, 'String');
        expect(variable.init, isNull);
        expect(variable.id?.name, 'n');
      },
    );

    test(
      'should have a name, and one argument with an init declaration',
      () {
        final tree = Tree(
          content: 'Function toto(String n = "")\nEndFunction',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final body = program.body.first as FunctionStatement;
        final param = body.params.first;
        final variable = (param as VariableDeclaration).variable as Variable;
        expect(variable.kind, equals('String'));
        expect(variable.id?.name, equals('n'));
        final init = variable.init;
        expect(init, TypeMatcher<Literal>());
        init as Literal;
        expect(init.value, equals(''));
      },
    );

    test(
      'without EndFunction should throws an error',
      () {
        final tree = Tree(
          content: 'Function toto(String n = "")\n',
          throwWhenMissingScriptname: false,
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<BlockStatementException>()),
        );
      },
    );

    test(
      'should have Global and Native flags',
      () {
        final tree = Tree(
          content: 'Function toto() Global Native',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        final function = program.body.first as FunctionStatement;
        expect(function.body, hasLength(0));
        expect(function.flags, hasLength(2));
        final flags = function.flags;
        final globalFlag = flags.first;
        final nativeFlag = flags[1];
        expect(globalFlag.flag, FunctionFlag.global);
        expect(nativeFlag.flag, FunctionFlag.native);
      },
    );

    test(
      'should have Global flag',
      () {
        final tree = Tree(
          content: 'Function toto() Global\n'
              'EndFunction',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        final function = program.body.first as FunctionStatement;
        expect(function.body, hasLength(1));
        expect(function.flags, hasLength(1));
        final flags = function.flags;
        final globalFlag = flags.first;
        expect(globalFlag.flag, FunctionFlag.global);
      },
    );

    test(
      'with an unknown flag should throws an error',
      () {
        final tree = Tree(
          content: 'Function toto() unknownFlag\n'
              'EndFunction',
          throwWhenMissingScriptname: false,
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<FunctionFlagException>()),
        );
      },
    );
  });

  group('VariableDeclaration', () {
    test(
      'should not have an init declaration',
      () {
        final tree = Tree(
          content: 'String val',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final variableDeclaration = program.body.first;
        expect(variableDeclaration, TypeMatcher<VariableDeclaration>());
        variableDeclaration as VariableDeclaration;
        expect(variableDeclaration.variable, isNotNull);
        final variable = variableDeclaration.variable as Variable;
        expect(variable.init, isNull);
        expect(variable.kind, equals('String'));
        expect(variable.id, isNotNull);
        final name = variable.id as Identifier;
        expect(name.name, equals('val'));
      },
    );

    test(
      'should have an init Literal declaration',
      () {
        final tree = Tree(
          content: 'String val = ""',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final variableDeclaration = program.body.first;
        expect(variableDeclaration, TypeMatcher<VariableDeclaration>());
        variableDeclaration as VariableDeclaration;
        expect(variableDeclaration.variable, isNotNull);
        final variable = variableDeclaration.variable as Variable;
        expect(variable.init, isNotNull);
        final init = variable.init;
        expect(init, TypeMatcher<Literal>());
        init as Literal;
        expect(init.value, '');
        expect(variable.kind, equals('String'));
        expect(variable.id, isNotNull);
        final name = variable.id as Identifier;
        expect(name.name, equals('val'));
      },
    );

    test(
      'should have an init LogicalExpression declaration',
      () {
        final tree = Tree(
          content: 'Bool val = ShouldStay() == false',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final variableDeclaration = program.body.first;
        expect(variableDeclaration, TypeMatcher<VariableDeclaration>());
        variableDeclaration as VariableDeclaration;
        expect(variableDeclaration.variable, isNotNull);
        final variable = variableDeclaration.variable as Variable;
        expect(variable.init, isNotNull);
        final init = variable.init;
        expect(init, TypeMatcher<LogicalExpression>());
        init as LogicalExpression;
        expect(init.left, TypeMatcher<CallExpression>());
        expect(init.operator, '==');
        expect(init.right, TypeMatcher<Literal>());
        expect(variable.kind, equals('Bool'));
        expect(variable.id, isNotNull);

        final name = variable.id as Identifier;

        expect(name.name, equals('val'));
      },
    );

    test(
      'should have a CastExpression that have one CallExpression and one Identifier',
      () {
        final tree = Tree(
          content: 'String t = toto() as String',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        final variableDeclaration = program.body.first;
        expect(variableDeclaration, TypeMatcher<VariableDeclaration>());
        variableDeclaration as VariableDeclaration;
        final variable = variableDeclaration.variable;
        expect(variable, isNotNull);
        variable as Variable;
        final cast = variable.init;
        expect(cast, TypeMatcher<CastExpression>());
        cast as CastExpression;
        final call = cast.id;
        expect(call, TypeMatcher<CallExpression>());
        call as CallExpression;
        final callee = call.callee;
        expect(callee, TypeMatcher<Identifier>());
        callee as Identifier;
        expect(callee.name, equals('toto'));
        final kind = cast.kind;
        expect(kind, TypeMatcher<Identifier>());
        kind as Identifier;
        expect(kind.name, equals('String'));
      },
    );
  });

  group('PropertyDeclaration', () {
    test(
      'should have a type, a name, and Auto flag',
      () {
        final tree = Tree(
          content: 'Int Property test Auto',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final property = program.body.first;
        expect(property, TypeMatcher<PropertyDeclaration>());
        property as PropertyDeclaration;
        expect(property.flags, hasLength(1));
        final id = property.id;
        expect(id, TypeMatcher<Identifier>());
        id as Identifier;
        expect(id.name, equals('test'));
        expect(property.kind, 'Int');
        expect(property.init, isNull);
      },
    );

    test(
      'should have a type, a name, an constant init declaration and AutoReadOnly flag',
      () {
        final tree = Tree(
          content: 'Int Property test = 1 AutoReadOnly',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final property = program.body.first;
        expect(property, TypeMatcher<PropertyDeclaration>());
        property as PropertyDeclaration;
        expect(property.flags, hasLength(1));
        expect(property.flags.first.flag, equals(PropertyFlag.autoReadonly));
        final id = property.id;
        expect(id, TypeMatcher<Identifier>());
        id as Identifier;
        expect(id.name, equals('test'));
        expect(property.kind, 'Int');
        expect(property.init, isNotNull);
        final init = property.init;
        expect(init, TypeMatcher<Literal>());
        init as Literal;
        expect(init.value, 1);
      },
    );

    test(
      'Full should have a type, a name, a setter, and a getter',
      () {
        final tree = Tree(
          content: 'Int Property test = 1\n'
              '  Int Function Get()\n'
              '  EndFunction\n'
              '  Function Set(Int value)\n'
              '  EndFunction\n'
              'EndProperty',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final property = program.body.first;
        expect(property, TypeMatcher<PropertyFullDeclaration>());
        property as PropertyFullDeclaration;
        expect(property.flags, hasLength(1));
        expect(property.flags.first.flag, equals(PropertyFlag.hidden));
        final id = property.id;
        expect(id, TypeMatcher<Identifier>());
        id as Identifier;
        expect(id.name, equals('test'));
        expect(property.kind, 'Int');
        expect(property.init, isNotNull);
        final init = property.init;
        expect(init, TypeMatcher<Literal>());
        init as Literal;
        expect(init.value, 1);
        expect(init.raw, '1');
      },
    );

    test(
      'Full without getter and setter should throws an error',
      () {
        final tree = Tree(
          content: 'Int Property test = 1 Hidden\n'
              'EndProperty',
          throwWhenMissingScriptname: false,
        );

        expect(() => tree.parse(), throwsA(TypeMatcher<PropertyException>()));
      },
    );

    test(
      'Full without Endshould throws an error',
      () {
        final tree = Tree(
          content: 'Int Property test = 1 Hidden\n'
              '  Int Function Get()\n'
              '  EndFunction',
          throwWhenMissingScriptname: false,
        );

        expect(() => tree.parse(), throwsA(TypeMatcher<PropertyException>()));
      },
    );

    test(
      'AutoReadOnly without an init declaration should throws an error',
      () {
        final tree = Tree(
          content: 'Int Property test AutoReadOnly\n',
          throwWhenMissingScriptname: false,
        );

        expect(() => tree.parse(), throwsA(TypeMatcher<PropertyException>()));
      },
    );

    test(
      'Conditional without an Auto or AutoReadOnly flag should throws an error',
      () {
        final tree = Tree(
          content: 'Int Property test Conditional\n',
          throwWhenMissingScriptname: false,
        );

        expect(() => tree.parse(), throwsA(TypeMatcher<PropertyException>()));
      },
    );

    test(
      'Auto Conditional without an init declaration should throws an error',
      () {
        final tree = Tree(
          content: 'Int Property test Auto Conditional\n',
          throwWhenMissingScriptname: false,
        );

        expect(() => tree.parse(), throwsA(TypeMatcher<PropertyException>()));
      },
    );
  });

  group('ReturnStatement', () {
    test(
      'argument should be a Literal',
      () {
        final tree = Tree(
          content: 'Function test()\n'
              '  Return true\n'
              'EndFunction',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final functionStatements =
            (program.body.first as FunctionStatement).body;
        expect(functionStatements, hasLength(1));
        expect(functionStatements.first, TypeMatcher<BlockStatement>());
        final block = functionStatements.first as BlockStatement;
        expect(block.body, hasLength(1));
        final returnStatement = block.body.first;
        expect(returnStatement, TypeMatcher<ReturnStatement>());
        returnStatement as ReturnStatement;
        expect(returnStatement.argument, TypeMatcher<Literal>());
        final argument = returnStatement.argument as Literal;
        expect(argument.value, true);
      },
    );

    test(
      'argument should be empty',
      () {
        final tree = Tree(
          content: 'Function test()\n'
              '  Return\n'
              'EndFunction',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final functionStatements =
            (program.body.first as FunctionStatement).body;
        expect(functionStatements, hasLength(1));
        expect(functionStatements.first, TypeMatcher<BlockStatement>());
        final block = functionStatements.first as BlockStatement;
        expect(block.body, hasLength(1));
        final returnStatement = block.body.first;
        expect(returnStatement, TypeMatcher<ReturnStatement>());
        returnStatement as ReturnStatement;
        expect(returnStatement.argument, isNull);
      },
    );

    test(
      'argument should be a CallExpression',
      () {
        final tree = Tree(
          content: 'Function test()\n'
              '  Return shouldStay()\n'
              'EndFunction',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final functionStatements =
            (program.body.first as FunctionStatement).body;
        expect(functionStatements, hasLength(1));
        expect(functionStatements.first, TypeMatcher<BlockStatement>());
        final block = functionStatements.first as BlockStatement;
        expect(block.body, hasLength(1));
        final returnStatement = block.body.first;
        expect(returnStatement, TypeMatcher<ReturnStatement>());
        returnStatement as ReturnStatement;
        expect(returnStatement.argument, TypeMatcher<CallExpression>());
        final argument = returnStatement.argument as CallExpression;
        expect(argument.callee, TypeMatcher<Identifier>());
        final callee = argument.callee as Identifier;
        expect(callee.name, equals('shouldStay'));
      },
    );

    test(
      'argument should be a LogicalExpression with two CallExpression',
      () {
        final tree = Tree(
          content: 'Function test()\n'
              '  Return (shouldStay() && shouldStay())\n'
              'EndFunction',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final functionStatements =
            (program.body.first as FunctionStatement).body;
        expect(functionStatements, hasLength(1));
        expect(functionStatements.first, TypeMatcher<BlockStatement>());
        final block = functionStatements.first as BlockStatement;
        expect(block.body, hasLength(1));
        final returnStatement = block.body.first;
        expect(returnStatement, TypeMatcher<ReturnStatement>());
        returnStatement as ReturnStatement;
        expect(returnStatement.argument, TypeMatcher<LogicalExpression>());
        final argument = returnStatement.argument as LogicalExpression;
        final left = argument.left;
        final right = argument.right;
        expect(left, TypeMatcher<CallExpression>());
        expect(right, TypeMatcher<CallExpression>());
        left as CallExpression;
        right as CallExpression;
        expect(left.callee, TypeMatcher<Identifier>());
        final lCallee = left.callee as Identifier;
        expect(lCallee.name, equals('shouldStay'));
        expect(right.callee, TypeMatcher<Identifier>());
        final rCallee = left.callee as Identifier;
        expect(rCallee.name, equals('shouldStay'));
      },
    );
  });

  group('IfStatement', () {
    test(
      'should have a Literal and no parenthesis',
      () {
        final tree = Tree(
          content: 'If true\nEndIf',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first;
        expect(ifStatement, TypeMatcher<IfStatement>());
        ifStatement as IfStatement;
        expect(ifStatement.test, isNotNull);
        final ifTest = ifStatement.test as Node;
        expect(ifTest.type, equals(NodeType.literal));
        expect(ifStatement.consequent, isNotNull);
        final consequent = ifStatement.consequent as Node;
        expect(consequent.type, equals(NodeType.block));
      },
    );

    test(
      'should have a Literal and parenthesis',
      () {
        final tree = Tree(
          content: 'If (true)\nEndIf',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first;
        expect(ifStatement, TypeMatcher<IfStatement>());
        ifStatement as IfStatement;
        expect(ifStatement.test, isNotNull);
        final ifTest = ifStatement.test as Node;
        expect(ifTest.type, equals(NodeType.literal));
        expect(ifStatement.consequent, isNotNull);
        final consequent = ifStatement.consequent as Node;
        expect(consequent.type, equals(NodeType.block));
      },
    );

    test(
      'should have a LogicalExpression with a CallExpression and a Literal, and parenthesis',
      () {
        final tree = Tree(
          content: 'If (shouldStay() == true)\n'
              'EndIf',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first;
        expect(ifStatement, TypeMatcher<IfStatement>());
        ifStatement as IfStatement;
        expect(ifStatement.test, isNotNull);
        final ifTest = ifStatement.test as Node;
        expect(ifTest, TypeMatcher<LogicalExpression>());
        ifTest as LogicalExpression;
        expect(ifTest.type, equals(NodeType.binary));
        expect(ifTest.left, TypeMatcher<CallExpression>());
        expect(ifTest.right, TypeMatcher<Literal>());
        expect(ifStatement.consequent, isNotNull);
        final consequent = ifStatement.consequent as Node;
        expect(consequent.type, equals(NodeType.block));
      },
    );

    test(
      'should have a LogicalExpression with two CallExpression, and parenthesis',
      () {
        final tree = Tree(
          content: 'If (shouldStay() == shouldStay())\n'
              'EndIf',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first;
        expect(ifStatement, TypeMatcher<IfStatement>());
        ifStatement as IfStatement;
        expect(ifStatement.test, isNotNull);
        final ifTest = ifStatement.test as Node;
        expect(ifTest, TypeMatcher<LogicalExpression>());
        ifTest as LogicalExpression;
        expect(ifTest.type, equals(NodeType.binary));
        expect(ifTest.left, TypeMatcher<CallExpression>());
        expect(ifTest.right, TypeMatcher<CallExpression>());
        expect(ifStatement.consequent, isNotNull);
        final consequent = ifStatement.consequent as Node;
        expect(consequent.type, equals(NodeType.block));
      },
    );

    test(
      'should have a LogicalExpression with two CallExpression, one with one parameter, and parenthesis',
      () {
        final tree = Tree(
          content: 'If (shouldStay(true) == shouldStay())\n'
              'EndIf',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first;
        expect(ifStatement, TypeMatcher<IfStatement>());
        ifStatement as IfStatement;
        expect(ifStatement.test, isNotNull);
        final ifTest = ifStatement.test as Node;
        expect(ifTest, TypeMatcher<LogicalExpression>());
        ifTest as LogicalExpression;
        expect(ifTest.type, equals(NodeType.binary));
        expect(ifTest.left, TypeMatcher<CallExpression>());
        expect((ifTest.left as CallExpression).arguments, hasLength(1));
        expect(ifTest.right, TypeMatcher<CallExpression>());
        expect(ifStatement.consequent, isNotNull);
        final consequent = ifStatement.consequent as Node;
        expect(consequent.type, equals(NodeType.block));
      },
    );

    test(
      'should have a LogicalExpression with two CallExpression, one with one param that is a CallExpression, and parenthesis',
      () {
        final tree = Tree(
          content: 'If (shouldStay(shouldStay()) == shouldStay())'
              'EndIf',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first;
        expect(ifStatement, TypeMatcher<IfStatement>());
        ifStatement as IfStatement;
        expect(ifStatement.test, isNotNull);
        final ifTest = ifStatement.test as Node;
        expect(ifTest, TypeMatcher<LogicalExpression>());
        ifTest as LogicalExpression;
        expect(ifTest.type, equals(NodeType.binary));
        expect(ifTest.left, TypeMatcher<CallExpression>());
        final left = ifTest.left as CallExpression;
        expect(left.arguments, hasLength(1));
        expect(left.arguments[0], TypeMatcher<CallExpression>());
        expect(ifTest.right, TypeMatcher<CallExpression>());
        expect(ifStatement.consequent, isNotNull);
        final consequent = ifStatement.consequent as Node;
        expect(consequent.type, equals(NodeType.block));
      },
    );

    test(
      'should have a Literal, parenthesis, and a BlockStatement with two CallExpression',
      () {
        final tree = Tree(
          content: 'If (true)'
              '  ShouldStay()\n'
              '  ShouldStay()\n'
              'EndIf',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first;
        expect(ifStatement, TypeMatcher<IfStatement>());
        ifStatement as IfStatement;
        expect(ifStatement.test, isNotNull);
        expect(ifStatement.consequent, isNotNull);
        final consequent = ifStatement.consequent as Node;
        expect(consequent, TypeMatcher<BlockStatement>());
        expect(consequent.type, equals(NodeType.block));
        consequent as BlockStatement;
        expect(consequent.body, hasLength(2));
      },
    );

    test(
      'should have a CastExpression that have a CallExpression and an Identifier',
      () {
        final tree = Tree(
          content: 'If t() as String\n'
              'EndIf',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        final ifStatement = program.body.first;
        expect(ifStatement, TypeMatcher<IfStatement>());
        ifStatement as IfStatement;
        final test = ifStatement.test;
        expect(test, TypeMatcher<CastExpression>());
        test as CastExpression;
        final call = test.id;
        expect(call, TypeMatcher<CallExpression>());
        call as CallExpression;
        final callee = call.callee;
        expect(callee, TypeMatcher<Identifier>());
        callee as Identifier;
        expect(callee.name, equals('t'));
        final kind = test.kind;
        expect(kind, TypeMatcher<Identifier>());
        kind as Identifier;
        expect(kind.name, equals('String'));
      },
    );

    test(
      'should have two CastExpression that have a CallExpression and an Identifier',
      () {
        final tree = Tree(
          content: 'If t() as String && a() as Int\n'
              'EndIf',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        final ifStatement = program.body.first;
        expect(ifStatement, TypeMatcher<IfStatement>());
        ifStatement as IfStatement;
        final test = ifStatement.test;
        expect(test, TypeMatcher<LogicalExpression>());
        test as LogicalExpression;
        expect(test.operator, equals('&&'));
        final leftTest = test.left;
        expect(leftTest, TypeMatcher<CastExpression>());
        leftTest as CastExpression;
        final call = leftTest.id;
        expect(call, TypeMatcher<CallExpression>());
        call as CallExpression;
        final callee = call.callee;
        expect(callee, TypeMatcher<Identifier>());
        callee as Identifier;
        expect(callee.name, equals('t'));
        final kind = leftTest.kind;
        expect(kind, TypeMatcher<Identifier>());
        kind as Identifier;
        expect(kind.name, equals('String'));

        final rightTest = test.right;
        expect(rightTest, TypeMatcher<CastExpression>());
        rightTest as CastExpression;
        final rightCall = rightTest.id;
        expect(rightCall, TypeMatcher<CallExpression>());
        rightCall as CallExpression;
        final rightCallee = rightCall.callee;
        expect(rightCallee, TypeMatcher<Identifier>());
        rightCallee as Identifier;
        expect(rightCallee.name, equals('a'));
        final rightKind = rightTest.kind;
        expect(rightKind, TypeMatcher<Identifier>());
        rightKind as Identifier;
        expect(rightKind.name, equals('Int'));
      },
    );

    test(
      'should have a CallExpression and an UnaryExpression',
      () {
        final tree = Tree(
          content: 'If t() == -1\n'
              'EndIf',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        final ifStatement = program.body.first;
        expect(ifStatement, TypeMatcher<IfStatement>());
        ifStatement as IfStatement;
        final test = ifStatement.test;
        expect(test, TypeMatcher<LogicalExpression>());
        test as LogicalExpression;
        expect(test.operator, equals('=='));
        final call = test.left;
        expect(call, TypeMatcher<CallExpression>());
        call as CallExpression;
        final callee = call.callee;
        expect(callee, TypeMatcher<Identifier>());
        callee as Identifier;
        expect(callee.name, equals('t'));

        final rightTest = test.right;
        expect(rightTest, TypeMatcher<UnaryExpression>());
        rightTest as UnaryExpression;
        expect(rightTest.argument, TypeMatcher<Literal>());
        expect(rightTest.isPrefix, isTrue);
        expect(rightTest.operator, '-');
        final rightLiteral = rightTest.argument;
        expect(rightLiteral, TypeMatcher<Literal>());
        rightLiteral as Literal;
        expect(rightLiteral.value, equals(1));
      },
    );
  });

  group('CallExpression', () {
    test(
      'should have a Literal positional param and an optional AssignExpression param',
      () {
        final tree = Tree(
          content: 'shouldAssign(false, t = true)',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        final call = program.body.first;
        expect(call, TypeMatcher<CallExpression>());
        call as CallExpression;
        expect(call.arguments, hasLength(2));
        expect(call.callee, TypeMatcher<Identifier>());
        final callee = call.callee as Identifier;
        expect(callee.name, 'shouldAssign');
        final positional = call.arguments.first;
        final optional = call.arguments[1];
        expect(positional, TypeMatcher<Literal>());
        expect(optional, TypeMatcher<AssignExpression>());
        positional as Literal;
        expect(positional.value, isFalse);
        optional as AssignExpression;
        expect(optional.left, TypeMatcher<Identifier>());
        expect(optional.right, TypeMatcher<Literal>());
        final opLeft = optional.left as Identifier;
        final opRight = optional.right as Literal;
        expect(opLeft.name, equals('t'));
        expect(opRight.value, isTrue);
      },
    );
  });

  group('CastExpression', () {
    test(
      'should have two Identifiers',
      () {
        final tree = Tree(
          content: 'toto as String',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        final cast = program.body.first;
        expect(cast, TypeMatcher<CastExpression>());
        cast as CastExpression;
        final id = cast.id;
        expect(id, TypeMatcher<Identifier>());
        id as Identifier;
        expect(id.name, equals('toto'));
        final kind = cast.kind;
        expect(kind, TypeMatcher<Identifier>());
        kind as Identifier;
        expect(kind.name, equals('String'));
      },
    );

    test(
      'should have one CallExpression and one Identifier',
      () {
        final tree = Tree(
          content: 'toto() as String',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();
        final cast = program.body.first;
        expect(cast, TypeMatcher<CastExpression>());
        cast as CastExpression;
        final call = cast.id;
        expect(call, TypeMatcher<CallExpression>());
        call as CallExpression;
        final callee = call.callee;
        expect(callee, TypeMatcher<Identifier>());
        callee as Identifier;
        expect(callee.name, equals('toto'));
        final kind = cast.kind;
        expect(kind, TypeMatcher<Identifier>());
        kind as Identifier;
        expect(kind.name, equals('String'));
      },
    );
  });

  group('Literal', () {
    test(
      'hex should be parsed',
      () {
        final tree = Tree(
          content: 'Int t = 0x0033FF',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();

        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable as Variable;
        final literal = variable.init;

        expect(literal, TypeMatcher<Literal>());
        literal as Literal;
        expect(literal.value, equals(0x0033FF));
        expect(literal.value, equals(13311));
        expect(literal.raw, equals('0x0033FF'));
      },
    );

    test(
      'int negative should be parsed',
      () {
        final tree = Tree(
          content: 'Int t = -1',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();

        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable as Variable;
        final expression = variable.init;
        expect(expression, TypeMatcher<UnaryExpression>());
        expression as UnaryExpression;
        expect(expression.operator, equals('-'));
        final literal = expression.argument;
        expect(literal, TypeMatcher<Literal>());
        literal as Literal;
        expect(literal.value, equals(1));
        expect(literal.raw, equals('1'));
      },
    );

    test(
      'float negative should be parsed',
      () {
        final tree = Tree(
          content: 'Float t = -1.0',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();

        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable as Variable;
        final expression = variable.init;
        expect(expression, TypeMatcher<UnaryExpression>());
        expression as UnaryExpression;
        expect(expression.operator, equals('-'));
        final literal = expression.argument;
        expect(literal, TypeMatcher<Literal>());
        literal as Literal;
        expect(literal.value, equals(1.0));
        expect(literal.raw, equals('1.0'));
      },
    );
  });

  // TODO: none literal
  // TODO: while
  // TODO: conditional property must be in scriptname conditional
  // TODO: conditional variable must be in scriptname conditional
}
