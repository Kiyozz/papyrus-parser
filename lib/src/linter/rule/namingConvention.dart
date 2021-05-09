import 'package:recase/recase.dart';

import '../../ast/types.dart';
import '../../ast/node.dart';

import '../report.dart';
import '../rule.dart';
import '../linter_context.dart';

class NamingConventionRule extends Rule {
  const NamingConventionRule()
      : super(
          hasAutoFix: false,
          messages: const {
            'notCamelcase': r'{{id}} {{name}} must be in camel case.',
            'notPascalcase': r'{{id}} {{name}} must be in pascal case',
          },
          name: 'naming-convention',
        );

  @override
  void startIdentifier({
    required Identifier node,
    required LinterContext context,
    required NodeType from,
  }) {
    if (!_isValidIdentifier(from)) {
      return;
    }

    final name = node.name;
    final rc = ReCase(name);

    if (rc.camelCase != name && from == NodeType.variable) {
      context.report(
        Report(
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
      context.report(
        Report(
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
    required LinterContext context,
    required NodeType from,
  }) {
    final name = node.raw;
    final rc = ReCase(name);

    if (rc.pascalCase != name) {
      context.report(
        Report(
          rule: this,
          severity: Severity.warning,
          node: node,
          messageId: 'notPascalcase',
          data: {'name': name, 'id': 'Flag'},
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
}
