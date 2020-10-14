// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/channel/lsp_byte_stream_channel.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:path/path.dart';

import '../../lsp/server_abstract.dart';

class AbstractLspAnalysisServerIntegrationTest
    with ClientCapabilitiesHelperMixin, LspAnalysisServerTestMixin {
  LspServerClient client;

  final Map<int, Completer<ResponseMessage>> _completers = {};

  @override
  Stream<Message> get serverToClient => client.serverToClient;

  /// Sends a request to the server and unwraps the result. Throws if the
  /// response was not successful or returned an error.
  @override
  Future<T> expectSuccessfulResponseTo<T, R>(
      RequestMessage request, T Function(R) fromJson) async {
    final resp = await sendRequestToServer(request);
    if (resp.error != null) {
      throw resp.error;
    } else if (T == Null) {
      return resp.result == null
          ? null
          : throw 'Expected Null response but got ${resp.result}';
    } else {
      return fromJson(resp.result);
    }
  }

  void newFile(String path, {String content}) =>
      File(path).writeAsStringSync(content ?? '');

  void newFolder(String path) => Directory(path).createSync(recursive: true);

  @override
  void sendNotificationToServer(NotificationMessage notification) =>
      client.channel.sendNotification(notification);

  @override
  Future<ResponseMessage> sendRequestToServer(RequestMessage request) {
    final completer = Completer<ResponseMessage>();
    final id = request.id.map((number) => number,
        (string) => throw 'String IDs not supported in tests');
    _completers[id] = completer;

    client.channel.sendRequest(request);

    return completer.future;
  }

  @override
  void sendResponseToServer(ResponseMessage response) =>
      client.channel.sendResponse(response);

  Future setUp() async {
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

    client = LspServerClient();
    await client.start();
    client.serverToClient.listen((message) {
      if (message is ResponseMessage) {
        final id = message.id.map((number) => number,
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
    client.close();
  }
}

class LspServerClient {
  Process _process;
  LspByteStreamServerChannel channel;
  final StreamController<Message> _serverToClient =
      StreamController<Message>.broadcast();

  Future<int> get exitCode => _process.exitCode;

  Stream<Message> get serverToClient => _serverToClient.stream;

  void close() {
    channel.close();
    _process.kill();
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

  Future start() async {
    if (_process != null) {
      throw Exception('Process already started');
    }

    var dartBinary = Platform.executable;

    var useSnapshot = true;
    String serverPath;

    if (useSnapshot) {
      // Look for snapshots/analysis_server.dart.snapshot.
      serverPath = normalize(join(dirname(Platform.resolvedExecutable),
          'snapshots', 'analysis_server.dart.snapshot'));

      if (!FileSystemEntity.isFileSync(serverPath)) {
        // Look for dart-sdk/bin/snapshots/analysis_server.dart.snapshot.
        serverPath = normalize(join(dirname(Platform.resolvedExecutable),
            'dart-sdk', 'bin', 'snapshots', 'analysis_server.dart.snapshot'));
      }
    } else {
      final rootDir =
          findRoot(Platform.script.toFilePath(windows: Platform.isWindows));
      serverPath = normalize(join(rootDir, 'bin', 'server.dart'));
    }

    final arguments = [serverPath, '--lsp', '--suppress-analytics'];
    _process = await Process.start(dartBinary, arguments);
    _process.exitCode.then((int code) {
      if (code != 0) {
        // TODO(dantup): Log/fail tests...
      }
    });

    // If the server writes to stderr, fail tests with a more useful message
    // (rather than having the test just hang waiting for a response).
    _process.stderr.listen((data) {
      final message = String.fromCharCodes(data);
      throw 'Analysis Server wrote to stderr:\n\n$message';
    });

    channel = LspByteStreamServerChannel(
        _process.stdout, _process.stdin, InstrumentationService.NULL_SERVICE);
    channel.listen(_serverToClient.add);
  }
}
