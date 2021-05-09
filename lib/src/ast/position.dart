class PositionInformation {
  final int line;
  final int character;

  const PositionInformation({
    required this.line,
    required this.character,
  });

  Position asPosition() {
    return Position(line: line, character: character);
  }
}

class Position {
  final int line;
  final int character;

  const Position({
    required this.line,
    required this.character,
  });

  Map<String, dynamic> toJson() {
    return {
      'line': line,
      'character': character,
    };
  }
}
