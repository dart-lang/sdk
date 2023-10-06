// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/channel/lsp_byte_stream_channel.dart';
import 'package:analysis_server/src/services/pub/pub_command.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';

import '../../lsp/request_helpers_mixin.dart';
import '../../lsp/server_abstract.dart';

abstract class AbstractLspAnalysisServerIntegrationTest
    with
        ClientCapabilitiesHelperMixin,
        LspRequestHelpersMixin,
        LspEditHelpersMixin,
        LspAnalysisServerTestMixin {
  final List<String> vmArgs = [];
  LspServerClient? client;
  InstrumentationService? instrumentationService;
  final Map<num, Completer<ResponseMessage>> _completers = {};
  String dartSdkPath = dirname(dirname(Platform.resolvedExecutable));

  /// Tracks the current overlay content so that when we apply edits they can
  /// be applied in the same way a real client would apply them.
  final _overlayContent = <Uri, String>{};

  LspByteStreamServerChannel get channel => client!.channel!;

  @override
  Context get pathContext => PhysicalResourceProvider.INSTANCE.pathContext;

  @override
  Stream<Message> get serverToClient => client!.serverToClient;

  @override
  Future<void> closeFile(Uri uri) {
    _overlayContent.remove(uri);
    return super.closeFile(uri);
  }

  /// Sends a request to the server and unwraps the result. Throws if the
  /// response was not successful or returned an error.
  @override
  Future<T> expectSuccessfulResponseTo<T, R>(
      RequestMessage request, T Function(R) fromJson) async {
    final resp = await sendRequestToServer(request);
    final error = resp.error;
    if (error != null) {
      throw error;
    } else if (T == Null) {
      return resp.result == null
          ? null as T
          : throw 'Expected Null response but got ${resp.result}';
    } else {
      return fromJson(resp.result as R);
    }
  }

  @override
  String? getCurrentFileContent(Uri uri) {
    // First try and overlay the test has set.
    if (_overlayContent.containsKey(uri)) {
      return _overlayContent[uri];
    }

    // Otherwise fall back to the disk.
    try {
      return File(uri.toFilePath()).readAsStringSync();
    } catch (_) {
      return null;
    }
  }

  void newFile(String path, String content) =>
      File(path).writeAsStringSync(content);

  void newFolder(String path) => Directory(path).createSync(recursive: true);

  @override
  Future<void> openFile(Uri uri, String content, {int version = 1}) {
    _overlayContent[uri] = content;
    return super.openFile(uri, content, version: version);
  }

  @override
  Future<void> replaceFile(int newVersion, Uri uri, String content) {
    _overlayContent[uri] = content;
    return super.replaceFile(newVersion, uri, content);
  }

  @override
  void sendNotificationToServer(NotificationMessage notification) =>
      channel.sendNotification(notification);

  @override
  Future<ResponseMessage> sendRequestToServer(RequestMessage request) {
    final completer = Completer<ResponseMessage>();
    final id = request.id.map((number) => number,
        (string) => throw 'String IDs not supported in tests');
    _completers[id] = completer;

    channel.sendRequest(request);

    return completer.future;
  }

  @override
  void sendResponseToServer(ResponseMessage response) =>
      channel.sendResponse(response);

  @mustCallSuper
  Future<void> setUp() async {
    // Set up temporary folder for the test.
    projectFolderPath = Directory.systemTemp
        .createTempSync('analysisServer')
        .resolveSymbolicLinksSync();
    newFolder(projectFolderPath);
    newFolder(join(projectFolderPath, 'lib'));
    projectFolderUri = Uri.file(projectFolderPath);
    mainFilePath = join(projectFolderPath, 'lib', 'main.dart');
    mainFileUri = Uri.file(mainFilePath);
    analysisOptionsPath = join(projectFolderPath, 'analysis_options.yaml');
    analysisOptionsUri = Uri.file(analysisOptionsPath);

    final client = LspServerClient(instrumentationService);
    this.client = client;
    await client.start(dartSdkPath: dartSdkPath, vmArgs: vmArgs);
    client.serverToClient.listen((message) {
      if (message is ResponseMessage) {
        final id = message.id!.map((number) => number,
            (string) => throw 'String IDs not supported in tests');

        final completer = _completers[id];
        if (completer == null) {
          throw 'Response with ID $id was unexpected';
        } else {
          _completers.remove(id);
          completer.complete(message);
        }
      }
    });
  }

  void tearDown() {
    // TODO(dantup): Graceful shutdown?
    client?.close();
  }
}

class LspServerClient {
  final InstrumentationService? instrumentationService;
  Process? _process;
  LspByteStreamServerChannel? channel;
  final StreamController<Message> _serverToClient =
      StreamController<Message>.broadcast();

