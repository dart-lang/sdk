// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'io_utils.dart';
import 'messages.dart';

enum LaunchFrom { Source, Dart, Aot }

abstract class LspBenchmark {
  static const int verbosity = 0;
  final Uri repoDir = computeRepoDirUri();
  late final Process p;
  late final Timer longRunningRequestsTimer;
  bool _launched = false;
  Completer<bool> _analyzingCompleter = Completer();
  final _buffer = <int>[];
  int? _headerContentLength;
  bool _printedVmServiceStuff = false;

  /// There's something weird about getting (several) id 3's that wasn't
  /// requested...
  int largestIdSeen = 3;

  final RegExp _newLineRegExp = RegExp('\r?\n');
  final Map<int, OutstandingRequest> _outstandingRequestsWithId = {};

  Duration? firstAnalyzingDuration;

  LspBenchmark() {
    _checkCorrectDart();
  }
  List<Uri> get additionalWorkspaceUris => const [];
  Uri? get cacheFolder => null;
  LaunchFrom get launchFrom => LaunchFrom.Source;

  Uri get rootUri;

  Future<void> afterInitialization();

  void exit() {
    longRunningRequestsTimer.cancel();
    p.kill();
  }

  Future<void> run() async {
    await _launch();
    p.stdout.listen(_listenToStdout);
    p.stderr.listen(stderr.add);
    longRunningRequestsTimer = Timer.periodic(
      const Duration(seconds: 1),
      _checkLongRunningRequests,
    );

    await _initialize(p);
    print('Should now be initialized.');

    await afterInitialization();
  }

  Future<OutstandingRequest?> send(Map<String, dynamic> json) async {
    // Mostly copied from
    // pkg/analysis_server/lib/src/lsp/channel/lsp_byte_stream_channel.dart
    var jsonEncodedBody = jsonEncode(json);
    var utf8EncodedBody = utf8.encode(jsonEncodedBody);
    var header =
        'Content-Length: ${utf8EncodedBody.length}\r\n'
        'Content-Type: application/vscode-jsonrpc; charset=utf-8\r\n\r\n';
    var asciiEncodedHeader = ascii.encode(header);

    OutstandingRequest? result;

    dynamic possibleId = json['id'];
    if (possibleId is int) {
      if (possibleId > largestIdSeen) {
        largestIdSeen = possibleId;
      }
      result = OutstandingRequest();
      _outstandingRequestsWithId[possibleId] = result;
      if (verbosity > 2) {
        print('Sending message with id $possibleId');
      }
    }

    // Header is always ascii, body is always utf8!
    p.stdin.add(asciiEncodedHeader);
    p.stdin.add(utf8EncodedBody);
    await p.stdin.flush();
    if (verbosity > 2) {
      print('\n\nMessage sent\n\n');
    }
    return result;
  }

  Future<void> waitWhileAnalyzing() async {
    // Wait until it's done analyzing.
    bool isAnalyzing = await _analyzingCompleter.future;
    Stopwatch stopwatch = Stopwatch()..start();
    while (isAnalyzing) {
      isAnalyzing = await _analyzingCompleter.future;
    }
    print('isAnalyzing is now done after ${stopwatch.elapsed}');
    firstAnalyzingDuration ??= stopwatch.elapsed;
  }

  void _checkCorrectDart() {
    Uri exe = Uri.base.resolveUri(Uri.file(Platform.resolvedExecutable));
    Uri librariesDart = exe.resolve(
      '../lib/_internal/sdk_library_metadata/lib/libraries.dart',
    );
    if (!File.fromUri(librariesDart).existsSync()) {
      throw 'Execute with a dart that has '
          "'../lib/_internal/sdk_library_metadata/lib/libraries.dart' "
          'available (e.g. out/ReleaseX64/dart-sdk/bin/dart)';
    }
  }

  void _checkLongRunningRequests(timer) {
    bool reportedSomething = false;
    for (MapEntry<int, OutstandingRequest> waitingFor
        in _outstandingRequestsWithId.entries) {
      if (waitingFor.value.stopwatch.elapsed > const Duration(seconds: 1)) {
        if (!reportedSomething) {
          print('----');
          reportedSomething = true;
        }
        print(
          '==> Has been waiting for required #${waitingFor.key} for '
          '${waitingFor.value.stopwatch.elapsed}',
        );
      }
    }
    if (reportedSomething) {
      print('----');
    } else {
      // print(" -- not waiting for anything -- ");
    }
  }

  /// Copied from pkg/analysis_server/lib/src/lsp/lsp_packet_transformer.dart.
  bool _endsWithCrLfCrLf() {
    var l = _buffer.length;
    return l > 4 &&
        _buffer[l - 1] == 10 &&
        _buffer[l - 2] == 13 &&
        _buffer[l - 3] == 10 &&
        _buffer[l - 4] == 13;
  }

