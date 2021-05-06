import 'dart:io';

import 'package:papyrus_parser/papyrus_parser.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('The first argument should be a path to a psc file');
    exit(1);
  }

  final filePath = arguments.first;
  final file = File(filePath);
  final tree = Tree(
    content: await file.readAsString(),
  );
  final program = tree.parse();

  print('Name is ${(program.body.first as ScriptNameStatement).id.name}');
}