  /// Whether the first line of output from the server was already checked.
  bool _firstLineChecked = false;

  /// If the first line of output turned out to be the DevTools URI line,
  /// these whole line is used for this completer.
  final Completer<String> _devToolsLineCompleter = Completer<String>();

  LspServerClient(this.instrumentationService);

  /// Completes with the DevTools URI line, maybe never.
  Future<String> get devToolsLine => _devToolsLineCompleter.future;

  Future<int> get exitCode => _process!.exitCode;

  Context get pathContext => PhysicalResourceProvider.INSTANCE.pathContext;

  Stream<Message> get serverToClient => _serverToClient.stream;

  void close() {
    channel?.close();
    _process?.kill();
  }

  /// Find the root directory of the analysis_server package by proceeding
  /// upward to the 'test' dir, and then going up one more directory.
  String findRoot(String pathname) {
    while (!['benchmark', 'test'].contains(basename(pathname))) {
      var parent = dirname(pathname);
      if (parent.length >= pathname.length) {
        throw Exception("Can't find root directory");
      }
      pathname = parent;
    }
    return dirname(pathname);
  }

  Future<void> start({
    required String dartSdkPath,
    List<String>? vmArgs,
  }) async {
    if (_process != null) {
      throw Exception('Process already started');
    }

    var dartBinary = join(dartSdkPath, 'bin', 'dart');

    // Setting the `TEST_SERVER_SNAPSHOT` env var to 'false' will disable the
    // snapshot and run from source.
    var useSnapshot = Platform.environment['TEST_SERVER_SNAPSHOT'] != 'false';
    String serverPath;

    if (useSnapshot) {
      serverPath = normalize(join(
          dartSdkPath, 'bin', 'snapshots', 'analysis_server.dart.snapshot'));
    } else {
      final rootDir =
          findRoot(Platform.script.toFilePath(windows: Platform.isWindows));
      serverPath = normalize(join(rootDir, 'bin', 'server.dart'));
    }

    final arguments = [
      ...?vmArgs,
      serverPath,
      '--lsp',
      '--suppress-analytics',
    ];
    final process = await Process.start(
      dartBinary,
      arguments,
      environment: {PubCommand.disablePubCommandEnvironmentKey: 'true'},
    );
    _process = process;
    unawaited(process.exitCode.then((int code) {
      if (code != 0) {
        // TODO(dantup): Log/fail tests...
      }
    }));

    // If the server writes to stderr, fail tests with a more useful message
    // (rather than having the test just hang waiting for a response).
    process.stderr.listen((data) {
      final message = String.fromCharCodes(data);
      throw 'Analysis Server wrote to stderr:\n\n$message';
    });

    final inputStream = _extractDevToolsLine(process.stdout);

    channel = LspByteStreamServerChannel(inputStream, process.stdin,
        instrumentationService ?? InstrumentationService.NULL_SERVICE)
      ..listen(_serverToClient.add);
  }

  /// Checks the first line in the [input], and if it is the DevTools URI
  /// line, completes [devToolsLine] with it, and excludes it from the sink.
  /// Otherwise, and after the first line, passes data to the sink.
  Stream<List<int>> _extractDevToolsLine(Stream<List<int>> input) {
    final buffer = <int>[];
    return input.transform(
      StreamTransformer.fromHandlers(
        handleData: (bytes, sink) {
          if (_firstLineChecked) {
            sink.add(bytes);
          } else {
            buffer.addAll(bytes);
            final lineFeedIndex = buffer.indexOf(0x0A);
            if (lineFeedIndex != -1) {
              _firstLineChecked = true;
              final lineBytes = buffer.sublist(0, lineFeedIndex);
              final line = utf8.decode(lineBytes);
              if (line.startsWith('The Dart DevTools')) {
                _devToolsLineCompleter.complete(line);
                sink.add(buffer.sublist(lineFeedIndex + 1));
              } else {
                sink.add(buffer);
              }
            }
          }
        },
      ),
    );
  }
}

/// An [InstrumentationLogger] that buffers logs until [debugStdio()] is called.
class PrintableLogger extends InstrumentationLogger {
  bool _printLogs = false;
  final _buffer = StringBuffer();

  void debugStdio() {
    print(_buffer.toString());
    _buffer.clear();
    _printLogs = true;
  }

  @override
  void log(String message) {
    if (_printLogs) {
      print(message);
    } else {
      _buffer.writeln(message);
    }
  }

  @override
  Future<void> shutdown() async {
    _printLogs = false;
    _buffer.clear();
  }
}
