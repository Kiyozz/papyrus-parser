import 'package:papyrus_parser/papyrus_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Scriptname', () {
    test('with name, extends and flags', () {
      final tree = Tree(
        content: 'Scriptname Test extends Form Hidden Conditional',
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
    });

    test('with name, no extends and one flag', () {
      final tree = Tree(
        content: 'Scriptname Test Hidden',
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
    });

    test('with missing scriptname', () {
      final tree = Tree(content: 'function toto()');

      expect(() => tree.parse(), throwsA(TypeMatcher<ScriptnameException>()));
    });
  });

  group('Function', () {
    test('have name and no arguments', () {
      final tree = Tree(
        content: 'Scriptname Test\nFunction toto()\nEndFunction',
      );

      final program = tree.parse();

      expect(program.body, hasLength(2));

      final secondNode = program.body[1];

      expect(secondNode, TypeMatcher<FunctionStatement>());

      final functionBody = secondNode as FunctionStatement;

      expect(functionBody.id?.name, equals('toto'));
      expect(functionBody.body, hasLength(1));
      expect(functionBody.type, equals(NodeType.functionKw));

      final functionBlock = functionBody.body[0];

      expect(functionBlock, TypeMatcher<BlockStatement>());

      final block = functionBlock as BlockStatement;

      expect(block.type, equals(NodeType.block));
    });

    test('have name, one argument', () {
      final tree = Tree(
        content: 'Scriptname Test\nFunction toto(String n)\nEndFunction',
      );

      final program = tree.parse();

      expect(program.body, hasLength(2));

      final body = program.body[1];

      expect(body, TypeMatcher<FunctionStatement>());

      final functionBody = body as FunctionStatement;

      expect(functionBody.id?.name, equals('toto'));
      expect(functionBody.body, hasLength(1));
      expect(functionBody.type, equals(NodeType.functionKw));
      expect(functionBody.params, hasLength(1));
    });
  });

  group('Variable', () {
    test('simple variable string', () {
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
    });

    test('simple variable string with init literal', () {
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
    });

    test('simple variable string with init logical call and literal', () {
      final tree = Tree(
        content: 'bool val = shouldStay() == false',
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

      expect(init, TypeMatcher<Logical>());

      init as Logical;

      expect(init.left, TypeMatcher<CallExpression>());
      expect(init.operator, '==');
      expect(init.right, TypeMatcher<Literal>());
      expect(variable.kind, equals('bool'));
      expect(variable.id, isNotNull);

      final name = variable.id as Identifier;

      expect(name.name, equals('val'));
    });
  });

  group('Property', () {
    test('auto property without default value', () {
      final tree = Tree(
        content: 'int property test auto',
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
      expect(property.kind, 'int');
      expect(property.init, isNull);
    });

    test('auto hidden property with default value', () {
      final tree = Tree(
        content: 'int property test = 1 auto hidden',
        throwWhenMissingScriptname: false,
      );

      final program = tree.parse();

      expect(program.body, hasLength(1));

      final property = program.body.first;

      expect(property, TypeMatcher<PropertyDeclaration>());

      property as PropertyDeclaration;

      expect(property.flags, hasLength(2));
      expect(property.flags.first.flag, equals(PropertyFlag.auto));
      expect(property.flags[1].flag, equals(PropertyFlag.hidden));

      final id = property.id;

      expect(id, TypeMatcher<Identifier>());

      id as Identifier;

      expect(id.name, equals('test'));
      expect(property.kind, 'int');
      expect(property.init, isNotNull);

      final init = property.init;

      expect(init, TypeMatcher<Literal>());

      init as Literal;

      expect(init.value, 1);
    });

    test('setter, getter property with default value', () {
      final tree = Tree(
        content: 'int property test = 1\n'
            '  Function set(int value)\n'
            '  EndFunction\n'
            '  Function get()\n'
            '  EndFunction\n'
            'EndProperty',
        throwWhenMissingScriptname: false,
      );

      final program = tree.parse();

      expect(program.body, hasLength(1));

      final property = program.body.first;

      expect(property, TypeMatcher<PropertyDeclaration>());

      property as PropertyDeclaration;

      expect(property.flags, hasLength(2));
      expect(property.flags.first.flag, equals(PropertyFlag.auto));
      expect(property.flags[1].flag, equals(PropertyFlag.hidden));

      final id = property.id;

      expect(id, TypeMatcher<Identifier>());

      id as Identifier;

      expect(id.name, equals('test'));
      expect(property.kind, 'int');
      expect(property.init, isNotNull);

      final init = property.init;

      expect(init, TypeMatcher<Literal>());

      init as Literal;

      expect(init.value, 1);
    });
  });

  group('Return', () {
    test('function returns literal', () {
      final tree = Tree(
        content: 'Function test()\n'
            '  Return true\n'
            'EndFunction',
        throwWhenMissingScriptname: false,
      );

      final program = tree.parse();
      expect(program.body, hasLength(1));
      final functionStatements = (program.body.first as FunctionStatement).body;
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
    });

    test('function returns nothing', () {
      final tree = Tree(
        content: 'Function test()\n'
            '  Return\n'
            'EndFunction',
        throwWhenMissingScriptname: false,
      );

      final program = tree.parse();
      expect(program.body, hasLength(1));
      final functionStatements = (program.body.first as FunctionStatement).body;
      expect(functionStatements, hasLength(1));
      expect(functionStatements.first, TypeMatcher<BlockStatement>());
      final block = functionStatements.first as BlockStatement;
      expect(block.body, hasLength(1));
      final returnStatement = block.body.first;
      expect(returnStatement, TypeMatcher<ReturnStatement>());
      returnStatement as ReturnStatement;
      expect(returnStatement.argument, isNull);
    });

    test('function returns call', () {
      final tree = Tree(
        content: 'Function test()\n'
            '  Return shouldStay()\n'
            'EndFunction',
        throwWhenMissingScriptname: false,
      );

      final program = tree.parse();
      expect(program.body, hasLength(1));
      final functionStatements = (program.body.first as FunctionStatement).body;
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
    });

    test('function returns call and call', () {
      final tree = Tree(
        content: 'Function test()\n'
            '  Return (shouldStay() && shouldStay())\n'
            'EndFunction',
        throwWhenMissingScriptname: false,
      );

      final program = tree.parse();
      expect(program.body, hasLength(1));
      final functionStatements = (program.body.first as FunctionStatement).body;
      expect(functionStatements, hasLength(1));
      expect(functionStatements.first, TypeMatcher<BlockStatement>());
      final block = functionStatements.first as BlockStatement;
      expect(block.body, hasLength(1));
      final returnStatement = block.body.first;
      expect(returnStatement, TypeMatcher<ReturnStatement>());
      returnStatement as ReturnStatement;
      expect(returnStatement.argument, TypeMatcher<Logical>());
      final argument = returnStatement.argument as Logical;
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
    });
  });

  group('If', () {
    test('If with literal and no parens', () {
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
    });

    test('If with literal and have parens', () {
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
    });

    test('If with call and literal, with have parens', () {
      final tree = Tree(
        content: 'If (shouldStay() == true)\nEndIf',
        throwWhenMissingScriptname: false,
      );

      final program = tree.parse();

      expect(program.body, hasLength(1));

      final ifStatement = program.body.first;

      expect(ifStatement, TypeMatcher<IfStatement>());

      ifStatement as IfStatement;

      expect(ifStatement.test, isNotNull);

      final ifTest = ifStatement.test as Node;

      expect(ifTest, TypeMatcher<Logical>());

      ifTest as Logical;

      expect(ifTest.type, equals(NodeType.binary));
      expect(ifTest.left, TypeMatcher<CallExpression>());
      expect(ifTest.right, TypeMatcher<Literal>());
      expect(ifStatement.consequent, isNotNull);

      final consequent = ifStatement.consequent as Node;

      expect(consequent.type, equals(NodeType.block));
    });

    test('If with call and call, with parens', () {
      final tree = Tree(
        content: 'If (shouldStay() == shouldStay())\nEndIf',
        throwWhenMissingScriptname: false,
      );

      final program = tree.parse();

      expect(program.body, hasLength(1));

      final ifStatement = program.body.first;

      expect(ifStatement, TypeMatcher<IfStatement>());

      ifStatement as IfStatement;

      expect(ifStatement.test, isNotNull);

      final ifTest = ifStatement.test as Node;

      expect(ifTest, TypeMatcher<Logical>());

      ifTest as Logical;

      expect(ifTest.type, equals(NodeType.binary));
      expect(ifTest.left, TypeMatcher<CallExpression>());
      expect(ifTest.right, TypeMatcher<CallExpression>());
      expect(ifStatement.consequent, isNotNull);

      final consequent = ifStatement.consequent as Node;

      expect(consequent.type, equals(NodeType.block));
    });

    test('If with call params and call no params, with parens', () {
      final tree = Tree(
        content: 'If (shouldStay(true) == shouldStay())\nEndIf',
        throwWhenMissingScriptname: false,
      );

      final program = tree.parse();

      expect(program.body, hasLength(1));

      final ifStatement = program.body.first;

      expect(ifStatement, TypeMatcher<IfStatement>());

      ifStatement as IfStatement;

      expect(ifStatement.test, isNotNull);

      final ifTest = ifStatement.test as Node;

      expect(ifTest, TypeMatcher<Logical>());

      ifTest as Logical;

      expect(ifTest.type, equals(NodeType.binary));
      expect(ifTest.left, TypeMatcher<CallExpression>());
      expect((ifTest.left as CallExpression).arguments, hasLength(1));
      expect(ifTest.right, TypeMatcher<CallExpression>());
      expect(ifStatement.consequent, isNotNull);

      final consequent = ifStatement.consequent as Node;

      expect(consequent.type, equals(NodeType.block));
    });

    test(
      'If with call params that is call, and call no params, with parens',
      () {
        final tree = Tree(
          content: 'If (shouldStay(shouldStay()) == shouldStay())\nEndIf',
          throwWhenMissingScriptname: false,
        );

        final program = tree.parse();

        expect(program.body, hasLength(1));

        final ifStatement = program.body.first;

        expect(ifStatement, TypeMatcher<IfStatement>());

        ifStatement as IfStatement;

        expect(ifStatement.test, isNotNull);

        final ifTest = ifStatement.test as Node;

        expect(ifTest, TypeMatcher<Logical>());

        ifTest as Logical;

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
      'If with literal, no parens, and calls in block',
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
  });
}
