// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

Future<(Object, StackTrace)?> compileWithAnalyzer(
  AnalyzerHelper analyzerHelper,
  String program,
  Uri fileUri,
  int version,
) async {
  try {
    ZoneSpecification specification = new ZoneSpecification(
      print: (_1, _2, _3, String line) {
        // Swallow!
      },
    );
    await runZoned(() async {
      Stopwatch stopwatch = new Stopwatch()..start();
      await analyzerHelper.changeFileContent(fileUri, program, version);
      print("Analyzer compile took ${stopwatch.elapsedMilliseconds} ms.");
    }, zoneSpecification: specification);
    return null;
  } catch (e, st) {
    print("Analyzer crashed on input.");
    return (e, st);
  }
}

Future<void> main() async {
  AnalyzerHelper analyzerHelper = new AnalyzerHelper();
  Directory root = Directory.systemTemp.createTempSync("fuzzer");
  File f = new File.fromUri(root.uri.resolve("testfile.dart"));
  f.writeAsStringSync("");
  int version = 1;

  await analyzerHelper.setup(root.uri);

  await analyzerHelper.changeFileContent(
    f.uri,
    "void main() { foo; }",
    version++,
  );

  await analyzerHelper.changeFileContent(f.uri, "void main() { }", version++);

  await analyzerHelper.changeFileContent(
    f.uri,
    "void main() { foo; } get foo => 42; ",
    version++,
  );

  analyzerHelper.shutdown();
  root.deleteSync(recursive: true);
}

class AnalyzerHelper {
  static const bool debug = false;
  static const int _printSizeCap = 300;
  late final Process _p;
  late final Timer _periodicTimer;
  bool _processShutDown = false;
  bool _processExited = false;

  Future<void> setup(Uri rootUri) async {
    _checkCorrectDart();
    Uri sdkUri = Uri.base
        .resolveUri(Uri.file(Platform.resolvedExecutable))
        .resolve("..");
    if (!Directory.fromUri(rootUri).existsSync()) {
      throw "Directory $rootUri doesn't exist. "
          "Specify existing directory with --root=";
    }

    if (!Directory.fromUri(sdkUri).existsSync()) {
      throw "Directory $sdkUri doesn't exist. "
          "Specify existing directory with --sdk=";
    }

    if (!debug) {
      _p = await Process.start(Platform.resolvedExecutable, [
        "language-server",
        "--lsp",
      ]);
    } else {
      _p = await Process.start(Platform.resolvedExecutable, [
        "--enable-vm-service",
        "--profiler",
        "pkg/analysis_server/bin/server.dart",
        "--lsp",
        "--port=9101",
      ]);
    }
    // ignore: unawaited_futures
    _p.exitCode.then((_) {
      _processExited = true;
      if (!_processShutDown) {
        shutdown();
        // Make sure we don't wait forever.
        _setAnalyzing(false);
      }
    });
    _p.stdout.listen(_listenToStdout);
    _periodicTimer = Timer.periodic(
      const Duration(seconds: 1),
      _checkLongRunningRequests,
    );
    await _initialize(sdkUri, rootUri, []);
  }

  void shutdown() {
    _processShutDown = true;
    _periodicTimer.cancel();
    _p.kill();
  }

  Future<void> _initialize(
    Uri sdkUri,
    Uri rootUri,
    List<Uri> additionalWorkspaceUris,
  ) async {
    OutstandingRequest? request = await _send(
      Messages.initMessage(pid, rootUri, additionalWorkspaceUris),
    );
    await request?.completer.future;
    _resetAnalyzingBool();
    await _send(Messages.initNotification);
    await _send(Messages.initMore(sdkUri));
    await _waitForAnalysisToComplete();
  }

  Set<Uri> _openFiles = {};

  Future<void> changeFileContent(
    Uri file,
    String newContent,
    int fileVersion,
  ) async {
    _resetAnalyzingBool();
    if (_openFiles.add(file)) {
      await _send(Messages.openFile(file, fileVersion, newContent));
    } else {
      await _send(Messages.changeFileContent(file, newContent, fileVersion));
    }

    await _waitForAnalysisToComplete();
  }

  void _checkCorrectDart() {
    Uri exe = Uri.base.resolveUri(Uri.file(Platform.resolvedExecutable));
    Uri librariesDart = exe.resolve(
      "../lib/_internal/sdk_library_metadata/lib/libraries.dart",
    );
    if (!File.fromUri(librariesDart).existsSync()) {
      throw "Execute with a dart that has "
          "'../lib/_internal/sdk_library_metadata/lib/libraries.dart' "
          "available (e.g. out/ReleaseX64/dart-sdk/bin/dart)";
    }
  }

  void _checkLongRunningRequests(timer) {
    bool reportedSomething = false;
    for (MapEntry<int, OutstandingRequest> waitingFor
        in _outstandingRequestsWithId.entries) {
      if (waitingFor.value.stopwatch.elapsed > const Duration(seconds: 1)) {
        if (!reportedSomething) {
          print("----");
          reportedSomething = true;
        }
        print(
          "==> Has been waiting for ${waitingFor.key} for "
          "${waitingFor.value.stopwatch.elapsed}",
        );
      }
    }
    if (reportedSomething) {
      print("----");
    }
  }

