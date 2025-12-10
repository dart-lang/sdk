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
  final bool enableAsyncSpans;
  final bool enableProfiler;
  final List<String> streams;

  final bool useKeyPressInsteadOfCtrlC;

  PerfWitnessRecorderConfig({
    this.outputDir,
    this.tag,
    this.recordNewProcesses = false,
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
  final io.Directory outputDir;
  if (config.outputDir case final String outputDirPath) {
    outputDir = io.Directory(outputDirPath);
  } else {
    outputDir = io.Directory.systemTemp.createTempSync('recording');
  }

  final sockets = getAllControlSockets();
  final connections = (await Future.wait([
    for (var s in sockets) Connection._tryConnectTo(s.socketPath),
  ])).nonNulls.toList(growable: false);

  print('Found ${connections.length} processes:');
  for (final c in connections) {
    print('  ${c.info}');
  }

  final matchedConnections = _closeNotMatching(connections, config.tag);
  if (config.tag != null) {
    print('Tag ${config.tag} matched ${matchedConnections.length} processes.');
  }

  print('... data will be written to $outputDir');

  final sw = Stopwatch()..start();
  await Future.wait([
    for (var conn in matchedConnections)
      conn.startRecording(outputDir.path, config: config),
  ]);

  bool recording = true;

  JsonRpcServer? newProcessServer;
  if (config.recordNewProcesses) {
    if (recorderSocketPath case final path?) {
      if (io.FileSystemEntity.typeSync(path) ==
          io.FileSystemEntityType.unixDomainSock) {
        print(
          'Warning: Control socket $path already exists '
          '(another recorder might be running).',
        );
      } else {
        newProcessServer = JsonRpcServer(await UnixDomainSocket.bind(path), {
          'process.announce': (requestor, params) async {
            if (!recording) {
              return null;
            }

            final info = ProcessInfo.fromJson(params as Map<String, Object?>);
            print('New process announced: $info');
            if (config.tag == null || info.tag == config.tag) {
              try {
                final conn = Connection._(info, requestor);
                matchedConnections.add(conn);
                await conn.startRecording(outputDir.path, config: config);
              } catch (e) {
                print('Failed to start recording: $e');
              }
            }
            return null;
          },
        });
        print('Listening for new processes on $path');
      }
    } else {
      print(
        'Warning: Unable to listen for new processes '
        '(path to the control socket is null).',
      );
    }
  }

  if (matchedConnections.isNotEmpty || config.recordNewProcesses) {
    await waitForUserToQuit(waitForQKeyPress: config.useKeyPressInsteadOfCtrlC);
    recording = false;
    await Future.wait([
      for (var conn in matchedConnections)
        conn.stopRecording().catchError((e) {
          print('Failed to stop recording of process ${conn.info.pid}: $e');
        }),
    ]);
    print('Recorded for ${sw.elapsed}');
  }

  for (final conn in matchedConnections) {
    conn.disconnect();
  }
  await newProcessServer?.close();
}

class Connection {
  final ProcessInfo info;
  final JsonRpcPeer _endpoint;

  Connection._(this.info, this._endpoint);

  Future<void> startRecording(
    String outputDir, {
    required PerfWitnessRecorderConfig config,
  }) async {
    await _endpoint.sendRequest('timeline.streamTo', {
      'recorder': 'perfetto',
      'path': p.join(outputDir, '${info.pid}.timeline'),
      'enableProfiler': config.enableProfiler,
      'enableAsyncSpans': config.enableAsyncSpans,
      'streams': config.streams,
    });
  }

  Future<void> stopRecording() async {
    await _endpoint.sendRequest('timeline.stopStreaming');
  }

  void disconnect() async {
    try {
      await _endpoint.close();
    } catch (_) {
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

List<Connection> _closeNotMatching(List<Connection> v, String? tag) {
  if (tag == null) {
    return v.toList(growable: true);
  }

  final open = <Connection>[];
  for (final c in v) {
    if (c.info.tag == tag) {
      open.add(c);
      continue;
    }
    c.disconnect();
  }
  return open;
}
