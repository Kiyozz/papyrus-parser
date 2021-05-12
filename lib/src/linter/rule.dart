import 'package:charcode/ascii.dart';
import 'package:papyrus/ast.dart';
import 'package:recase/recase.dart';

import 'problem.dart';
import 'problem_holder.dart';

class Expected {
  final String name;
  final bool inRange;

  const Expected(this.name, {required this.inRange});
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

  void startProgram({
    required Program program,
    required String content,
    required ProblemHolder context,
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

    if (name != expected.name) {
      context.add(
        Problem(
          rule: this,
          severity: Severity.warning,
          node: node,
          messageId: 'notExpected',
          data: {'name': name, 'id': 'Flag', 'expected': expected.name},
        ),
      );

      return;
    }

    final rc = ReCase(name);

    if (name != rc.pascalCase) {
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
    final expected = _nameToExpected(name);

    if (name == expected.name && expected.inRange) return;

    final rc = ReCase(name);

    if (expected.name != name) {
      context.add(
        Problem(
          rule: this,
          severity: Severity.warning,
          node: node,
          messageId: 'notExpected',
          data: {'name': name, 'id': 'Keyword', 'expected': expected.name},
        ),
      );
    } else if (name != rc.pascalCase) {
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

  @override
  void startProgram({
    required Program program,
    required String content,
    required ProblemHolder context,
  }) {}

  bool _isValidIdentifier(NodeType node) {
    return node == NodeType.variable ||
        node == NodeType.functionKw ||
        node == NodeType.eventKw ||
        node == NodeType.stateKw;
  }

  Expected _nameToExpected(String name) {
    switch (name.toLowerCase()) {
      case 'autoreadonly':
        return Expected('AutoReadonly', inRange: true);
      case 'endfunction':
        return Expected('EndFunction', inRange: true);
      case 'endstate':
        return Expected('EndState', inRange: true);
      case 'endif':
        return Expected('EndIf', inRange: true);
      case 'elseif':
        return Expected('ElseIf', inRange: true);
      case 'endproperty':
        return Expected('EndProperty', inRange: true);
      case 'endwhile':
        return Expected('EndWhile', inRange: true);
      case 'endevent':
        return Expected('EndEvent', inRange: true);
      case 'scriptname':
        return Expected('ScriptName', inRange: true);
      case 'new':
        return Expected('new', inRange: true);
      default:
        return Expected(name, inRange: false);
    }
  }
}

class SpaceRule extends Rule {
  const SpaceRule()
      : super(
          hasAutoFix: false,
          messages: const {
            'extraSpace': 'Delete space',
            'extraLine': 'Delete line',
            'missingSpace': 'Insert space',
            'missingLine': 'Insert line',
          },
          name: 'space',
        );

  @override
  void startIdentifier({
    required Identifier node,
    required ProblemHolder context,
    required NodeType from,
  }) {}

  @override
  void startFlag({
    required FlagDeclaration node,
    required ProblemHolder context,
    required NodeType from,
  }) {}

  @override
  void startKind({
    required Node node,
    required String kind,
    required ProblemHolder context,
    required NodeType from,
  }) {}

  @override
  void startMeta({
    required Identifier node,
    required ProblemHolder context,
    required NodeType from,
  }) {}

  @override
  void startProgram({
    required Program program,
    required String content,
    required ProblemHolder context,
  }) {
    _processNodes(container: program, nodes: program.body, context: context);

    for (final node in program.body) {
      _processNode(node, content: content, context: context);
    }
  }

  void _processNodes({
    required Node container,
    required List<Node> nodes,
    required ProblemHolder context,
  }) {
    for (var i = 1; i < nodes.length; i++) {
      final previous = nodes[i - 1];
      final current = nodes[i];

      if (previous.endPos.line + 2 < current.startPos.line) {
        context.add(
          Problem(
            rule: this,
            severity: Severity.warning,
            node: Node(
              start: previous.end,
              end: current.start,
              startPos: previous.endPos.copy(line: previous.endPos.line + 2),
              endPos: current.startPos.copy(line: current.startPos.line - 1),
            ),
            messageId: 'extraLine',
          ),
        );
      }
    }

    if (nodes.isNotEmpty) {
      final first = nodes.first;
      final firstLinesDiff = first.startPos.line - container.startPos.line;
      final indicator = container is Program ? 0 : 1;

      if (firstLinesDiff > indicator) {
        context.add(
          Problem(
            rule: this,
            severity: Severity.warning,
            node: Node(
              start: container.start,
              startPos: container.startPos.copy(
                line: container.startPos.line + 1,
                character: 0,
              ),
              end: first.start,
              endPos: first.startPos.copy(
                line: first.startPos.line - 1,
                character: 0,
              ),
            ),
            messageId: 'extraLine',
          ),
        );
      }

      final last = nodes.length > 1 ? nodes.last : nodes.first;
      final lastLinesDiff = container.endPos.line - last.endPos.line;

      if (container is Program) {
        if (lastLinesDiff == 0) {
          context.add(
            Problem(
              rule: this,
              severity: Severity.warning,
              node: Node(
                start: last.end,
                startPos: last.endPos.copy(line: last.endPos.line + 1),
                end: container.end,
                endPos: container.endPos,
              ),
              messageId: 'missingLine',
            ),
          );
        } else if (lastLinesDiff > 1) {
          context.add(
            Problem(
              rule: this,
              severity: Severity.warning,
              node: Node(
                start: last.end,
                startPos: last.endPos,
                end: container.end,
                endPos: container.endPos.copy(line: container.endPos.line - 1),
              ),
              messageId: 'extraLine',
            ),
          );
        }
      } else if (lastLinesDiff > 1) {
        context.add(
          Problem(
            rule: this,
            severity: Severity.warning,
            node: Node(
              start: last.end,
              startPos: last.endPos.copy(
                line: last.endPos.line + 1,
                character: 0,
              ),
              end: container.end,
              endPos: container.endPos.copy(
                line: container.endPos.line - 1,
                character: 0,
              ),
            ),
            messageId: 'extraLine',
          ),
        );
      }
    } else {
      var startPos = container.startPos;
      var endPos = container.endPos;
      var linesDiff = endPos.line - startPos.line;

      if (linesDiff > 1) {
        context.add(
          Problem(
            rule: this,
            severity: Severity.warning,
            node: Node(
              start: container.start,
              startPos: container.startPos.copy(
                line: container.startPos.line + 1,
                character: 0,
              ),
              end: container.end,
              endPos: endPos.copy(line: endPos.line - 1, character: 0),
            ),
            messageId: 'extraLine',
          ),
        );
      }
    }
  }

  void _processNode(
    Node node, {
    required String content,
    required ProblemHolder context,
  }) {
    if (node is VariableDeclaration) {
      final init = node.variable.init;

      if (init != null) {
        final end = node.variable.id.end;
        final endPos = node.variable.id.endPos;
        final equalIndex = content.indexOf('=', end);

        if (end == equalIndex) {
          context.add(
            Problem(
              rule: this,
              severity: Severity.warning,
              node: Node(
                start: end,
                startPos: endPos,
                end: end,
                endPos: endPos,
              ),
              messageId: 'missingSpace',
            ),
          );
        } else {
          final endDiff = equalIndex - end - 1;

          if (endDiff > 0) {
            final equalPos = endPos.copy(
              character: endPos.character + endDiff + 1,
            );

            context.add(
              Problem(
                rule: this,
                severity: Severity.warning,
                node: Node(
                  start: end + 1,
                  startPos: endPos.copy(character: endPos.character + 1),
                  end: equalIndex,
                  endPos: equalPos,
                ),
                messageId: 'extraSpace',
              ),
            );
          }
        }

        final initStart = init.start;
        final initStartPos = init.startPos;

        if (initStart == equalIndex + 1) {
          context.add(
            Problem(
              rule: this,
              severity: Severity.warning,
              node: Node(
                start: initStart,
                startPos: initStartPos,
                end: initStart + 1,
                endPos: initStartPos.copy(
                  character: initStartPos.character + 1,
                ),
              ),
              messageId: 'missingSpace',
            ),
          );
        } else {
          final endDiff = initStart - equalIndex - 1;
          if (endDiff != 1) {
            final equalPos = endPos.copy(
              character: endPos.character + 3,
            );

            context.add(
              Problem(
                rule: this,
                severity: Severity.warning,
                node: Node(
                  start: equalIndex + 3,
                  startPos: equalPos,
                  end: initStart,
                  endPos: initStartPos,
                ),
                messageId: 'extraSpace',
              ),
            );
          }
        }
      }
    } else if (node is FunctionStatement) {
      _processTwoNode(
        from: node.meta,
        to: node.id,
        context: context,
        content: content,
        doExtraSpace: true,
      );

      final body = node.body;

      if (body != null) {
        _processNodes(container: body, nodes: body.body, context: context);
        _processNode(body, content: content, context: context);
      }
    } else if (node is BlockStatement) {
      for (final blockNode in node.body) {
        _processNode(blockNode, content: content, context: context);
      }
    } else if (node is IfStatement) {
      _processTwoNode(
        from: node.meta,
        to: node.test,
        context: context,
        content: content,
        doExtraSpace: true,
        doMissingSpace: true,
      );

      _processNode(node.test, content: content, context: context);
      _processNode(node.consequent, content: content, context: context);
      _processNodes(
        container: node.consequent,
        nodes: node.consequent.body,
        context: context,
      );

      final alternate = node.alternate;

      if (alternate != null) {
        _processNode(alternate, content: content, context: context);

        if (alternate is BlockStatement) {
          _processNodes(
            container: alternate,
            nodes: alternate.body,
            context: context,
          );
        }
      }
    } else if (node is WhileStatement) {
      _processTwoNode(
        from: node.meta,
        to: node.test,
        context: context,
        content: content,
        doExtraSpace: true,
      );

      _processNodes(
        container: node.consequent,
        nodes: node.consequent.body,
        context: context,
      );
      _processNode(node.consequent, content: content, context: context);
    } else if (node is EventStatement) {
      _processTwoNode(
        from: node.meta,
        to: node.id,
        context: context,
        content: content,
        doExtraSpace: true,
      );

      final body = node.body;

      if (body != null) {
        _processNodes(container: body, nodes: body.body, context: context);
        _processNode(body, content: content, context: context);
      }
    } else if (node is StateStatement) {
      _processTwoNode(
        from: node.meta,
        to: node.id,
        context: context,
        content: content,
        doExtraSpace: true,
      );

      _processNode(node.body, content: content, context: context);
      _processNodes(
        container: node.body,
        nodes: node.body.body,
        context: context,
      );
    } else if (node is ParenthesisExpression) {
      final body = node.body;

      if (body != null) {
        _processTwoNode(
          from: Node(
            start: node.start,
            startPos: node.startPos,
            end: node.start,
            endPos: node.startPos,
          ),
          to: body,
          context: context,
          content: content,
          doExtraSpace: true,
        );

        _processTwoNode(
          from: body,
          to: Node(
            start: node.end,
            startPos: node.endPos,
            end: node.end,
            endPos: node.endPos,
          ),
          context: context,
          content: content,
          doExtraSpace: true,
        );
      }
    }
  }

  void _processTwoNode({
    required Node from,
    required Node to,
    required ProblemHolder context,
    required String content,
    bool doMissingSpace = false,
    bool doExtraSpace = false,
  }) {
    final fromStart = from.end;
    final fromStartPos = from.endPos;
    var toStart = to.start;
    var toStartPos = to.startPos;

    if (doMissingSpace) {
      if (fromStart == toStart) {
        context.add(
          Problem(
            rule: this,
            severity: Severity.warning,
            node: Node(
              start: fromStart,
              startPos: fromStartPos,
              end: fromStart + 1,
              endPos: fromStartPos.copy(
                character: fromStartPos.character + 1,
              ),
            ),
            messageId: 'missingSpace',
          ),
        );

        return;
      }
    }

    if (doExtraSpace) {
      if (fromStart + 1 != toStart) {
        context.add(
          Problem(
            rule: this,
            severity: Severity.warning,
            node: Node(
              start: fromStart + 1,
              startPos: fromStartPos.copy(
                character: fromStartPos.character + 1,
              ),
              end: toStart,
              endPos: toStartPos,
            ),
            messageId: 'extraSpace',
          ),
        );

        return;
      }
    }
  }
}