  int? _headerContentLength;

  bool? _currentlyAnalyzing;
  Completer<void> _analyzingCompleter = Completer();

  final _buffer = <int>[];

  /// There's something weird about getting (several) id 3's that wasn't
  /// requested...
  int _largestIdSeen = 3;

  RegExp _newLineRegExp = RegExp("\r?\n");

  Map<int, OutstandingRequest> _outstandingRequestsWithId = {};

  bool _printedVmServiceStuff = false;

  int _verbosity = 0;

  void _setAnalyzing(bool b) {
    _analyzingCompleter.complete(b);
    _currentlyAnalyzing = b;
    _analyzingCompleter = Completer<bool>();
  }

  void _resetAnalyzingBool() {
    _currentlyAnalyzing = null;
  }

  Future<void> _waitForAnalysisToComplete() async {
    // Wait until it's done analyzing.
    if (_currentlyAnalyzing == null) {
      await _analyzingCompleter.future;
    }
    Stopwatch stopwatch = Stopwatch()..start();
    while (_currentlyAnalyzing == true) {
      await _analyzingCompleter.future;
    }
    print("isAnalyzing is now done after ${stopwatch.elapsed}");
    if (_processExited) {
      // TODO(jensj): We should extract the correct stacktrace somehow.
      throw "Process exited.";
    }
  }

  void _listenToStdout(List<int> event) {
    // General idea taken from
    // pkg/analysis_server/lib/src/lsp/lsp_packet_transformer.dart
    for (int element in event) {
      _buffer.add(element);
      if (_verbosity > 3 &&
          _buffer.length >= 1000 &&
          _buffer.length % 1000 == 0) {
        print(
          "DEBUG MESSAGE: Stdout buffer with length "
          "${_buffer.length} so far: "
          "${utf8.decode(_buffer)}",
        );
      }
      if (_headerContentLength == null && _endsWithCrLfCrLf()) {
        String headerRaw = utf8.decode(_buffer);
        _buffer.clear();
        // Use a regex that makes the "\r" optional to handle "The Dart VM
        // service is listening on [..." message - at least on linux - being \n
        // terminated which would otherwise mean that we'd be stuck because no
        // message would start with "Content-Length:".
        List<String> headers = headerRaw.split(_newLineRegExp);
        for (String header in headers) {
          if (!_printedVmServiceStuff &&
              header.startsWith("The Dart VM service")) {
            print("\n\n$header\n\n");
            _printedVmServiceStuff = true;
          }
          if (header.startsWith("Content-Length:")) {
            String contentLength = header
                .substring("Content-Length:".length)
                .trim();
            _headerContentLength = int.parse(contentLength);
            break;
          }
        }
      } else if (_headerContentLength != null &&
          _buffer.length == _headerContentLength!) {
        String messageString = utf8.decode(_buffer);
        _buffer.clear();
        _headerContentLength = null;
        Map<String, dynamic> message =
            json.decode(messageString) as Map<String, dynamic>;

        // {"jsonrpc":"2.0","method":"$/analyzerStatus","params":{"isAnalyzing":false}}
        dynamic method = message["method"];
        if (method == r"$/analyzerStatus") {
          dynamic params = message["params"];
          if (params is Map) {
            dynamic isAnalyzing = params["isAnalyzing"];
            if (isAnalyzing is bool) {
              _setAnalyzing(isAnalyzing);
              if (_verbosity > 0) {
                print("Got analyzerStatus isAnalyzing = $isAnalyzing");
              }
            }
          }
        }
        dynamic possibleId = message["id"];
        if (possibleId is int) {
          if (possibleId > _largestIdSeen) {
            _largestIdSeen = possibleId;
          }

          if (_verbosity > 0) {
            if (messageString.length > _printSizeCap) {
              print(
                "Got message "
                "${messageString.substring(0, _printSizeCap)}...",
              );
            } else {
              print("Got message $messageString");
            }
          }

          OutstandingRequest? outstandingRequest = _outstandingRequestsWithId
              .remove(possibleId);
          if (outstandingRequest != null) {
            outstandingRequest.stopwatch.stop();
            outstandingRequest.completer.complete(message);
            if (_verbosity > 2) {
              print(
                " => Got response for $possibleId in "
                "${outstandingRequest.stopwatch.elapsed}",
              );
            }
          }
        } else if (_verbosity > 1) {
          if (messageString.length > _printSizeCap) {
            print(
              "Got message "
              "${messageString.substring(0, _printSizeCap)}...",
            );
          } else {
            print("Got message $messageString");
          }
        }
      }
    }
  }

