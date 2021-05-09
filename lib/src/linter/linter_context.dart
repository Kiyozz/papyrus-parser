import 'report.dart';

class LinterContext {
  final String filename;
  final String content;
  final List<Report> reports = [];

  LinterContext({
    required this.filename,
    required this.content,
  });

  void report(Report report) {
    reports.add(report);
  }

  Map<String, dynamic> toJson() {
    return {
      'reports': reports.map((report) => report.toJson()).toList(),
    };
  }
}
