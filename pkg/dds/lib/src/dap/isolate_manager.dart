// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart' as vm;

import 'adapters/dart.dart';
import 'exceptions.dart';
import 'protocol_generated.dart';

/// Manages state of Isolates (called Threads by the DAP protocol).
///
/// Handles incoming Isolate and Debug events to track the lifetime of isolates
/// and updating breakpoints for each isolate as necessary.
class IsolateManager {
  // TODO(dantup): This class has a lot of overlap with the same-named class
  //  in DDS. Review what can be shared.
  final DartDebugAdapter _adapter;
  final Map<String, Completer<void>> _isolateRegistrations = {};
  final Map<String, ThreadInfo> _threadsByIsolateId = {};
  final Map<int, ThreadInfo> _threadsByThreadId = {};
  int _nextThreadNumber = 1;

  /// Whether debugging is enabled.
  ///
  /// This must be set before any isolates are spawned and controls whether
  /// breakpoints or exception pause modes are sent to the VM.
  ///
  /// This is used to support debug sessions that have VM Service connections
  /// but were run with noDebug: true (for example we may need a VM Service
  /// connection for a noDebug flutter app in order to support hot reload).
  bool _debug = false;

  /// Tracks breakpoints last provided by the client so they can be sent to new
  /// isolates that appear after initial breakpoints were sent.
  final Map<String, List<SourceBreakpoint>> _clientBreakpointsByUri = {};

  /// Tracks breakpoints created in the VM so they can be removed when the
  /// editor sends new breakpoints (currently the editor just sends a new list
  /// and not requests to add/remove).
  final Map<String, Map<String, List<vm.Breakpoint>>>
      _vmBreakpointsByIsolateIdAndUri = {};

  /// The exception pause mode last provided by the client.
  ///
  /// This will be sent to isolates as they are created, and to all existing
  /// isolates at start or when changed.
  String _exceptionPauseMode = 'None';

  /// An incrementing number used as the reference for [_storedData].
  var _nextStoredDataId = 1;

  /// A store of data indexed by a number that is used for round tripping
  /// references to the client (which only accepts ints).
  ///
  /// For example, when we send a stack frame back to the client we provide only
  /// a "sourceReference" integer and the client may later ask us for the source
  /// using that number (via sourceRequest).
  ///
  /// Stored data is thread-scoped but the client will not provide the thread
  /// when asking for data so it's all stored together here.
  final _storedData = <int, _StoredData>{};

  IsolateManager(this._adapter);

  /// A list of all current active isolates.
  ///
  /// When isolates exit, they will no longer be returned in this list, although
  /// due to the async nature, it's not guaranteed that threads in this list have
  /// not exited between accessing this list and trying to use the results.
  List<ThreadInfo> get threads => _threadsByIsolateId.values.toList();

  Future<T> getObject<T extends vm.Response>(
      vm.IsolateRef isolate, vm.ObjRef object) async {
    final res = await _adapter.vmService?.getObject(isolate.id!, object.id!);
    return res as T;
  }

  /// Retrieves some basic data indexed by an integer for use in "reference"
  /// fields that are round-tripped to the client.
  _StoredData? getStoredData(int id) {
    return _storedData[id];
  }

  ThreadInfo? getThread(int threadId) => _threadsByThreadId[threadId];

  /// Handles Isolate and Debug events
  Future<void> handleEvent(vm.Event event) async {
    final isolateId = event.isolate?.id;
    if (isolateId == null) {
      return;
    }

    final eventKind = event.kind;
    if (eventKind == vm.EventKind.kIsolateStart ||
        eventKind == vm.EventKind.kIsolateRunnable) {
      await registerIsolate(event.isolate!, eventKind!);
    }

    // Additionally, ensure the thread registration has completed before trying
    // to process any other events. This is to cover the case where we are
    // processing the above registerIsolate call in the handler for one isolate
    // event but another one arrives and gets us here before the registration
    // above (in the other event handler) has finished.
    await _isolateRegistrations[isolateId]?.future;

    if (eventKind == vm.EventKind.kIsolateExit) {
      _handleExit(event);
    } else if (eventKind?.startsWith('Pause') ?? false) {
      await _handlePause(event);
    } else if (eventKind == vm.EventKind.kResume) {
      _handleResumed(event);
    }
  }

