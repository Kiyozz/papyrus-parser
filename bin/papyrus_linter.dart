import 'dart:io';
import 'dart:convert';

import 'package:papyrus_parser/papyrus_parser.dart';
import 'package:papyrus_parser/papyrus_linter.dart';

void main(List<String> arguments) {
  final jsonEncoder = JsonEncoder();
  final jsonDecoder = JsonDecoder();

  final sub = stdin.transform(utf8.decoder).listen((data) async {
    final jsonData = jsonDecoder.convert(data);
    final start = jsonData['start'] ?? 0;
    final content = jsonData['content'] ?? '';
    final line = jsonData['line'] ?? 0;
    final character = jsonData['character'] ?? 0;
    final filename = jsonData['filename'] ?? '';
    try {
      final linter = Linter(
        tree: Tree(
          content: content,
          start: start,
          startPos: Position(
            line: line,
            character: character,
          ),
          filename: filename,
        ),
        context: LinterContext(filename: filename, content: content),
      );

      final result = await linter.lint();

      stdout.write(json.encode({'filename': filename, 'result': result}));
    } on NodeException catch (e) {
      stdout.write(
        jsonEncoder.convert({
          'filename': filename,
          'result': {
            'isException': true,
            'start': e.startPos.toJson(),
            'end': e.endPos.toJson(),
            'message': e.toString(),
          }
        }),
      );
    } catch (e) {
      stdout.write(
        jsonEncoder.convert({
          'filename': filename,
          'result': {
            'isException': true,
            'start': {'line': 0, 'character': 0},
            'end': {'line': 0, 'character': 0},
            'message': e.toString(),
          }
        }),
      );
    }
  });

  sub.onDone(() {
    exit(0);
  });
}
