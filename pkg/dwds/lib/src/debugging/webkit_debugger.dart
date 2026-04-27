// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dwds/src/debugging/remote_debugger.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

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

  @override
  Future<void> Function()? onReconnect;

  WebkitDebugger(this._wipDebugger) {
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
      var retry = false;
      var retryCount = 0;
      const maxAttempts = 5;
      do {
        retry = false;
        try {
          _wipDebugger = WipDebugger(
            await WipConnection.connect(connection.url),
          );
          await onReconnect?.call();
        } on Exception {
          await Future<void>.delayed(Duration(milliseconds: 25 << retryCount));
          retry = true;
          retryCount++;
        }
      } while (retry && retryCount <= maxAttempts);
      if (retryCount > maxAttempts) {
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
    await _wipDebugger.connection.close();
    await Future.wait([for (final sub in _streamSubscriptions) sub.cancel()]);
  }();

  @override
  Future<void> disable() => _wipDebugger.disable();

  @override
  Future<void> enable() async {
    // TODO(markzipan): Handle race conditions more gracefully.
    // Try to enable the debugger multiple times.
    var attempts = 3;
    while (true) {
      try {
        await _wipDebugger.enable().timeout(const Duration(seconds: 5));
        return;
      } on TimeoutException {
        if (attempts-- == 0) rethrow;
      }
    }
  }

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
