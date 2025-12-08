// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ffi' as ffi;
import 'dart:io' as io;

import 'package:ffi/ffi.dart' show calloc;
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'src/common.dart';
import 'src/json_rpc.dart';
import 'src/process_info.dart';

class PerfWitnessServer {
  final String? _tag;
  final String _controlSocketPath;
  final String _recorderSocketPath;
  final ffi.Pointer<ffi.Bool> _isRecordingTimelineWithAsyncSpans;

  bool _isRecordingTimeline = false;

  JsonRpcServer? _server;
  json_rpc.Peer? _recorderConnection;

  static ffi.Pointer<ffi.Bool>? _sharedIsRecordingTimelineWithAsyncSpans;

  late final Map<String, JsonRpcMethod> _methods = {
    'process.getInfo': _getProcessInfo,
    'timeline.streamTo': _timelineStreamTo,
    'timeline.stopStreaming': _timelineStopStreaming,
    'process._isRecordingTimelineWithAsyncSpansAddr':
        _isRecordingTimelineWithAsyncSpansAddr,
  };

  static PerfWitnessServer? _instance;

  PerfWitnessServer._(
    this._tag,
    this._controlSocketPath,
    this._recorderSocketPath,
  ) : _isRecordingTimelineWithAsyncSpans = calloc(ffi.sizeOf<ffi.Bool>());

  static Future<void> start({String? tag}) async {
    if (_instance != null) {
      return;
    }

    if (controlSocketPath case final socketPath?) {
      if (io.FileSystemEntity.typeSync(socketPath) == .unixDomainSock) {
        // Another isolate is already serving the process. We assume that
        // server will remain open as long as the process is running.
        // However we want to make sure that setting global settings (e.g.
        // whether async spans are enabled or not) will affect all isolates
        // not just the one that created the server.
        final client = jsonRpcPeerFromSocket(
          await UnixDomainSocket.connect(socketPath),
        );
        final {'address': int addr, 'pid': int pid} =
            await client.sendRequest(
                  'process._isRecordingTimelineWithAsyncSpansAddr',
                )
                as Map<String, dynamic>;
        // Just double check that we are the very same process.
        if (pid != io.pid) {
          return;
        }
        _sharedIsRecordingTimelineWithAsyncSpans = .fromAddress(addr);
        return;
      }

      _instance = PerfWitnessServer._(tag, socketPath, recorderSocketPath!);
      await _instance!._start();
    }
  }

  static Future<void> shutdown() async {
    await _instance?._shutdown();
    _instance = null;
  }

  static bool get isRecordingTimelineWithAsyncSpans {
    return _sharedIsRecordingTimelineWithAsyncSpans?.value ?? false;
  }

  Future<void> _timelineStreamTo(
    json_rpc.Peer requestor,
    Map<String, Object?>? params,
  ) async {
    if (_isRecordingTimeline) {
      throw StateError('Timeline is already being recorded');
    }

    final paramsObj = StreamTimelineToRequest(params ?? {});

    final streams = paramsObj.streams
        ?.map((s) => developer.TimelineStream.values.byName(s))
        .toList();

    final samplingIntervalUs = paramsObj.samplingInterval;
    final samplingInterval = samplingIntervalUs != null
        ? Duration(microseconds: samplingIntervalUs)
        : const Duration(microseconds: 1000);

    final enableAsyncSpans = paramsObj.enableAsyncSpans ?? false;

    developer.NativeRuntime.streamTimelineTo(
      developer.TimelineRecorder.values.byName(paramsObj.recorder),
      path: paramsObj.path,
      streams:
          streams ??
          const [developer.TimelineStream.dart, developer.TimelineStream.gc],
      enableProfiler: paramsObj.enableProfiler ?? false,
      samplingInterval: samplingInterval,
    );
    _isRecordingTimeline = true;
    _isRecordingTimelineWithAsyncSpans.value = enableAsyncSpans;
  }

  Future<void> _timelineStopStreaming(
    json_rpc.Peer requestor,
    Map<String, Object?>? params,
  ) async {
    if (!_isRecordingTimeline) {
      throw StateError('Timeline is not being recorded');
    }

    developer.NativeRuntime.stopStreamingTimeline();
    _isRecordingTimeline = false;
    _isRecordingTimelineWithAsyncSpans.value = false;
  }

  Future<Map<String, Object?>> _getProcessInfo(
    json_rpc.Peer requestor,
    Map<String, Object?>? params,
  ) async {
    return ProcessInfo.current(tag: _tag).toJson();
  }

  Future<Map<String, Object?>> _isRecordingTimelineWithAsyncSpansAddr(
    json_rpc.Peer requestor,
    Map<String, Object?>? params,
  ) async {
    return {
      'address': _isRecordingTimelineWithAsyncSpans.address,
      'pid': io.pid,
    };
  }

  Future<void> _start() async {
    _sharedIsRecordingTimelineWithAsyncSpans =
        _isRecordingTimelineWithAsyncSpans;
    _server = JsonRpcServer(
      await UnixDomainSocket.bind(_controlSocketPath),
      _methods,
    );
    await _announceProcessTo(
      _recorderSocketPath,
      _tag,
    ).timeout(Duration(milliseconds: 100), onTimeout: () => Future.value());
  }

  Future<void> _announceProcessTo(String recorderPath, String? tag) async {
    try {
      _recorderConnection = jsonRpcPeerFromSocket(
        await UnixDomainSocket.connect(recorderPath),
        _methods,
      );
      await _recorderConnection!.sendRequest(
        'process.announce',
        ProcessInfo.current(tag: tag).toJson(),
      );
    } catch (e) {
      // ignore, recorder might not be running.
    }
  }

  Future<void> _shutdown() async {
    _recorderConnection?.close();
    await _server?.close();
    if (io.FileSystemEntity.typeSync(_controlSocketPath) != .notFound) {
      io.File(_controlSocketPath).deleteSync();
    }
    calloc.free(_isRecordingTimelineWithAsyncSpans);
    if (_isRecordingTimeline) {
      developer.NativeRuntime.stopStreamingTimeline();
      _isRecordingTimeline = false;
    }
  }
}

extension type StreamTimelineToRequest(Map<String, Object?> json) {
  String get recorder => json['recorder'] as String;
  String? get path => json['path'] as String?;
  List<String>? get streams => (json['streams'] as List?)?.cast<String>();
  bool? get enableProfiler => json['enableProfiler'] as bool?;
  int? get samplingInterval => json['samplingInterval'] as int?;
  bool? get enableAsyncSpans => json['enableAsyncSpans'] as bool?;
}
