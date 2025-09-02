// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'io_utils.dart';
import 'legacy_messages.dart';
import 'lsp_messages.dart';
import 'utils.dart';

abstract class DartLanguageServerBenchmark {
  int verbosity = 0;
  final Uri repoDir = computeRepoDirUri();
  late final Process p;
  late final Timer longRunningRequestsTimer;
  bool _launched = false;
  bool _exited = false;
  Completer<bool> _analyzingCompleter = Completer();
  final _buffer = _Uint8ListHelper();
  int? _headerContentLength;
  bool _printedVmServiceStuff = false;
  final String executableToUse;

  /// There's something weird about getting (several) id 3's that wasn't
  /// requested...
  int largestIdSeen = 3;

  final RegExp _newLineRegExp = RegExp('\r?\n');
  final Map<int, OutstandingRequest> _outstandingRequestsWithId = {};

  bool _addedInitialAnalysisDuration = false;
  List<DurationInfo> durationInfo = [];
  List<MemoryInfo> memoryInfo = [];

  final bool _lsp;

  DartLanguageServerBenchmark(List<String> args, {required bool useLspProtocol})
    : _lsp = useLspProtocol,
      executableToUse = extractDartParamOrDefault(args) {
    _checkCorrectDart();
  }

  List<Uri> get additionalWorkspaceUris => const [];
  Uri? get cacheFolder => null;

  LaunchFrom get launchFrom => LaunchFrom.Source;

  Uri get rootUri;
  Future<void> afterInitialization();

  void exit() {
    _exited = true;
    longRunningRequestsTimer.cancel();
    if (Platform.isLinux) {
      try {
        File f = File('/proc/${p.pid}/status');
        for (var line in f.readAsLinesSync()) {
          if (line.startsWith('VmPeak:')) {
            memoryInfo.addInfoMaybe(
              'peak virtual memory size',
              _extractSizeFromProcStatusMemoryLine(line),
            );
          } else if (line.startsWith('VmSize:')) {
            memoryInfo.addInfoMaybe(
              'total program size (virtual)',
              _extractSizeFromProcStatusMemoryLine(line),
            );
          } else if (line.startsWith('VmHWM:')) {
            memoryInfo.addInfoMaybe(
              'peak resident set size ("high water mark")',
              _extractSizeFromProcStatusMemoryLine(line),
            );
          } else if (line.startsWith('VmRSS:')) {
            memoryInfo.addInfoMaybe(
              'size of memory portions (rss)',
              _extractSizeFromProcStatusMemoryLine(line),
            );
          }
        }
      } catch (e) {
        // ignore
      }
    }
    p.kill();
  }

  Future<void> run() async {
    if (_lsp) {
      await _runLsp();
    } else {
      await _runLegacy();
    }
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
    if (!_lsp && possibleId is String && int.tryParse(possibleId) != null) {
      possibleId = int.tryParse(possibleId);
    }
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
    if (verbosity > 3) {
      print('Sending message: $jsonEncodedBody');
    }

    if (_lsp) {
      // Header is always ascii, body is always utf8!
      p.stdin.add(asciiEncodedHeader);
    }
    p.stdin.add(utf8EncodedBody);
    if (!_lsp) {
      p.stdin.add(const [10]);
    }
    await p.stdin.flush();
    if (verbosity > 2) {
      print('\n\nMessage sent\n\n');
    }
    return result;
  }

  Future<bool> waitUntilIsAnalyzingChanges() async {
    return await _analyzingCompleter.future;
  }

  Future<void> waitWhileAnalyzing() async {
    // Wait until it's done analyzing.
    bool isAnalyzing = await _analyzingCompleter.future;
    Stopwatch stopwatch = Stopwatch()..start();
    while (isAnalyzing) {
      isAnalyzing = await _analyzingCompleter.future;
    }
    if (verbosity >= 0) {
      print('isAnalyzing is now done after ${stopwatch.elapsed}');
    }
    if (!_addedInitialAnalysisDuration) {
      _addedInitialAnalysisDuration = true;
      durationInfo.add(DurationInfo('Initial analysis', stopwatch.elapsed));
    }
  }

