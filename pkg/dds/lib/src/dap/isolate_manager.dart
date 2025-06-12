// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:dap/dap.dart';
import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:vm_service/vm_service.dart' as vm;

import '../rpc_error_codes.dart';
import 'adapters/dart.dart';
import 'adapters/mixins.dart';
import 'utils.dart';
import 'variables.dart';

/// A composite ID for breakpoints made up of an isolate ID and breakpoint ID.
///
/// Breakpoint IDs are not unique across all isolates so any place we need to
/// know about a breakpoint specifically, we must use this.
typedef _UniqueVmBreakpointId = ({String isolateId, String breakpointId});

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

  /// Whether debugging is enabled for this session.
  ///
  /// This must be set before any isolates are spawned and controls whether
  /// breakpoints or exception pause modes are sent to the VM.
  ///
  /// If false, requests to send breakpoints or exception pause mode will be
  /// dropped. Other functionality (handling pause events, resuming, etc.) will
  /// all still function.
  ///
  /// This is used to support debug sessions that have VM Service connections
  /// but were run with noDebug: true (for example we may need a VM Service
  /// connection for a noDebug flutter app in order to support hot reload).
  bool debug = false;

  /// Whether SDK libraries should be marked as debuggable.
  ///
  /// Calling [sendLibraryDebuggables] is required after changing this value to
  /// apply changes. This allows applying both [debugSdkLibraries] and
  /// [debugExternalPackageLibraries] in one step.
  bool debugSdkLibraries = true;

  /// Whether external package libraries should be marked as debuggable.
  ///
  /// Calling [sendLibraryDebuggables] is required after changing this value to
  /// apply changes. This allows applying both [debugSdkLibraries] and
  /// [debugExternalPackageLibraries] in one step.
  bool debugExternalPackageLibraries = true;

  /// Tracks breakpoints last provided by the client (by the client URI) so they
  /// can be sent to new isolates that appear after initial breakpoints were sent.
  final Map<String, List<ClientBreakpoint>> clientBreakpointsByUri = {};

  /// Tracks client breakpoints by the ID assigned by the VM so we can look up
  /// conditions/logpoints when hitting breakpoints.
  ///
  /// Because the VM might return the same breakpoint for multiple
  /// `addBreakpointWithScriptUri` calls (if they immediately resolve to the
  /// same location) there may be multiple client breakpoints for a given VM
  /// breakpoint ID.
  ///
  /// When an item is added to this map, any pending events in
  /// [_breakpointResolvedEventsByVmId] MUST be processed immediately.
  final Map<_UniqueVmBreakpointId, List<ClientBreakpoint>>
      _clientBreakpointsByVmId = {};

  /// Tracks `BreakpointAdded` or `BreakpointResolved` events for VM
  /// breakpoints.
  ///
  /// These are kept for all breakpoints until they are removed by the VM
  /// because it's always possible that the VM will reuse a breakpoint ID (eg.
  /// if we add a new breakpoint that resolves to the same location as another
  /// breakpoint).
  ///
  /// When new breakpoints are added by the client, we must check this map to
  /// see it's an already-resolved breakpoint so that we can send resolution
  /// info to the client.
  final Map<_UniqueVmBreakpointId, vm.Event> _breakpointResolvedEventsByVmId =
      {};

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
  final _storedData = <int, StoredData>{};

  /// A pattern that matches an opening brace `{` that was not preceded by a
  /// dollar.
  ///
  /// Any leading character matched in place of the dollar is in the first capture.
  final _braceNotPrefixedByDollarOrBackslashPattern = RegExp(r'(^|[^\\\$]){');

  /// A [RegExp] to extract the useful part of an error message when adding
  /// breakpoints so that the tooltip shown in editors can be less wordy.
  final _terseBreakpointFailureRegex =
      RegExp(r'Error occurred when resolving breakpoint location: (.*?)\.?$');

  IsolateManager(this._adapter);

  /// A list of all current active isolates.
  ///
  /// When isolates exit, they will no longer be returned in this list, although
  /// due to the async nature, it's not guaranteed that threads in this list have
  /// not exited between accessing this list and trying to use the results.
  List<ThreadInfo> get threads => _threadsByIsolateId.values.toList();

  /// Re-applies debug options to all isolates/libraries.
  ///
  /// This is required if options like debugSdkLibraries are modified, but is a
  /// separate step to batch together changes to multiple options.
  Future<void> applyDebugOptions() async {
    await Future.wait(_threadsByThreadId.values.map(
      // debuggable libraries is the only thing currently affected by these
      // changable options.
      (thread) => _sendLibraryDebuggables(thread),
    ));
  }

  Future<T> getObject<T extends vm.Response>(
    vm.IsolateRef isolate,
    vm.ObjRef object, {
    int? offset,
    int? count,
  }) async {
    final res = await _adapter.vmService?.getObject(
      isolate.id!,
      object.id!,
      offset: offset,
      count: count,
    );
    return res as T;
  }

  Future<vm.ScriptList> getScripts(vm.IsolateRef isolate) async {
    return (await _adapter.vmService?.getScripts(isolate.id!)) as vm.ScriptList;
  }

  /// Retrieves some basic data indexed by an integer for use in "reference"
  /// fields that are round-tripped to the client.
  StoredData? getStoredData(int id) {
    return _storedData[id];
  }

  ThreadInfo? getThread(int threadId) => _threadsByThreadId[threadId];

  /// Handles Isolate and Debug events.
  Future<void> handleEvent(vm.Event event) async {
    final isolateId = event.isolate?.id!;

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
    } else if (eventKind == vm.EventKind.kInspect) {
      _handleInspect(event);
    } else if (eventKind == vm.EventKind.kBreakpointAdded ||
        eventKind == vm.EventKind.kBreakpointResolved) {
      _handleBreakpointAddedOrResolved(event);
    }
  }

  /// Registers a new isolate that exists at startup, or has subsequently been
  /// created.
  ///
  /// New isolates will be configured with the correct pause-exception behaviour,
  /// libraries will be marked as debuggable if appropriate, and breakpoints
  /// sent.
  Future<ThreadInfo> registerIsolate(
    vm.IsolateRef isolate,
    String eventKind,
  ) async {
    // Ensure the completer is set up before doing any async work, so future
    // events can wait on it.
    final registrationCompleter =
        _isolateRegistrations.putIfAbsent(isolate.id!, () => Completer<void>());

    final thread = _threadsByIsolateId.putIfAbsent(
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
    if (eventKind == vm.EventKind.kIsolateRunnable && !thread.runnable) {
      thread.runnable = true;
      await _configureIsolate(thread);
      registrationCompleter.complete();
    }

    return thread;
  }

  /// Calls reloadSources for all isolates.
  Future<void> reloadSources() async {
    await Future.wait(_threadsByThreadId.values.map(
      (isolate) => _reloadSources(isolate.isolate),
    ));
  }

  Future<void> resumeIsolate(vm.IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;

    final thread = _threadsByIsolateId[isolateId];
    if (thread == null) {
      return;
    }

    await resumeThread(thread.threadId);
  }

  Future<void> readyToResumeIsolate(vm.IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;

    final thread = _threadsByIsolateId[isolateId];
    if (thread == null) {
      return;
    }

    await readyToResumeThread(thread.threadId);
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
    await _resume(threadId, resumeType: resumeType);
  }

  /// Resumes an isolate using its client [threadId].
  ///
  /// CAUTION: This should only be used for a tool-initiated resume, not a user-
  /// initiated resume.
  ///
  /// See: https://pub.dev/documentation/dds_service_extensions/latest/dds_service_extensions/DdsExtension/readyToResume.html
  Future<void> readyToResumeThread(int threadId) async {
    await _readyToResume(threadId);
  }

  /// Rewinds an isolate to an earlier frame using its client [threadId].
  ///
  /// If the isolate is not paused, or already has a pending resume request
  /// in-flight, a request will not be sent.
  Future<void> rewindThread(int threadId, {required int frameIndex}) async {
    await _resume(
      threadId,
      resumeType: vm.StepOption.kRewind,
      frameIndex: frameIndex,
    );
  }

  /// Resumes (or steps) an isolate using its client [threadId] on behalf
  /// of the user.
  ///
  /// If the isolate is not paused, or already has a pending resume request
  /// in-flight, a request will not be sent.
  ///
  /// If the isolate is paused at an async suspension and the [resumeType] is
  /// [vm.StepOption.kOver], a [vm.StepOption.kOverAsyncSuspension] step will be
  /// sent instead.
  ///
  /// If [resumeType] is [vm.StepOption.kRewind], [frameIndex] must be supplied.
  Future<void> _resume(
    int threadId, {
    String? resumeType,
    int? frameIndex,
  }) async {
    final thread = _threadsByThreadId[threadId];
    if (thread == null) {
      if (isInvalidThreadId(threadId)) {
        throw DebugAdapterException('Thread $threadId was not found');
      } else {
        // Otherwise, this thread has exited and we don't need to do anything.
        // It's possible another debugger unpaused or we're shutting down and
        // the VM has terminated it.
        return;
      }
    }

    // Check this thread hasn't already been resumed by another handler in the
    // meantime (for example if the user performs a hot restart or something
    // while we processing some previous events).
    if (!thread.paused || thread.hasPendingUserResume) {
      return;
    }

    // We always assume that a step when at an async suspension is intended to
    // be an async step.
    if (resumeType == vm.StepOption.kOver && thread.atAsyncSuspension) {
      resumeType = vm.StepOption.kOverAsyncSuspension;
    }

    // Finally, when we're resuming, all stored objects become invalid and
    // we can drop them to save memory.
    await thread.clearTemporaryData();

    thread.hasPendingUserResume = true;
    try {
      await _adapter.vmService?.resume(
        thread.isolate.id!,
        step: resumeType,
        frameIndex: frameIndex,
      );
    } on vm.SentinelException {
      // It's possible during these async requests that the isolate went away
      // (for example a shutdown/restart) and we no longer care about
      // resuming it.
    } on vm.RPCError catch (e) {
      if (e.code == RpcErrorCodes.kIsolateMustBePaused) {
        // It's possible something else resumed the thread (such as if another
        // debugger is attached), we can just continue.
      } else if (e.isServiceDisposedError) {
        // The VM service connection was terminated, we can silently ignore this
        // because we're likely shutting down.
      } else if (e.code == RpcErrorCodes.kInternalError &&
          e.message.contains('No running isolate (inspector is not set).')) {
        // TODO(bkonyi): remove once https://github.com/flutter/flutter/issues/156793
        // is resolved.
        // It's possible during these async requests that the isolate went away
        // (for example a shutdown/restart) and we no longer care about
        // resuming it.
      } else {
        rethrow;
      }
    } finally {
      thread.hasPendingUserResume = false;
    }
  }

  /// Resumes an isolate using its client [threadId].
  ///
  /// CAUTION: This should only be used for a tool-initiated resume, not a user-
  /// initiated resume.
  ///
  /// See: https://pub.dev/documentation/dds_service_extensions/latest/dds_service_extensions/DdsExtension/readyToResume.html
  Future<void> _readyToResume(int threadId) async {
    final thread = _threadsByThreadId[threadId];
    if (thread == null) {
      if (isInvalidThreadId(threadId)) {
        throw DebugAdapterException('Thread $threadId was not found');
      } else {
        // Otherwise, this thread has exited and we don't need to do anything.
        // It's possible another debugger unpaused or we're shutting down and
        // the VM has terminated it.
        return;
      }
    }

    final isolateId = thread.isolate.id!;
    try {
      // When we're resuming, all stored objects become invalid and we can drop
      // to save memory.
      await thread.clearTemporaryData();

      // Finally, signal that we're ready to resume.
      await _adapter.vmService?.readyToResume(isolateId);
    } on UnimplementedError {
      // Fallback to a regular resume if the DDS version doesn't support
      // `readyToResume`:
      return _resume(threadId);
    } on vm.SentinelException {
      // It's possible during these async requests that the isolate went away
      // (for example a shutdown/restart) and we no longer care about
      // resuming it.
    } on vm.RPCError catch (e) {
      if (e.code == RpcErrorCodes.kIsolateMustBePaused) {
        // It's possible something else resumed the thread (such as if another
        // debugger is attached), we can just continue.
      } else if (e.isServiceDisposedError) {
        // The VM service connection was terminated, we can silently ignore this
        // because we're likely shutting down.
      } else if (e.code == RpcErrorCodes.kMethodNotFound) {
        // Fallback to a regular resume if the DDS service extension isn't
        // available:
        return _resume(threadId);
      } else if (e.code == RpcErrorCodes.kInternalError &&
          e.message.contains('No running isolate (inspector is not set).')) {
        // TODO(bkonyi): remove once https://github.com/flutter/flutter/issues/156793
        // is resolved.
        // It's possible during these async requests that the isolate went away
        // (for example a shutdown/restart) and we no longer care about
        // resuming it.
      } else {
        rethrow;
      }
    }
  }

  /// Pauses an isolate using its client [threadId].
  ///
  /// This is simply a _request_ to pause. It does not change any state by
  /// itself - we will handle the pause via an event if the pause request
  /// succeeds.
  Future<void> pauseThread(int threadId) async {
    final thread = _threadsByThreadId[threadId];
    if (thread == null) {
      if (isInvalidThreadId(threadId)) {
        throw DebugAdapterException('Thread $threadId was not found');
      } else {
        // Otherwise, this thread has recently exited so we cannot attempt
        // to pause it.
        return;
      }
    }

    try {
      await _adapter.vmService?.pause(thread.isolate.id!);
    } on vm.SentinelException {
      // It's possible during these async requests that the isolate went away
      // (for example a shutdown/restart) and we no longer care about
      // pausing it.
    } on vm.RPCError catch (e) {
      if (e.code == RpcErrorCodes.kInternalError &&
          e.message.contains('No running isolate (inspector is not set).')) {
        // TODO(bkonyi): remove once https://github.com/flutter/flutter/issues/156793
        // is resolved.
        // It's possible during these async requests that the isolate went away
        // (for example a shutdown/restart) and we no longer care about
        // resuming it.
      } else {
        rethrow;
      }
    }
  }

  /// Checks whether [threadId] is invalid and has never been used.
  ///
  /// Returns `false` is [threadId] corresponds to either a live, or previously
  /// exited thread.
  bool isInvalidThreadId(int threadId) => threadId >= _nextThreadNumber;

  /// Sends an event informing the client that a thread is stopped at entry.
  void sendStoppedOnEntryEvent(ThreadInfo thread) {
    _adapter.sendEvent(StoppedEventBody(
      reason: 'entry',
      threadId: thread.threadId,
      allThreadsStopped: false,
    ));
  }

  // Tracks the latest set of breakpoints sent by the client that should
  // be sent to any new isolates that start.
  void recordLatestClientBreakpoints(
    String uri,
    List<ClientBreakpoint> breakpoints,
  ) {
    clientBreakpointsByUri[uri] = breakpoints;
  }

  /// Clears all breakpoints.
  Future<void> clearAllBreakpoints() async {
    // Group all breakpoints for all URIs before clearing the list.
    final clientBreakpointsToDelete =
        clientBreakpointsByUri.values.expand((bps) => bps).toList();
    clientBreakpointsByUri.clear();

    // Remove all breakpoints for all threads.
    await Future.wait(clientBreakpointsToDelete.map((clientBreakpoint) {
      return Future.wait(_threadsByThreadId.values
          .map((thread) => removeBreakpoint(clientBreakpoint, thread)));
    }));
  }

  /// Records exception pause mode as one of 'None', 'Unhandled' or 'All'. All
  /// existing isolates will be updated to reflect the new setting.
  Future<void> setExceptionPauseMode(String mode) async {
    _exceptionPauseMode = mode;

    // Send to all existing threads.
    await Future.wait(_threadsByThreadId.values.map(
      (thread) => _sendExceptionPauseMode(thread),
    ));
  }

  /// Stores some basic data indexed by an integer for use in "reference" fields
  /// that are round-tripped to the client.
  int storeData(ThreadInfo thread, Object data) {
    final id = _nextStoredDataId++;
    _storedData[id] = StoredData(thread, data);
    return id;
  }

  ThreadInfo? threadForIsolate(vm.IsolateRef? isolate) =>
      isolate?.id != null ? threadForIsolateId(isolate!.id!) : null;

  ThreadInfo? threadForIsolateId(String isolateId) =>
      _threadsByIsolateId[isolateId];

  /// Evaluates breakpoint condition [condition] and returns whether the result
  /// is true (or non-zero for a numeric), sending any evaluation error to the
  /// client.
  Future<bool> _breakpointConditionEvaluatesTrue(
    ThreadInfo thread,
    String condition,
  ) async {
    final result =
        await _evaluateAndPrintErrors(thread, condition, 'condition');
    if (result == null) {
      return false;
    }

    // Values we consider true for breakpoint conditions are boolean true,
    // or non-zero numerics.
    return (result.kind == vm.InstanceKind.kBool &&
            result.valueAsString == 'true') ||
        (result.kind == vm.InstanceKind.kInt && result.valueAsString != '0') ||
        (result.kind == vm.InstanceKind.kDouble && result.valueAsString != '0');
  }

  /// Configures a new isolate, setting it's exception-pause mode, which
  /// libraries are debuggable, and sending all breakpoints.
  Future<void> _configureIsolate(ThreadInfo thread) async {
    try {
      // Libraries must be set as debuggable _before_ sending breakpoints, or
      // they may fail for SDK sources.
      await Future.wait([
        _sendLibraryDebuggables(thread),
        _sendExceptionPauseMode(thread),
      ], eagerError: true);

      await Future.wait(clientBreakpointsByUri.entries.map((mapEntry) async {
        var clientUri = mapEntry.key;
        var clientBreakpoints = mapEntry.value;
        await Future.wait(clientBreakpoints.map((clientBreakpoint) =>
            addBreakpoint(clientBreakpoint, thread, clientUri)));
      }));
    } on vm.SentinelException {
      // It's possible during these async requests that the isolate went away
      // (for example a shutdown/restart) and we no longer care about
      // configuring it. State will be cleaned up by the IsolateExit event.
    } on vm.RPCError catch (e) {
      if (e.code == RpcErrorCodes.kInternalError &&
          e.message.contains('No running isolate (inspector is not set).')) {
        // TODO(bkonyi): remove once https://github.com/flutter/flutter/issues/156793
        // is resolved.
        // It's possible during these async requests that the isolate went away
        // (for example a shutdown/restart) and we no longer care about
        // resuming it.
      } else {
        rethrow;
      }
    }
  }

  /// Evaluates an expression, returning the result if it is a [vm.InstanceRef]
  /// and sending any error as an [OutputEvent].
  Future<vm.InstanceRef?> _evaluateAndPrintErrors(
    ThreadInfo thread,
    String expression,
    String type,
  ) async {
    try {
      final result = await _adapter.vmEvaluateInFrame(thread, 0, expression);

      if (result is vm.InstanceRef) {
        return result;
      } else if (result is vm.ErrorRef) {
        final message = result.message ?? '<error ref>';
        _adapter.sendConsoleOutput(
          'Debugger failed to evaluate breakpoint $type "$expression": $message',
        );
      } else if (result is vm.Sentinel) {
        final message = result.valueAsString ?? '<collected>';
        _adapter.sendConsoleOutput(
          'Debugger failed to evaluate breakpoint $type "$expression": $message',
        );
      }
    } catch (e) {
      _adapter.sendConsoleOutput(
        'Debugger failed to evaluate breakpoint $type "$expression": $e',
      );
    }
    return null;
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
  /// For [vm.EventKind.kPausePostRequest] which occurs after a restart, the
  /// isolate will be re-configured (pause-exception behaviour, debuggable
  /// libraries, breakpoints) and we'll declare we are ready to resume.
  ///
  /// For [vm.EventKind.kPauseStart] we'll declare we are ready to resume.
  ///
  /// For breakpoints with conditions that are not met and for logpoints, the
  /// isolate will be automatically resumed.
  ///
  /// For all other pause types, the isolate will remain paused and a
  /// corresponding "Stopped" event sent to the editor.
  Future<void> _handlePause(vm.Event event) async {
    final eventKind = event.kind;
    final isolate = event.isolate!;
    final isolateId = isolate.id!;
    final thread = _threadsByIsolateId[isolateId];

    if (thread == null) {
      return;
    }

    thread.atAsyncSuspension = event.atAsyncSuspension ?? false;
    thread.paused = true;
    thread.pauseEvent = event;

    // For PausePostRequest we need to re-send all breakpoints; this happens
    // after a hot restart.
    if (eventKind == vm.EventKind.kPausePostRequest) {
      await _configureIsolate(thread);

      // We always want to resume here regardless of whether startupHandled was
      // already `true` (because that might be from before the reload).
      // Therefore set the flag and resume always.
      thread.startupHandled = true;
      await readyToResumeThread(thread.threadId);
    } else if (eventKind == vm.EventKind.kPauseStart) {
      handleThreadStartup(thread, sendStoppedOnEntry: true);
    } else {
      // PauseExit, PauseBreakpoint, PauseInterrupted, PauseException
      var reason = 'pause';

      if (eventKind == vm.EventKind.kPauseBreakpoint &&
          (event.pauseBreakpoints?.isNotEmpty ?? false)) {
        reason = 'breakpoint';
        // Look up the client breakpoints that correspond to the VM breakpoint(s)
        // we hit. It's possible some of these may be missing because we could
        // hit a breakpoint that was set before we were attached.
        //
        // When multiple client breakpoints have been folded into a single VM
        // breakpoint, we (arbitrarily) use the first one for conditions and
        // logpoints.
        final clientBreakpoints = event.pauseBreakpoints!.map((bp) {
          final uniqueBreakpointId =
              (isolateId: isolateId, breakpointId: bp.id!);
          return _clientBreakpointsByVmId[uniqueBreakpointId]
              ?.firstOrNull
              ?.breakpoint;
        }).toSet();

        // Split into logpoints (which just print messages) and breakpoints.
        final logPoints = clientBreakpoints.nonNulls
            .where((bp) => bp.logMessage?.isNotEmpty ?? false)
            .toSet();
        final breakpoints = clientBreakpoints.difference(logPoints);

        await _processLogPoints(thread, logPoints);

        // Resume if there are no (non-logpoint) breakpoints, of any of the
        // breakpoints don't have false conditions.
        if (breakpoints.isEmpty ||
            !await _shouldHitBreakpoint(thread, breakpoints)) {
          await resumeThread(thread.threadId);
          return;
        }
      } else if (eventKind == vm.EventKind.kPauseBreakpoint) {
        reason = 'step';
      } else if (eventKind == vm.EventKind.kPauseException) {
        reason = 'exception';
      } else if (eventKind == vm.EventKind.kPauseExit) {
        reason = 'exit';
      }

      // If we stopped at an exception, capture the exception instance so we
      // can add a variables scope for it so it can be examined.
      final exception = event.exception;
      String? text;
      if (exception != null) {
        _adapter.storeEvaluateName(exception, threadExceptionExpression);
        thread.exceptionReference = thread.storeData(exception);
        text = await _adapter.getFullString(thread, exception);
      }

      // Notify the client.
      _adapter.sendEvent(
        StoppedEventBody(
          reason: reason,
          threadId: thread.threadId,
          allThreadsStopped: false,
          text: text,
        ),
      );
    }
  }

  /// Handles thread startup if it has not already been handled.
  ///
  /// This includes sending Stopped-on-Entry and sending a readyToResume.
  Future<void> handleThreadStartup(
    ThreadInfo thread, {
    required bool sendStoppedOnEntry,
  }) async {
    // Don't resume from a PauseStart if this has already happened (see
    // comments on [thread.startupHandled]).
    if (thread.startupHandled) {
      return;
    }

    thread.startupHandled = true;
    // Send a Stopped event to inform the client UI the thread is paused and
    // declare that we are ready to resume (which might result in an
    // immediate resume).
    if (sendStoppedOnEntry) {
      sendStoppedOnEntryEvent(thread);
    }
    await readyToResumeThread(thread.threadId);
  }

  /// Handles a resume event from the VM, updating our local state.
  void _handleResumed(vm.Event event) {
    final isolate = event.isolate!;
    final thread = _threadsByIsolateId[isolate.id!];
    if (thread != null) {
      // When a thread is resumed, we must inform the client. This is not
      // necessary when the user has clicked Continue because it is implied.
      // However, resume events can now be triggered by other things (eg. other
      // in other IDEs or DevTools) so we must notify the client.
      _adapter.sendEvent(ContinuedEventBody(
        threadId: thread.threadId,
        // Although the DAP spec makes it seem like this defaults to false,
        // VS Code treats it as true. As such, always provide it explicitly.
        // https://github.com/microsoft/vscode/issues/224832#issuecomment-2469552752
        allThreadsContinued: false,
      ));
      thread.paused = false;
      thread.pauseEvent = null;
      thread.exceptionReference = null;
    }
  }

  /// Handles an inspect event from the VM, sending the value/variable to the
  /// debugger.
  void _handleInspect(vm.Event event) {
    final isolate = event.isolate!;
    final thread = _threadsByIsolateId[isolate.id!];
    final inspectee = event.inspectee;

    if (thread != null && inspectee != null) {
      final ref = thread.storeData(InspectData(inspectee));
      _adapter.sendOutput(
        'console',
        '', // Not shown by the client because it fetches the variable.
        variablesReference: ref,
      );
    }
  }

  /// Handles 'BreakpointAdded'/'BreakpointResolved' events from the VM,
  /// informing the client of updated information about the breakpoint.
  ///
  /// Information about unresolved breakpoints will be ignored to avoid
  /// overwriting resolved breakpoint info with unresolved/stale info in the
  /// case of multiple isolates where they haven't all loaded the scripts that
  /// we added breakpoints for.
  void _handleBreakpointAddedOrResolved(vm.Event event) {
    final breakpoint = event.breakpoint!;
    final isolateId = event.isolate!.id!;
    final breakpointId = breakpoint.id!;
    final uniqueBreakpointId =
        (isolateId: isolateId, breakpointId: breakpointId);

    if (!(breakpoint.resolved ?? false)) {
      // Unresolved breakpoint, don't need to do anything.
      return;
    }

    // If we already have an event, assert that the resolution location is the
    // same because we are making assumptions that we can reuse these resolution
    // events to speed up telling the client a breakpoint was resolved.
    assert(() {
      final existingResolvedEvent =
          _breakpointResolvedEventsByVmId[uniqueBreakpointId];
      if (existingResolvedEvent != null) {
        final existingLocation =
            existingResolvedEvent.breakpoint?.location as vm.SourceLocation?;
        final newLocation = event.breakpoint?.location as vm.SourceLocation?;
        assert(existingLocation!.line == newLocation!.line);
        assert(existingLocation!.column == newLocation!.column);
      }
      return true;
    }());

    // Store this event so if we get any future breakpoints that resolve to this
    // VM breakpoint, we can access the resolution info.
    _breakpointResolvedEventsByVmId[(
      isolateId: isolateId,
      breakpointId: breakpointId
    )] = event;

    // And for existing breakpoints, send (or queue) resolved events.
    final existingBreakpoints = _clientBreakpointsByVmId[uniqueBreakpointId];
    for (final existingBreakpoint in existingBreakpoints ?? const []) {
      queueBreakpointResolutionEvent(event, existingBreakpoint);
    }
  }

  /// Queues a breakpoint resolution event that passes resolution info from
  /// the VM back to the client.
  ///
  /// This queue will be processed only after the client has been given the ID
  /// of this breakpoint. If that has already happened, the event will be
  /// processed on the next task queue iteration.
  void queueBreakpointResolutionEvent(
    vm.Event addedOrResolvedEvent,
    ClientBreakpoint clientBreakpoint,
  ) {
    assert(addedOrResolvedEvent.breakpoint != null);
    final breakpoint = addedOrResolvedEvent.breakpoint!;
    assert(breakpoint.resolved ?? false);

    // This is always resolved because of the check above.
    final location = breakpoint.location;
    final resolvedLocation = location as vm.SourceLocation;

    // Track that this breakpoint has been resolved, so that if we are asked to
    // set the same breakpoint in future, we can immediately return
    // resolved=true in the response.
    clientBreakpoint.resolved(resolvedLocation.line, resolvedLocation.column);

    final updatedBreakpoint = Breakpoint(
      id: clientBreakpoint.id,
      line: clientBreakpoint.resolvedLine,
      column: clientBreakpoint.resolvedColumn,
      verified: clientBreakpoint.verified,
    );

    // Ensure we don't send the breakpoint event until the client has been
    // given the breakpoint ID by queueing it.
    clientBreakpoint.queueAction(
      () => _adapter.sendEvent(
        BreakpointEventBody(breakpoint: updatedBreakpoint, reason: 'changed'),
      ),
    );
  }

  /// Queues a breakpoint event that passes an error reason from the VM back to
  /// the client.
  ///
  /// This queue will be processed only after the client has been given the ID
  /// of this breakpoint. If that has already happened, the event will be
  /// processed on the next task queue iteration.
  void queueFailedBreakpointEvent(
    Object error,
    ClientBreakpoint clientBreakpoint,
  ) {
    // Attempt to clean up the message to something that fits better in a
    // tooltip.
    //
    // An example failure is:
    //
    //    addBreakpointWithScriptUri: Cannot add breakpoint at line 8.
    //    Error occurred when resolving breakpoint location:
    //    No debuggable code where breakpoint was requested.
    var userMessage = error is vm.RPCError
        ? error.details ?? error.toString()
        : error.toString();
    var terseMessageMatch =
        _terseBreakpointFailureRegex.firstMatch(userMessage);
    if (terseMessageMatch != null) {
      userMessage = terseMessageMatch.group(1) ?? userMessage;
    }

    // Record the failure state only if we don't already have a success state
    // because if we set a breakpoint in some isolates but not others, we do not
    // want to show that as unresolved.
    if (!clientBreakpoint.verified) {
      clientBreakpoint.unresolved(reason: 'failed', message: userMessage);
    }

    final updatedBreakpoint = Breakpoint(
      id: clientBreakpoint.id,
      verified: clientBreakpoint.verified,
      message: clientBreakpoint.verifiedMessage,
      reason: clientBreakpoint.verifiedReason,
    );
    // Ensure we don't send the breakpoint event until the client has been
    // given the breakpoint ID by queueing it.
    clientBreakpoint.queueAction(
      () => _adapter.sendEvent(
        BreakpointEventBody(breakpoint: updatedBreakpoint, reason: 'changed'),
      ),
    );
  }

  /// Attempts to resolve [uris] to file:/// URIs via the VM Service.
  ///
  /// This method calls the VM service directly. Most requests to resolve URIs
  /// should go through [ThreadInfo]'s resolveXxx methods which perform caching
  /// of results.
  Future<List<Uri?>?> _lookupResolvedPackageUris<T extends vm.Response>(
    vm.IsolateRef isolate,
    List<Uri> uris,
  ) async {
    final isolateId = isolate.id!;
    final uriStrings = uris.map((uri) => uri.toString()).toList();
    try {
      final res = await _adapter.vmService
          ?.lookupResolvedPackageUris(isolateId, uriStrings, local: true);

      return res?.uris
          ?.cast<String?>()
          .map((uri) => uri != null ? Uri.parse(uri) : null)
          .toList();
    } on vm.SentinelException {
      // If the isolate disappeared before we sent this request, just return
      // null responses.
      return uris.map((e) => null).toList();
    } on vm.RPCError catch (e) {
      if (e.code == RpcErrorCodes.kInternalError &&
          e.message.contains('No running isolate (inspector is not set).')) {
        // TODO(bkonyi): remove once https://github.com/flutter/flutter/issues/156793
        // is resolved.
        // If the isolate disappeared before we sent this request, just return
        // null responses.
        return uris.map((e) => null).toList();
      } else {
        rethrow;
      }
    }
  }

  /// Interpolates and prints messages for any log points.
  ///
  /// Log Points are breakpoints with string messages attached. When the VM hits
  /// the breakpoint, we evaluate/print the message and then automatically
  /// resume (as long as there was no other breakpoint).
  Future<void> _processLogPoints(
    ThreadInfo thread,
    Set<SourceBreakpoint> logPoints,
  ) async {
    // Otherwise, we need to evaluate all of the conditions and see if any are
    // true, in which case we will also hit.
    final messages = logPoints.map((bp) => bp.logMessage!).toList();

    final results = await Future.wait(messages.map(
      (message) {
        // Log messages are bare so use jsonEncode to make them valid string
        // expressions.
        final expression = jsonEncode(message)
            // The DAP spec says "Expressions within {} are interpolated" so to
            // avoid any clever parsing, just prefix them with $ and treat them
            // like other Dart interpolation expressions.
            .replaceAllMapped(_braceNotPrefixedByDollarOrBackslashPattern,
                (match) => '${match.group(1)}\${')
            // Remove any backslashes the user added to "escape" braces.
            .replaceAll(r'\\{', '{');
        return _evaluateAndPrintErrors(thread, expression, 'log message');
      },
    ));

    for (final messageResult in results) {
      // TODO(dantup): Format this using other existing code in protocol converter?
      _adapter.sendConsoleOutput(messageResult?.valueAsString);
    }
  }

  /// Resumes any paused isolates.
  Future<void> resumeAll() async {
    final pausedThreads = threads.where((thread) => thread.paused).toList();
    await Future.wait(
      pausedThreads.map((thread) => resumeThread(thread.threadId)),
    );
  }

  /// Calls reloadSources for the given isolate.
  Future<void> _reloadSources(vm.IsolateRef isolateRef) async {
    final service = _adapter.vmService;
    if (!debug || service == null) {
      return;
    }

    final isolateId = isolateRef.id!;

    await service.reloadSources(isolateId);
  }

  /// Tries to find an existing [ClientBreakpoint] matching the location of the
  /// provided [breakpoint] so that it can be reused/kept when updating
  /// breakpoints.
  ClientBreakpoint? findExistingClientBreakpoint(
      String clientUri, SourceBreakpoint breakpoint) {
    var clientBreakpoints = clientBreakpointsByUri[clientUri];
    if (clientBreakpoints == null) {
      return null;
    }

    return clientBreakpoints.firstWhereOrNull((clientBreakpoint) =>
        // These conditions must cover all fields that would be sent to the VM.
        // They do not need to include things like `condition` which we check
        // DAP-side.

        // We always compare breakpoints based on the original location and not
        // the resolved location, because clients will not update the underlying
        // breakpoints with resolution, they will only assign a temporary
        // overriden location.
        //
        // See https://github.com/microsoft/vscode/issues/250453.
        clientBreakpoint.breakpoint.line == breakpoint.line &&
        clientBreakpoint.breakpoint.column == breakpoint.column);
  }

  /// Creates a breakpoint in [clientUri] for [thread] in the VM that
  /// corresponds to [clientBreakpoint] received from the client.
  Future<void> addBreakpoint(ClientBreakpoint clientBreakpoint,
      ThreadInfo thread, String clientUri) async {
    final service = _adapter.vmService;
    if (!debug || service == null) {
      return;
    }

    final isolateId = thread.isolate.id!;

    try {
      // Some file URIs (like SDK sources) need to be converted to
      // appropriate internal URIs to be able to set breakpoints.
      final vmUri = await thread.resolvePathToUri(Uri.parse(clientUri));

      if (vmUri == null) {
        return;
      }

      final vmBp = await service.addBreakpointWithScriptUri(
          isolateId, vmUri.toString(), clientBreakpoint.breakpoint.line,
          column: clientBreakpoint.breakpoint.column);
      clientBreakpoint.forThread[thread] = vmBp;
      final uniqueBreakpointId = (isolateId: isolateId, breakpointId: vmBp.id!);

      // Store this client breakpoint by the VM ID, so when we get events
      // from the VM we can map them back to client breakpoints (for example
      // to send resolved events).
      _clientBreakpointsByVmId
          .putIfAbsent(uniqueBreakpointId, () => [])
          .add(clientBreakpoint);

      // Queue any resolved events that may have already arrived
      // (either because the VM sent them before responding to us, or
      // because it gave us an existing VM breakpoint because it resolved to
      // the same location as another).
      final resolvedEvent = _breakpointResolvedEventsByVmId[uniqueBreakpointId];
      if (resolvedEvent != null) {
        queueBreakpointResolutionEvent(resolvedEvent, clientBreakpoint);
      }
    } catch (e) {
      // Swallow errors setting breakpoints rather than failing the whole
      // request as it's very easy for editors to send us breakpoints that
      // aren't valid any more.
      _adapter.logger?.call('Failed to add breakpoint $e');
      queueFailedBreakpointEvent(e, clientBreakpoint);
    }
  }

  /// Removes [clientBreakpoint] from [thread] in the VM.
  Future<void> removeBreakpoint(
      ClientBreakpoint clientBreakpoint, ThreadInfo thread) async {
    final service = _adapter.vmService;
    if (!debug || service == null) {
      return;
    }

    final isolateId = thread.isolate.id!;
    final vmBreakpoint = clientBreakpoint.forThread[thread];
    if (vmBreakpoint == null) {
      // This isolate didn't have this breakpoint.
      return;
    }

    try {
      await service.removeBreakpoint(isolateId, vmBreakpoint.id!);
      clientBreakpoint.forThread.remove(thread);
    } catch (e) {
      // Swallow errors removing breakpoints rather than failing the whole
      // request as it's very possible that an isolate exited while we were
      // sending this and the request will fail.
      _adapter.logger?.call('Failed to remove old breakpoint $e');
    }
  }

  /// Sets the exception pause mode for an individual isolate.
  Future<void> _sendExceptionPauseMode(ThreadInfo thread) async {
    final service = _adapter.vmService;
    if (!debug || service == null) {
      return;
    }

    await service.setIsolatePauseMode(
      thread.isolate.id!,
      exceptionPauseMode: _exceptionPauseMode,
    );
  }

  /// Calls setLibraryDebuggable for all libraries in the given isolate based
  /// on the debug settings.
  Future<void> _sendLibraryDebuggables(ThreadInfo thread) async {
    final service = _adapter.vmService;
    if (!debug || service == null) {
      return;
    }

    final isolateId = thread.isolate.id!;

    final isolate = await service.getIsolate(isolateId);
    final libraries = isolate.libraries;
    if (libraries == null) {
      return;
    }

    // Pre-resolve all URIs in batch so the call below does not trigger
    // many requests to the server.
    if (!debugExternalPackageLibraries) {
      final allUris = libraries
          .map((library) => library.uri)
          .nonNulls
          .map(Uri.parse)
          .toList();
      await thread.resolveUrisToPackageLibPathsBatch(allUris);
    }

    await Future.wait(libraries.map((library) async {
      final libraryUri = library.uri;
      final isDebuggableNew = libraryUri != null
          ? await _adapter.libraryIsDebuggable(thread, Uri.parse(libraryUri))
          : false;
      final isDebuggableCurrent =
          thread.getIsLibraryCurrentlyDebuggable(library);
      thread.setIsLibraryCurrentlyDebuggable(library, isDebuggableNew);
      if (isDebuggableNew == isDebuggableCurrent) {
        return;
      }
      try {
        await service.setLibraryDebuggable(
            isolateId, library.id!, isDebuggableNew);
      } on vm.RPCError catch (e) {
        // DWDS does not currently support `setLibraryDebuggable` so instead of
        // failing (because this code runs in a VM event handler where there's
        // no incoming request to fail/reject), just log this error.
        // https://github.com/dart-lang/webdev/issues/606
        if (e.code == RpcErrorCodes.kMethodNotFound) {
          _adapter.logger?.call(
            'setLibraryDebuggable not available ($libraryUri, $e)',
          );
        } else {
          rethrow;
        }
      }
    }));
  }

  /// Checks whether a breakpoint the VM paused at is one we should actually
  /// remain at. That is, it either has no condition, or its condition evaluates
  /// to something truthy.
  Future<bool> _shouldHitBreakpoint(
    ThreadInfo thread,
    Set<SourceBreakpoint?> breakpoints,
  ) async {
    // If any were missing (they're null) or do not have a condition, we should
    // hit the breakpoint.
    final clientBreakpointsWithConditions =
        breakpoints.where((bp) => bp?.condition?.isNotEmpty ?? false).toList();
    if (breakpoints.length != clientBreakpointsWithConditions.length) {
      return true;
    }

    // Otherwise, we need to evaluate all of the conditions and see if any are
    // true, in which case we will also hit.
    final conditions =
        clientBreakpointsWithConditions.map((bp) => bp!.condition!).toSet();

    final results = await Future.wait(conditions.map(
      (condition) => _breakpointConditionEvaluatesTrue(thread, condition),
    ));

    return results.any((result) => result);
  }

  /// Clears all data stored for [thread].
  ///
  /// References to stored data become invalid when a thread is resumed.
  void clearStoredData(ThreadInfo thread) {
    _storedData.removeWhere((_, value) => value.thread == thread);
  }
}

/// Holds state for a single Isolate/Thread.
class ThreadInfo with FileUtils {
  final IsolateManager _manager;
  final vm.IsolateRef isolate;
  final int threadId;
  var runnable = false;
  var atAsyncSuspension = false;
  int? exceptionReference;

  /// A [Completer] that completes with the evaluation zone ID for this thread.
  ///
  /// The completer is created when the request to create an evaluation zone is
  /// started (which is lazy, the first time evaluation is performed).
  ///
  /// When the Debug Adapter is ready to resume this Isolate, it will first
  /// invalidate all evaluation IDs in this zone so that they can be collected.
  /// If the [Completer] is null, no evaluation has occurred and invalidation
  /// can be skipped.
  Completer<String?>? _currentEvaluationZoneIdCompleter;

  /// Returns the current evaluation zone ID.
  ///
  /// To avoid additional 'await's, may return a String? directly if the value
  /// is already available.
  FutureOr<String?> get currentEvaluationZoneId {
    // We already have the value, avoid the Future.
    if (_currentEvaluationZoneId != null) {
      return _currentEvaluationZoneId;
    }
    return _createOrGetEvaluationZoneId();
  }

  /// The current evaluation zone ID (if available).
  String? _currentEvaluationZoneId;

  /// Whether this thread is currently known to be paused in the VM.
  ///
  /// Because requests are async, this is not guaranteed to be always correct
  /// but should represent the state based on the latest VM events.
  var paused = false;

  /// Tracks whether an isolates startup routine has been handled.
  ///
  /// The startup routine will either automatically resume the isolate or send
  /// a stopped-on-entry event, depending on whether we're launching or
  /// attaching.
  ///
  /// This is used to prevent trying to resume a thread twice if a PauseStart
  /// event arrives around the same time that are our initialization code (which
  /// automatically resumes threads that are in the PauseStart state when we
  /// connect).
  ///
  /// If we send a duplicate resume, it could trigger an unwanted resume for a
  /// breakpoint or exception that occur early on.
  ///
  /// In the case of attach, a similar race exists.. The initialization may
  /// choose not to resume the isolate (so we can attach to a VM with paused
  /// isolates) but then a PauseStart event that arrived during initialization
  /// could trigger a resume that we don't want.
  bool startupHandled = false;

  /// The most recent pauseEvent for this isolate.
  vm.Event? pauseEvent;

  /// A cache of requests (Futures) to fetch scripts, so that multiple requests
  /// that require scripts (for example looking up locations for stack frames from
  /// tokenPos) can share the same response.
  final _scripts = <String, Future<vm.Script>>{};

  /// A cache of requests (Futures) to resolve URIs to their file-like URIs.
  ///
  /// Used so that multiple requests that require them (for example looking up
  /// locations for stack frames from tokenPos) can share the same response.
  ///
  /// Keys are URIs in string form.
  /// Values are file-like URIs (file: or similar, such as dart-macro+file:).
  final _resolvedPaths = <String, Future<Uri?>>{};

  /// Whether this isolate has an in-flight user-initiated resume request that
  /// has not yet been responded to.
  var hasPendingUserResume = false;

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

  /// Fetches scripts for a given isolate.
  Future<vm.ScriptList> getScripts() {
    return _manager.getScripts(isolate);
  }

  /// Returns the evaluation zone ID for this thread.
  ///
  /// If it has not been created yet, creates it. If creation is in progress,
  /// returns the existing future.
  Future<String?> _createOrGetEvaluationZoneId() async {
    // If we already have a completer, the request is already in flight (or
    // has completed).
    var completer = _currentEvaluationZoneIdCompleter;
    if (completer != null) {
      return completer.future;
    }

    // Otherwise, we need to start the request.
    _currentEvaluationZoneIdCompleter = completer = Completer();

    try {
      final response = await _manager._adapter.vmService?.createIdZone(
        isolate.id!,
        vm.IdZoneBackingBufferKind.kRing,
        vm.IdAssignmentPolicy.kAlwaysAllocate,
        // Default capacity is 512. Since these are short-lived (only while
        // paused) and we don't want to prevent expanding Lists, use something a
        // little bigger.
        capacity: 2048,
      );
      _currentEvaluationZoneId = response?.id;
    } catch (_) {
      // If this request fails for any reason (perhaps the target VM does not
      // support this request), we should just use `null` as the zone ID and not
      // prevent any evaluation requests.
      _currentEvaluationZoneId = null;
    }
    completer.complete(_currentEvaluationZoneId);
    return _currentEvaluationZoneId;
  }

  /// Resolves a source file path (or URI) into a URI for the VM.
  ///
  /// sdk-path/lib/core/print.dart -> dart:core/print.dart
  /// c:\foo\bar -> package:foo/bar
  /// dart-macro+file:///c:/foo/bar -> dart-macro+package:foo/bar
  ///
  /// This is required so that when the user sets a breakpoint in an SDK source
  /// (which they may have navigated to via the Analysis Server) we generate a
  /// valid URI that the VM would create a breakpoint for.
  ///
  /// Because the VM supports using `file:` URIs in many places, we usually do
  /// not need to convert file paths into `package:` URIs, however this will
  /// be done if [forceResolveFileUris] is `true`.
  Future<Uri?> resolvePathToUri(
    Uri sourcePathUri, {
    bool forceResolveFileUris = false,
  }) async {
    final sdkUri = _manager._adapter.convertUriToOrgDartlangSdk(sourcePathUri);
    if (sdkUri != null) {
      return sdkUri;
    }

    final google3Uri = _convertPathToGoogle3Uri(sourcePathUri);
    final uri = google3Uri ?? sourcePathUri;

    // As an optimisation, we don't resolve file -> package URIs in many cases
    // because the VM can set breakpoints for file: URIs anyway. However for
    // G3 or if [forceResolveFileUris] is set, we will.
    final performResolve = google3Uri != null || forceResolveFileUris;

    // TODO(dantup): Consider caching results for this like we do for
    //  resolveUriToPath (and then forceResolveFileUris can be removed and just
    //  always used).
    final packageUriList = performResolve
        ? await _manager._adapter.vmService
            ?.lookupPackageUris(isolate.id!, [uri.toString()])
        : null;
    final packageUriString = packageUriList?.uris?.firstOrNull;

    if (packageUriString != null) {
      // Use package URI if we resolved something
      return Uri.parse(packageUriString);
    } else if (google3Uri != null) {
      // If we failed to resolve and was a Google3 URI, return null
      return null;
    } else {
      // Otherwise, use the original (file) URI
      return uri;
    }
  }

  /// Batch resolves source URIs from the VM to a file-like URI for the package
  /// lib folder.
  ///
  /// This method is more performant than repeatedly calling
  /// [resolveUrisToPackageLibPath] because it resolves multiple URIs in a
  /// single request to the VM.
  ///
  /// Results are cached and shared with [resolveUrisToPackageLibPath] (and
  /// [resolveUriToPath]) so it's reasonable to call this method up-front and
  /// then use [resolveUrisToPackageLibPath] (and [resolveUriToPath]) to read
  /// the results later.
  Future<List<Uri?>> resolveUrisToPackageLibPathsBatch(
    List<Uri> uris,
  ) async {
    final results = await resolveUrisToPathsBatch(uris);
    return results
        .mapIndexed((i, filePath) => _trimPathToLibFolder(filePath, uris[i]))
        .toList();
  }

  /// Batch resolves source URIs from the VM to a file-like URI.
  ///
  /// This method is more performant than repeatedly calling [resolveUriToPath]
  /// because it resolves multiple URIs in a single request to the VM.
  ///
  /// Results are cached and shared with [resolveUriToPath] so it's reasonable
  /// to call this method up-front and then use [resolveUriToPath] to read
  /// the results later.
  Future<List<Uri?>> resolveUrisToPathsBatch(List<Uri> uris) async {
    // First find the set of URIs we don't already have results for.
    final requiredUris = uris
        .where(isResolvableUri)
        .where((uri) => !_resolvedPaths.containsKey(uri.toString()))
        .toSet() // Take only distinct values.
        .toList();

    if (requiredUris.isNotEmpty) {
      // Populate completers for each URI before we start the request so that
      // concurrent calls to this method will not start their own requests.
      final completers = Map<String, Completer<Uri?>>.fromEntries(
        requiredUris.map((uri) => MapEntry('$uri', Completer<Uri?>())),
      );
      completers.forEach(
        (uri, completer) => _resolvedPaths[uri] = completer.future,
      );
      try {
        final results =
            await _manager._lookupResolvedPackageUris(isolate, requiredUris);
        if (results == null) {
          // If no result, all of the results are null.
          completers.forEach((uri, completer) => completer.complete(null));
        } else if (results.length != requiredUris.length) {
          // If the lengths of the lists are different, we have an invalid
          // response from the VM. This is a bug in the VM/VM Service:
          // https://github.com/dart-lang/sdk/issues/52632

          final reason =
              results.length > requiredUris.length ? 'more' : 'fewer';
          final message =
              'lookupResolvedPackageUris result contained $reason results than '
              'the request. See https://github.com/dart-lang/sdk/issues/52632';
          final error = Exception(message);
          completers
              .forEach((uri, completer) => completer.completeError(error));
        } else {
          // Otherwise, complete each one by index with the corresponding value.
          results.map(_convertUriToFilePath).forEachIndexed((i, result) {
            final uri = requiredUris[i].toString();
            completers[uri]!.complete(result);
          });
        }
      } catch (e) {
        // We can't leave dangling completers here because others may already
        // be waiting on them, so propagate the error to them.
        completers.forEach((uri, completer) {
          // Only complete if not already completed. It's possible an exception
          // occurred above inside the loop and that some of the completers have
          // already completed. We don't want to replace a good exception with
          // "Future already completed".
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        });

        // Don't rethrow here, because it will cause these completers futures
        // to not have error handlers attached which can cause their errors to
        // go unhandled. Instead, these completers futures will be returned
        // below and awaited by the caller (which will propagate the errors).
      }
    }

    // Finally, assemble a list of the values by using the cached futures and
    // the original list. Any non-file URI is guaranteed to be in [_resolvedPaths]
    // because they were either filtered out of [requiredUris] because they were
    // already there, or we then populated completers for them above.
    final futures = uris.map((uri) async {
      if (_manager._adapter.isSupportedFileScheme(uri)) {
        return uri;
      } else {
        return await _resolvedPaths[uri.toString()];
      }
    });
    return Future.wait(futures);
  }

  /// Returns whether [library] is currently debuggable according to the VM
  /// (or there is a request in-flight to set it).
  bool getIsLibraryCurrentlyDebuggable(vm.LibraryRef library) {
    return _libraryIsDebuggableById[library.id!] ??
        _getIsLibraryDebuggableByDefault(library);
  }

  /// Records whether [library] is currently debuggable for this isolate.
  ///
  /// This should be called whenever a `setLibraryDebuggable` request is made
  /// to the VM.
  void setIsLibraryCurrentlyDebuggable(
    vm.LibraryRef library,
    bool isDebuggable,
  ) {
    if (isDebuggable == _getIsLibraryDebuggableByDefault(library)) {
      _libraryIsDebuggableById.remove(library.id!);
    } else {
      _libraryIsDebuggableById[library.id!] = isDebuggable;
    }
  }

  /// Returns whether [library] is debuggable by default.
  ///
  /// This value is _assumed_ to avoid having to fetch each library for each
  /// isolate.
  bool _getIsLibraryDebuggableByDefault(vm.LibraryRef library) {
    final isSdkLibrary = library.uri?.startsWith('dart:') ?? false;
    return !isSdkLibrary;
  }

  /// Tracks whether libraries are currently marked as debuggable in the VM.
  ///
  /// If a library ID is not in the map, it is set to the default (which is
  /// debuggable for non-SDK sources, and not-debuggable for SDK sources).
  ///
  /// This can be used to avoid calling setLibraryDebuggable where the value
  /// would not be changed.
  final _libraryIsDebuggableById = <String, bool>{};

  /// Resolves a source URI to a file-like URI for the lib folder of its
  /// package.
  ///
  /// package:foo/a/b/c/d.dart -> file:///code/packages/foo/lib
  /// dart-macro+package:foo/a/b/c/d.dart -> dart-macro+file:///code/packages/foo/lib
  ///
  /// This method is an optimisation over calling [resolveUriToPath] where only
  /// the package root is required (for example when determining whether a
  /// package is within the users workspace). This method allows results to be
  /// cached per-package to avoid hitting the VM Service for each individual
  /// library within a package.
  Future<Uri?> resolveUriToPackageLibPath(Uri uri) async {
    final result = await resolveUrisToPackageLibPathsBatch([uri]);
    return result.first;
  }

  /// Resolves a source URI from the VM to a file-like URI.
  ///
  /// dart:core/print.dart -> sdk-path/lib/core/print.dart
  ///
  /// This is required so that when the user stops (or navigates via a stack
  /// frame) we open the same file on their local disk. If we downloaded the
  /// source from the VM, they would end up seeing two copies of files (and they
  /// would each have their own breakpoints) which can be confusing.
  Future<Uri?> resolveUriToPath(Uri uri) async {
    final result = await resolveUrisToPathsBatch([uri]);
    return result.first;
  }

  /// Stores some basic data indexed by an integer for use in "reference" fields
  /// that are round-tripped to the client.
  int storeData(Object data) => _manager.storeData(this, data);

  Uri? _convertPathToGoogle3Uri(Uri input) {
    // TODO(dantup): Do we need to handle non-file here? Eg. can we have
    //  dart-macro+file:/// for a google3 path?
    if (!input.isScheme('file')) {
      return null;
    }
    final inputPath = input.toFilePath();

    const search = '/google3/';
    if (inputPath.startsWith('/google') && inputPath.contains(search)) {
      var idx = inputPath.indexOf(search);
      var remainingPath = inputPath.substring(idx + search.length);
      return Uri(
        scheme: 'google3',
        host: '',
        path: remainingPath,
      );
    }

    return null;
  }

  /// Converts a VM-returned URI to a file-like URI, taking org-dartlang-sdk
  /// schemes into account.
  ///
  /// Supports file-like URIs and org-dartlang-sdk:// URIs.
  Uri? _convertUriToFilePath(Uri? input) {
    if (input == null) {
      return null;
    } else if (_manager._adapter.isSupportedFileScheme(input)) {
      return input;
    } else {
      // TODO(dantup): UriConverter should be upgraded to use file-like URIs
      //  instead of paths, but that might be breaking because it's used
      //  outside of this package?
      final uriConverter = _manager._adapter.uriConverter();
      if (uriConverter != null) {
        final filePath = uriConverter(input.toString());
        return filePath != null ? Uri.file(filePath) : null;
      }
      return _manager._adapter.convertOrgDartlangSdkToPath(input);
    }
  }

  /// Helper to remove a libraries path from the a file path so it points at the
  /// lib folder.
  ///
  /// [uri] should be the equivalent package: URI and is used to know how many
  /// segments to remove from the file path to get to the lib folder.
  Uri? _trimPathToLibFolder(Uri? fileLikeUri, Uri uri) {
    if (fileLikeUri == null) {
      return null;
    }

    // Track how many segments from the path are from the lib folder to the
    // library that will need to be removed later.
    final libraryPathSegments = uri.pathSegments.length - 1;

    // It should never be the case that the returned value doesn't have at
    // least as many segments as the path of the URI.
    assert(uri.pathSegments.length > libraryPathSegments);
    if (uri.pathSegments.length <= libraryPathSegments) {
      return fileLikeUri;
    }

    // Strip off the correct number of segments to the resulting path points
    // to the root of the package:/ URI.
    final keepSegments = fileLikeUri.pathSegments.length - libraryPathSegments;
    return fileLikeUri.replace(
        pathSegments: fileLikeUri.pathSegments.sublist(0, keepSegments));
  }

  /// Clears all temporary stored for this thread. This includes:
  ///
  /// - dropping any variablesReferences
  /// - invalidating the evaluation ID zone
  ///
  /// This is generally called when requesting execution continues, since any
  /// evaluated references are not expected to live past this point.
  ///
  /// https://microsoft.github.io/debug-adapter-protocol/overview#lifetime-of-objects-references
  Future<void> clearTemporaryData() async {
    // Clear variablesReferences.
    _manager.clearStoredData(this);

    // Invalidate all existing references in this evaluation zone.
    // If the completer is null, no zone has ever been created (or started to
    // be created), so this can be skipped.
    if (_currentEvaluationZoneIdCompleter != null) {
      final futureOrEvalZoneId = currentEvaluationZoneId;
      final evalZoneId = futureOrEvalZoneId is String
          ? futureOrEvalZoneId
          : await futureOrEvalZoneId;
      if (evalZoneId != null) {
        await _manager._adapter.vmService
            ?.invalidateIdZone(isolate.id!, evalZoneId);
      }
    }
  }

  /// Attempts to get a [vm.LibraryRef] for the given [scriptFileUri].
  ///
  /// This involves fetching all scripts for this isolate and looking for a
  /// match and then returning the relevant library reference.
  Future<vm.LibraryRef?> getLibraryForFileUri(Uri scriptFileUri) async {
    // We start with a file URI and need to find the Library (via the script).
    //
    // We need to handle msimatched drive letters, and also file vs package
    // URIs.
    final scriptResolvedUri = await resolvePathToUri(
      scriptFileUri,
      forceResolveFileUris: true,
    );
    final candidateUris = {
      scriptFileUri.toString(),
      normalizeUri(scriptFileUri).toString(),
      if (scriptResolvedUri != null) scriptResolvedUri.toString(),
      if (scriptResolvedUri != null) normalizeUri(scriptResolvedUri).toString(),
    };

    // Find the matching script/library.
    final scriptRefs = (await getScripts()).scripts ?? const [];
    final scriptRef = scriptRefs
        .singleWhereOrNull((script) => candidateUris.contains(script.uri));
    final script = scriptRef != null ? await getScript(scriptRef) : null;

    return script?.library;
  }
}

/// A wrapper over the client-provided [SourceBreakpoint] with a unique ID.
///
/// In order to tell clients about breakpoint changes (such as resolution) we
/// must assign them an ID. If the VM does not have any running Isolates at the
/// time initial breakpoints are set we cannot yet send the breakpoints (and
/// therefore cannot get IDs from the VM). So we generate our own IDs and hold
/// them with the breakpoint here. When we get a 'BreakpointResolved' event we
/// can look up this [ClientBreakpoint] and use the ID to send an update to the
/// client.
class ClientBreakpoint {
  /// The next number to use as a client ID for breakpoints.
  ///
  /// To slightly improve debugging, we start this at 100000 so it doesn't
  /// initially overlap with VM-produced breakpoint numbers so it's more obvious
  /// in log files which numbers are DAP-client and which are VM.
  static int _nextId = 100000;

  final SourceBreakpoint breakpoint;
  final int id;

  /// Whether this breakpoint has been sent to the VM (and not removed).
  bool get isKnownToVm => forThread.isNotEmpty;

  /// A map of [ThreadInfo] -> [vm.Breakpoint] recording the VM breakpoint for
  /// each isolate for this client breakpoint.
  ///
  /// Note: It's possible for multiple [ClientBreakpoint]s to resolve to the
  /// same VM breakpoint!
  Map<ThreadInfo, vm.Breakpoint> forThread = {};

  /// Whether this breakpoint was previously been verified.
  bool get verified => _verified;

  bool _verified = false;

  /// A user-friendly explanation of why this breakpoint could not be resolved
  /// (if [verified] is `false`, otherwise `null`).
  String? get verifiedMessage => _verifiedMessage;

  String? _verifiedMessage = 'Breakpoint has not yet been resolved';

  /// A machine-readable reason (specified by DAP) of why this breakpoint is not
  /// resolved (if [verified] is `false`, otherwise `null`).
  String? get verifiedReason => _verifiedReason;

  String? _verifiedReason = 'pending';

  /// The line that this breakpoint resolved to, or the request line if not
  /// resolved.
  int get resolvedLine => _resolvedLine ?? breakpoint.line;

  int? _resolvedLine;

  /// The column that this breakpoint resolved to, or the request column if not
  /// resolved.
  int? get resolvedColumn => _resolvedColumn ?? breakpoint.column;

  int? _resolvedColumn;

  /// A [Future] that completes with the last action that sends breakpoint
  /// information to the client, to ensure breakpoint events are always sent
  /// in-order and after the initial response sending the IDs to the client.
  Future<void> _lastActionFuture;

  ClientBreakpoint(this.breakpoint, Future<void> setBreakpointResponse)
      : id = _nextId++,
        _lastActionFuture = setBreakpointResponse;

  /// Queues an action to run after all previous actions that sent breakpoint
  /// information to the client.
  FutureOr<T> queueAction<T>(FutureOr<T> Function() action) {
    final actionFuture = _lastActionFuture.then((_) => action());
    _lastActionFuture = actionFuture;
    return actionFuture;
  }

  /// Marks that this breakpoint was resolved.
  void resolved(int? line, int? column) {
    _verified = true;
    _verifiedReason = null;
    _verifiedMessage = null;
    _resolvedLine = line;
    _resolvedColumn = column;
  }

  /// Marks that this breakpoint was not resolved and why.
  void unresolved({required String reason, required String message}) {
    _verified = false;
    _verifiedReason = reason;
    _verifiedMessage = message;
  }
}

/// Tracks actions resulting from `BreakpointAdded`/`BreakpointResolved` events
/// that arrive before the `addBreakpointWithScriptUri` request completes.
///
/// These events need to be chained into the end of the [ClientBreakpoint] once
/// that request completes.
class PendingBreakpointActions {
  /// A completer that will trigger processing of the queue.
  final completer = Completer<void>();

  /// A [Future] that completes with the last action in the queue.
  late Future<void> _lastActionFuture;

  PendingBreakpointActions() {
    _lastActionFuture = completer.future;
  }

  /// Queues an action to run after all previous actions.
  FutureOr<T> queueAction<T>(FutureOr<T> Function() action) {
    final actionFuture = _lastActionFuture.then((_) => action());
    _lastActionFuture = actionFuture;
    return actionFuture;
  }
}

class StoredData {
  final ThreadInfo thread;
  final Object data;

  StoredData(this.thread, this.data);
}
