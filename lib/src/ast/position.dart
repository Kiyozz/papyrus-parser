import 'package:charcode/ascii.dart';

class Position {
  final int line;
  final int character;

  const Position({
    required this.line,
    required this.character,
  });

  Position.fromIndex(
    int index, {
    required String content,
  })   : line = _lineAndColumnAt(index, text: content)[0],
        character = _lineAndColumnAt(index, text: content)[1];

  Map<String, dynamic> toJson() {
    return {
      'line': line,
      'character': character,
    };
  }
}

List<int> _lineAndColumnAt(int index, {required String text}) {
  var c = 0;
  var line = 0;
  var col = 0;

  while (c < index) {
    if (text.codeUnitAt(c) == $lf) {
      ++line;
      col = 0;
    } else {
      ++col;
    }

    c++;
  }

  return [line, col];
}
