// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'src/common.dart';
import 'src/json_rpc.dart';
import 'src/process_info.dart';

class PerfWitnessRecorderConfig {
  final String? outputDir;
  final String? tag;
  final bool recordNewProcesses;
  final bool recordOnlyNewProcesses;
  final bool enableAsyncSpans;
  final bool enableProfiler;
  final List<String> streams;

  final bool useKeyPressInsteadOfCtrlC;

  PerfWitnessRecorderConfig({
    this.outputDir,
    this.tag,
    this.recordNewProcesses = false,
    this.recordOnlyNewProcesses = false,
    this.enableAsyncSpans = false,
    this.enableProfiler = true,
    this.streams = const [],
    this.useKeyPressInsteadOfCtrlC = false,
  });

  factory PerfWitnessRecorderConfig.fromParsedArgs(ArgResults args) {
    var streams = args['streams'] as List<String>;
    if (streams.contains('all')) {
      streams = TimelineStream.values.map((s) => s.name).toList();
    }
    return PerfWitnessRecorderConfig(
      outputDir: args['output-dir'] as String?,
      tag: args['tag'] as String?,
      recordNewProcesses: args['record-new-processes'] as bool,
      recordOnlyNewProcesses: args['record-only-new-processes'] as bool,
      enableAsyncSpans: args['enable-async-spans'] as bool,
      enableProfiler: args['enable-profiler'] as bool,
      streams: streams,
      useKeyPressInsteadOfCtrlC: args['wait-for-keypress'] as bool,
    );
  }

  factory PerfWitnessRecorderConfig.fromArgs(List<String> args) {
    final parsedArgs = configureArgParser().parse(args);
    return PerfWitnessRecorderConfig.fromParsedArgs(parsedArgs);
  }

  static ArgParser configureArgParser([ArgParser? parser]) {
    return (parser ?? ArgParser())
      ..addOption('output-dir', abbr: 'o')
      ..addOption('tag', help: 'Tag to filter processes by.')
      ..addFlag(
        'record-new-processes',
        help: 'Record processes that start after the recorder.',
        negatable: false,
      )
      ..addFlag(
        'record-only-new-processes',
        help: 'Record only processes that start after the recorder.',
        negatable: false,
      )
      ..addFlag(
        'enable-async-spans',
        help: 'Enable async spans.',
        negatable: false,
      )
      ..addFlag(
        'enable-profiler',
        help: 'Enable profiler.',
        negatable: true,
        defaultsTo: true,
      )
      ..addFlag(
        'wait-for-keypress',
        help: 'Use Q keypress instead of Ctrl-C',
        negatable: false,
        hide: true,
      )
      ..addMultiOption(
        'streams',
        help: 'Streams to record.',
        allowed: [...TimelineStream.values.map((s) => s.name), 'all'],
        defaultsTo: [TimelineStream.gc.name, TimelineStream.dart.name],
      );
  }
}

Future<void> record(PerfWitnessRecorderConfig config) async {
  await _Recorder._(config).record();
}

class _Recorder {
  final PerfWitnessRecorderConfig config;
  late final io.Directory outputDir;

  final List<Connection> _activeConnections = [];

  JsonRpcServer? _newProcessServer;

  bool _recording = false;

  _Recorder._(this.config);

  Future<void> record() async {
    try {
      if (config.outputDir case final String outputDirPath) {
        outputDir = io.Directory(outputDirPath);
      } else {
        outputDir = io.Directory.systemTemp.createTempSync('recording');
      }

      if (!outputDir.existsSync()) {
        print('Created output directory $outputDir');
        outputDir.createSync(recursive: true);
      }

      final sockets = getAllControlSockets();
      final connections = (await Future.wait([
        for (var s in sockets) Connection._tryConnectTo(s.socketPath),
      ])).nonNulls.toList(growable: false);

      print('Found ${connections.length} processes:');
      for (final c in connections) {
        print('  ${c.info}');
      }

      _activeConnections.addAll(_closeNotMatching(connections));
      if (config.tag != null) {
        print(
          'Tag ${config.tag} matched ${_activeConnections.length} processes.',
        );
      }

      print('... data will be written to $outputDir');

      _recording = true;
      if (!config.recordOnlyNewProcesses) {
        await Future.wait([
          for (var conn in _activeConnections)
            conn.startRecording(outputDir.path, config: config),
        ]);
      } else {
        assert(_activeConnections.isEmpty);
      }

      if (config.recordNewProcesses || config.recordOnlyNewProcesses) {
        _newProcessServer = await _recordNewProcesses();
      }

      if (_activeConnections.isNotEmpty || _newProcessServer != null) {
        await waitForUserToQuit(
          waitForQKeyPress: config.useKeyPressInsteadOfCtrlC,
        );
        _recording = false;
        await Future.wait([
          for (var conn in _activeConnections)
            conn.stopRecording().catchError((e) {
              print('Failed to stop recording of process ${conn.info.pid}: $e');
            }),
        ]);
      }
    } finally {
      for (final conn in _activeConnections) {
        try {
          conn.disconnect();
        } catch (_) {
          // Ignore exception.
        }
      }
      try {
        await _newProcessServer?.close();
      } catch (_) {
        // Ignore exception.
      }
    }
  }

