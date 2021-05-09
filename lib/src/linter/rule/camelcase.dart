import 'package:recase/recase.dart';

import '../../ast/types.dart';
import '../../ast/node.dart';

import '../report.dart';
import '../rule.dart';
import '../linter_context.dart';

class CamelcaseRule extends Rule {
  const CamelcaseRule()
      : super(
          hasAutoFix: false,
          messages: const {
            'notCamelcase': r'Identifier {{name}} is not in camel case.',
          },
          listenTypes: const [
            NodeType.variable,
            NodeType.propertyKw,
          ],
          name: 'camelcase',
        );

  @override
  void start({required Node node, required LinterContext context}) {
    if (!isValid(node)) {
      return;
    }

    node as Identifier;

    final name = node.name;

    final rc = ReCase(name);

    if (rc.camelCase != name) {
      context.report(
        Report(
          rule: this,
          severity: Severity.warning,
          node: node,
          messageId: 'notCamelcase',
          data: {'name': name},
        ),
      );
    }
  }

  bool isValid(Node node) {
    return node is Identifier;
  }
}
