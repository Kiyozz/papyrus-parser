import 'package:papyrus/ast.dart';

import 'problem_holder.dart';

class IdentifierParams {
  final NodeType from;
  final ProblemHolder context;
  final Identifier id;

  const IdentifierParams({
    required this.from,
    required this.context,
    required this.id,
  });
}

class FlagParams {
  final NodeType from;
  final ProblemHolder context;
  final FlagDeclaration flag;

  const FlagParams({
    required this.from,
    required this.context,
    required this.flag,
  });
}

class MetaParams {
  final NodeType from;
  final ProblemHolder context;
  final Identifier id;

  const MetaParams({
    required this.from,
    required this.context,
    required this.id,
  });
}

class KindParams {
  final NodeType from;
  final ProblemHolder context;
  final Node node;
  final String kind;

  const KindParams({
    required this.from,
    required this.context,
    required this.node,
    required this.kind,
  });
}