  Future<void> _initialize(Process p) async {
    OutstandingRequest? request = await send(
      Messages.initMessage(pid, rootUri, additionalWorkspaceUris),
    );
    await request?.completer.future;
    await send(Messages.initNotification);

    // Wait until it's done analyzing.
    await waitWhileAnalyzing();
  }

  Future<void> _launch() async {
    if (_launched) throw 'Already launched';
    _launched = true;

    List<String> cacheFolderArgs = [];
    if (cacheFolder != null) {
      cacheFolderArgs.add('--cache');
      cacheFolderArgs.add(cacheFolder!.toFilePath());
    }

    switch (launchFrom) {
      case LaunchFrom.Source:
        File serverFile = File.fromUri(
          repoDir.resolve('pkg/analysis_server/bin/server.dart'),
        );
        if (!serverFile.existsSync()) {
          throw "Couldn't find 'analysis_server/bin/server.dart' "
              'expected it at $serverFile';
        }

        // TODO(jensj): Option of passing --profiler
        p = await Process.start(Platform.resolvedExecutable, [
          '--enable-vm-service',
          '--profiler',
          serverFile.path,
          '--lsp',
          '--port=9102',
          ...cacheFolderArgs,
        ]);
      case LaunchFrom.Dart:
        // TODO(jensj): Option of wrapping in `perf record -g` call.
        p = await Process.start(Platform.resolvedExecutable, [
          'language-server',
          '--lsp',
          '--port=9102',
          ...cacheFolderArgs,
        ]);
      case LaunchFrom.Aot:
        File serverFile = File.fromUri(
          repoDir.resolve('pkg/analysis_server/bin/server.aot'),
        );
        if (!serverFile.existsSync()) {
          throw "Couldn't find 'analysis_server/bin/server.aot' "
              'expected it at $serverFile';
        }

        // TODO(jensj): Option of passing --profiler
        Uri dart = Uri.base.resolveUri(Uri.file(Platform.resolvedExecutable));
        File aotRuntime = File.fromUri(dart.resolve('dartaotruntime'));
        if (!aotRuntime.existsSync()) {
          throw "Couldn't find 'dartaotruntime' expected it at $aotRuntime";
        }
        p = await Process.start(aotRuntime.path, [
          serverFile.path,
          '--lsp',
          '--port=9102',
          ...cacheFolderArgs,
        ]);
    }

    print('Launched with pid ${p.pid}');
  }

  void _listenToStdout(List<int> event) {
    // General idea taken from
    // pkg/analysis_server/lib/src/lsp/lsp_packet_transformer.dart
    for (int element in event) {
      _buffer.add(element);
      if (verbosity > 3 &&
          _buffer.length >= 1000 &&
          _buffer.length % 1000 == 0) {
        print(
          'DEBUG MESSAGE: Stdout buffer with length ${_buffer.length} so far: '
          '${utf8.decode(_buffer)}',
        );
      }
      if (_headerContentLength == null && _endsWithCrLfCrLf()) {
        String headerRaw = utf8.decode(_buffer);
        _buffer.clear();
        // Use a regex that makes the '\r' optional to handle "The Dart VM service
        // is listening on [..." message - at least on linux - being \n terminated
        // which would otherwise mean that we'd be stuck because no message would
        // start with 'Content-Length:'.
        List<String> headers = headerRaw.split(_newLineRegExp);
        for (String header in headers) {
          if (!_printedVmServiceStuff &&
              header.startsWith('The Dart VM service')) {
            print('\n\n$header\n\n');
            _printedVmServiceStuff = true;
          }
          if (header.startsWith('Content-Length:')) {
            String contentLength =
                header.substring('Content-Length:'.length).trim();
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
        dynamic method = message['method'];
        if (method == r'$/analyzerStatus') {
          dynamic params = message['params'];
          if (params is Map) {
            dynamic isAnalyzing = params['isAnalyzing'];
            if (isAnalyzing is bool) {
              _analyzingCompleter.complete(isAnalyzing);
              _analyzingCompleter = Completer<bool>();
              if (verbosity > 0) {
                print('Got analyzerStatus isAnalyzing = $isAnalyzing');
              }
            }
          }
        }
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

          OutstandingRequest? outstandingRequest = _outstandingRequestsWithId
              .remove(possibleId);
          if (outstandingRequest != null) {
            outstandingRequest.stopwatch.stop();
            outstandingRequest.completer.complete(message);
            if (verbosity > 2) {
              print(
                ' => Got response for $possibleId in '
                '${outstandingRequest.stopwatch.elapsed}',
              );
            }
          }
        } else if (verbosity > 1) {
          if (messageString.length > 100) {
            print('Got message ${messageString.substring(0, 100)}...');
          } else {
            print('Got message $messageString');
          }
        }
      }
    }
  }
}

class OutstandingRequest {
  final Stopwatch stopwatch = Stopwatch();
  final Completer<Map<String, dynamic>> completer = Completer();
  OutstandingRequest() {
    stopwatch.start();
  }
}
