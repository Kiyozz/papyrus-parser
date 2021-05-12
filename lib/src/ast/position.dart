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

  Position copy({int? character, int? line}) {
    final currentCharacter = this.character;
    final currentLine = this.line;

    return Position(
      line: line ?? currentLine,
      character: character ?? currentCharacter,
    );
  }
}
