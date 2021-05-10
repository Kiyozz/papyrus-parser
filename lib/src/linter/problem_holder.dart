import 'problem.dart';

class ProblemHolder {
  final String filename;
  final String text;
  final List<Problem> problems = [];
  final int maxProblems;

  bool get canInsertProblem => problems.length < maxProblems;

  ProblemHolder({
    required this.filename,
    required this.text,
    required this.maxProblems,
  });

  void add(Problem problem) {
    problems.add(problem);
  }

  Map<String, dynamic> toJson() {
    return {
      'problems': problems.map((problem) => problem.toJson()).toList(),
    };
  }
}
