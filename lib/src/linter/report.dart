import 'rule.dart';
import '../ast/node.dart';

class Report {
  final Rule rule;
  final Severity severity;
  final Node node;
  final String messageId;
  final Map<String, dynamic> data;

  const Report({
    required this.rule,
    required this.severity,
    required this.node,
    required this.messageId,
    this.data = const {},
  });

  Map<String, dynamic> toJson() {
    var name = rule.messages[messageId];

    for (final item in data.entries) {
      if (name == null) {
        throw Exception();
      }

      name = name.replaceAll('{{${item.key}}}', item.value);
    }

    return {
      'ruleName': rule.name,
      'message': name,
      'severity': severity.name,
      'start': node.startPos.toJson(),
      'end': node.endPos.toJson(),
    };
  }
}

enum Severity { error, warning, information, hint }

extension SeverityString on Severity {
  String get name {
    switch (this) {
      case Severity.error:
        return 'error';
      case Severity.warning:
        return 'warning';
      case Severity.information:
        return 'information';
      case Severity.hint:
        return 'hint';
    }
  }
}
