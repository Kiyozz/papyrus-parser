import 'dart:async';
import 'dart:isolate';

import 'package:papyrus_parser/papyrus_parser.dart';

import '../ast/tree.dart';
import '../ast/types.dart';
import 'linter_context.dart';
import 'rule.dart';

export 'linter_context.dart';
export 'report.dart';

class IdentifierParams {
  final NodeType from;
  final LinterContext context;
  final Identifier id;

  const IdentifierParams({
    required this.from,
    required this.context,
    required this.id,
  });
}

class FlagParams {
  final NodeType from;
  final LinterContext context;
  final FlagDeclaration flag;

  const FlagParams({
    required this.from,
    required this.context,
    required this.flag,
  });
}

class Linter {
  final Tree _tree;
  final LinterContext _context;
  final List<Rule> rules = const [
    NamingConventionRule(),
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

  _processNode(node: node, context: context, rule: rule);

  port.send(context);
}

void _processNode({
  required Node node,
  required LinterContext context,
  required Rule rule,
}) {
  final idParams = <IdentifierParams>[];
  final flagParams = <FlagParams>[];

  if (node is ScriptNameStatement) {
    idParams.add(
      IdentifierParams(from: node.type, context: context, id: node.id),
    );

    for (final flag in node.flags) {
      flagParams.add(
        FlagParams(from: node.type, context: context, flag: flag),
      );
    }
  }

  if (node is PropertyDeclaration) {
    if (node.isFull) {
      node as PropertyFullDeclaration;

      final getter = node.getter;
      final setter = node.setter;

      if (getter != null) {
        _processNode(node: getter, context: context, rule: rule);
      }

      if (setter != null) {
        _processNode(node: setter, context: context, rule: rule);
      }
    }

    for (final flag in node.flags) {
      flagParams.add(
        FlagParams(from: node.type, context: context, flag: flag),
      );
    }
  }

  if (node is FunctionStatement) {
    idParams.add(
      IdentifierParams(from: node.type, context: context, id: node.id),
    );

    for (final blockNode in (node.body?.body ?? [])) {
      _processNode(node: blockNode, context: context, rule: rule);
    }

    for (final param in node.params) {
      _processNode(node: param, context: context, rule: rule);
    }

    for (final flag in node.flags) {
      flagParams.add(
        FlagParams(from: node.type, context: context, flag: flag),
      );
    }
  }

  if (node is EventStatement) {
    idParams.add(
      IdentifierParams(from: node.type, context: context, id: node.id),
    );

    for (final blockNode in (node.body?.body ?? [])) {
      _processNode(node: blockNode, context: context, rule: rule);
    }

    for (final flag in node.flags) {
      flagParams.add(
        FlagParams(from: node.type, context: context, flag: flag),
      );
    }
  }

  if (node is StateStatement) {
    idParams.add(
      IdentifierParams(from: node.type, context: context, id: node.id),
    );

    for (final blockNode in node.body.body) {
      _processNode(node: blockNode, context: context, rule: rule);
    }

    final flag = node.flag;

    if (flag != null) {
      flagParams.add(FlagParams(from: node.type, context: context, flag: flag));
    }
  }

  if (node is VariableDeclaration) {
    idParams.add(
      IdentifierParams(
        from: NodeType.variable,
        context: context,
        id: node.variable.id,
      ),
    );
  }

  for (final param in idParams) {
    rule.startIdentifier(
      node: param.id,
      context: param.context,
      from: param.from,
    );
  }

  for (final param in flagParams) {
    rule.startFlag(
      node: param.flag,
      context: param.context,
      from: param.from,
    );
  }
}
