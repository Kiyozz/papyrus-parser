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
        final scriptName = program.body.first as ScriptNameStatement;
        expect(scriptName.type, equals(NodeType.scriptNameKw));
        expect(scriptName.flags, hasLength(2));
        final extendsDeclaration =
            scriptName.extendsDeclaration as ExtendsDeclaration;
        expect(
          extendsDeclaration.extended?.name,
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
        final scriptName = program.body.first as ScriptNameStatement;
        expect(scriptName.type, equals(NodeType.scriptNameKw));
        expect(scriptName.flags, hasLength(1));
        expect(scriptName.extendsDeclaration, isNull);
      },
    );

    test(
      'without ScriptNameStatement should throws an error',
      () {
        final tree = Tree(content: 'function toto()\nendfunction');

        expect(() => tree.parse(), throwsA(TypeMatcher<ScriptNameException>()));
      },
    );

    test(
      'not the same as the filename should throws an error',
      () {
        final tree = Tree(content: 'ScriptName notTest', filename: 'Test');

        expect(() => tree.parse(), throwsA(TypeMatcher<ScriptNameException>()));
      },
    );

    test(
      'that appears more than once should throws an error',
      () {
        final tree = Tree(
          content: 'ScriptName test\nScriptName toto',
          options: const TreeOptions(
            throwWhenScriptnameMismatchFilename: false,
          ),
        );

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
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final functionBody = program.body.first as FunctionStatement;
        expect(functionBody.id?.name, equals('toto'));
        expect(functionBody.body, hasLength(1));
        expect(functionBody.type, equals(NodeType.functionKw));
        final block = functionBody.body[0] as BlockStatement;
        expect(block.type, equals(NodeType.block));
      },
    );

    test(
      'should have a name and one argument without an init declaration',
      () {
        final tree = Tree(
          content: 'Function toto(String n)\nEndFunction',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final body = program.body.first as FunctionStatement;
        expect(body.id?.name, equals('toto'));
        expect(body.body, hasLength(1));
        expect(body.type, equals(NodeType.functionKw));
        expect(body.params, hasLength(1));
        final param = body.params.first as VariableDeclaration;
        final variable = param.variable as Variable;
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
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final body = program.body.first as FunctionStatement;
        final param = body.params.first as VariableDeclaration;
        final variable = param.variable as Variable;
        expect(variable.kind, equals('String'));
        expect(variable.id?.name, equals('n'));
        final init = variable.init as Literal;
        expect(init.value, equals(''));
      },
    );

    test(
      'without EndFunction should throws an error',
      () {
        final tree = Tree(
          content: 'Function toto(String n = "")\n',
          options: TreeOptions(throwWhenMissingScriptname: false),
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
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();
        final function = program.body.first as FunctionStatement;
        expect(function.body, isEmpty);
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
          options: TreeOptions(throwWhenMissingScriptname: false),
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
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<FunctionFlagException>()),
        );
      },
    );

    test(
      'should have VariableDeclaration with init declaration in first parameter',
      () {
        final tree = Tree(
          content: 'Function toto(String n = "") global\n'
              'EndFunction',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final functionStatement = tree.parse().body.first as FunctionStatement;
        final variableDeclaration =
            functionStatement.params.first as VariableDeclaration;
        final variable = variableDeclaration.variable as Variable;
        expect(variable.init, TypeMatcher<Literal>());
      },
    );
  });

  group('VariableDeclaration', () {
    test(
      'should not have an init declaration',
      () {
        final tree = Tree(
          content: 'String val',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable as Variable;
        expect(variable.init, isNull);
        expect(variable.kind, equals('String'));
        final name = variable.id as Identifier;
        expect(name.name, equals('val'));
      },
    );

    test(
      'should have an init Literal declaration',
      () {
        final tree = Tree(
          content: 'String val = ""',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable as Variable;
        final init = variable.init as Literal;
        expect(init.value, '');
        expect(variable.kind, equals('String'));
        final name = variable.id as Identifier;
        expect(name.name, equals('val'));
      },
    );

    test(
      'should have an init LogicalExpression declaration',
      () {
        final tree = Tree(
          content: 'Bool val = ShouldStay() == false',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable as Variable;
        final init = variable.init as LogicalExpression;
        expect(init.left, TypeMatcher<CallExpression>());
        expect(init.operator, '==');
        expect(init.right, TypeMatcher<Literal>());
        expect(variable.kind, equals('Bool'));
        final name = variable.id as Identifier;
        expect(name.name, equals('val'));
      },
    );

    test(
      'should have a CastExpression that have one CallExpression and one Identifier',
      () {
        final tree = Tree(
          content: 'String t = toto() as String',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();
        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable as Variable;
        final cast = variable.init as CastExpression;
        final call = cast.id as CallExpression;
        final callee = call.callee as Identifier;
        expect(callee.name, equals('toto'));
        final kind = cast.kind as Identifier;
        expect(kind.name, equals('String'));
      },
    );

    test(
      'should have an MemberExpression as init declaration',
      () {
        final tree = Tree(
          content: 'String f = toto.init.toto',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final variableDeclaration =
            tree.parse().body.first as VariableDeclaration;
        final variable = variableDeclaration.variable as Variable;
        expect(variable.init, TypeMatcher<MemberExpression>());
      },
    );
  });

  group('PropertyDeclaration', () {
    test(
      'should have a type, a name, and Auto flag',
      () {
        final tree = Tree(
          content: 'Int Property test Auto',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final property = program.body.first as PropertyDeclaration;
        expect(property.flags, hasLength(1));
        final id = property.id as Identifier;
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
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final property = program.body.first as PropertyDeclaration;
        expect(property.flags, hasLength(1));
        expect(property.flags.first.flag, equals(PropertyFlag.autoReadonly));
        final id = property.id as Identifier;
        expect(id.name, equals('test'));
        expect(property.kind, 'Int');
        final init = property.init as Literal;
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
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final property = program.body.first as PropertyFullDeclaration;
        expect(property.flags, hasLength(1));
        expect(property.flags.first.flag, equals(PropertyFlag.hidden));
        final id = property.id as Identifier;
        expect(id.name, equals('test'));
        expect(property.kind, 'Int');
        final init = property.init as Literal;
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
          options: TreeOptions(throwWhenMissingScriptname: false),
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
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        expect(() => tree.parse(), throwsA(TypeMatcher<PropertyException>()));
      },
    );

    test(
      'AutoReadOnly without an init declaration should throws an error',
      () {
        final tree = Tree(
          content: 'Int Property test AutoReadOnly\n',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        expect(() => tree.parse(), throwsA(TypeMatcher<PropertyException>()));
      },
    );

    test(
      'Conditional without an Auto or AutoReadOnly flag should throws an error',
      () {
        final tree = Tree(
          content: 'Int Property test Conditional\n',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        expect(() => tree.parse(), throwsA(TypeMatcher<PropertyException>()));
      },
    );

    test(
      'Auto Conditional without an init declaration should throws an error',
      () {
        final tree = Tree(
          content: 'Int Property test Auto Conditional\n',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        expect(() => tree.parse(), throwsA(TypeMatcher<PropertyException>()));
      },
    );

    test(
      'Conditional not in a Conditional ScriptName should throws an error',
      () {
        final tree = Tree(
          content: 'ScriptName Test\n\n'
              'Int Property test Auto Conditional',
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<PropertyException>()),
        );
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
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final functionStatements =
            (program.body.first as FunctionStatement).body;
        expect(functionStatements, hasLength(1));
        final block = functionStatements.first as BlockStatement;
        expect(block.body, hasLength(1));
        final returnStatement = block.body.first as ReturnStatement;
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
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final functionStatements =
            (program.body.first as FunctionStatement).body;
        expect(functionStatements, hasLength(1));
        final block = functionStatements.first as BlockStatement;
        expect(block.body, hasLength(1));
        final returnStatement = block.body.first as ReturnStatement;
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
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final functionStatements =
            (program.body.first as FunctionStatement).body;
        expect(functionStatements, hasLength(1));
        final block = functionStatements.first as BlockStatement;
        expect(block.body, hasLength(1));
        final returnStatement = block.body.first as ReturnStatement;
        final argument = returnStatement.argument as CallExpression;
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
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final functionStatements =
            (program.body.first as FunctionStatement).body;
        expect(functionStatements, hasLength(1));
        final block = functionStatements.first as BlockStatement;
        expect(block.body, hasLength(1));
        final returnStatement = block.body.first as ReturnStatement;
        final argument = returnStatement.argument as LogicalExpression;
        final left = argument.left as CallExpression;
        final right = argument.right as CallExpression;
        final lCallee = left.callee as Identifier;
        expect(lCallee.name, equals('shouldStay'));
        final rCallee = right.callee as Identifier;
        expect(rCallee.name, equals('shouldStay'));
      },
    );

    test('used outside of FunctionStatement should throws an error', () {
      final tree = Tree(
        content: 'Return true',
        options: TreeOptions(throwWhenMissingScriptname: false),
      );

      expect(
        () => tree.parse(),
        throwsA(TypeMatcher<UnexpectedTokenException>()),
      );
    });
  });

  group('IfStatement', () {
    test(
      'should have a Literal and no parenthesis',
      () {
        final tree = Tree(
          content: 'If true\n'
              'EndIf',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenIfOutsideOfFunctionOrEvent: false,
          ),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first as IfStatement;
        expect(ifStatement.test, TypeMatcher<Literal>());
        final consequent = ifStatement.consequent as BlockStatement;
        expect(consequent.type, equals(NodeType.block));
      },
    );

    test(
      'should have a Literal and parenthesis',
      () {
        final tree = Tree(
          content: 'If (true)\n'
              'EndIf',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenIfOutsideOfFunctionOrEvent: false,
          ),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first as IfStatement;
        expect(ifStatement.test, TypeMatcher<Literal>());
        final consequent = ifStatement.consequent as BlockStatement;
        expect(consequent.type, equals(NodeType.block));
      },
    );

    test(
      'should have a LogicalExpression with a CallExpression and a Literal, and parenthesis',
      () {
        final tree = Tree(
          content: 'If (shouldStay() == true)\n'
              'EndIf',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenIfOutsideOfFunctionOrEvent: false,
          ),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first as IfStatement;
        final ifTest = ifStatement.test as LogicalExpression;
        expect(ifTest.type, equals(NodeType.binary));
        expect(ifTest.left, TypeMatcher<CallExpression>());
        expect(ifTest.right, TypeMatcher<Literal>());
        final consequent = ifStatement.consequent as BlockStatement;
        expect(consequent.type, equals(NodeType.block));
      },
    );

    test(
      'should have a LogicalExpression with two CallExpression, and parenthesis',
      () {
        final tree = Tree(
          content: 'If (shouldStay() == shouldStay())\n'
              'EndIf',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenIfOutsideOfFunctionOrEvent: false,
          ),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first as IfStatement;
        final ifTest = ifStatement.test as LogicalExpression;
        expect(ifTest.type, equals(NodeType.binary));
        expect(ifTest.left, TypeMatcher<CallExpression>());
        expect(ifTest.right, TypeMatcher<CallExpression>());
        final consequent = ifStatement.consequent as BlockStatement;
        expect(consequent.type, equals(NodeType.block));
      },
    );

    test(
      'should have a LogicalExpression with two CallExpression, one with one parameter, and parenthesis',
      () {
        final tree = Tree(
          content: 'If (shouldStay(true) == shouldStay())\n'
              'EndIf',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenIfOutsideOfFunctionOrEvent: false,
          ),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first as IfStatement;
        final ifTest = ifStatement.test as LogicalExpression;
        expect(ifTest.type, equals(NodeType.binary));
        final left = ifTest.left as CallExpression;
        expect(left.arguments, hasLength(1));
        expect(ifTest.right, TypeMatcher<CallExpression>());
        final consequent = ifStatement.consequent as BlockStatement;
        expect(consequent.type, equals(NodeType.block));
      },
    );

    test(
      'should have a LogicalExpression with two CallExpression, one with one param that is a CallExpression, and parenthesis',
      () {
        final tree = Tree(
          content: 'If (shouldStay(shouldStay()) == shouldStay())\n'
              'EndIf',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenIfOutsideOfFunctionOrEvent: false,
          ),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first as IfStatement;
        final ifTest = ifStatement.test as LogicalExpression;
        expect(ifTest.type, equals(NodeType.binary));
        final left = ifTest.left as CallExpression;
        expect(left.arguments, hasLength(1));
        expect(left.arguments[0], TypeMatcher<CallExpression>());
        expect(ifTest.right, TypeMatcher<CallExpression>());
        final consequent = ifStatement.consequent as BlockStatement;
        expect(consequent.type, equals(NodeType.block));
      },
    );

    test(
      'should have a Literal, parenthesis, and a BlockStatement with two CallExpression',
      () {
        final tree = Tree(
          content: 'If (true)\n'
              '  ShouldStay()\n'
              '  ShouldStay()\n'
              'EndIf',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenIfOutsideOfFunctionOrEvent: false,
          ),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first as IfStatement;
        expect(ifStatement.test, isNotNull);
        final consequent = ifStatement.consequent as BlockStatement;
        expect(consequent.body, hasLength(2));
      },
    );

    test(
      'should have a CastExpression that have a CallExpression and an Identifier',
      () {
        final tree = Tree(
          content: 'If t() as String\n'
              'EndIf',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenIfOutsideOfFunctionOrEvent: false,
          ),
        );

        final program = tree.parse();
        final ifStatement = program.body.first as IfStatement;
        final test = ifStatement.test as CastExpression;
        final call = test.id as CallExpression;
        final callee = call.callee as Identifier;
        expect(callee.name, equals('t'));
        final kind = test.kind as Identifier;
        expect(kind.name, equals('String'));
      },
    );

    test(
      'should have two CastExpression that have a CallExpression and an Identifier',
      () {
        final tree = Tree(
          content: 'If t() as String && a() as Int\n'
              'EndIf',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenIfOutsideOfFunctionOrEvent: false,
          ),
        );

        final program = tree.parse();
        final ifStatement = program.body.first as IfStatement;
        final test = ifStatement.test as LogicalExpression;
        expect(test.operator, equals('&&'));

        final leftTest = test.left as CastExpression;
        final call = leftTest.id as CallExpression;
        final callee = call.callee as Identifier;
        expect(callee.name, equals('t'));
        final kind = leftTest.kind as Identifier;
        expect(kind.name, equals('String'));

        final rightTest = test.right as CastExpression;
        final rightCall = rightTest.id as CallExpression;
        final rightCallee = rightCall.callee as Identifier;
        expect(rightCallee.name, equals('a'));
        final rightKind = rightTest.kind as Identifier;
        expect(rightKind.name, equals('Int'));
      },
    );

    test(
      'should have a CallExpression and an UnaryExpression',
      () {
        final tree = Tree(
          content: 'If t() == -1\n'
              'EndIf',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenIfOutsideOfFunctionOrEvent: false,
          ),
        );

        final program = tree.parse();
        final ifStatement = program.body.first as IfStatement;
        final test = ifStatement.test as LogicalExpression;
        expect(test.operator, equals('=='));
        final call = test.left as CallExpression;
        final callee = call.callee as Identifier;
        expect(callee.name, equals('t'));

        final rightTest = test.right as UnaryExpression;
        expect(rightTest.argument, TypeMatcher<Literal>());
        expect(rightTest.isPrefix, isTrue);
        expect(rightTest.operator, '-');
        final rightLiteral = rightTest.argument as Literal;
        expect(rightLiteral.value, equals(1));
      },
    );

    test(
      'should have an Else alternate statement',
      () {
        final tree = Tree(
          content: 'If true\n'
              'Else\n'
              'EndIf',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenIfOutsideOfFunctionOrEvent: false,
          ),
        );

        final ifStatement = tree.parse().body.first as IfStatement;
        final test = ifStatement.test as Literal;
        final consequent = ifStatement.consequent as BlockStatement;
        final alternate = ifStatement.alternate as BlockStatement;

        expect(test.value, equals(true));
        expect(consequent.body, isEmpty);
        expect(alternate.body, isEmpty);
      },
    );

    test(
      'should have an alternate statement with a VariableDeclaration',
      () {
        final tree = Tree(
          content: 'If true\n'
              'Else\n'
              '  String v = ""\n'
              'EndIf',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenIfOutsideOfFunctionOrEvent: false,
          ),
        );

        final ifStatement = tree.parse().body.first as IfStatement;
        final test = ifStatement.test as Literal;
        final consequent = ifStatement.consequent as BlockStatement;
        final alternate = ifStatement.alternate as BlockStatement;

        expect(test.value, equals(true));
        expect(consequent.body, isEmpty);
        expect(alternate.body.first, TypeMatcher<VariableDeclaration>());
      },
    );

    test(
      'should have an alternate statement with a ElseIf, Else statement',
      () {
        final tree = Tree(
          content: 'If true\n'
              'ElseIf false\n'
              '  String v = ""'
              'Else\n'
              'EndIf',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenIfOutsideOfFunctionOrEvent: false,
          ),
        );

        final ifStatement = tree.parse().body.first as IfStatement;
        final test = ifStatement.test as Literal;
        final elseIfStatement = ifStatement.alternate as IfStatement;
        final elseIfTest = elseIfStatement.test as Literal;
        final elseIfConsequent = elseIfStatement.consequent as BlockStatement;
        final elseIfAlternate = elseIfStatement.alternate as BlockStatement;

        expect(test.value, equals(true));
        expect(elseIfTest.value, equals(false));
        expect(elseIfConsequent.body.first, TypeMatcher<VariableDeclaration>());
        expect(elseIfAlternate.body, isEmpty);
      },
    );

    test(
      'should have multiple alternate statement ElseIf, Else',
      () {
        final tree = Tree(
          content: 'If true\n'
              'ElseIf false\n'
              '  String v = ""'
              'ElseIf false\n'
              '  String v = ""'
              'ElseIf false\n'
              '  String v = ""'
              'ElseIf false\n'
              '  String v = ""'
              'Else\n'
              'EndIf',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenIfOutsideOfFunctionOrEvent: false,
          ),
        );

        final ifStatement = tree.parse().body.first as IfStatement;
        final test = ifStatement.test as Literal;

        expect(test.value, equals(true));

        var currentIfStatement = ifStatement.alternate;
        var numberOfIfStatement = 0;

        while (currentIfStatement is IfStatement) {
          numberOfIfStatement++;
          currentIfStatement = currentIfStatement.alternate;
        }

        expect(numberOfIfStatement, equals(4));
      },
    );
  });

  group('CallExpression', () {
    test(
      'should have a Literal positional param and an optional AssignExpression param',
      () {
        final tree = Tree(
          content: 'shouldAssign(false, t = true)',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenCallExpressionOutsideOfFunctionOrEvent: false,
          ),
        );

        final program = tree.parse();
        final call = program.body.first as CallExpression;
        expect(call.arguments, hasLength(2));
        final callee = call.callee as Identifier;
        expect(callee.name, 'shouldAssign');
        final positional = call.arguments.first as Literal;
        final optional = call.arguments[1] as AssignExpression;
        expect(positional.value, isFalse);
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
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenCastExpressionOutsideOfFunctionOrEvent: false,
          ),
        );

        final program = tree.parse();
        final cast = program.body.first as CastExpression;
        final id = cast.id as Identifier;
        expect(id.name, equals('toto'));
        final kind = cast.kind as Identifier;
        expect(kind.name, equals('String'));
      },
    );

    test(
      'should have one CallExpression and one Identifier',
      () {
        final tree = Tree(
          content: 'toto() as String',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenCastExpressionOutsideOfFunctionOrEvent: false,
          ),
        );

        final program = tree.parse();
        final cast = program.body.first as CastExpression;
        final call = cast.id as CallExpression;
        final callee = call.callee as Identifier;
        expect(callee.name, equals('toto'));
        final kind = cast.kind as Identifier;
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
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();

        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable as Variable;
        final literal = variable.init as Literal;
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
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();

        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable as Variable;
        final expression = variable.init as UnaryExpression;
        expect(expression.operator, equals('-'));
        final literal = expression.argument as Literal;
        expect(literal.value, equals(1));
        expect(literal.raw, equals('1'));
      },
    );

    test(
      'float negative should be parsed',
      () {
        final tree = Tree(
          content: 'Float t = -1.0',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();

        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable as Variable;
        final expression = variable.init as UnaryExpression;
        expect(expression.operator, equals('-'));
        final literal = expression.argument as Literal;
        expect(literal.value, equals(1.0));
        expect(literal.raw, equals('1.0'));
      },
    );

    test(
      'None should be parsed',
      () {
        final tree = Tree(
          content: 'Actor t = None',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final program = tree.parse();

        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable as Variable;
        final literal = variable.init as Literal;
        expect(literal.value, equals(null));
        expect(literal.raw, equals('None'));
      },
    );
  });

  group('WhileStatement', () {
    test(
      'should have one Literal and one empty BlockStatement',
      () {
        final tree = Tree(
          content: 'While true\n'
              'EndWhile',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenWhileStatementOutsideOfFunctionOrEvent: false,
          ),
        );

        final program = tree.parse();
        final whileStatement = program.body.first as WhileStatement;
        final test = whileStatement.test as Literal;
        final consequent = whileStatement.consequent as BlockStatement;
        expect(test.value, true);
        expect(consequent.body, isEmpty);
      },
    );

    test(
      'should have one LogicalExpression with one CallExpression and UnaryExpression',
      () {
        final tree = Tree(
          content: 'While call() == -1\n'
              'EndWhile',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
            throwWhenWhileStatementOutsideOfFunctionOrEvent: false,
          ),
        );

        final program = tree.parse();
        final whileStatement = program.body.first as WhileStatement;
        final test = whileStatement.test as LogicalExpression;
        final call = test.left as CallExpression;
        final unary = test.right as UnaryExpression;
        final callee = call.callee as Identifier;
        final unaryArgument = unary.argument as Literal;
        expect(callee.name, equals('call'));
        expect(unaryArgument.value, equals(1));
        expect(unary.operator, equals('-'));
      },
    );
  });

  group('StateStatement', () {
    test(
      'should have a Auto flag and an empty BlockStatement',
      () {
        final tree = Tree(
          content: 'Auto State Test\n'
              'EndState',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final state = tree.parse().body.first as StateStatement;
        expect(state.flag, equals(StateFlag.auto));
        final id = state.id as Identifier;
        expect(id.name, equals('Test'));
        expect(state.body?.body, isEmpty);
      },
    );

    test(
      'should have a FunctionStatement in a BlockStatement',
      () {
        final tree = Tree(
          content: 'State Test\n'
              '  Int Function test()\n'
              '  EndFunction\n'
              'EndState',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final state = tree.parse().body.first as StateStatement;
        final id = state.id as Identifier;
        expect(id.name, equals('Test'));
        expect(state.body?.body, hasLength(1));
        final functionStatement = state.body?.body.first as FunctionStatement;
        expect(functionStatement.id?.name, equals('test'));
        expect(functionStatement.kind, equals('Int'));
      },
    );

    test(
      'that have a StateStatement in the BlockStatement should throws an error',
      () {
        final tree = Tree(
          content: 'State Test\n'
              '  State T\n'
              '  EndState\n'
              'EndState',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<StateStatementException>()),
        );
      },
    );
  });

  group('EventStatement', () {
    test(
      'should have Native flag',
      () {
        final tree = Tree(
          content: 'Event OnTest() Native',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final event = tree.parse().body.first as EventStatement;
        expect(event.body, isNull);
        expect(event.flags, hasLength(1));
        final flag = event.flags.first;
        expect(flag.flag, equals(EventFlag.native));
        final id = event.id as Identifier;
        expect(id.name, equals('OnTest'));
      },
    );

    test(
      'should have one parameter',
      () {
        final tree = Tree(
          content: 'Event OnTest(String n)\n'
              'EndEvent',
          options: TreeOptions(throwWhenMissingScriptname: false),
        );

        final event = tree.parse().body.first as EventStatement;
        expect(event.flags, isEmpty);
        final id = event.id as Identifier;
        expect(id.name, equals('OnTest'));
        final params = event.params;
        expect(params, hasLength(1));
        final param = event.params.first as VariableDeclaration;
        final variable = param.variable as Variable;
        expect(variable.init, isNull);
        expect(variable.kind, equals('String'));
        expect(variable.id?.name, equals('n'));
      },
    );
  });

  group('Parent MemberExpression', () {
    test('used as a function should throws an error', () {
      final tree = Tree(
        content: 'ScriptName test extends Form\n'
            '\n'
            'Function test()\n'
            '  Parent()\n'
            'EndFunction',
      );

      expect(() => tree.parse(), throwsA(TypeMatcher<ParentMemberException>()));
    });

    test('used when ScriptName does not extends should throws an error', () {
      final tree = Tree(
        content: 'ScriptName test\n'
            '\n'
            'Function test()\n'
            '  Parent.test()\n'
            'EndFunction',
      );

      expect(() => tree.parse(), throwsA(TypeMatcher<ParentMemberException>()));
    });

    test('used as a property of MemberExpression should throws an error', () {
      final tree = Tree(
        content: 'ScriptName test extends Form\n'
            '\n'
            'Function test()\n'
            '  Parent.Parent.test()\n'
            'EndFunction',
      );

      expect(() => tree.parse(), throwsA(TypeMatcher<ParentMemberException>()));
    });
  });

  group('Program', () {
    test(
      'should have a ScriptName, two FunctionStatement and one StateStatement',
      () {
        final tree = Tree(
          content: 'ScriptName Test\n'
              'Function test()\n'
              'EndFunction\n'
              '\n'
              'Function toto(String n)\n'
              '  String v = n\n'
              '  test()\n'
              'EndFunction\n'
              '\n'
              'Auto State T\n'
              '  Function test()\n'
              '  EndFunction\n'
              'EndState\n',
        );

        final program = tree.parse();

        expect(program.body, hasLength(4));
      },
    );
  });

  group('ImportStatement', () {
    test(
      'should have an identifier',
      () {
        final tree = Tree(
          content: 'Import Debug',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
          ),
        );

        final importStatement = tree.parse().body.first as ImportStatement;
        final id = importStatement.id as Identifier;
        expect(id.name, equals('Debug'));
      },
    );

    test(
      'inside a FunctionStatement should throws an error',
      () {
        final tree = Tree(
          content: 'Function test()\n'
              '  Import Debug\n'
              'EndFunction',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
          ),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<UnexpectedTokenException>()),
        );
      },
    );

    test(
      'inside a StateStatement should throws an error',
      () {
        final tree = Tree(
          content: 'State test\n'
              '  Import Debug\n'
              'EndState',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
          ),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<UnexpectedTokenException>()),
        );
      },
    );

    test(
      'inside a EventStatement should throws an error',
      () {
        final tree = Tree(
          content: 'Event test()\n'
              '  Import Debug\n'
              'EndEvent',
          options: TreeOptions(
            throwWhenMissingScriptname: false,
          ),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<UnexpectedTokenException>()),
        );
      },
    );
  });

  // TODO: review start/end of nodes
  // TODO: process line/column
  // TODO: throw when while, call, cast, if is used outside of function
  // TODO: self Expression can only be used inside CallExpression params
  // TODO: FunctionStatement cannot have a FunctionStatement inside
  // TODO: FunctionStatement cannot have a StateStatement inside
}
