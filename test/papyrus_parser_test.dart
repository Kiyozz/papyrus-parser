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
          extendsDeclaration.extended.name,
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
            throwScriptnameMismatch: false,
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
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final functionBody = program.body.first as FunctionStatement;
        expect(functionBody.id.name, equals('toto'));
        expect(functionBody.body, isNotNull);
        expect(functionBody.type, equals(NodeType.functionKw));
        expect(functionBody.body?.type, equals(NodeType.block));
      },
    );

    test(
      'should have a name and one argument without an init declaration',
      () {
        final tree = Tree(
          content: 'Function toto(String n)\nEndFunction',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final body = program.body.first as FunctionStatement;
        expect(body.id.name, equals('toto'));
        expect(body.body, isNotNull);
        expect(body.type, equals(NodeType.functionKw));
        expect(body.params, hasLength(1));
        final param = body.params.first as VariableDeclaration;
        final variable = param.variable;
        expect(variable.kind, 'String');
        expect(variable.init, isNull);
        expect(variable.id.name, 'n');
      },
    );

    test(
      'should have a Array VariableDeclaration',
      () {
        final tree = Tree(
          content: 'Function toto(String[] n)\nEndFunction',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final functionBody = tree.parse().body.first as FunctionStatement;
        expect(functionBody.id.name, equals('toto'));
        expect(functionBody.body, isNotNull);
        expect(functionBody.type, equals(NodeType.functionKw));
        expect(functionBody.params, hasLength(1));
        final param = functionBody.params.first as VariableDeclaration;
        final variable = param.variable;
        expect(variable.kind, 'String[]');
        expect(variable.init, isNull);
        expect(variable.id.name, 'n');
      },
    );

    test(
      'should have a name, two arguments, one with an init declaration',
      () {
        final tree = Tree(
          content: 'Function toto(String v, String n = "")\nEndFunction',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final body = program.body.first as FunctionStatement;
        final param = body.params[1] as VariableDeclaration;
        final variable = param.variable;
        expect(variable.kind, equals('String'));
        expect(variable.id.name, equals('n'));
        final init = variable.init as Literal;
        expect(init.value, equals(''));
      },
    );

    test(
      'without EndFunction should throws an error',
      () {
        final tree = Tree(
          content: 'Function toto(String n = "")\n',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<BlockStatementException>()),
        );
      },
    );

    test(
      'with parenthesis before the identifier should throws an error',
      () {
        final tree = Tree(
          content: 'Function (toto)(String n = "")\n'
              'EndFunction',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<UnexpectedTokenException>()),
        );
      },
    );

    test(
      'without parenthesis should throws an error',
      () {
        final tree = Tree(
          content: 'Function toto\n'
              'EndFunction',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<UnexpectedTokenException>()),
        );
      },
    );

    test(
      'should have Global and Native flags',
      () {
        final tree = Tree(
          content: 'Function toto() Global Native',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();
        final function = program.body.first as FunctionStatement;
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
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();
        final function = program.body.first as FunctionStatement;
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
          options: TreeOptions(throwScriptnameMissing: false),
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
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final statement = tree.parse().body.first as FunctionStatement;
        final variableDeclaration =
            statement.params.first as VariableDeclaration;
        final variable = variableDeclaration.variable;
        expect(variable.init, TypeMatcher<Literal>());
      },
    );

    test(
      'should have an MemberExpression',
      () {
        final tree = Tree(
          content: 'Function test()\n'
              '  Debug.Trace("[")\n'
              'EndFunction',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final statement = tree.parse().body.first as FunctionStatement;
        final expression = statement.body?.body.first as ExpressionStatement;
        final call = expression.expression as CallExpression;
        final member = call.callee as MemberExpression;
        final object = member.object as Identifier;
        final property = member.property as Identifier;

        expect(object.name, equals('Debug'));
        expect(property.name, equals('Trace'));
        expect(call.arguments, isNotEmpty);
      },
    );

    test(
      'with an Function statement should throws an error',
      () {
        final tree = Tree(
          content: 'Function test()\n'
              '  Function toto()\n'
              '  EndFunction'
              'EndFunction',
          options: TreeOptions(
            throwScriptnameMissing: false,
          ),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<UnexpectedTokenException>()),
        );
      },
    );

    test(
      'with an Event statement should throws an error',
      () {
        final tree = Tree(
          content: 'Function test()\n'
              '  Event toto()\n'
              '  EndEvent'
              'EndFunction',
          options: TreeOptions(
            throwScriptnameMissing: false,
          ),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<UnexpectedTokenException>()),
        );
      },
    );

    test(
      'with an State statement should throws an error',
      () {
        final tree = Tree(
          content: 'Function test()\n'
              '  State A\n'
              '    Event toto()\n'
              '    EndEvent'
              '  EndState'
              'EndFunction',
          options: TreeOptions(
            throwScriptnameMissing: false,
          ),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<UnexpectedTokenException>()),
        );
      },
    );
  });

  group('VariableDeclaration', () {
    test(
      'should not have an init declaration, kind "String"',
      () {
        final tree = Tree(
          content: 'String val',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable;
        expect(variable.init, isNull);
        expect(variable.kind, equals('String'));
        expect(variable.id.name, equals('val'));
      },
    );

    test(
      'should not have an init declaration, kind "String[]", isArray',
      () {
        final tree = Tree(
          content: 'String[] val',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();
        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable;
        expect(variable.init, isNull);
        expect(variable.kind, equals('String[]'));
        expect(variable.isArray, isTrue);
        expect(variable.id.name, equals('val'));
      },
    );

    test(
      'should have an init Literal declaration',
      () {
        final tree = Tree(
          content: 'String val = ""',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable;
        final init = variable.init as Literal;
        expect(init.value, '');
        expect(variable.kind, equals('String'));
        expect(variable.id.name, equals('val'));
      },
    );

    test(
      'should have an init BinaryExpression declaration',
      () {
        final tree = Tree(
          content: 'Bool val = ShouldStay() == false',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwBinaryOutside: false,
            throwCallOutside: false,
          ),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable;
        final init = variable.init as BinaryExpression;
        expect(init.left, TypeMatcher<CallExpression>());
        expect(init.operator, '==');
        expect(init.right, TypeMatcher<Literal>());
        expect(variable.kind, equals('Bool'));
        expect(variable.id.name, equals('val'));
      },
    );

    test(
      'should have a CastExpression that have one CallExpression and one Identifier',
      () {
        final tree = Tree(
          content: 'String t = toto() as String',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwCastOutside: false,
            throwCallOutside: false,
          ),
        );

        final program = tree.parse();
        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable;
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
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final variableDeclaration =
            tree.parse().body.first as VariableDeclaration;
        final variable = variableDeclaration.variable;
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
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final property = program.body.first as PropertyDeclaration;
        expect(property.flags, hasLength(1));
        expect(property.id.name, equals('test'));
        expect(property.kind, 'Int');
        expect(property.init, isNull);
      },
    );

    test(
      'should have a type, a name, an constant init declaration and AutoReadOnly flag',
      () {
        final tree = Tree(
          content: 'Int Property test = 1 AutoReadOnly',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final property = program.body.first as PropertyDeclaration;
        expect(property.flags, hasLength(1));
        expect(property.flags.first.flag, equals(PropertyFlag.autoReadonly));
        expect(property.id.name, equals('test'));
        expect(property.kind, 'Int');
        final init = property.init as Literal;
        expect(init.value, 1);
      },
    );

    test(
      'Full should have a type, a name, a setter, and a getter',
      () {
        final tree = Tree(
          content: 'Int Property test = 1 Hidden\n'
              '  Int Function Get()\n'
              '  EndFunction\n'
              '  Function Set(Int value)\n'
              '  EndFunction\n'
              'EndProperty',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final property = program.body.first as PropertyFullDeclaration;
        expect(property.flags, hasLength(1));
        expect(property.flags.first.flag, equals(PropertyFlag.hidden));
        expect(property.id.name, equals('test'));
        expect(property.kind, 'Int');
        final init = property.init as Literal;
        expect(init.value, 1);
        expect(init.raw, '1');
      },
    );

    test(
      'Full without Hidden flag should throws an error',
      () {
        final tree = Tree(
          content: 'Int Property test = 1\n'
              '  int Function Get()\n'
              '    Return 2\n'
              '  Function\n'
              'EndProperty',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        expect(() => tree.parse(), throwsA(TypeMatcher<PropertyException>()));
      },
    );

    test(
      'Full without getter and setter should throws an error',
      () {
        final tree = Tree(
          content: 'Int Property test = 1 Hidden\n'
              'EndProperty',
          options: TreeOptions(throwScriptnameMissing: false),
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
          options: TreeOptions(throwScriptnameMissing: false),
        );

        expect(() => tree.parse(), throwsA(TypeMatcher<PropertyException>()));
      },
    );

    test(
      'AutoReadOnly without an init declaration should throws an error',
      () {
        final tree = Tree(
          content: 'Int Property test AutoReadOnly\n',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        expect(() => tree.parse(), throwsA(TypeMatcher<PropertyException>()));
      },
    );

    test(
      'Conditional without an Auto or AutoReadOnly flag should throws an error',
      () {
        final tree = Tree(
          content: 'Int Property test Conditional\n',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        expect(() => tree.parse(), throwsA(TypeMatcher<PropertyException>()));
      },
    );

    test(
      'Auto Conditional without an init declaration should throws an error',
      () {
        final tree = Tree(
          content: 'Int Property test Auto Conditional\n',
          options: TreeOptions(throwScriptnameMissing: false),
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

    test(
      'used inside a Function/Event Statement should throws an error',
      () {
        final tree = Tree(
          content: 'Function test()\n'
              '  Int Property test Auto\n'
              'EndFunction',
          options: TreeOptions(
            throwScriptnameMissing: false,
          ),
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
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final block =
            (program.body.first as FunctionStatement).body as BlockStatement;
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
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final block =
            (program.body.first as FunctionStatement).body as BlockStatement;
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
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final block =
            (program.body.first as FunctionStatement).body as BlockStatement;
        expect(block.body, hasLength(1));
        final returnStatement = block.body.first as ReturnStatement;
        final argument = returnStatement.argument as CallExpression;
        final callee = argument.callee as Identifier;
        expect(callee.name, equals('shouldStay'));
      },
    );

    test(
      'argument should be a BinaryExpression with two CallExpression',
      () {
        final tree = Tree(
          content: 'Function test()\n'
              '  Return (shouldStay() && shouldStay())\n'
              'EndFunction',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final block =
            (program.body.first as FunctionStatement).body as BlockStatement;
        expect(block.body, hasLength(1));
        final returnStatement = block.body.first as ReturnStatement;
        final argument = returnStatement.argument as BinaryExpression;
        final left = argument.left as CallExpression;
        final right = argument.right as CallExpression;
        final lCallee = left.callee as Identifier;
        expect(lCallee.name, equals('shouldStay'));
        final rCallee = right.callee as Identifier;
        expect(rCallee.name, equals('shouldStay'));
      },
    );

    test(
      'argument should have two BinaryExpression, "*", ">=", and MemberExpression',
      () {
        final tree = Tree(
          content: 'Return (currentTime - lastTime) * 24 >= dt.  test',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwReturnOutside: false,
            throwBinaryOutside: false,
          ),
        );

        final program = tree.parse();
        final returnStatement = program.body.first as ReturnStatement;
        final argument = returnStatement.argument as BinaryExpression;
        expect(argument.operator, equals('*'));
        expect(argument.type, equals(NodeType.binary));
        final left = argument.left as BinaryExpression;
        expect(left.operator, equals('-'));
        expect((left.left as Identifier).name, equals('currentTime'));
        expect((left.right as Identifier).name, equals('lastTime'));
        final right = argument.right as BinaryExpression;
        expect(right.operator, equals('>='));
        expect((right.left as Literal).value, 24);
        final member = right.right as MemberExpression;
        expect((member.object as Identifier).name, equals('dt'));
        expect((member.property as Identifier).name, equals('test'));
      },
    );

    test('used outside of FunctionStatement should throws an error', () {
      final tree = Tree(
        content: 'Return true',
        options: TreeOptions(
          throwScriptnameMissing: false,
        ),
      );

      expect(
        () => tree.parse(),
        throwsA(TypeMatcher<UnexpectedTokenException>()),
      );
    });

    test('used inside of EventStatement should throws an error', () {
      final tree = Tree(
        content: 'Event t()\n'
            '  Return true\n'
            'EndEvent',
        options: TreeOptions(
          throwScriptnameMissing: false,
        ),
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
            throwScriptnameMissing: false,
            throwIfOutside: false,
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
            throwScriptnameMissing: false,
            throwIfOutside: false,
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
      'should have a UnaryExpression Literal and parenthesis',
      () {
        final tree = Tree(
          content: 'If (!((((((true)))))))\n'
              'EndIf',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwIfOutside: false,
            throwBinaryOutside: false,
          ),
        );

        final ifStatement = tree.parse().body.first as IfStatement;
        final test = ifStatement.test as UnaryExpression;
        expect(test.argument, TypeMatcher<Literal>());
        expect(test.operator, equals('!'));
      },
    );

    test(
      'should have a BinaryExpression with a CallExpression and a Literal, and parenthesis',
      () {
        final tree = Tree(
          content: 'If (shouldStay() == true)\n'
              'EndIf',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwIfOutside: false,
            throwBinaryOutside: false,
            throwCallOutside: false,
          ),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first as IfStatement;
        final ifTest = ifStatement.test as BinaryExpression;
        expect(ifTest.type, equals(NodeType.binary));
        expect(ifTest.left, TypeMatcher<CallExpression>());
        expect(ifTest.right, TypeMatcher<Literal>());
        final consequent = ifStatement.consequent as BlockStatement;
        expect(consequent.type, equals(NodeType.block));
      },
    );

    test(
      'should have a BinaryExpression with two CallExpression, and parenthesis',
      () {
        final tree = Tree(
          content: 'If (shouldStay() == shouldStay())\n'
              'EndIf',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwIfOutside: false,
            throwCallOutside: false,
            throwBinaryOutside: false,
          ),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first as IfStatement;
        final ifTest = ifStatement.test as BinaryExpression;
        expect(ifTest.type, equals(NodeType.binary));
        expect(ifTest.left, TypeMatcher<CallExpression>());
        expect(ifTest.right, TypeMatcher<CallExpression>());
        final consequent = ifStatement.consequent as BlockStatement;
        expect(consequent.type, equals(NodeType.block));
      },
    );

    test(
      'should have a BinaryExpression with two CallExpression, one with one parameter, and parenthesis',
      () {
        final tree = Tree(
          content: 'If (shouldStay(true) == shouldStay())\n'
              'EndIf',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwIfOutside: false,
            throwCallOutside: false,
            throwBinaryOutside: false,
          ),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first as IfStatement;
        final ifTest = ifStatement.test as BinaryExpression;
        expect(ifTest.type, equals(NodeType.binary));
        final left = ifTest.left as CallExpression;
        expect(left.arguments, hasLength(1));
        expect(ifTest.right, TypeMatcher<CallExpression>());
        final consequent = ifStatement.consequent as BlockStatement;
        expect(consequent.type, equals(NodeType.block));
      },
    );

    test(
      'should have a BinaryExpression with two CallExpression, one with one param that is a CallExpression, and parenthesis',
      () {
        final tree = Tree(
          content: 'If (shouldStay(shouldStay()) == shouldStay())\n'
              'EndIf',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwIfOutside: false,
            throwBinaryOutside: false,
            throwCallOutside: false,
            throwCastOutside: false,
          ),
        );

        final program = tree.parse();
        expect(program.body, hasLength(1));
        final ifStatement = program.body.first as IfStatement;
        final ifTest = ifStatement.test as BinaryExpression;
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
      'should have two BinaryExpression, one ">=" and one "*" and parenthesis',
      () {
        final tree = Tree(
          content: 'If (currentTime - lastTime) * 24 >= dt.test\n'
              'EndIf',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwIfOutside: false,
            throwBinaryOutside: false,
          ),
        );

        final program = tree.parse();
        final ifStatement = program.body.first as IfStatement;
        final ifTest = ifStatement.test as BinaryExpression;
        expect(ifTest.operator, equals('*'));
        expect(ifTest.type, equals(NodeType.binary));
        final left = ifTest.left as BinaryExpression;
        expect(left.operator, equals('-'));
        expect((left.left as Identifier).name, equals('currentTime'));
        expect((left.right as Identifier).name, equals('lastTime'));
        final right = ifTest.right as BinaryExpression;
        expect(right.operator, equals('>='));
        expect((right.left as Literal).value, 24);
        final member = right.right as MemberExpression;
        expect((member.object as Identifier).name, equals('dt'));
        expect((member.property as Identifier).name, equals('test'));
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
            throwScriptnameMissing: false,
            throwIfOutside: false,
            throwBinaryOutside: false,
            throwCallOutside: false,
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
            throwScriptnameMissing: false,
            throwIfOutside: false,
            throwCastOutside: false,
            throwCallOutside: false,
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
            throwScriptnameMissing: false,
            throwIfOutside: false,
            throwBinaryOutside: false,
            throwCallOutside: false,
            throwCastOutside: false,
          ),
        );

        final program = tree.parse();
        final ifStatement = program.body.first as IfStatement;
        final test = ifStatement.test as BinaryExpression;
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
            throwScriptnameMissing: false,
            throwIfOutside: false,
            throwBinaryOutside: false,
            throwCallOutside: false,
          ),
        );

        final program = tree.parse();
        final ifStatement = program.body.first as IfStatement;
        final test = ifStatement.test as BinaryExpression;
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
            throwScriptnameMissing: false,
            throwIfOutside: false,
          ),
        );

        final ifStatement = tree.parse().body.first as IfStatement;
        final test = ifStatement.test as Literal;
        final consequent = ifStatement.consequent as BlockStatement;
        final alternate = ifStatement.alternate as BlockStatement;

        expect(test.value, isTrue);
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
            throwScriptnameMissing: false,
            throwIfOutside: false,
          ),
        );

        final ifStatement = tree.parse().body.first as IfStatement;
        final test = ifStatement.test as Literal;
        final consequent = ifStatement.consequent as BlockStatement;
        final alternate = ifStatement.alternate as BlockStatement;

        expect(test.value, isTrue);
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
            throwScriptnameMissing: false,
            throwIfOutside: false,
          ),
        );

        final ifStatement = tree.parse().body.first as IfStatement;
        final test = ifStatement.test as Literal;
        final elseIfStatement = ifStatement.alternate as IfStatement;
        final elseIfTest = elseIfStatement.test as Literal;
        final elseIfConsequent = elseIfStatement.consequent as BlockStatement;
        final elseIfAlternate = elseIfStatement.alternate as BlockStatement;

        expect(test.value, isTrue);
        expect(elseIfTest.value, isFalse);
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
            throwScriptnameMissing: false,
            throwIfOutside: false,
          ),
        );

        final ifStatement = tree.parse().body.first as IfStatement;
        final test = ifStatement.test as Literal;

        expect(test.value, isTrue);

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
            throwScriptnameMissing: false,
            throwCallOutside: false,
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
            throwScriptnameMissing: false,
            throwCastOutside: false,
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
      'should have multiple BinaryExpression',
      () {
        final tree = Tree(
          content: 'Float t = (chance * (1 - health / 100)) as Float',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwCastOutside: false,
            throwBinaryOutside: false,
          ),
        );

        final program = tree.parse();
        final variable = (program.body.first as VariableDeclaration).variable;
        final cast = variable.init as CastExpression;
        final firstBinary = cast.id as BinaryExpression;
        expect(firstBinary.operator, equals('*'));
        expect((firstBinary.left as Identifier).name, equals('chance'));
        final rightFirstBinary = firstBinary.right as BinaryExpression;
        final literalOne = rightFirstBinary.left as Literal;
        expect(literalOne.value, equals(1));
        expect(rightFirstBinary.operator, equals('-'));
        final binary = rightFirstBinary.right as BinaryExpression;
        expect((binary.left as Identifier).name, equals('health'));
        expect((binary.right as Literal).value, equals(100));
        expect((cast.kind as Identifier).name, equals('Float'));
      },
    );

    test(
      'should have one CallExpression and one Identifier',
      () {
        final tree = Tree(
          content: 'toto() as String',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwCastOutside: false,
            throwCallOutside: false,
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
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();

        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable;
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
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();

        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable;
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
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();

        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable;
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
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final program = tree.parse();

        final variableDeclaration = program.body.first as VariableDeclaration;
        final variable = variableDeclaration.variable;
        final literal = variable.init as Literal;
        expect(literal.value, isNull);
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
            throwScriptnameMissing: false,
            throwWhileOutside: false,
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
      'should have one BinaryExpression with one CallExpression and UnaryExpression',
      () {
        final tree = Tree(
          content: 'While call() == -1\n'
              'EndWhile',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwWhileOutside: false,
            throwCallOutside: false,
            throwBinaryOutside: false,
          ),
        );

        final program = tree.parse();
        final whileStatement = program.body.first as WhileStatement;
        final test = whileStatement.test as BinaryExpression;
        final call = test.left as CallExpression;
        final unary = test.right as UnaryExpression;
        final callee = call.callee as Identifier;
        final unaryArgument = unary.argument as Literal;
        expect(callee.name, equals('call'));
        expect(unaryArgument.value, equals(1));
        expect(unary.operator, equals('-'));
      },
    );

    test(
      'should not report missing EndWhile'
      ' when a LineComment is at the end of the line',
      () {
        final tree = Tree(
          content: 'While (true);\n'
              'EndWhile\n',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwWhileOutside: false,
          ),
        );

        expect(() => tree.parse(), isNot(throwsA(NodeException)));
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
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final state = tree.parse().body.first as StateStatement;
        expect(state.flag, equals(StateFlag.auto));
        expect(state.id.name, equals('Test'));
        expect(state.body.body, isEmpty);
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
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final state = tree.parse().body.first as StateStatement;
        expect(state.id.name, equals('Test'));
        expect(state.body.body, hasLength(1));
        final functionStatement = state.body.body.first as FunctionStatement;
        expect(functionStatement.id.name, equals('test'));
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
          options: TreeOptions(throwScriptnameMissing: false),
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
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final event = tree.parse().body.first as EventStatement;
        expect(event.body, isNull);
        expect(event.flags, hasLength(1));
        final flag = event.flags.first;
        expect(flag.flag, equals(EventFlag.native));
        expect(event.id.name, equals('OnTest'));
      },
    );

    test(
      'should have one parameter',
      () {
        final tree = Tree(
          content: 'Event OnTest(String n)\n'
              'EndEvent',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        final event = tree.parse().body.first as EventStatement;
        expect(event.flags, isEmpty);
        expect(event.id.name, equals('OnTest'));
        final params = event.params;
        expect(params, hasLength(1));
        final param = event.params.first as VariableDeclaration;
        final variable = param.variable;
        expect(variable.init, isNull);
        expect(variable.kind, equals('String'));
        expect(variable.id.name, equals('n'));
      },
    );

    test(
      'with an State statement should throws an error',
      () {
        final tree = Tree(
          content: 'Event toto()\n'
              '  State A\n'
              '  EndState\n'
              'EndEvent',
          options: TreeOptions(
            throwScriptnameMissing: false,
          ),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<UnexpectedTokenException>()),
        );
      },
    );

    test(
      'with parenthesis before the identifier should throws an error',
      () {
        final tree = Tree(
          content: 'Event (toto)(String n)\n'
              'EndEvent',
          options: TreeOptions(throwScriptnameMissing: false),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<UnexpectedTokenException>()),
        );
      },
    );

    test(
      'with an Function statement should throws an error',
      () {
        final tree = Tree(
          content: 'Event toto()\n'
              '  Function A()\n'
              '  EndFunction\n'
              'EndEvent',
          options: TreeOptions(
            throwScriptnameMissing: false,
          ),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<UnexpectedTokenException>()),
        );
      },
    );

    test(
      'without parenthesis should throws an error',
      () {
        final tree = Tree(
          content: 'Event toto\n'
              'EndEvent',
          options: TreeOptions(
            throwScriptnameMissing: false,
          ),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<UnexpectedTokenException>()),
        );
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
            throwScriptnameMissing: false,
          ),
        );

        final importStatement = tree.parse().body.first as ImportStatement;
        expect(importStatement.id.name, equals('Debug'));
      },
    );

    test(
      'with parenthesis should throws an error',
      () {
        final tree = Tree(
          content: 'Import (Debug)',
          options: TreeOptions(
            throwScriptnameMissing: false,
          ),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<UnexpectedTokenException>()),
        );
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
            throwScriptnameMissing: false,
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
            throwScriptnameMissing: false,
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
            throwScriptnameMissing: false,
          ),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<UnexpectedTokenException>()),
        );
      },
    );
  });

  group('BinaryExpression', () {
    test(
      'should have plus operator, one Literal and Identifier',
      () {
        final tree = Tree(
          content: '1 + serviceName',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwBinaryOutside: false,
          ),
        );

        final expression = tree.parse().body.first as ExpressionStatement;
        final binary = expression.expression as BinaryExpression;
        final left = binary.left as Literal;
        final right = binary.right as Identifier;
        expect(binary.operator, equals('+'));
        expect(left.value, equals(1));
        expect(right.name, equals('serviceName'));
      },
    );

    test(
      'should have greater than or equals, one Literal and Identifier',
      () {
        final tree = Tree(
          content: '1 >= serviceName',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwBinaryOutside: false,
          ),
        );

        final expression = tree.parse().body.first as ExpressionStatement;
        final binary = expression.expression as BinaryExpression;
        final left = binary.left as Literal;
        final right = binary.right as Identifier;
        expect(binary.operator, '>=');
        expect(left.value, equals(1));
        expect(right.name, equals('serviceName'));
      },
    );
  });

  group('AssignExpression', () {
    test(
      'with Literal "="',
      () {
        final tree = Tree(
          content: 'a = 1',
          options: TreeOptions(
            throwScriptnameMissing: false,
          ),
        );

        final assign = tree.parse().body.first as AssignExpression;
        final left = assign.left as Identifier;
        final right = assign.right as Literal;
        expect(assign.operator, equals('='));
        expect(left.name, equals('a'));
        expect(right.value, equals(1));
      },
    );

    test(
      'with Literal "+="',
      () {
        final tree = Tree(
          content: 'a += 1',
          options: TreeOptions(
            throwScriptnameMissing: false,
          ),
        );

        final assign = tree.parse().body.first as AssignExpression;
        final left = assign.left as Identifier;
        final right = assign.right as Literal;
        expect(assign.operator, equals('+='));
        expect(left.name, equals('a'));
        expect(right.value, equals(1));
      },
    );

    test(
      'with CallExpression with MemberExpression',
      () {
        final tree = Tree(
          content: 'a = Uti.Get()',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwCallOutside: false,
          ),
        );

        final assign = tree.parse().body.first as AssignExpression;
        final left = assign.left as Identifier;
        final right = assign.right as CallExpression;
        final member = right.callee as MemberExpression;
        final memberObject = member.object as Identifier;
        final memberProperty = member.property as Identifier;
        expect(left.name, equals('a'));
        expect(memberObject.name, equals('Uti'));
        expect(memberProperty.name, equals('Get'));
      },
    );
  });

  group('LineTerminator', () {
    test(
      'should ignore backslash to go to next token',
      () {
        final tree = Tree(
          content: 'if true && \\ \n'
              '  false\n'
              'EndIf',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwIfOutside: false,
            throwBinaryOutside: false,
          ),
        );

        final program = tree.parse();
        final ifStatement = program.body.first as IfStatement;
        final ifTest = ifStatement.test as BinaryExpression;
        expect((ifTest.left as Literal).value, isTrue);
        expect((ifTest.right as Literal).value, isFalse);
        expect(ifTest.operator, equals('&&'));
      },
    );

    test(
      'more than one line terminator in the same line should throws an error',
      () {
        final tree = Tree(
          content: 'if true && \\ \\ \n'
              '  false\n'
              'EndIf',
          options: TreeOptions(
            throwScriptnameMissing: false,
            throwIfOutside: false,
          ),
        );

        expect(
          () => tree.parse(),
          throwsA(TypeMatcher<UnexpectedTokenException>()),
        );
      },
    );
  });

  group('NewExpression', () {
    test('should create new array', () {
      final tree = Tree(
        content: 'String[] s = new String[4]',
        options: TreeOptions(
          throwScriptnameMissing: false,
          throwNewOutside: false,
        ),
      );

      final program = tree.parse();
      final variableDeclaration = program.body.first as VariableDeclaration;
      final variable = variableDeclaration.variable;
      expect(variable.kind, equals('String[]'));
      expect(variable.isArray, isTrue);
      final init = variable.init as NewExpression;
      final member = init.argument as MemberExpression;
      expect(member.computed, isTrue);
      expect(member.property, TypeMatcher<Literal>());
      final object = member.object as Identifier;
      expect(object.name, equals('String'));
    });

    test('with index non Literal should throws an error', () {
      final tree = Tree(
        content: 'String[] s = new String[n()]',
        options: TreeOptions(
          throwScriptnameMissing: false,
          throwNewOutside: false,
        ),
      );

      expect(
        () => tree.parse(),
        throwsA(TypeMatcher<UnexpectedTokenException>()),
      );
    });

    test('outside of Function/Event should throws an error', () {
      final tree = Tree(
        content: 'String[] s = new String[3]',
        options: TreeOptions(
          throwScriptnameMissing: false,
        ),
      );

      expect(
        () => tree.parse(),
        throwsA(TypeMatcher<UnexpectedTokenException>()),
      );
    });
  });

  group('Array', () {
    test(
      'should assign to array index',
      () {
        final tree = Tree(
          content: 'toto[4] = true',
          options: TreeOptions(
            throwScriptnameMissing: false,
          ),
        );

        final program = tree.parse();
        final expression = program.body.first as ExpressionStatement;
        final assign = expression.expression as AssignExpression;
        final member = assign.left as MemberExpression;
        expect(member.property, TypeMatcher<Literal>());
        expect(member.computed, isTrue);
        final object = member.object as Identifier;
        expect(object.name, equals('toto'));
        final right = assign.right as Literal;
        expect(right.value, isTrue);
      },
    );
  });

  group(
    'Token',
    () {
      test(
        '"++" and "--" operators should throws an error',
        () {
          final tree = Tree(
            content: 'int f = 0\n'
                'f++',
            options: TreeOptions(
              throwBinaryOutside: false,
              throwScriptnameMissing: false,
            ),
          );

          expect(
            () => tree.parse(),
            throwsA(TypeMatcher<UnexpectedTokenException>()),
          );
        },
      );
    },
  );

  // TODO: review start/end of nodes
  // TODO: process line/column
}
