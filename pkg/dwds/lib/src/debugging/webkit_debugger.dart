// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show WebSocketException;

import 'package:dwds/src/debugging/remote_debugger.dart';
import 'package:logging/logging.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart'
    hide StackTrace;

typedef _EventStreamState = ({
  StreamController controller,
  WipEventTransformer transformer,
});

/// A remote debugger with a Webkit Inspection Protocol connection.
class WebkitDebugger implements RemoteDebugger {
  WipDebugger _wipDebugger;

  /// Null until [close] is called.
  ///
  /// All subsequent calls to [close] will return this future.
  Future<void>? _closed;

  /// Completes when [close] is called, or when the connection is lost and
  /// can't be reestablished.
  final _disconnected = Completer<void>();

  // We need to forward the events from the [WipDebugger] instance rather than
  // directly expose its streams as it may need to be recreated due to an
  // unexpected loss in connection to the debugger.
  final _onClosedController = StreamController<WipConnection>.broadcast();
  final _onConsoleAPICalledController =
      StreamController<ConsoleAPIEvent>.broadcast();
  final _onExceptionThrownController =
      StreamController<ExceptionThrownEvent>.broadcast();
  final _onGlobalObjectClearedController =
      StreamController<GlobalObjectClearedEvent>.broadcast();
  final _onPausedController = StreamController<DebuggerPausedEvent>.broadcast();
  final _onResumedController =
      StreamController<DebuggerResumedEvent>.broadcast();
  final _onScriptParsedController =
      StreamController<ScriptParsedEvent>.broadcast();
  final _onTargetCrashedController =
      StreamController<TargetCrashedEvent>.broadcast();

  /// Tracks and manages all subscriptions to streams created with
  /// `eventStream`.
  final _eventStreams = <String, _EventStreamState>{};

  late final _controllers = <StreamController>[
    _onClosedController,
    _onConsoleAPICalledController,
    _onExceptionThrownController,
    _onGlobalObjectClearedController,
    _onPausedController,
    _onResumedController,
    _onScriptParsedController,
    _onTargetCrashedController,
  ];

  final _streamSubscriptions = <StreamSubscription>[];

  final _logger = Logger('WebkitDebugger');

  /// How often [enable] resends `Debugger.enable` while waiting for Chrome to
  /// respond.
  final Duration _enableRetryInterval;

  /// How long [enable] waits for Chrome to respond to `Debugger.enable`.
  final Duration _enableTimeout;

  @override
  Future<void> Function()? onReconnect;

  WebkitDebugger(
    this._wipDebugger, {
    this._enableRetryInterval = const Duration(seconds: 5),
    this._enableTimeout = const Duration(minutes: 3),
  }) {
    _initialize();
  }

  void _initialize() {
    late StreamSubscription sub;
    sub = _wipDebugger.connection.onClose.listen((connection) async {
      await sub.cancel();
      if (_closed != null) {
        // The connection closing is expected.
        await _shutdown(connection);
        return;
      }
      final previousDebugger = _wipDebugger;
      var retry = false;
      var retryCount = 0;
      const maxAttempts = 5;
      do {
        retry = false;
        WipConnection? newConnection;
        try {
          newConnection = await WipConnection.connect(connection.url);
          // Stop if the debugger was closed while reconnecting.
          if (_closed != null) break;
          _wipDebugger = WipDebugger(newConnection);
          // Requests on a closed connection never complete, so stop waiting for
          // onReconnect if the debugger is closed or the connection is lost.
          await Future.any([
            onReconnect?.call() ?? Future<void>.value(),
            _disconnected.future,
            newConnection.onClose.first.then(
              (_) => throw const WebSocketException(
                'The connection to Chrome was lost while reconnecting.',
              ),
            ),
          ]);
          if (_closed != null) break;
          newConnection = null; // Reconnected, so keep it open.
        } on Exception {
          await Future<void>.delayed(Duration(milliseconds: 25 << retryCount));
          retry = true;
          retryCount++;
        } finally {
          // Unless we reconnected, go back to the previous connection and
          // close the new one.
          if (newConnection != null) {
            _wipDebugger = previousDebugger;
            await newConnection.close();
          }
        }
      } while (retry && retryCount <= maxAttempts && _closed == null);
      if (_closed != null || retryCount > maxAttempts) {
        await _shutdown(connection);
      } else {
        _initialize();
      }
    });

    final runtime = _wipDebugger.connection.runtime;
    _streamSubscriptions
      ..forEach((e) => e.cancel())
      ..clear()
      ..addAll([
        runtime.onConsoleAPICalled.listen(_onConsoleAPICalledController.add),
        runtime.onExceptionThrown.listen(_onExceptionThrownController.add),
        _wipDebugger.onGlobalObjectCleared.listen(
          _onGlobalObjectClearedController.add,
        ),
        _wipDebugger.onPaused.listen(_onPausedController.add),
        _wipDebugger.onResumed.listen(_onResumedController.add),
        _wipDebugger.onScriptParsed.listen(_onScriptParsedController.add),
        _wipDebugger
            .eventStream(
              'Inspector.targetCrashed',
              (WipEvent event) => TargetCrashedEvent(event.json),
            )
            .listen(_onTargetCrashedController.add),

        for (final MapEntry(:key, value: (:controller, :transformer))
            in _eventStreams.entries)
          _wipDebugger
              .eventStream(key, transformer)
              .listen(controller.add, onError: controller.addError),
      ]);
  }