  /// Registers a new isolate that exists at startup, or has subsequently been
  /// created.
  ///
  /// New isolates will be configured with the correct pause-exception behaviour,
  /// libraries will be marked as debuggable if appropriate, and breakpoints
  /// sent.
  Future<void> registerIsolate(
    vm.IsolateRef isolate,
    String eventKind,
  ) async {
    // Ensure the completer is set up before doing any async work, so future
    // events can wait on it.
    final registrationCompleter =
        _isolateRegistrations.putIfAbsent(isolate.id!, () => Completer<void>());

    final info = _threadsByIsolateId.putIfAbsent(
      isolate.id!,
      () {
        // The first time we see an isolate, start tracking it.
        final info = ThreadInfo(this, _nextThreadNumber++, isolate);
        _threadsByThreadId[info.threadId] = info;
        // And notify the client about it.
        _adapter.sendEvent(
          ThreadEventBody(reason: 'started', threadId: info.threadId),
        );
        return info;
      },
    );

    // If it's just become runnable (IsolateRunnable), configure the isolate
    // by sending breakpoints etc.
    if (eventKind == vm.EventKind.kIsolateRunnable && !info.runnable) {
      info.runnable = true;
      await _configureIsolate(isolate);
      registrationCompleter.complete();
    }
  }

  Future<void> resumeIsolate(vm.IsolateRef isolateRef,
      [String? resumeType]) async {
    final isolateId = isolateRef.id;
    if (isolateId == null) {
      return;
    }

    final thread = _threadsByIsolateId[isolateId];
    if (thread == null) {
      return;
    }

    await resumeThread(thread.threadId);
  }

  /// Resumes (or steps) an isolate using its client [threadId].
  ///
  /// If the isolate is not paused, or already has a pending resume request
  /// in-flight, a request will not be sent.
  ///
  /// If the isolate is paused at an async suspension and the [resumeType] is
  /// [vm.StepOption.kOver], a [StepOption.kOverAsyncSuspension] step will be
  /// sent instead.
  Future<void> resumeThread(int threadId, [String? resumeType]) async {
    final thread = _threadsByThreadId[threadId];
    if (thread == null) {
      throw DebugAdapterException('Thread $threadId was not found');
    }

    // Check this thread hasn't already been resumed by another handler in the
    // meantime (for example if the user performs a hot restart or something
    // while we processing some previous events).
    if (!thread.paused || thread.hasPendingResume) {
      return;
    }

    // We always assume that a step when at an async suspension is intended to
    // be an async step.
    if (resumeType == vm.StepOption.kOver && thread.atAsyncSuspension) {
      resumeType = vm.StepOption.kOverAsyncSuspension;
    }

    thread.hasPendingResume = true;
    try {
      await _adapter.vmService?.resume(thread.isolate.id!, step: resumeType);
    } finally {
      thread.hasPendingResume = false;
    }
  }

  /// Records breakpoints for [uri].
  ///
  /// [breakpoints] represents the new set and entirely replaces anything given
  /// before.
  Future<void> setBreakpoints(
    String uri,
    List<SourceBreakpoint> breakpoints,
  ) async {
    // Track the breakpoints to get sent to any new isolates that start.
    _clientBreakpointsByUri[uri] = breakpoints;

    // Send the breakpoints to all existing threads.
    await Future.wait(_threadsByThreadId.values
        .map((isolate) => _sendBreakpoints(isolate.isolate, uri: uri)));
  }

  /// Sets whether debugging is enabled for this session.
  ///
  /// If not, requests to send breakpoints or exception pause mode will be
  /// dropped. Other functionality (handling pause events, resuming, etc.) will
  /// all still function.
  ///
  /// This is used to support debug sessions that have VM Service connections
  /// but were run with noDebug: true (for example we may need a VM Service
  /// connection for a noDebug flutter app in order to support hot reload).
  void setDebugEnabled(bool debug) {
    _debug = debug;
  }

  /// Records exception pause mode as one of 'None', 'Unhandled' or 'All'. All
  /// existing isolates will be updated to reflect the new setting.
  Future<void> setExceptionPauseMode(String mode) async {
    _exceptionPauseMode = mode;

    // Send to all existing threads.
    await Future.wait(_threadsByThreadId.values.map(
      (isolate) => _sendExceptionPauseMode(isolate.isolate),
    ));
  }

  /// Stores some basic data indexed by an integer for use in "reference" fields
  /// that are round-tripped to the client.
  int storeData(ThreadInfo thread, Object data) {
    final id = _nextStoredDataId++;
    _storedData[id] = _StoredData(thread, data);
    return id;
  }

  ThreadInfo? threadForIsolate(vm.IsolateRef? isolate) =>
      isolate?.id != null ? _threadsByIsolateId[isolate!.id!] : null;

