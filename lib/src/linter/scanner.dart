import 'dart:async';
import 'dart:isolate';

import 'package:papyrus/ast.dart';
import 'package:papyrus/linter.dart';

import 'problem_holder.dart';
import 'params.dart';
import 'rule.dart';

class Scanner {
  const Scanner();

  /// List of active rules
  final List<Rule> _activeRules = const [NamingConventionRule(), SpaceRule()];

  /// Max problems reported
  final int _maxProblems = 60;

  Stream<Map<String, dynamic>> problemsIn({
    required String text,
    required String filename,
  }) async* {
    final parser = Parser(content: text);
    final context = ProblemHolder(
      filename: filename,
      text: text,
      maxProblems: _maxProblems,
    );
    final port = ReceivePort();
    final program = parser.parse();
    var sentMessages = 0;
    var receivedMessages = 0;

    for (final rule in _activeRules) {
      sentMessages++;
      await Isolate.spawn<StartParam>(
        _processRule,
        StartParam(
          context: context,
          program: program,
          rule: rule,
          port: port.sendPort,
        ),
      );
    }

    await for (final message in port) {
      if (message is ProblemHolder) {
        receivedMessages++;
        context.problems.addAll(message.problems);

        if (context.problems.length >= _maxProblems) {
          port.close();
          yield context.toJson();
          return;
        }
      }

      if (receivedMessages >= sentMessages) {
        port.close();
        yield context.toJson();
        return;
      }
    }
  }
}

void _processRule(StartParam param) {
  final program = param.program;
  final context = param.context;
  final port = param.port;
  final rule = param.rule;

  for (final node in program.body) {
    _processNode(node: node, context: context, rule: rule);
  }

  _processNode(node: program, context: context, rule: rule);

  port.send(context);
}

void _processNode({
  required Node node,
  required ProblemHolder context,
  required Rule rule,
}) {
  final idParams = <IdentifierParam>[];
  final flagParams = <FlagParam>[];
  final metaParams = <MetaParam>[];
  final kindParams = <KindParam>[];

  if (node is ScriptNameStatement) {
    idParams.add(
      IdentifierParam(from: node.type, context: context, id: node.id),
    );

    metaParams.add(
      MetaParam(from: node.type, context: context, id: node.meta),
    );

    for (final flag in node.flags) {
      flagParams.add(
        FlagParam(from: node.type, context: context, flag: flag),
      );
    }
  } else if (node is PropertyDeclaration) {
    metaParams.add(
      MetaParam(from: node.type, context: context, id: node.meta),
    );

    kindParams.add(
      KindParam(
        from: node.type,
        context: context,
        node: node,
        kind: node.kind,
      ),
    );

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

      metaParams.add(
        MetaParam(from: node.type, context: context, id: node.endMeta),
      );
    }

    for (final flag in node.flags) {
      flagParams.add(
        FlagParam(from: node.type, context: context, flag: flag),
      );
    }
  } else if (node is FunctionStatement) {
    idParams.add(
      IdentifierParam(from: node.type, context: context, id: node.id),
    );

    metaParams.add(
      MetaParam(from: node.type, context: context, id: node.meta),
    );

    final endMeta = node.endMeta;

    if (endMeta != null) {
      metaParams.add(
        MetaParam(from: node.type, context: context, id: endMeta),
      );
    }

    if (node.kind != '') {
      kindParams.add(
        KindParam(
          from: node.type,
          context: context,
          node: node,
          kind: node.kind,
        ),
      );
    }

    final body = node.body;

    if (body != null) {
      _processNode(node: body, context: context, rule: rule);
    }

    for (final param in node.params) {
      _processNode(node: param, context: context, rule: rule);
    }

    for (final flag in node.flags) {
      flagParams.add(
        FlagParam(from: node.type, context: context, flag: flag),
      );
    }
  } else if (node is IfStatement) {
    metaParams.addAll([
      MetaParam(from: node.type, context: context, id: node.meta),
      MetaParam(from: node.type, context: context, id: node.endMeta),
    ]);

    _processNode(node: node.consequent, context: context, rule: rule);

    final alternate = node.alternate;

    if (alternate != null) {
      final alternateMeta = node.alternateMeta;

      if (alternateMeta != null) {
        metaParams.add(
          MetaParam(from: alternate.type, context: context, id: alternateMeta),
        );
      }

      _processNode(node: alternate, context: context, rule: rule);
    }

    _processNode(node: node.test, context: context, rule: rule);
  } else if (node is EventStatement) {
    idParams.add(
      IdentifierParam(from: node.type, context: context, id: node.id),
    );

    metaParams.add(
      MetaParam(from: node.type, context: context, id: node.meta),
    );

    final endMeta = node.endMeta;

    if (endMeta != null) {
      metaParams.add(
        MetaParam(from: node.type, context: context, id: endMeta),
      );
    }

    for (final param in node.params) {
      _processNode(node: param, context: context, rule: rule);
    }

    final body = node.body;

    if (body != null) {
      _processNode(node: body, context: context, rule: rule);
    }

    for (final flag in node.flags) {
      flagParams.add(
        FlagParam(from: node.type, context: context, flag: flag),
      );
    }
  } else if (node is StateStatement) {
    idParams.add(
      IdentifierParam(from: node.type, context: context, id: node.id),
    );

    _processNode(node: node.body, context: context, rule: rule);

    final flag = node.flag;

    if (flag != null) {
      flagParams.add(FlagParam(from: node.type, context: context, flag: flag));
    }
  } else if (node is VariableDeclaration) {
    idParams.add(
      IdentifierParam(
        from: NodeType.variable,
        context: context,
        id: node.variable.id,
      ),
    );

    kindParams.add(
      KindParam(
        from: node.type,
        context: context,
        node: node,
        kind: node.variable.kind,
      ),
    );

    final init = node.variable.init;

    if (init != null) {}
  } else if (node is WhileStatement) {
    metaParams.addAll([
      MetaParam(from: node.type, context: context, id: node.meta),
      MetaParam(from: node.type, context: context, id: node.endMeta),
    ]);

    _processNode(node: node.consequent, context: context, rule: rule);
  } else if (node is BlockStatement) {
    for (final blockNode in node.body) {
      _processNode(node: blockNode, context: context, rule: rule);
    }
  } else if (node is ReturnStatement) {
    metaParams.add(
      MetaParam(from: node.type, context: context, id: node.meta),
    );

    final argument = node.argument;

    if (argument != null) {
      _processNode(node: argument, context: context, rule: rule);
    }
  } else if (node is Program) {
    rule.startProgram(program: node, context: context);
  }

  for (final param in idParams) {
    if (!context.canInsertProblem) {
      break;
    }

    rule.startIdentifier(
      node: param.id,
      context: param.context,
      from: param.from,
    );
  }

  for (final param in flagParams) {
    if (!context.canInsertProblem) {
      break;
    }

    rule.startFlag(
      node: param.flag,
      context: param.context,
      from: param.from,
    );
  }

  for (final param in metaParams) {
    if (!context.canInsertProblem) {
      break;
    }

    rule.startMeta(
      node: param.id,
      context: param.context,
      from: param.from,
    );
  }

  for (final param in kindParams) {
    if (!context.canInsertProblem) {
      break;
    }

    rule.startKind(
      node: param.node,
      kind: param.kind,
      context: param.context,
      from: param.from,
    );
  }
}
