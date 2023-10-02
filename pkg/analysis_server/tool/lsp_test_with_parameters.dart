// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  print('''
================================================================================
  Stress test tool for language-server protocol.

  Example run:
  out/ReleaseX64/dart-sdk/bin/dart \\
     pkg/analysis_server/tool/lspTestWithParameters.dart \\
     --root=pkg/analysis_server \\
     --sdk=out/ReleaseX64/dart-sdk/ \\
     --click=pkg/analyzer/lib/src/dart/analysis/driver.dart \\
     --line=506 \\
     --column=20

  Additional options:
  -v / --verbose     Be more verbose. Specify several times for more verbosity.
  --verbosity=<int>  Set verbosity directly. Defaults to 0. A higher number is
                     more verbose.
  --every=<int>      Set how often - in ms - to fire an event. Defaults to 100.

================================================================================
''');
  {
    Uri exe = Uri.base.resolve(Platform.resolvedExecutable);
    Uri librariesDart =
        exe.resolve('../lib/_internal/sdk_library_metadata/lib/libraries.dart');
    if (!File.fromUri(librariesDart).existsSync()) {
      throw 'Execute with a dart that has '
          "'../lib/_internal/sdk_library_metadata/lib/libraries.dart' "
          'available (e.g. out/ReleaseX64/dart-sdk/bin/dart)';
    }
  }
  Uri? rootUri;
  Uri? sdkUri;
  Uri? clickOnUri;
  int? clickLine;
  int? clickColumn;
  int everyMs = 100;
  for (String arg in args) {
    if (arg.startsWith('--root=')) {
      rootUri = Uri.base.resolve(arg.substring('--root='.length).trim());
    } else if (arg.startsWith('--sdk=')) {
      sdkUri = Uri.base.resolve(arg.substring('--sdk='.length).trim());
    } else if (arg.startsWith('--click=')) {
      clickOnUri = Uri.base.resolve(arg.substring('--click='.length).trim());
    } else if (arg.startsWith('--line=')) {
      clickLine = int.parse(arg.substring('--line='.length).trim());
    } else if (arg.startsWith('--column=')) {
      clickColumn = int.parse(arg.substring('--column='.length).trim());
    } else if (arg.startsWith('--every=')) {
      everyMs = int.parse(arg.substring('--every='.length).trim());
    } else if (arg == '--verbose' || arg == '-v') {
      verbosity++;
    } else if (arg.startsWith('--verbosity=')) {
      verbosity = int.parse(arg.substring('--verbosity='.length).trim());
    } else {
      throw 'Unknown argument: $arg';
    }
  }

  if (rootUri == null) {
    throw "Didn't get a root uri. Specify with --root=";
  }
  if (!Directory.fromUri(rootUri).existsSync()) {
    throw "Directory $rootUri doesn't exist. "
        'Specify existing directory with --root=';
  }

  if (sdkUri == null) {
    throw "Didn't get a sdk path. Specify with --sdk=";
  }
  if (!Directory.fromUri(sdkUri).existsSync()) {
    throw "Directory $sdkUri doesn't exist. "
        'Specify existing directory with --sdk=';
  }

  if (clickOnUri == null) {
    throw "Didn't get a sdk path. Specify with --click=";
  }
  if (!File.fromUri(clickOnUri).existsSync()) {
    throw "File $clickOnUri doesn't exist. "
        'Specify existing file with --click=';
  }

  if (clickLine == null) {
    throw "Didn't get a line to click on. Specify with --line=";
  }
  if (clickColumn == null) {
    throw "Didn't get a column to click on. Specify with --column=";
  }

  Process p = await Process.start(Platform.resolvedExecutable, [
    'language-server',
  ]);

  p.stdout.listen(listenToStdout);
  Timer.periodic(const Duration(seconds: 1), (timer) {
    bool reportedSomething = false;
    for (MapEntry<int, Stopwatch> waitingFor
        in outstandingRequestsWithId.entries) {
      if (waitingFor.value.elapsed > const Duration(seconds: 1)) {
        if (!reportedSomething) {
          print('----');
          reportedSomething = true;
        }
        print('==> Has been waiting for ${waitingFor.key} for '
            '${waitingFor.value.elapsed}');
      }
    }
    if (reportedSomething) {
      print('----');
    } else {
      print(' -- not waiting for anything -- ');
    }
  });

  await send(p, initMessage(pid, rootUri));
  await receivedCompleter.future;
  await send(p, initNotification);
  await receivedCompleter.future;
  await send(p, initMore(sdkUri));
  await receivedCompleter.future;

  // Try to let it get done...
  await Future.delayed(const Duration(seconds: 2));

  final Duration everyDuration = Duration(milliseconds: everyMs);
  while (true) {
    await send(
        p,
        gotoDef(
          largestIdSeen + 1,
          clickOnUri,
          clickLine,
          clickColumn,
        ));
    await Future.delayed(everyDuration);
  }
}

final buffer = <int>[];

int? headerContentLength;

Map<String, dynamic> initNotification = {
  'jsonrpc': '2.0',
  'method': 'initialized',
  'params': {}
};

/// There's something weird about getting (several) id 3's that wasn't
/// requested...
int largestIdSeen = 3;
Map<int, Stopwatch> outstandingRequestsWithId = {};
Completer<Map<String, dynamic>> receivedCompleter = Completer();

int verbosity = 0;
Map<String, dynamic> gotoDef(int id, Uri uri, int line, int char) {
  return {
    'jsonrpc': '2.0',
    'id': id,
    'method': 'textDocument/definition',
    'params': {
      'textDocument': {'uri': '$uri'},
      'position': {'line': line, 'character': char}
    }
  };
}

// Messages taken from what VSCode sent.

Map<String, dynamic> initMessage(int processId, Uri rootUri) {
  String rootPath = rootUri.toFilePath();
  String name = rootUri.pathSegments.last;
  if (name.isEmpty) {
    name = rootUri.pathSegments[rootUri.pathSegments.length - 2];
  }
  return {
    'id': 0,
    'jsonrpc': '2.0',
    'method': 'initialize',
    'params': {
      'processId': processId,
      'clientInfo': {'name': 'lspTestScript', 'version': '0.0.1'},
      'locale': 'en',
      'rootPath': rootPath,
      'rootUri': '$rootUri',
      'capabilities': {},
      'initializationOptions': {},
      'workspaceFolders': [
        {'uri': '$rootUri', 'name': rootUri.pathSegments.last}
      ]
    }
  };
}

Map<String, dynamic> initMore(Uri sdkUri) {
  String sdkPath = sdkUri.toFilePath();
  return {
    'id': 1,
    'jsonrpc': '2.0',
    'result': [
      {
        'useLsp': true,
        'sdkPath': sdkPath,
        'allowAnalytics': false,
      }
    ]
  };
}

void listenToStdout(List<int> event) {
  // General idea taken from
  // pkg/analysis_server/lib/src/lsp/lsp_packet_transformer.dart
  for (int element in event) {
    buffer.add(element);
    if (verbosity > 3 && buffer.length % 1000 == 999) {
      print('DEBUG MESSAGE: Stdout buffer with length ${buffer.length} so far: '
          '${utf8.decode(buffer)}');
    }
    if (headerContentLength == null && _endsWithCrLfCrLf()) {
      String headerRaw = utf8.decode(buffer);
      buffer.clear();
      List<String> headers = headerRaw.split('\r\n');
      for (String header in headers) {
        if (header.startsWith('Content-Length:')) {
          String contentLength =
              header.substring('Content-Length:'.length).trim();
          headerContentLength = int.parse(contentLength);
          break;
        }
      }
    } else if (headerContentLength != null &&
        buffer.length == headerContentLength!) {
      String messageString = utf8.decode(buffer);
      buffer.clear();
      headerContentLength = null;
      Map<String, dynamic> message =
          json.decode(messageString) as Map<String, dynamic>;
      dynamic possibleId = message['id'];
      if (possibleId is int) {
        if (possibleId > largestIdSeen) {
          largestIdSeen = possibleId;
        }

        if (verbosity > 0) {
          if (messageString.length > 100) {
            print('Got message ${messageString.substring(0, 100)}...');
          } else {
            print('Got message $messageString');
          }
        }

        Stopwatch? stopwatch = outstandingRequestsWithId.remove(possibleId);
        if (stopwatch != null) {
          stopwatch.stop();
          if (verbosity > 2) {
            print(' => Got response for $possibleId in ${stopwatch.elapsed}');
          }
        }
      } else if (verbosity > 1) {
        if (messageString.length > 100) {
          print('Got message ${messageString.substring(0, 100)}...');
        } else {
          print('Got message $messageString');
        }
      }
      receivedCompleter.complete(message);
      receivedCompleter = Completer();
    }
  }
}

Future<void> send(Process p, Map<String, dynamic> json) async {
  // Mostly copied from
  // pkg/analysis_server/lib/src/lsp/channel/lsp_byte_stream_channel.dart
  final jsonEncodedBody = jsonEncode(json);
  final utf8EncodedBody = utf8.encode(jsonEncodedBody);
  final header = 'Content-Length: ${utf8EncodedBody.length}\r\n'
      'Content-Type: application/vscode-jsonrpc; charset=utf-8\r\n\r\n';
  final asciiEncodedHeader = ascii.encode(header);

  dynamic possibleId = json['id'];
  if (possibleId is int && possibleId > largestIdSeen) {
    largestIdSeen = possibleId;
    outstandingRequestsWithId[possibleId] = Stopwatch()..start();
    if (verbosity > 2) {
      print('Sending message with id $possibleId');
    }
  }

  // Header is always ascii, body is always utf8!
  p.stdin.add(asciiEncodedHeader);
  p.stdin.add(utf8EncodedBody);
  await p.stdin.flush();
  if (verbosity > 2) {
    print('\n\nMessage sent...\n\n');
  }
}

/// Copied from pkg/analysis_server/lib/src/lsp/lsp_packet_transformer.dart.
bool _endsWithCrLfCrLf() {
  var l = buffer.length;
  return l > 4 &&
      buffer[l - 1] == 10 &&
      buffer[l - 2] == 13 &&
      buffer[l - 3] == 10 &&
      buffer[l - 4] == 13;
}
