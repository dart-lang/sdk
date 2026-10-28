// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dap_adapters/dap_adapters.dart';
import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:dds_service_extensions/dap.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import 'dds_backend.dart';

/// A [StreamEvent] that wraps a DAP [Event] for notifications on the
/// [DapEventStreams.kDAP] stream.
final class DapStreamEvent extends StreamEvent {
  DapStreamEvent({required this.event})
    : super(kind: DapEventKind.kDAPEvent, streamId: DapEventStreams.kDAP);

  static const _kDapDataKey = 'dapData';
  static const _kEventType = 'Event';
  static const _kKindKey = 'kind';
  static const _kTimestampKey = 'timestamp';
  static const _kTypeKey = 'type';

  final Event event;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    StreamEvent.kEvent: <String, Object?>{
      _kDapDataKey: event.toJson(),
      _kKindKey: kind,
      _kTimestampKey: timestamp,
      _kTypeKey: _kEventType,
    },
    StreamEvent.kStreamId: streamId,
  };
}

/// Responds to incoming DAP messages using a debug adapter connected to DDS.
class DapHandler {
  DapHandler({required this.backend});

  static const _kAdapterId = 'dds-dap-handler';
  static const _kDapResponseKey = 'dapResponse';
  static const _kDapResponseType = 'DapResponse';
  static const _kInitializedEvent = 'initialized';
  static const _kInitialSequenceNumber = -1000;
  static const _kMessageParam = 'message';
  static const _kTypeKey = 'type';

  final DartRuntimeServiceDdsBackend backend;

  late final _adapter = DdsHostedAdapter();
  final _initializedCompleter = Completer<void>();

  /// Future for the lazy, once-only initialization of [_adapter].
  late final Future<void> _adapterInitialization = _startAdapter();

  /// Processes an incoming DAP request message and returns the serialized
  /// `DapResponse` payload.
  Future<RpcResponse> sendRequest(json_rpc.Parameters parameters) async {
    await _adapterInitialization;

    // TODO(helin24): Consider a sequence offset for incoming messages to avoid
    // overlapping sequence numbers with startup requests.
    final message = parameters[_kMessageParam].asString;

    // TODO(dantup): If/when DAP needs to care about ordering (eg. it handles
    // both requests and events), this will need to be changed to have the
    // caller provide a "responseWriter" function so the result can be written
    // directly to the stream synchronously, to avoid future events being able
    // to be inserted before the response (eg. initializedEvent).
    final responseCompleter = Completer<Response>();
    _adapter.handleMessage(message, responseCompleter.complete);
    final result = await responseCompleter.future;

    return <String, Object?>{
      _kTypeKey: _kDapResponseType,
      _kDapResponseKey: result.toJson(),
    };
  }

  void _handleEvent(Event event) {
    if (event.event == _kInitializedEvent &&
        !_initializedCompleter.isCompleted) {
      _initializedCompleter.complete();
    }
    backend.frontend.eventStreams.streamNotify(
      data: DapStreamEvent(event: event),
      streamId: DapEventStreams.kDAP,
    );
  }

  Future<void> _startAdapter() async {
    _adapter.ddsUri = backend.frontend.httpUri;
    _adapter.setEventHandler(_handleEvent);

    // TODO(helin24): Most likely we'll want the client to do these
    // initialization steps so that clients can differentiate capabilities. This
    // may require a custom stream for the debug adapter.

    // Each DAP request has a `seq` number (essentially a message ID) which
    // should be unique.
    //
    // We send a few requests to initialize the adapter, but these are not
    // visible to the DDS client so if we start at 1, the IDs will be
    // reused.
    //
    // To avoid that, for our own initialization requests, use negative numbers
    // (though they must still ascend) so there's no overlay with the messages
    // we'll forward from the DDS client.
    var seq = _kInitialSequenceNumber;
    await _adapter.initializeRequest(
      Request(command: Command.initialize, seq: seq),
      DartInitializeRequestArguments(adapterID: _kAdapterId),
      (_) {},
    );
    await _initializedCompleter.future;
    await _adapter.configurationDoneRequest(
      Request(
        arguments: const <String, Object?>{},
        command: Command.configurationDone,
        seq: seq++,
      ),
      ConfigurationDoneArguments(),
      _noopCallback,
    );
    await _adapter.attachRequest(
      Request(
        arguments: const <String, Object?>{},
        command: Command.attach,
        seq: seq++,
      ),
      DartAttachRequestArguments(
        vmServiceUri: backend.remoteVmServiceUri.toString(),
      ),
      _noopCallback,
    );
    // Wait for the debugger to fully initialize, because the request that
    // triggered this initialization may require things like isolates that will
    // only be known after the debugger has initialized.
    await _adapter.debuggerInitialized;
  }

  static void _noopCallback() {}
}
