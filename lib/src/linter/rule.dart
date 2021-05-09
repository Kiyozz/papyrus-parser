import 'dart:isolate';

import '../ast/types.dart';
import '../ast/node.dart';
import 'linter_context.dart';

export 'rule/namingConvention.dart';

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

  const Rule({
    required this.name,
    required this.hasAutoFix,
    required this.messages,
  });

  void startIdentifier({
    required Identifier node,
    required LinterContext context,
    required NodeType from,
  });

  void startFlag({
    required FlagDeclaration node,
    required LinterContext context,
    required NodeType from,
  });
}