  /// Configures a new isolate, setting it's exception-pause mode, which
  /// libraries are debuggable, and sending all breakpoints.
  Future<void> _configureIsolate(vm.IsolateRef isolate) async {
    await Future.wait([
      _sendLibraryDebuggables(isolate),
      _sendExceptionPauseMode(isolate),
      _sendBreakpoints(isolate),
    ], eagerError: true);
  }

  void _handleExit(vm.Event event) {
    final isolate = event.isolate!;
    final isolateId = isolate.id!;
    final thread = _threadsByIsolateId[isolateId];
    if (thread != null) {
      // Notify the client.
      _adapter.sendEvent(
        ThreadEventBody(reason: 'exited', threadId: thread.threadId),
      );
      _threadsByIsolateId.remove(isolateId);
      _threadsByThreadId.remove(thread.threadId);
    }
  }

  /// Handles a pause event.
  ///
  /// For [vm.EventKind.kPausePostRequest] which occurs after a restart, the isolate
  /// will be re-configured (pause-exception behaviour, debuggable libraries,
  /// breakpoints) and then resumed.
  ///
  /// For [vm.EventKind.kPauseStart], the isolate will be resumed.
  ///
  /// For breakpoints with conditions that are not met and for logpoints, the
  /// isolate will be automatically resumed.
  ///
  /// For all other pause types, the isolate will remain paused and a
  /// corresponding "Stopped" event sent to the editor.
  Future<void> _handlePause(vm.Event event) async {
    final eventKind = event.kind;
    final isolate = event.isolate!;
    final thread = _threadsByIsolateId[isolate.id!];

    if (thread == null) {
      return;
    }

    thread.atAsyncSuspension = event.atAsyncSuspension ?? false;
    thread.paused = true;
    thread.pauseEvent = event;

    // For PausePostRequest we need to re-send all breakpoints; this happens
    // after a hot restart.
    if (eventKind == vm.EventKind.kPausePostRequest) {
      await _configureIsolate(isolate);
      await resumeThread(thread.threadId);
    } else if (eventKind == vm.EventKind.kPauseStart) {
      // Don't resume from a PauseStart if this has already happened (see
      // comments on [thread.hasBeenStarted]).
      if (!thread.hasBeenStarted) {
        thread.hasBeenStarted = true;
        await resumeThread(thread.threadId);
      }
    } else {
      // PauseExit, PauseBreakpoint, PauseInterrupted, PauseException
      var reason = 'pause';

      if (eventKind == vm.EventKind.kPauseBreakpoint &&
          (event.pauseBreakpoints?.isNotEmpty ?? false)) {
        reason = 'breakpoint';
      } else if (eventKind == vm.EventKind.kPauseBreakpoint) {
        reason = 'step';
      } else if (eventKind == vm.EventKind.kPauseException) {
        reason = 'exception';
      }

      // If we stopped at an exception, capture the exception instance so we
      // can add a variables scope for it so it can be examined.
      final exception = event.exception;
      if (exception != null) {
        thread.exceptionReference = thread.storeData(exception);
      }

      // Notify the client.
      _adapter.sendEvent(
        StoppedEventBody(reason: reason, threadId: thread.threadId),
      );
    }
  }

  /// Handles a resume event from the VM, updating our local state.
  void _handleResumed(vm.Event event) {
    final isolate = event.isolate!;
    final thread = _threadsByIsolateId[isolate.id!];
    if (thread != null) {
      thread.paused = false;
      thread.pauseEvent = null;
      thread.exceptionReference = null;
    }
  }

  bool _isExternalPackageLibrary(vm.LibraryRef library) =>
      // TODO(dantup): This needs to check if it's _external_, eg.
      //
      // - is from the flutter SDK (flutter, flutter_test, ...)
      // - is from pub/pubcache
      //
      // This is intended to match the users idea of "my code". For example
      // they may wish to debug the current app being run, as well as any other
      // projects that are references with path: dependencies (which are likely
      // their own supporting projects).
      false /*library.uri?.startsWith('package:') ?? false*/;

  bool _isSdkLibrary(vm.LibraryRef library) =>
      library.uri?.startsWith('dart:') ?? false;

  /// Checks whether a library should be considered debuggable.
  ///
  /// This usesthe settings from the launch arguments (debugSdkLibraries
  /// and debugExternalPackageLibraries) against the type of library given.
  bool _libaryIsDebuggable(vm.LibraryRef library) {
    if (_isSdkLibrary(library)) {
      return _adapter.args.debugSdkLibraries ?? false;
    } else if (_isExternalPackageLibrary(library)) {
      return _adapter.args.debugExternalPackageLibraries ?? false;
    } else {
      return true;
    }
  }

