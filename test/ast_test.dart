import 'package:papyrus_parser/papyrus_parser.dart';
import 'package:papyrus_parser/src/ast/node.dart';
import 'package:papyrus_parser/src/ast/types.dart';
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

  group('Property', () {
    test('auto property without default value', () {
      final tree = Tree(
        content: 'Scriptname Test\nint property test auto',
      );

      final program = tree.parse();

      expect(program.body, hasLength(2));
    });

    test('auto property with default value', () {
      final tree = Tree(
        content: 'Scriptname Test\nint property test = 1 auto',
      );

      final program = tree.parse();

      expect(program.body, hasLength(2));
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
          content: 'If (true)\nShouldStay()\nShouldStay()\nEndIf',
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
