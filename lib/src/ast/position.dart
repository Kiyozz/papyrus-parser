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
