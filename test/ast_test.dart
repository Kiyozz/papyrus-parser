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
        final scriptName = program.body.first as ScriptName;
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
        final scriptName = program.body.first as ScriptName;
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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

    test(
      'should have VariableDeclaration with init declaration in first parameter',
      () {
        final tree = Tree(
          content: 'Function toto(String n = "") global\n'
              'EndFunction',
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          content: 'If (true)\nEndIf',
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          content: 'If (shouldStay(shouldStay()) == shouldStay())'
              'EndIf',
          throwWhenMissingScriptname: false,
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
          content: 'If (true)'
              '  ShouldStay()\n'
              '  ShouldStay()\n'
              'EndIf',
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
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
          throwWhenMissingScriptname: false,
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<StateStatementException>()),
        );
      },
    );
  });

  // TODO: EventStatement
}
