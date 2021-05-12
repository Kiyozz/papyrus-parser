import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:papyrus/linter.dart';
import 'package:papyrus/ast.dart';

void main(List<String> arguments) async {
  const port = 54800;
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
  final scanner = const Scanner();

  print('Server listening on ${server.address.address}:$port');

  server.listen((client) {
    print(
      'Connection from '
      '${client.remoteAddress.address}:${client.remotePort}',
    );

    StreamSubscription<Map<String, dynamic>>? subscription;

    client.listen(
      (dynamic chars) async {
        final message = String.fromCharCodes(chars);
        final watch = Stopwatch()..start();
        final data = message.split(';-[papyruslint]-;');
        final filename = data.first;

        await subscription?.cancel();

        final problems = scanner.problemsIn(
          text: data.last,
          filename: filename,
        );
        final scannerSubscription = problems.listen(
          (result) {
            print('Lint took: ${watch.elapsedMilliseconds}ms');
            watch.stop();
            client.write(json.encode({'filename': filename, 'result': result}));
          },
          onError: (e, stack) {
            watch.stop();
            if (e is NodeException) {
              client.write(json.encode({
                'filename': filename,
                'result': {
                  'isException': true,
                  'start': e.startPos.toJson(),
                  'end': e.endPos.toJson(),
                  'message': e.toString(),
                }
              }));
            } else {
              print(stack);

              client.write(json.encode({
                'filename': filename,
                'result': {
                  'isException': true,
                  'start': {'line': 0, 'character': 0},
                  'end': {'line': 0, 'character': 0},
                  'message': e.toString(),
                }
              }));
            }
          },
        );

        subscription = scannerSubscription;
      },

      // handle errors
      onError: (error) {
        print(error);
        client.close();
      },

      // handle the client closing the connection
      onDone: () {
        print('Client left');
        client.close();
      },
    );
  });
}
