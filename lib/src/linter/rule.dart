import 'dart:isolate';

import '../ast/types.dart';
import '../ast/node.dart';
import 'linter_context.dart';

export 'rule/camelcase.dart';

class StartParam {
  final SendPort port;
  final LinterContext context;
  final Node node;
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
  final List<NodeType> listenTypes;

  const Rule({
    required this.name,
    required this.hasAutoFix,
    required this.messages,
    required this.listenTypes,
  });

  void start({required Node node, required LinterContext context});
}
