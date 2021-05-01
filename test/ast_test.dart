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

      ScriptName scriptName = program.body.first;

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

      ScriptName scriptName = program.body.first;

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

      FunctionStatement? functionBody = program.body[1];

      expect(functionBody?.id?.name, equals('toto'));
      expect(functionBody?.body, hasLength(1));
      expect(functionBody?.type, equals(NodeType.functionKw));

      final functionBlock = functionBody?.body[0];

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
}
