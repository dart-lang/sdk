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
import 'package:analyzer_plugin/src/utilities/client_uri_converter.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../../constants.dart';
import '../../lsp/request_helpers_mixin.dart';
import '../../lsp/server_abstract.dart';
import '../../support/sdk_paths.dart';

abstract class AbstractLspAnalysisServerIntegrationTest
    with
        ClientCapabilitiesHelperMixin,
        LspRequestHelpersMixin,
        LspReverseRequestHelpersMixin,
        LspNotificationHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin,
        LspAnalysisServerTestMixin {
  final List<String> vmArgs = [];
  LspServerClient? client;
  InstrumentationService? instrumentationService;
  final Map<num, Completer<ResponseMessage>> _completers = {};
  String dartSdkPath = path.dirname(path.dirname(Platform.resolvedExecutable));

  @override
  late final ClientUriConverter uriConverter = ClientUriConverter.noop(
    pathContext,
  );

  /// Tracks the current overlay content so that when we apply edits they can
  /// be applied in the same way a real client would apply them.
  final _overlayContent = <Uri, String>{};

  LspByteStreamServerChannel get channel => client!.channel!;

  @override
  path.Context get pathContext => PhysicalResourceProvider.INSTANCE.pathContext;

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
    RequestMessage request,
    T Function(R) fromJson,
  ) async {
    var resp = await sendRequestToServer(request);
    var error = resp.error;
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
    var completer = Completer<ResponseMessage>();
    var id = request.id.map(
      (number) => number,
      (string) => throw 'String IDs not supported in tests',
    );
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
    projectFolderPath =
        Directory.systemTemp
            .createTempSync('analysisServer')
            .resolveSymbolicLinksSync();
    newFolder(projectFolderPath);
    newFolder(path.join(projectFolderPath, 'lib'));
    mainFilePath = path.join(projectFolderPath, 'lib', 'main.dart');
    analysisOptionsPath = path.join(projectFolderPath, 'analysis_options.yaml');

    var client = LspServerClient(instrumentationService);
    this.client = client;
    await client.start(dartSdkPath: dartSdkPath, vmArgs: vmArgs);
    client.serverToClient.listen((message) {
      if (message is ResponseMessage) {
        var id = message.id!.map(
          (number) => number,
          (string) => throw 'String IDs not supported in tests',
        );

        var completer = _completers[id];
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

  path.Context get pathContext => PhysicalResourceProvider.INSTANCE.pathContext;

  Stream<Message> get serverToClient => _serverToClient.stream;

  void close() {
    channel?.close();
    _process?.kill();
  }

  Future<void> start({
    required String dartSdkPath,
    List<String>? vmArgs,
  }) async {
    if (_process != null) {
      throw Exception('Process already started');
    }

    var dartBinary = path.join(dartSdkPath, 'bin', 'dart');
    var serverPath = await getAnalysisServerPath(dartSdkPath);

    var arguments = [...?vmArgs, serverPath, '--lsp', '--suppress-analytics'];
    var process = await Process.start(
      dartBinary,
      arguments,
      environment: {PubCommand.disablePubCommandEnvironmentKey: 'true'},
    );
    _process = process;
    unawaited(
      process.exitCode.then((int code) {
        if (code != 0) {
          // TODO(dantup): Log/fail tests...
        }
      }),
    );

    // If the server writes to stderr, fail tests with a more useful message
    // (rather than having the test just hang waiting for a response).
    process.stderr.listen((data) {
      var message = String.fromCharCodes(data);
      throw 'Analysis Server wrote to stderr:\n\n$message';
    });

    var inputStream = _extractDevToolsLine(process.stdout);
    var outputStream = process.stdin;

    channel = LspByteStreamServerChannel(
      inputStream,
      outputStream,
      instrumentationService ?? InstrumentationLogAdapter(PrintableLogger()),
    )..listen(_serverToClient.add);
  }

  /// Checks the first line in the [input], and if it is the DevTools URI
  /// line, completes [devToolsLine] with it, and excludes it from the sink.
  /// Otherwise, and after the first line, passes data to the sink.
  Stream<List<int>> _extractDevToolsLine(Stream<List<int>> input) {
    var buffer = <int>[];
    return input.transform(
      StreamTransformer.fromHandlers(
        handleData: (bytes, sink) {
          if (_firstLineChecked) {
            sink.add(bytes);
          } else {
            buffer.addAll(bytes);
            var lineFeedIndex = buffer.indexOf(0x0A);
            if (lineFeedIndex != -1) {
              _firstLineChecked = true;
              var lineBytes = buffer.sublist(0, lineFeedIndex);
              var line = utf8.decode(lineBytes);
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
  bool _printLogs = debugPrintCommunication;
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
