// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dart_runtime_service/dart_runtime_service.dart';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:logging/logging.dart';
import 'package:stream_channel/stream_channel.dart';

import 'src/dart_runtime_service_vm_rpcs.dart';
import 'src/native_bindings.dart';
import 'src/vm_clients.dart';
import 'src/vm_dev_fs.dart';
import 'src/vm_expression_evaluator.dart';
import 'src/vm_isolate_manager.dart';

class DartRuntimeServiceVMBackend
    extends DartRuntimeServiceBackend<VmIsolateManager> {
  /// The backend implementation for the Dart VM Service.
  ///
  /// [signalWatch] is the internal implementation of [ProcessSignal.watch],
  /// which bypasses checks that prevent [ProcessSignal.sigquit] from being
  /// watched.
  DartRuntimeServiceVMBackend({
    required super.frontend,
    required this.signalWatch,
    required Stream<VmRunningIsolate> runningIsolatesStream,
    required this.residentCompilerInfoFile,
    required this._ddsManager,
  }) : isolateManager = VmIsolateManager(
         runningIsolatesStream: runningIsolatesStream,
       );

  static const int _kServiceExitMessageId = 0;
  static const int _kIsolateStartupMessageId = 1;
  static const int _kIsolateShutdownMessageId = 2;
  static const int _kWebServerControlMessageId = 3;
  static const int _kServerInfoMessageId = 4;

  /// Signals an RPC coming from native code (instead of from a websocket
  /// connection).  These calls are limited to simple request-response and do
  /// not allow arbitrary json-rpc messages.
  ///
  /// The messages are an array of length 3:
  ///   (kMethodCallFromNative, String jsonRequest, PortId replyPort).
  static const int _kMethodCallFromNativeId = 5;

  /// The internal implementation of [ProcessSignal.watch].
  final Stream<ProcessSignal> Function(ProcessSignal signal) signalWatch;
  StreamSubscription<ProcessSignal>? _sigquitSubscription;

  /// The port the VM uses to send messages to the VM service.
  static final isolateControlPort = RawReceivePort();

  /// Used to create an artificial client from within the VM service, allowing
  /// for VM service requests to be made from within the VM or through the Dart
  /// embedding API.
  final _nativeRpcClientStreamChannelController =
      StreamChannelController<String>(sync: true);

  /// Iterator for RPC responses sent to the artificial client.
  late final _nativeRpcClientResponseStream = StreamIterator(
    _nativeRpcClientStreamChannelController.local.stream,
  );

  final _nativeBindings = NativeBindings();
  final _logger = Logger('$DartRuntimeServiceVMBackend');
  final _devFs = VMDevelopmentFileSystemCollection.createDevFS();

  @override
  final VmIsolateManager isolateManager;

  @override
  late final VmExpressionEvaluator expressionEvaluator;

  late final _vmServiceRpcs = DartRuntimeServiceVmRpcs(backend: this);

  final File? residentCompilerInfoFile;

  /// Adds support for launching and accepting connections from the
  /// Dart Development Service.
  final DartDevelopmentServiceManager _ddsManager;

  @override
  UnmodifiableListView<ServiceRpcHandler> get rpcs => UnmodifiableListView([
    ..._vmServiceRpcs.rpcs,
    ..._devFs.rpcs,
    ..._ddsManager.rpcs,
  ]);

  @override
  UnmodifiableListView<RpcHandlerWithParameters>
  get fallbacks => UnmodifiableListView([
    // If the registered Dart RPC handlers can't handle a request, forward it
    // it to the native VM service implementation for processing.
    sendToRuntime,
  ]);

  @override
  OptionalHandler get httpHandler => _devFs.handlePutStreamRequest;

  @override
  VmClientManager clientManagerBuilder() =>
      VmClientManager(backend: this, eventStreamMethods: frontend.eventStreams);

  @override
  Future<void> initialize() async {
    _logger.info('Initializing...');
    expressionEvaluator = VmExpressionEvaluator(
      clients: frontend.clients,
      backend: this,
    );
    isolateControlPort.handler = _vmMessageHandler;
    frontend.addArtificialClient(
      name: 'native-rpc-client',
      connection: _nativeRpcClientStreamChannelController.foreign,
    );
    _nativeBindings.onStart();
    _logger.info('Initialized.');
  }

  @override
  Future<void> clearState() async {
    // Do nothing for now.
  }

  @override
  Future<void> shutdown() async {
    _logger.info('Shutting down...');
    await _ddsManager.shutdown();
    await Future.wait([
      _sigquitSubscription?.cancel() ?? Future<void>.value(),
      _nativeRpcClientStreamChannelController.local.sink.close(),
      _devFs.cleanup(),
    ]);
    isolateControlPort.close();
    _nativeBindings.onExit();
    _logger.info('Shutdown.');
  }

  @override
  Future<void> onServiceReady(DartRuntimeService service) async {
    // SIGQUIT isn't supported on Fuchsia or Windows.
    if (Platform.isFuchsia || Platform.isWindows) {
      return;
    }
    _sigquitSubscription = signalWatch(ProcessSignal.sigquit).listen((_) {
      _logger.info('SIGQUIT received. Toggling VM Service HTTP server.');
      service.toggleServer();
    });
  }

  @override
  Future<void> onServerStarted({
    required Uri httpUri,
    required Uri wsUri,
  }) async {
    if (_ddsManager.launchOnStart) {
      await _ddsManager.start(vmServiceUri: httpUri);
      httpUri = await _ddsManager.ddsConnected;
    }
    frontend.printServiceOutput('The Dart VM service is listening on $httpUri');
    final devToolsUri = _ddsManager.devToolsUri;
    if (devToolsUri != null) {
      frontend.printServiceOutput(
        'The Dart DevTools debugger and profiler is available at: $devToolsUri',
      );
    }
    final dtdUri = _ddsManager.dtdUri;
    if (dtdUri != null) {
      frontend.printServiceOutput(
        'The Dart Tooling Daemon (DTD) is available at: $dtdUri',
      );
    }
    _nativeBindings.onServerAddressChange(httpUri.toString());
  }

  @override
  Future<void> onServerShutdown() async {
    // Cleanup DDS state so it can be reinitialized if the server is started
    // again.
    await _ddsManager.shutdown();
  }

  @override
  bool onStreamListen({
    required String streamId,
    required Map<String, Object?> params,
  }) {
    var includePrivates = false;
    if (params case {'includePrivates': final bool value}) {
      includePrivates = value;
    }
    return _nativeBindings.streamListen(
      streamId: streamId,
      includePrivates: includePrivates,
    );
  }

  @override
  void onStreamCancel({required String streamId}) {
    _nativeBindings.streamCancel(streamId: streamId);
  }

  /// Sends service requests to the Dart VM runtime for processing.
  Future<RpcResponse> sendToRuntime(json_rpc.Parameters request) async {
    final method = request.method;
    // It's possible that a client will omit the parameters map for RPCs with
    // no parameters. Don't try and cast the request unless the value is
    // actually a map, otherwise assume there's no arugments.
    final params = request.value is Map
        ? request.asMap.cast<String, Object?>()
        : const <String, Object?>{};
    if (params case {'isolateId': final String _}) {
      _logger.info(
        'Sending request to isolate. Method: $method Params: $params',
      );
      return await isolateManager.sendToIsolate(method: method, params: params);
    }
    _logger.info('Sending request to VM. Method: $method Params: $params');
    return await _nativeBindings.sendToVM(method: method, params: params);
  }

  /// Handles messages sent directly from the VM via the isolate control port.
  ///
  /// Messages sent over the isolate control port include:
  ///   - Stream events
  ///   - Request to shutdown the service
  ///   - RPC invocations from the VM or VM's embedder
  ///   - dart:developer API invocations (e.g. Service.getInfo() and
  ///     Service.toggleWebServer())
  ///   - Isolate startup and shutdown notifications
  void _vmMessageHandler(List<Object?> message) {
    _logger.fine('VM message: $message');
    switch (message) {
      case [final String streamId, final Object event]:
        // This is an event.
        _eventMessageHandler(streamId, event);
      case [final int opcode]:
        // This is a control message directing the vm service to exit.
        assert(opcode == _kServiceExitMessageId);
        frontend.shutdown();
      case [
            final int opcode,
            final List<int> messageBytes,
            final SendPort replyPort,
          ]
          when opcode == _kMethodCallFromNativeId:
        _handleNativeRpcCall(messageBytes, replyPort);
      case [
            final int opcode,
            final SendPort sendPort,
            final bool enable,
            final bool? silenceOutput,
          ]
          when opcode == _kWebServerControlMessageId ||
              opcode == _kServerInfoMessageId:
        // This is a message interacting with the web server.
        _serverMessageHandler(opcode, sendPort, enable, silenceOutput);
      case [
            final int opcode,
            final int portId,
            final SendPort sendPort,
            final String name,
          ]
          when opcode == _kIsolateStartupMessageId ||
              opcode == _kIsolateShutdownMessageId:
        // This is a message informing us of the birth or death of an
        // isolate.
        _isolateControlMessageHandler(opcode, portId, sendPort, name);
      default:
        _logger.warning(
          'Internal vm-service error: ignoring illegal message: $message',
        );
    }
  }

  /// Forward VM service events sent from the VM.
  void _eventMessageHandler(String streamId, Object event) {
    frontend.sendEvent(
      event: switch (event) {
        final String jsonString => ForwardingStreamEvent(
          streamId: streamId,
          event: json.decode(jsonString) as Map<String, Object?>,
        ),
        [final Uint8List utf8String] => ForwardingStreamEvent(
          streamId: streamId,
          event: json.decode(utf8.decode(utf8String)) as Map<String, Object?>,
        ),
        final Uint8List binaryData => BinaryStreamEvent(
          streamId: streamId,
          data: binaryData,
        ),
        _ => throw UnimplementedError(
          'Unexpected event type: ${event.runtimeType}.',
        ),
      },
    );
  }

  /// Handle notifications from the VM related to isolate startup and shutdown.
  void _isolateControlMessageHandler(
    int code,
    int portId,
    SendPort sp,
    String name,
  ) {
    switch (code) {
      case _kIsolateStartupMessageId:
        isolateManager.onIsolateStartupMessage(
          id: portId,
          sendPort: sp,
          name: name,
        );
      case _kIsolateShutdownMessageId:
        isolateManager.onIsolateShutdownMessage(id: portId);
    }
  }

  /// Handle requests from the VM related to the state of the service's HTTP
  /// server.
  Future<void> _serverMessageHandler(
    int code,
    SendPort sp,
    bool enable,
    bool? silenceOutput,
  ) async {
    void sendServerInfo() {
      try {
        sp.send(frontend.httpUri.toString());
      } on DartRuntimeServiceServerNotRunning {
        sp.send(null);
      }
    }

    switch (code) {
      case _kWebServerControlMessageId:
        await frontend.serverControl(
          enable: enable,
          silenceOutput: silenceOutput,
        );
        sendServerInfo();
      case _kServerInfoMessageId:
        sendServerInfo();
    }
  }

  /// Handle VM service requests from native code (see
  /// `Dart_InvokeVMServiceMethod` in `dart_tools_api.h`).
  Future<void> _handleNativeRpcCall(
    List<int> message,
    SendPort replyPort,
  ) async {
    // The original VM service implementation could, in theory, handle binary
    // and "UTF8String" responses. However, no binary or "UTF8String" responses
    // are sent in response to service RPCs so we should be able to assume that
    // `message` can be converted to a `String`.
    //
    // If this decode throws an exception, we'll need to revisit this.
    final messageStr = utf8.decode(message);
    _logger.info('Native RPC request: $messageStr');
    _nativeRpcClientStreamChannelController.local.sink.add(messageStr);

    if (!await _nativeRpcClientResponseStream.moveNext()) {
      _logger.warning('Native RPC client stream has closed.');
      return;
    }
    _logger.info(
      'Response received: ${_nativeRpcClientResponseStream.current}',
    );
    replyPort.send(utf8.encode(_nativeRpcClientResponseStream.current));
  }
}

final class ForwardingStreamEvent extends StreamEvent {
  ForwardingStreamEvent({required super.streamId, required this.event})
    : super(kind: '<ignored>');

  static const kParams = 'params';

  Map<String, Object?> event;

  @override
  Map<String, Object?> toJson() {
    return event[kParams] as Map<String, Object?>;
  }
}
