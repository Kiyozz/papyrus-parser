import 'package:papyrus_parser/papyrus_parser.dart';

void main(List<String> arguments) {
  final tree = Tree(
    content: 'ScriptName Test',
  );

  final program = tree.parse();

  print('Name is ${(program.body.first as ScriptName).id?.name}');
}
