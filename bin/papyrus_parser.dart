import 'dart:io';
import 'dart:convert';

import 'package:papyrus_parser/papyrus_parser.dart';

void createProgram({required String content, required String filename}) {
  final tree = Tree(content: content, filename: filename);
  final jsonEncoder = JsonEncoder();

  try {
    final program = tree.parse();
    final json = program.toJson();
    stdout.write(
      jsonEncoder.convert({
        'isException': false,
        ...json,
      }),
    );
    exit(0);
  } on NodeException catch (e) {
    final display = {
      'start': e.startPos.toJson(),
      'end': e.endPos.toJson(),
      'message': e.toString(),
      'type': e.runtimeType.toString(),
      'isException': true,
    };
    print(jsonEncoder.convert(display));
    exit(0);
  }
}

void main(List<String> arguments) async {
  if (arguments.length < 2) {
    print('The first argument should be psc filename');
    exit(1);
  }

  final isFilename = arguments.first == 'file';
  final pathOrFilename = arguments[1];

  if (isFilename) {
    if (arguments.length != 3) {
      print('When using filepath, third argument must be the filename');
      exit(1);
    }

    final file = File(pathOrFilename);
    createProgram(content: await file.readAsString(), filename: arguments[2]);
  } else {
    var content = '';

    final subcription = stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((data) {
      content += '$data\n';
    });

    subcription.onDone(() {
      createProgram(content: content, filename: pathOrFilename);
    });
  }
}
