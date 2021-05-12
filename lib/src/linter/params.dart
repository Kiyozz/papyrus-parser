import 'dart:isolate';

import 'package:papyrus/ast.dart';

import 'problem_holder.dart';
import 'rule.dart';

class StartParam {
  final SendPort port;
  final ProblemHolder context;
  final Program program;
  final Rule rule;
  final String text;

  const StartParam({
    required this.context,
    required this.program,
    required this.rule,
    required this.port,
    required this.text,
  });
}

class IdentifierParam {
  final NodeType from;
  final ProblemHolder context;
  final Identifier id;

  const IdentifierParam({
    required this.from,
    required this.context,
    required this.id,
  });
}

class FlagParam {
  final NodeType from;
  final ProblemHolder context;
  final FlagDeclaration flag;

  const FlagParam({
    required this.from,
    required this.context,
    required this.flag,
  });
}

class MetaParam {
  final NodeType from;
  final ProblemHolder context;
  final Identifier id;

  const MetaParam({
    required this.from,
    required this.context,
    required this.id,
  });
}

class KindParam {
  final NodeType from;
  final ProblemHolder context;
  final Node node;
  final String kind;

  const KindParam({
    required this.from,
    required this.context,
    required this.node,
    required this.kind,
  });
}
