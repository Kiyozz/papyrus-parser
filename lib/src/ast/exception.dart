class ScriptnameException {
  final int _pos;

  ScriptnameException({required int pos}) : _pos = pos;

  @override
  String toString() {
    return 'Unexpected token at $_pos. Scriptname statement is not complete';
  }
}

class UnexpectedTokenException {
  final int _pos;
  final String? _expected;

  UnexpectedTokenException({required int pos, String? expected})
      : _pos = pos,
        _expected = expected;

  @override
  String toString() {
    final buffer = StringBuffer('Unexpected token at $_pos.');

    if (_expected != null) {
      buffer.write(' Expected $_expected');
    }

    return buffer.toString();
  }
}
