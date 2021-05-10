import 'dart:isolate';

import 'package:papyrus/ast.dart';
import 'package:recase/recase.dart';

import 'problem.dart';
import 'problem_holder.dart';

class StartParam {
  final SendPort port;
  final ProblemHolder context;
  final List<Node> node;
  final Rule rule;

  const StartParam({
    required this.context,
    required this.node,
    required this.rule,
    required this.port,
  });
}

abstract class Rule {
  final String name;
  final bool hasAutoFix;
  final Map<String, String> messages;

  const Rule({
    required this.name,
    required this.hasAutoFix,
    required this.messages,
  });

  void startIdentifier({
    required Identifier node,
    required ProblemHolder context,
    required NodeType from,
  });

  void startFlag({
    required FlagDeclaration node,
    required ProblemHolder context,
    required NodeType from,
  });

  void startMeta({
    required Identifier node,
    required ProblemHolder context,
    required NodeType from,
  });

  void startKind({
    required Node node,
    required String kind,
    required ProblemHolder context,
    required NodeType from,
  });
}

class NamingConventionRule extends Rule {
  const NamingConventionRule()
      : super(
          hasAutoFix: false,
          messages: const {
            'notCamelcase': r'{{id}} {{name}} must be in camel case.',
            'notPascalcase': r'{{id}} {{name}} must be in pascal case',
            'notExpected': r'{{id}} {{name}} must be "{{expected}}"',
          },
          name: 'naming-convention',
        );

  @override
  void startIdentifier({
    required Identifier node,
    required ProblemHolder context,
    required NodeType from,
  }) {
    if (!_isValidIdentifier(from)) {
      return;
    }

    final name = node.name;
    final rc = ReCase(name);

    if (rc.camelCase != name && from == NodeType.variable) {
      context.add(
        Problem(
          rule: this,
          severity: Severity.warning,
          node: node,
          messageId: 'notCamelcase',
          data: {'name': name, 'id': from.name},
        ),
      );
    }

    if (rc.pascalCase != name &&
        (from == NodeType.functionKw ||
            from == NodeType.eventKw ||
            from == NodeType.stateKw)) {
      context.add(
        Problem(
          rule: this,
          severity: Severity.warning,
          node: node,
          messageId: 'notPascalcase',
          data: {'name': name, 'id': from.name},
        ),
      );
    }
  }

  @override
  void startFlag({
    required FlagDeclaration node,
    required ProblemHolder context,
    required NodeType from,
  }) {
    final name = node.raw;
    final expected = _nameToExpected(name);

    if (expected != name) {
      context.add(
        Problem(
          rule: this,
          severity: Severity.warning,
          node: node,
          messageId: 'notExpected',
          data: {'name': name, 'id': 'Flag', 'expected': expected},
        ),
      );

      return;
    }

    final rc = ReCase(name);

    if (rc.pascalCase != name) {
      context.add(
        Problem(
          rule: this,
          severity: Severity.warning,
          node: node,
          messageId: 'notExpected',
          data: {'name': name, 'id': 'Flag', 'expected': rc.pascalCase},
        ),
      );
    }
  }

  @override
  void startMeta({
    required Identifier node,
    required ProblemHolder context,
    required NodeType from,
  }) {
    final name = node.name;
    final rc = ReCase(name);
    final expected = _nameToExpected(name);

    if (expected != name) {
      context.add(
        Problem(
          rule: this,
          severity: Severity.warning,
          node: node,
          messageId: 'notExpected',
          data: {'name': name, 'id': 'Keyword', 'expected': expected},
        ),
      );

      return;
    }

    if (rc.pascalCase != name) {
      context.add(
        Problem(
          rule: this,
          severity: Severity.warning,
          node: node,
          messageId: 'notExpected',
          data: {'name': name, 'id': 'Keyword', 'expected': rc.pascalCase},
        ),
      );
    }
  }

  @override
  void startKind({
    required Node node,
    required String kind,
    required ProblemHolder context,
    required NodeType from,
  }) {
    final name = kind;
    final rc = ReCase(name);

    if (rc.pascalCase != name) {
      context.add(
        Problem(
          rule: this,
          severity: Severity.warning,
          node: node,
          messageId: 'notPascalcase',
          data: {'name': name, 'id': 'Type'},
        ),
      );
    }
  }

  bool _isValidIdentifier(NodeType node) {
    return node == NodeType.variable ||
        node == NodeType.functionKw ||
        node == NodeType.eventKw ||
        node == NodeType.stateKw;
  }

  String _nameToExpected(String name) {
    switch (name.toLowerCase()) {
      case 'autoreadonly':
        return 'AutoReadonly';
      case 'endfunction':
        return 'EndFunction';
      case 'endstate':
        return 'EndState';
      case 'endif':
        return 'EndIf';
      case 'elseif':
        return 'ElseIf';
      case 'endproperty':
        return 'EndProperty';
      case 'endwhile':
        return 'EndWhile';
      case 'endevent':
        return 'EndEvent';
      case 'scriptname':
        return 'ScriptName';
      default:
        return name;
    }
  }
}
