import 'dart:async';
import 'dart:isolate';

import 'package:papyrus_parser/papyrus_parser.dart';

import '../ast/tree.dart';
import '../ast/types.dart';
import 'linter_context.dart';
import 'rule.dart';

export 'linter_context.dart';
export 'report.dart';

class Linter {
  final Tree _tree;
  final LinterContext _context;
  final List<Rule> rules = const [
    CamelcaseRule(),
  ];

  const Linter({
    required Tree tree,
    required LinterContext context,
  })   : _tree = tree,
        _context = context;

  Future<Map<String, dynamic>> lint() {
    final completer = Completer<Map<String, dynamic>>();
    final port = ReceivePort();
    final program = _tree.parse();
    var sentMessages = 0;
    var receivedMessages = 0;

    port.listen((message) {
      if (message is LinterContext) {
        receivedMessages++;
        _context.reports.addAll(message.reports);
      }

      if (receivedMessages >= sentMessages) {
        port.close();
        completer.complete(_context.toJson());
      }
    });

    for (final node in program.body) {
      for (final rule in rules) {
        sentMessages++;
        Isolate.spawn<StartParam>(
          _processRule,
          StartParam(
            context: _context,
            node: node,
            rule: rule,
            port: port.sendPort,
          ),
        );
      }
    }

    return completer.future;
  }
}

void _processRule(StartParam param) {
  final node = param.node;
  final context = param.context;
  final port = param.port;
  final rule = param.rule;

  if (node is ScriptNameStatement) {
    if (wantToListenTo(NodeType.id, rule)) {
      rule.start(node: node.id, context: context);
    }
  }

  if (node is FunctionStatement) {
    if (wantToListenTo(NodeType.id, rule)) {
      rule.start(node: node.id, context: context);
    }
  }

  if (node is VariableDeclaration) {
    if (wantToListenTo(NodeType.variable, rule)) {
      rule.start(node: node.variable, context: context);
    }
  }

  port.send(context);
}

bool wantToListenTo(NodeType type, Rule rule) {
  return rule.listenTypes.contains(type);
}

bool wantToListenIdentifier(Rule rule) => wantToListenTo(NodeType.id, rule);
