// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/channel/lsp_byte_stream_channel.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:path/path.dart';

import '../../lsp/server_abstract.dart';

class AbstractLspAnalysisServerIntegrationTest
    with
        ResourceProviderMixin,
        ClientCapabilitiesHelperMixin,
        LspAnalysisServerTestMixin {
  LspServerClient client;

  final Map<int, Completer<ResponseMessage>> _completers = {};

  @override
  Stream<Message> get serverToClient => client.serverToClient;

  @override
  void sendNotificationToServer(NotificationMessage notification) =>
      client.channel.sendNotification(notification);

  @override
  Future<ResponseMessage> sendRequestToServer(RequestMessage request) {
    final completer = new Completer<ResponseMessage>();
    final id = request.id.map(
        (num) => num, (string) => throw 'String IDs not supported in tests');
    _completers[id] = completer;

    client.channel.sendRequest(request);

    return completer.future;
  }

  @override
  void sendResponseToServer(ResponseMessage response) =>
      client.channel.sendResponse(response);

  Future setUp() async {
    client = new LspServerClient();
    await client.start();
    client.serverToClient.listen((message) {
      if (message is ResponseMessage) {
        final id = message.id.map((num) => num,
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

  tearDown() {
    // TODO(dantup): Graceful shutdown?
    client.close();
  }
}

class LspServerClient {
  Process _process;
  LspByteStreamServerChannel channel;
  final StreamController<Message> _serverToClient =
      new StreamController<Message>.broadcast();

  Future<int> get exitCode => _process.exitCode;

  Stream<Message> get serverToClient => _serverToClient.stream;

  void close() {
    channel.close();
    _process.kill();
  }

  /**
   * Find the root directory of the analysis_server package by proceeding
   * upward to the 'test' dir, and then going up one more directory.
   */
  String findRoot(String pathname) {
    while (!['benchmark', 'test'].contains(basename(pathname))) {
      String parent = dirname(pathname);
      if (parent.length >= pathname.length) {
        throw new Exception("Can't find root directory");
      }
      pathname = parent;
    }
    return dirname(pathname);
  }

  Future start() async {
    if (_process != null) {
      throw new Exception('Process already started');
    }

    String dartBinary = Platform.executable;

    // TODO(dantup): The other servers integration tests can run with a snapshot
    // which is much faster - we may wish to investigate doing the same here.
    final rootDir =
        findRoot(Platform.script.toFilePath(windows: Platform.isWindows));
    final serverPath = normalize(join(rootDir, 'bin', 'server.dart'));

    final arguments = [serverPath, '--lsp', '--suppress-analytics'];
    _process = await Process.start(dartBinary, arguments);
    _process.exitCode.then((int code) {
      if (code != 0) {
        // TODO(dantup): Log/fail tests...
      }
    });

    channel = new LspByteStreamServerChannel(
        _process.stdout, _process.stdin, InstrumentationService.NULL_SERVICE);
    channel.listen(_serverToClient.add);
  }
}