  /// Sets breakpoints for an individual isolate.
  ///
  /// If [uri] is provided, only breakpoints for that URI will be sent (used
  /// when breakpoints are modified for a single file in the editor). Otherwise
  /// breakpoints for all previously set URIs will be sent (used for
  /// newly-created isolates).
  Future<void> _sendBreakpoints(vm.IsolateRef isolate, {String? uri}) async {
    final service = _adapter.vmService;
    if (!_debug || service == null) {
      return;
    }

    final isolateId = isolate.id!;

    // If we were passed a single URI, we should send breakpoints only for that
    // (this means the request came from the client), otherwise we should send
    // all of them (because this is a new/restarting isolate).
    final uris = uri != null ? [uri] : _clientBreakpointsByUri.keys;

    for (final uri in uris) {
      // Clear existing breakpoints.
      final existingBreakpointsForIsolate =
          _vmBreakpointsByIsolateIdAndUri.putIfAbsent(isolateId, () => {});
      final existingBreakpointsForIsolateAndUri =
          existingBreakpointsForIsolate.putIfAbsent(uri, () => []);
      await Future.forEach<vm.Breakpoint>(existingBreakpointsForIsolateAndUri,
          (bp) => service.removeBreakpoint(isolateId, bp.id!));

      // Set new breakpoints.
      final newBreakpoints = _clientBreakpointsByUri[uri] ?? const [];
      await Future.forEach<SourceBreakpoint>(newBreakpoints, (bp) async {
        final vmBp = await service.addBreakpointWithScriptUri(
            isolateId, uri, bp.line,
            column: bp.column);
        existingBreakpointsForIsolateAndUri.add(vmBp);
      });
    }
  }

  /// Sets the exception pause mode for an individual isolate.
  Future<void> _sendExceptionPauseMode(vm.IsolateRef isolate) async {
    final service = _adapter.vmService;
    if (!_debug || service == null) {
      return;
    }

    await service.setExceptionPauseMode(isolate.id!, _exceptionPauseMode);
  }

  /// Calls setLibraryDebuggable for all libraries in the given isolate based
  /// on the debug settings.
  Future<void> _sendLibraryDebuggables(vm.IsolateRef isolateRef) async {
    final service = _adapter.vmService;
    if (!_debug || service == null) {
      return;
    }

    final isolateId = isolateRef.id;
    if (isolateId == null) {
      return;
    }

    final isolate = await service.getIsolate(isolateId);
    final libraries = isolate.libraries;
    if (libraries == null) {
      return;
    }
    await Future.wait(libraries.map((library) async {
      final isDebuggable = _libaryIsDebuggable(library);
      await service.setLibraryDebuggable(isolateId, library.id!, isDebuggable);
    }));
  }
}

/// Holds state for a single Isolate/Thread.
class ThreadInfo {
  final IsolateManager _manager;
  final vm.IsolateRef isolate;
  final int threadId;
  var runnable = false;
  var atAsyncSuspension = false;
  int? exceptionReference;
  var paused = false;

  /// Tracks whether an isolate has been started from its PauseStart state.
  ///
  /// This is used to prevent trying to resume a thread twice if a PauseStart
  /// event arrives around the same time that are our initialization code (which
  /// automatically resumes threads that are in the PauseStart state when we
  /// connect).
  ///
  /// If we send a duplicate resume, it could trigger an unwanted resume for a
  /// breakpoint or exception that occur early on.
  bool hasBeenStarted = false;

  // The most recent pauseEvent for this isolate.
  vm.Event? pauseEvent;

  // A cache of requests (Futures) to fetch scripts, so that multiple requests
  // that require scripts (for example looking up locations for stack frames from
  // tokenPos) can share the same response.
  final _scripts = <String, Future<vm.Script>>{};

  /// Whether this isolate has an in-flight resume request that has not yet
  /// been responded to.
  var hasPendingResume = false;

  ThreadInfo(this._manager, this.threadId, this.isolate);

  Future<T> getObject<T extends vm.Response>(vm.ObjRef ref) =>
      _manager.getObject<T>(isolate, ref);

  /// Fetches a script for a given isolate.
  ///
  /// Results from this method are cached so that if there are multiple
  /// concurrent calls (such as when converting multiple stack frames) they will
  /// all use the same script.
  Future<vm.Script> getScript(vm.ScriptRef script) {
    return _scripts.putIfAbsent(script.id!, () => getObject<vm.Script>(script));
  }

  /// Stores some basic data indexed by an integer for use in "reference" fields
  /// that are round-tripped to the client.
  int storeData(Object data) => _manager.storeData(this, data);
}

class _StoredData {
  final ThreadInfo thread;
  final Object data;

  _StoredData(this.thread, this.data);
}