  void _checkCorrectDart() {
    Uri exe = Uri.base.resolveUri(Uri.file(executableToUse));
    Uri librariesDart = exe.resolve(
      '../lib/_internal/sdk_library_metadata/lib/libraries.dart',
    );
    if (!File.fromUri(librariesDart).existsSync()) {
      throw 'Execute with a dart that has '
          "'../lib/_internal/sdk_library_metadata/lib/libraries.dart' "
          'available (e.g. out/ReleaseX64/dart-sdk/bin/dart)';
    }
  }

  void _checkLongRunningRequests(Timer timer) {
    if (verbosity < 0) return;
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

  bool _endsWithLf() {
    var l = _buffer.length;
    return l > 1 && _buffer[l - 1] == 10;
  }

  int? _extractSizeFromProcStatusMemoryLine(String line) {
    int colon = line.indexOf(':');
    if (colon < 0) return null;
    int kb = line.indexOf('kB', colon);
    if (kb < 0) return null;
    String substring = line.substring(colon + 1, kb).trim();
    return int.tryParse(substring);
  }

  Future<void> _initializeLegacy() async {
    await send(LegacyMessages.getVersion(largestIdSeen + 1));
    await send(LegacyMessages.setSubscriptionsStatus(largestIdSeen + 1));
    await send(LegacyMessages.updateOptions(largestIdSeen + 1));
    await send(LegacyMessages.setClientCapabilities(largestIdSeen + 1));
    await send(
      LegacyMessages.setAnalysisRoots(largestIdSeen + 1, [
        rootUri,
        ...additionalWorkspaceUris,
      ]),
    );

    // Wait until it's done analyzing.
    await waitWhileAnalyzing();
  }

  Future<void> _initializeLsp() async {
    OutstandingRequest? request = await send(
      LspMessages.initMessage(pid, rootUri, additionalWorkspaceUris),
    );
    await request?.completer.future;
    await send(LspMessages.initNotification);

    // Wait until it's done analyzing.
    await waitWhileAnalyzing();
  }

  Future<void> _launch({required bool lsp}) async {
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
        p = await Process.start(executableToUse, [
          '--enable-vm-service',
          '--profiler',
          serverFile.path,
          lsp ? '--protocol=lsp' : '--protocol=analyzer',
          '--port=9102',
          ...cacheFolderArgs,
        ]);
      case LaunchFrom.Dart:
        // TODO(jensj): Option of wrapping in `perf record -g` call.
        p = await Process.start(executableToUse, [
          'language-server',
          lsp ? '--protocol=lsp' : '--protocol=analyzer',
          '--port=9102',
          ...cacheFolderArgs,
        ]);
      case LaunchFrom.AotWithPerf:
      case LaunchFrom.Aot:
        File serverFile = File.fromUri(
          repoDir.resolve('pkg/analysis_server/bin/server.aot'),
        );
        if (!serverFile.existsSync()) {
          throw "Couldn't find 'analysis_server/bin/server.aot' "
              'expected it at $serverFile';
        }

        // TODO(jensj): Option of passing --profiler
        Uri dart = Uri.base.resolveUri(Uri.file(executableToUse));
        File aotRuntime = File.fromUri(dart.resolve('dartaotruntime'));
        if (!aotRuntime.existsSync()) {
          throw "Couldn't find 'dartaotruntime' expected it at $aotRuntime";
        }

        p = await Process.start(aotRuntime.path, [
          serverFile.path,
          lsp ? '--protocol=lsp' : '--protocol=analyzer',
          '--port=9102',
          ...cacheFolderArgs,
        ]);

        if (launchFrom == LaunchFrom.AotWithPerf) {
          await Process.start('perf', [
            'record',
            '-p',
            '${p.pid}',
            '-g',
          ], mode: ProcessStartMode.inheritStdio);
        }
    }

    // ignore: unawaited_futures
    p.exitCode.then((exitCode) {
      if (verbosity >= 0) {
        print('Process existed with exitCode $exitCode');
      }
      if (!_exited) {
        _analyzingCompleter.completeError('Process exited 1.');
        while (_outstandingRequestsWithId.isNotEmpty) {
          var entry = _outstandingRequestsWithId.entries.first;
          _outstandingRequestsWithId.remove(entry.key);
          entry.value.completer.completeError('Process exited 2.');
        }
      }
    });

    if (verbosity >= 0) {
      print('Launched with pid ${p.pid}');
    }
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
          '${utf8.decode(_buffer.view())}',
        );
      }
      if (_lsp && _headerContentLength == null && _endsWithCrLfCrLf()) {
        String headerRaw = utf8.decode(_buffer.view());
        _buffer.clear();
        // Use a regex that makes the '\r' optional to handle "The Dart VM service
        // is listening on [..." message - at least on linux - being \n terminated
        // which would otherwise mean that we'd be stuck because no message would
        // start with 'Content-Length:'.
        List<String> headers = headerRaw.split(_newLineRegExp);
        for (String header in headers) {
          if (!_printedVmServiceStuff &&
              header.startsWith('The Dart VM service')) {
            if (verbosity >= 0) {
              print('\n\n$header\n\n');
            }
            _printedVmServiceStuff = true;
          }
          if (header.startsWith('Content-Length:')) {
            String contentLength =
                header.substring('Content-Length:'.length).trim();
            _headerContentLength = int.parse(contentLength);
            break;
          }
        }
      } else if ((_lsp &&
              _headerContentLength != null &&
              _buffer.length == _headerContentLength!) ||
          (!_lsp && _endsWithLf())) {
        String messageString = utf8.decode(_buffer.view());
        _buffer.clear();
        _headerContentLength = null;

        if (messageString.startsWith('The Dart VM service')) {
          if (verbosity >= 0) print('\n\n$messageString\n\n');
          continue;
        }
        if (messageString.startsWith('The Dart DevTools')) {
          if (verbosity >= 0) print('\n\n$messageString\n\n');
          continue;
        }

        Map<String, dynamic> message =
            json.decode(messageString) as Map<String, dynamic>;

        // LSP: {"jsonrpc":"2.0","method":"$/analyzerStatus","params":{"isAnalyzing":false}}
        // Analyzer: {"event":"server.status","params":{"analysis":{"isAnalyzing":true}}}
        if ((_lsp && message['method'] == r'$/analyzerStatus') ||
            (!_lsp && message['event'] == 'server.status')) {
          dynamic params = message['params'];
          if (params is Map) {
            dynamic isAnalyzing =
                _lsp
                    ? params['isAnalyzing']
                    : params['analysis']?['isAnalyzing'];
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
        if (!_lsp && possibleId is String && int.tryParse(possibleId) != null) {
          possibleId = int.tryParse(possibleId);
        }
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

  Future<void> _runLegacy() async {
    assert(!_lsp);
    await _launch(lsp: false);
    p.stdout.listen(_listenToStdout);
    p.stderr.listen(stderr.add);
    longRunningRequestsTimer = Timer.periodic(
      const Duration(seconds: 1),
      _checkLongRunningRequests,
    );

    await _initializeLegacy();
    if (verbosity >= 0) {
      print('Should now be initialized.');
    }

    await afterInitialization();
  }

  Future<void> _runLsp() async {
    assert(_lsp);
    await _launch(lsp: true);
    p.stdout.listen(_listenToStdout);
    p.stderr.listen(stderr.add);
    longRunningRequestsTimer = Timer.periodic(
      const Duration(seconds: 1),
      _checkLongRunningRequests,
    );

    await _initializeLsp();
    if (verbosity >= 0) {
      print('Should now be initialized.');
    }

    await afterInitialization();
  }
}

class DurationInfo {
  final String name;
  final Duration duration;

  DurationInfo(this.name, this.duration);
}

enum LaunchFrom { Source, Dart, Aot, AotWithPerf }

class MemoryInfo {
  final String name;
  final int kb;

  MemoryInfo(this.name, this.kb);
}

class OutstandingRequest {
  final Stopwatch stopwatch = Stopwatch();
  final Completer<Map<String, dynamic>> completer = Completer();
  OutstandingRequest() {
    stopwatch.start();
  }
}

class _Uint8ListHelper {
  Uint8List data;
  int length = 0;
  _Uint8ListHelper() : data = Uint8List(1024);

  int operator [](int index) {
    if (index < 0 || index >= length) throw 'Out of bounds: $index';
    return data[index];
  }

  void add(int i) {
    if (length == data.length) {
      var newData = Uint8List(length * 2);
      newData.setRange(0, length, data);
      data = newData;
    }
    data[length++] = i;
  }

  void clear() {
    length = 0;
  }

  Uint8List view() {
    return Uint8List.sublistView(data, 0, length);
  }
}

extension on List<MemoryInfo> {
  void addInfoMaybe(String description, int? value) {
    if (value == null) return;
    add(MemoryInfo(description, value));
  }
}