  Future<JsonRpcServer?> _recordNewProcesses() async {
    final controlPath = recorderSocketPath;
    if (controlPath == null) {
      print(
        'Warning: Unable to listen for new processes '
        '(path to the control socket is null).',
      );
      return null;
    }

    if (!await _checkIfControlSocketIsFree(controlPath)) {
      return null;
    }

    final newProcessServer = JsonRpcServer(
      await UnixDomainSocket.bind(controlPath),
      {
        'recorder.info': (requestor, params) async {
          return {'pid': io.pid};
        },
        'process.announce': (requestor, params) async {
          if (!_recording) {
            return null;
          }

          final info = ProcessInfo.fromJson(params as Map<String, Object?>);
          print('New process announced: $info');
          if (config.tag == null || info.tag == config.tag) {
            try {
              final conn = Connection._(info, requestor);
              _activeConnections.add(conn);
              await conn.startRecording(outputDir.path, config: config);
            } catch (e) {
              print('Failed to start recording: $e');
            }
          }
          return null;
        },
      },
    );
    print('Listening for new processes...');
    return newProcessServer;
  }

  static Future<bool> _checkIfControlSocketIsFree(String controlPath) async {
    final type = io.FileSystemEntity.typeSync(controlPath);
    if (type == .notFound) {
      return true;
    }

    // If there is already a socket bound at [controlPath] then try
    // connecting to it to check if recorder is still active.
    if (type == .unixDomainSock) {
      try {
        final otherServer = jsonRpcPeerFromSocket(
          await UnixDomainSocket.connect(controlPath),
        );
        Object? info;
        try {
          info = await otherServer
              .sendRequest('recorder.info')
              .timeout(Duration(milliseconds: 500));
        } finally {
          await otherServer.close();
        }
        if (info case {'pid': final int pid}) {
          print(
            'Error: cannot listen for new processes because another'
            ' recorder process (pid $pid) is already running and listening.',
          );
          return false;
        }
      } catch (_) {
        // Ignore.
      }
    }

    // Not a unix domain socket or it did not respond to our connection
    // with a meaningful answer so it's probably not used by another recorder.
    // We can try to delete the socket to free it.
    try {
      io.File(controlPath).deleteSync();
      print('Deleted stale control socket ($controlPath)');
      return true;
    } catch (e) {
      print('Error: Failed to delete control socket $controlPath: $e');
      return false;
    }
  }

  List<Connection> _closeNotMatching(List<Connection> v) {
    if (config.recordOnlyNewProcesses) {
      for (var c in v) {
        print('asking ${c.info} to disconnect');
        c.disconnect();
      }
      return [];
    }

    if (config.tag == null) {
      return v.toList(growable: true);
    }

    final open = <Connection>[];
    for (final c in v) {
      if (c.info.tag == config.tag) {
        open.add(c);
        continue;
      }
      c.disconnect();
    }
    return open;
  }
}

class Connection {
  final Stopwatch _recordingTime = Stopwatch();
  final ProcessInfo info;
  final JsonRpcPeer _endpoint;

  Connection._(this.info, this._endpoint);

  Future<void> startRecording(
    String outputDir, {
    required PerfWitnessRecorderConfig config,
  }) async {
    _recordingTime.start();
    await _endpoint.sendRequest('timeline.streamTo', {
      'recorder': 'perfetto',
      'path': p.join(outputDir, '${info.pid}.timeline'),
      'enableProfiler': config.enableProfiler,
      'enableAsyncSpans': config.enableAsyncSpans,
      'streams': config.streams,
    });
  }

  Future<void> stopRecording() async {
    _recordingTime.stop();
    print('Recorded process ${info.pid} for ${_recordingTime.elapsed}');
    await _endpoint.sendRequest('timeline.stopStreaming');
  }

  void disconnect() async {
    try {
      await _endpoint.close();
    } catch (e) {
      print('failed to disconnect: $e');
      // Ignore exceptions
    }
  }

  static Future<Connection> connectTo(String controlSocketPath) async {
    final client = jsonRpcPeerFromSocket(
      await UnixDomainSocket.connect(controlSocketPath),
    );
    final info = ProcessInfo.fromJson(
      await client.sendRequest('process.getInfo') as Map<String, Object?>,
    );
    return Connection._(info, client);
  }

  static Future<Connection?> _tryConnectTo(String controlSocket) async {
    try {
      return await Connection.connectTo(controlSocket);
    } catch (_) {
      try {
        io.File(controlSocket).deleteSync(); // Likely stale file. Purge it.
      } catch (_) {}
      return null;
    }
  }
}