  Future<void> _shutdown(WipConnection connection) async {
    if (!_disconnected.isCompleted) _disconnected.complete();
    _onClosedController.add(connection);
    await Future.wait([
      for (final controller in _controllers) controller.close(),
      for (final MapEntry(value: (:controller, transformer: _))
          in _eventStreams.entries)
        controller.close(),
    ]);
  }

  @override
  Stream<ConsoleAPIEvent> get onConsoleAPICalled =>
      _onConsoleAPICalledController.stream;

  @override
  Stream<ExceptionThrownEvent> get onExceptionThrown =>
      _onExceptionThrownController.stream;

  @override
  Future<WipResponse> sendCommand(
    String command, {
    Map<String, dynamic>? params,
  }) => _wipDebugger.sendCommand(command, params: params);

  @override
  Future<void> close() => _closed ??= () async {
    if (!_disconnected.isCompleted) _disconnected.complete();
    await _wipDebugger.connection.close();
    await Future.wait([for (final sub in _streamSubscriptions) sub.cancel()]);
  }();

  @override
  Future<void> disable() => _wipDebugger.disable();

  /// Sends `Debugger.enable` and waits for Chrome to respond.
  ///
  /// Lost requests are resent every [_enableRetryInterval].
  /// Chrome can take a long time to respond to the first request (for large
  /// apps). Complete when any response arrives for any resent request.
  ///
  /// Throws a [TimeoutException] if Chrome doesn't respond within
  /// [_enableTimeout]. Throws a [WebSocketException] when the debugger is
  /// closed or its connection is lost.
  @override
  Future<void> enable() async {
    final stopwatch = Stopwatch()..start();
    final requests = <Future<void>>[];
    while (!_disconnected.isCompleted) {
      if (stopwatch.elapsed >= _enableTimeout) {
        throw TimeoutException(
          'Debugger.enable did not complete',
          _enableTimeout,
        );
      }
      requests.add(_wipDebugger.enable());
      try {
        // Wait for Chrome to respond to any of the requests, or for the
        // debugger to be disconnected.
        await Future.any([...requests, _disconnected.future])
            .timeout(_enableRetryInterval);
        if (!_disconnected.isCompleted) return;
      } on TimeoutException {
        _logger.fine(
          'Debugger.enable has not completed after ${stopwatch.elapsed}. '
          'Resending.',
        );
      }
    }
    throw _connectionClosedException;
  }

  static const _connectionClosedException = WebSocketException(
    'The connection to Chrome was closed before Debugger.enable completed.',
  );

  @override
  Future<String> getScriptSource(String scriptId) =>
      _wipDebugger.getScriptSource(scriptId);

  @override
  Future<WipResponse> pause() => _wipDebugger.pause();

  @override
  Future<WipResponse> resume() => _wipDebugger.resume();

  @override
  Future<WipResponse> setPauseOnExceptions(PauseState state) =>
      _wipDebugger.setPauseOnExceptions(state);

  @override
  Future<WipResponse> removeBreakpoint(String breakpointId) =>
      _wipDebugger.removeBreakpoint(breakpointId);

  @override
  Future<WipResponse> stepInto({Map<String, dynamic>? params}) =>
      _wipDebugger.stepInto(params: params);

  @override
  Future<WipResponse> stepOut() => _wipDebugger.stepOut();

  @override
  Future<WipResponse> stepOver({Map<String, dynamic>? params}) =>
      _wipDebugger.stepOver(params: params);

  @override
  Future<WipResponse> enablePage() => _wipDebugger.connection.page.enable();

  @override
  Future<WipResponse> pageReload() => _wipDebugger.connection.page.reload();

  @override
  Future<RemoteObject> evaluate(
    String expression, {
    bool? returnByValue,
    int? contextId,
  }) {
    return _wipDebugger.connection.runtime.evaluate(
      expression,
      returnByValue: returnByValue,
    );
  }

  @override
  Future<RemoteObject> evaluateOnCallFrame(
    String callFrameId,
    String expression,
  ) {
    return _wipDebugger.connection.debugger.evaluateOnCallFrame(
      callFrameId,
      expression,
    );
  }

  @override
  Future<List<WipBreakLocation>> getPossibleBreakpoints(WipLocation start) {
    return _wipDebugger.connection.debugger.getPossibleBreakpoints(start);
  }

  @override
  Stream<T> eventStream<T>(String method, WipEventTransformer<T> transformer) {
    return _eventStreams
        .putIfAbsent(method, () {
          final controller = StreamController<T>();
          final stream = _wipDebugger.eventStream(method, transformer);
          stream.listen(controller.add, onError: controller.addError);
          return (controller: controller, transformer: transformer);
        })
        .controller
        .stream
        .cast<T>();
  }

  @override
  Stream<GlobalObjectClearedEvent> get onGlobalObjectCleared =>
      _onGlobalObjectClearedController.stream;

  @override
  Stream<DebuggerPausedEvent> get onPaused => _onPausedController.stream;

  @override
  Stream<DebuggerResumedEvent> get onResumed => _onResumedController.stream;

  @override
  Stream<ScriptParsedEvent> get onScriptParsed =>
      _onScriptParsedController.stream;

  @override
  Stream<TargetCrashedEvent> get onTargetCrashed =>
      _onTargetCrashedController.stream;

  @override
  Map<String, WipScript> get scripts => _wipDebugger.scripts;

  @override
  Stream<WipConnection> get onClose => _onClosedController.stream;
}
