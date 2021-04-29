import 'package:papyrus_parser/papyrus_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Header', () {
    test('G', () {
      final tree = Tree(content: ' Scriptname Test');

      final program = tree.parse();
    });
  });
}
