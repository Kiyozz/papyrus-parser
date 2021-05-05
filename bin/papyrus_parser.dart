import 'package:papyrus_parser/papyrus_parser.dart';

void main(List<String> arguments) {
  final tree = Tree(
    content: 'ScriptName test\n'
        'If true\n'
        'EndIf',
  );

  final program = tree.parse();

  print('Name is ${(program.body.first as ScriptNameStatement).id?.name}');
}