  Future<OutstandingRequest?> _send(Map<String, dynamic> json) async {
    if (_processExited) throw "Process is gone.";
    // Mostly copied from
    // pkg/analysis_server/lib/src/lsp/channel/lsp_byte_stream_channel.dart
    String jsonEncodedBody = jsonEncode(json);
    Uint8List utf8EncodedBody = utf8.encode(jsonEncodedBody);
    String header =
        "Content-Length: ${utf8EncodedBody.length}\r\n"
        "Content-Type: application/vscode-jsonrpc; charset=utf-8\r\n\r\n";
    Uint8List asciiEncodedHeader = ascii.encode(header);

    OutstandingRequest? result;

    dynamic possibleId = json["id"];
    if (possibleId is int) {
      if (possibleId > _largestIdSeen) {
        _largestIdSeen = possibleId;
      }
      result = OutstandingRequest();
      _outstandingRequestsWithId[possibleId] = result;
      if (_verbosity > 2) {
        print("Sending message with id $possibleId");
      }
    }

    // Header is always ascii, body is always utf8!
    _p.stdin.add(asciiEncodedHeader);
    _p.stdin.add(utf8EncodedBody);
    await _p.stdin.flush();
    if (_verbosity > 2) {
      print("\n\nMessage sent...\n\n");
      print("jsonEncodedBody: $jsonEncodedBody");
    }
    return result;
  }

  /// Copied from pkg/analysis_server/lib/src/lsp/lsp_packet_transformer.dart.
  bool _endsWithCrLfCrLf() {
    int l = _buffer.length;
    return l > 4 &&
        _buffer[l - 1] == 10 &&
        _buffer[l - 2] == 13 &&
        _buffer[l - 3] == 10 &&
        _buffer[l - 4] == 13;
  }
}

class Location {
  final Uri uri;
  final int line;
  final int column;

  Location(this.uri, this.line, this.column);

  @override
  String toString() => "Location[$uri:$line:$column]";
}

// Messages taken from what VSCode sent.
class Messages {
  static Map<String, dynamic> initNotification = {
    "jsonrpc": "2.0",
    "method": "initialized",
    "params": {},
  };

  static Map<String, dynamic> gotoDef(int id, Location location) {
    return {
      "jsonrpc": "2.0",
      "id": id,
      "method": "textDocument/definition",
      "params": {
        "textDocument": {"uri": "${location.uri}"},
        "position": {"line": location.line, "character": location.column},
      },
    };
  }

  static Map<String, dynamic> implementation(int id, Location location) {
    return {
      "jsonrpc": "2.0",
      "id": id,
      "method": "textDocument/implementation",
      "params": {
        "textDocument": {"uri": "${location.uri}"},
        "position": {"line": location.line, "character": location.column},
      },
    };
  }

  static Map<String, dynamic> initMessage(
    int processId,
    Uri rootUri,
    List<Uri> additionalWorkspaceUris,
  ) {
    String rootPath = rootUri.toFilePath();
    String name = rootUri.pathSegments.last;
    if (name.isEmpty) {
      name = rootUri.pathSegments[rootUri.pathSegments.length - 2];
    }
    return {
      "id": 0,
      "jsonrpc": "2.0",
      "method": "initialize",
      "params": {
        "processId": processId,
        "clientInfo": {"name": "lspTestScript", "version": "0.0.1"},
        "locale": "en",
        "rootPath": rootPath,
        "rootUri": "$rootUri",
        "capabilities": {},
        "initializationOptions": {},
        "workspaceFolders": [
          {"uri": "$rootUri", "name": name},
          ...additionalWorkspaceUris.map((uri) {
            String name = uri.pathSegments.last;
            if (name.isEmpty) {
              name = uri.pathSegments[uri.pathSegments.length - 2];
            }
            return {"uri": "$uri", "name": name};
          }),
        ],
      },
    };
  }

  static Map<String, dynamic> initMore(Uri sdkUri) {
    String sdkPath = sdkUri.toFilePath();
    return {
      // "id": 1,
      "jsonrpc": "2.0",
      "result": [
        {"useLsp": true, "sdkPath": sdkPath, "allowAnalytics": false},
      ],
    };
  }

  static Map<String, dynamic> references(int id, Location location) {
    return {
      "jsonrpc": "2.0",
      "id": id,
      "method": "textDocument/references",
      "params": {
        "textDocument": {"uri": "${location.uri}"},
        "position": {"line": location.line, "character": location.column},
        "context": {"includeDeclaration": true},
      },
    };
  }

  static Map<String, dynamic> openFile(
    Uri file,
    int fileVersion,
    String content,
  ) {
    return {
      "jsonrpc": "2.0",
      "method": "textDocument/didOpen",
      "params": {
        "textDocument": {
          "uri": "$file",
          "languageId": "dart",
          "version": fileVersion,
          "text": content,
        },
      },
    };
  }

  static Map<String, dynamic> changeFileContent(
    Uri file,
    String newContent,
    int fileVersion,
  ) {
    return {
      "jsonrpc": "2.0",
      "method": "textDocument/didChange",
      "params": {
        "textDocument": {"uri": "$file", "version": fileVersion},
        "contentChanges": [
          {"text": newContent},
        ],
      },
    };
  }
}

class OutstandingRequest {
  final Stopwatch stopwatch = Stopwatch();
  final Completer<Map<String, dynamic>> completer = Completer();
  OutstandingRequest() {
    stopwatch.start();
  }
}
