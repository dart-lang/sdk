// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:vm_service/vm_service.dart' as vm;

import '../rpc_error_codes.dart';
import 'adapters/dart.dart';
import 'exceptions.dart';
import 'protocol_generated.dart';
import 'utils.dart';
import 'variables.dart';

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

  /// Whether to automatically resume new isolates after configuring them.
  ///
  /// This setting is almost always `true` because isolates are paused only so
  /// we can configure them (send breakpoints, pause-on-exceptions,
  /// setLibraryDebuggables) without races. It is set to `false` during the
  /// initial connection of an `attachRequest` to allow paused isolates to
  /// remain paused. In this case, it will be automatically re-set to `true` the
  /// first time the user resumes.
  bool autoResumeStartingIsolates = true;

  /// Tracks breakpoints last provided by the client so they can be sent to new
  /// isolates that appear after initial breakpoints were sent.
  final Map<String, List<ClientBreakpoint>> _clientBreakpointsByUri = {};

  /// Tracks client breakpoints by the ID assigned by the VM so we can look up
  /// conditions/logpoints when hitting breakpoints.
  final Map<String, ClientBreakpoint> _clientBreakpointsByVmId = {};

  /// Tracks breakpoints created in the VM so they can be removed when the
  /// editor sends new breakpoints (currently the editor just sends a new list
  /// and not requests to add/remove).
  ///
  /// Breakpoints are indexed by their ID so that duplicates are not stored even
  /// if multiple client breakpoints resolve to a single VM breakpoint.
  ///
  /// IsolateId -> Uri -> breakpointId -> VM Breakpoint.
  final Map<String, Map<String, Map<String, vm.Breakpoint>>>
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
  final _storedData = <int, StoredData>{};

  /// A pattern that matches an opening brace `{` that was not preceded by a
  /// dollar.
  ///
  /// Any leading character matched in place of the dollar is in the first capture.
  final _braceNotPrefixedByDollarOrBackslashPattern = RegExp(r'(^|[^\\\$]){');

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

  /// Resumes (or steps) an isolate using its client [threadId].
  ///
  /// If the isolate is not paused, or already has a pending resume request
  /// in-flight, a request will not be sent.
  ///
  /// If the isolate is paused at an async suspension and the [resumeType] is
  /// [vm.StepOption.kOver], a [StepOption.kOverAsyncSuspension] step will be
  /// sent instead.
  Future<void> resumeThread(int threadId, [String? resumeType]) async {
    // The first time a user resumes a thread is our signal that the app is now
    // "running" and future isolates can be auto-resumed. This only affects
    // attach, as it's already `true` for launch requests.
    autoResumeStartingIsolates = true;

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

  /// Sends an event informing the client that a thread is stopped at entry.
  void sendStoppedOnEntryEvent(int threadId) {
    _adapter.sendEvent(StoppedEventBody(reason: 'entry', threadId: threadId));
  }

  /// Records breakpoints for [uri].
  ///
  /// [breakpoints] represents the new set and entirely replaces anything given
  /// before.
  Future<void> setBreakpoints(
    String uri,
    List<ClientBreakpoint> breakpoints,
  ) async {
    // Track the breakpoints to get sent to any new isolates that start.
    _clientBreakpointsByUri[uri] = breakpoints;

    // Send the breakpoints to all existing threads.
    await Future.wait(_threadsByThreadId.values
        .map((thread) => _sendBreakpoints(thread, uri: uri)));
  }

  /// Clears all breakpoints.
  Future<void> clearAllBreakpoints() async {
    // Clear all breakpoints for each URI. Do not remove the items from the map
    // as that will stop them being tracked/sent by the call below.
    _clientBreakpointsByUri.updateAll((key, value) => []);

    // Send the breakpoints to all existing threads.
    await Future.wait(
      _threadsByThreadId.values.map((thread) => _sendBreakpoints(thread)),
    );
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
      isolate?.id != null ? _threadsByIsolateId[isolate!.id!] : null;

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
    // Libraries must be set as debuggable _before_ sending breakpoints, or
    // they may fail for SDK sources.
    await Future.wait([
      _sendLibraryDebuggables(thread),
      _sendExceptionPauseMode(thread),
    ], eagerError: true);

    await _sendBreakpoints(thread);
  }

  /// Evaluates an expression, returning the result if it is a [vm.InstanceRef]
  /// and sending any error as an [OutputEvent].
  Future<vm.InstanceRef?> _evaluateAndPrintErrors(
    ThreadInfo thread,
    String expression,
    String type,
  ) async {
    try {
      final result = await _adapter.vmService?.evaluateInFrame(
        thread.isolate.id!,
        0,
        expression,
        disableBreakpoints: true,
      );

      if (result is vm.InstanceRef) {
        return result;
      } else if (result is vm.ErrorRef) {
        final message = result.message ?? '<error ref>';
        _adapter.sendOutput(
          'console',
          'Debugger failed to evaluate breakpoint $type "$expression": $message\n',
        );
      } else if (result is vm.Sentinel) {
        final message = result.valueAsString ?? '<collected>';
        _adapter.sendOutput(
          'console',
          'Debugger failed to evaluate breakpoint $type "$expression": $message\n',
        );
      }
    } catch (e) {
      _adapter.sendOutput(
        'console',
        'Debugger failed to evaluate breakpoint $type "$expression": $e\n',
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
  /// libraries, breakpoints) and then (if [autoResumeStartingIsolates] is
  /// `true`) resumed.
  ///
  /// For [vm.EventKind.kPauseStart] and [autoResumeStartingIsolates] is `true`,
  /// the isolate will be resumed.
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
      await _configureIsolate(thread);
      if (autoResumeStartingIsolates) {
        await resumeThread(thread.threadId);
      }
    } else if (eventKind == vm.EventKind.kPauseStart) {
      // Don't resume from a PauseStart if this has already happened (see
      // comments on [thread.hasBeenStarted]).
      if (!thread.startupHandled) {
        thread.startupHandled = true;
        // If requested, automatically resume. Otherwise send a Stopped event to
        // inform the client UI the thread is paused.
        if (autoResumeStartingIsolates) {
          await resumeThread(thread.threadId);
        } else {
          sendStoppedOnEntryEvent(thread.threadId);
        }
      }
    } else {
      // PauseExit, PauseBreakpoint, PauseInterrupted, PauseException
      var reason = 'pause';

      if (eventKind == vm.EventKind.kPauseBreakpoint &&
          (event.pauseBreakpoints?.isNotEmpty ?? false)) {
        reason = 'breakpoint';
        // Look up the client breakpoints that correspond to the VM breakpoint(s)
        // we hit. It's possible some of these may be missing because we could
        // hit a breakpoint that was set before we were attached.
        final clientBreakpoints = event.pauseBreakpoints!
            .map((bp) => _clientBreakpointsByVmId[bp.id!]?.breakpoint)
            .toSet();

        // Split into logpoints (which just print messages) and breakpoints.
        final logPoints = clientBreakpoints
            .whereNotNull()
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
          text: text,
        ),
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
  void _handleBreakpointAddedOrResolved(vm.Event event) {
    final breakpoint = event.breakpoint!;
    final breakpointId = breakpoint.id!;

    final existingBreakpoint = _clientBreakpointsByVmId[breakpointId];
    if (existingBreakpoint == null) {
      // If we can't match this breakpoint up, we cannot get its ID or send
      // events for it. This can happen if a breakpoint is being resolved just
      // as a user changes breakpoints, so we have replaced our collection with
      // a new set before we processed this event.
      return;
    }

    // Location may be [SourceLocation] or [UnresolvedSourceLocaion] depending
    // on whether this is an Added or Resolved event.
    final location = breakpoint.location;
    final resolvedLocation = location is vm.SourceLocation ? location : null;
    final unresolvedLocation =
        location is vm.UnresolvedSourceLocation ? location : null;
    final updatedBreakpoint = Breakpoint(
      id: existingBreakpoint.id,
      line: resolvedLocation?.line ?? unresolvedLocation?.line,
      column: resolvedLocation?.column ?? unresolvedLocation?.column,
      verified: breakpoint.resolved ?? false,
    );
    _adapter.sendEvent(
      BreakpointEventBody(breakpoint: updatedBreakpoint, reason: 'changed'),
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
    final res = await _adapter.vmService
        ?.lookupResolvedPackageUris(isolateId, uriStrings, local: true);

    return res?.uris
        ?.cast<String?>()
        .map((uri) => uri != null ? Uri.parse(uri) : null)
        .toList();
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
      _adapter.sendOutput('console', '${messageResult?.valueAsString}\n');
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

  /// Sets breakpoints for an individual isolate.
  ///
  /// If [uri] is provided, only breakpoints for that URI will be sent (used
  /// when breakpoints are modified for a single file in the editor). Otherwise
  /// breakpoints for all previously set URIs will be sent (used for
  /// newly-created isolates).
  Future<void> _sendBreakpoints(ThreadInfo thread, {String? uri}) async {
    final service = _adapter.vmService;
    if (!debug || service == null) {
      return;
    }

    final isolateId = thread.isolate.id!;

    // If we were passed a single URI, we should send breakpoints only for that
    // (this means the request came from the client), otherwise we should send
    // all of them (because this is a new/restarting isolate).
    final uris = uri != null ? [uri] : _clientBreakpointsByUri.keys;

    for (final uri in uris) {
      // Clear existing breakpoints.
      final existingBreakpointsForIsolate =
          _vmBreakpointsByIsolateIdAndUri.putIfAbsent(isolateId, () => {});
      final existingBreakpointsForIsolateAndUri =
          existingBreakpointsForIsolate.putIfAbsent(uri, () => {});
      // Before doing async work, take a copy of the breakpoints to remove
      // and remove them from the list, so any subsequent calls here don't
      // try to remove the same ones multiple times.
      final breakpointsToRemove =
          existingBreakpointsForIsolateAndUri.values.toList();
      existingBreakpointsForIsolateAndUri.clear();
      await Future.forEach<vm.Breakpoint>(breakpointsToRemove, (bp) async {
        try {
          await service.removeBreakpoint(isolateId, bp.id!);
        } catch (e) {
          // Swallow errors removing breakpoints rather than failing the whole
          // request as it's very possible that an isolate exited while we were
          // sending this and the request will fail.
          _adapter.logger?.call('Failed to remove old breakpoint $e');
        }
      });

      // Set new breakpoints.
      final newBreakpoints = _clientBreakpointsByUri[uri] ?? const [];
      await Future.forEach<ClientBreakpoint>(newBreakpoints, (bp) async {
        try {
          // Some file URIs (like SDK sources) need to be converted to
          // appropriate internal URIs to be able to set breakpoints.
          final vmUri = await thread.resolvePathToUri(
            Uri.parse(uri).toFilePath(),
          );

          if (vmUri == null) {
            return;
          }

          final vmBp = await service.addBreakpointWithScriptUri(
              isolateId, vmUri.toString(), bp.breakpoint.line,
              column: bp.breakpoint.column);
          existingBreakpointsForIsolateAndUri[vmBp.id!] = vmBp;
          _clientBreakpointsByVmId[vmBp.id!] = bp;
        } catch (e) {
          // Swallow errors setting breakpoints rather than failing the whole
          // request as it's very easy for editors to send us breakpoints that
          // aren't valid any more.
          _adapter.logger?.call('Failed to add breakpoint $e');
        }
      });
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
    final allUris = libraries
        .map((library) => library.uri)
        .whereNotNull()
        .map(Uri.parse)
        .toList();
    await thread.resolveUrisToPackageLibPathsBatch(allUris);

    await Future.wait(libraries.map((library) async {
      final libraryUri = library.uri;
      final isDebuggable = libraryUri != null
          ? await _adapter.libraryIsDebuggable(thread, Uri.parse(libraryUri))
          : false;
      try {
        await service.setLibraryDebuggable(
            isolateId, library.id!, isDebuggable);
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

  /// A cache of requests (Futures) to resolve URIs to their local file paths.
  ///
  /// Used so that multiple requests that require them (for example looking up
  /// locations for stack frames from tokenPos) can share the same response.
  ///
  /// Keys are URIs in string form.
  /// Values are file paths (not file URIs!).
  final _resolvedPaths = <String, Future<String?>>{};

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

  /// Resolves a source file path into a URI for the VM.
  ///
  /// sdk-path/lib/core/print.dart -> dart:core/print.dart
  ///
  /// This is required so that when the user sets a breakpoint in an SDK source
  /// (which they may have navigated to via the Analysis Server) we generate a
  /// valid URI that the VM would create a breakpoint for.
  Future<Uri?> resolvePathToUri(String filePath) async {
    var google3Path = _convertPathToGoogle3Uri(filePath);
    if (google3Path != null) {
      var result = await _manager._adapter.vmService
          ?.lookupPackageUris(isolate.id!, [google3Path.toString()]);
      var uriStr = result?.uris?.first;
      return uriStr != null ? Uri.parse(uriStr) : null;
    }

    // We don't need to call lookupPackageUris in non-google3 because the VM can
    // handle incoming file:/// URIs for packages, and also the org-dartlang-sdk
    // URIs directly for SDK sources (we do not need to convert to 'dart:'),
    // however this method is Future-returning in case this changes in future
    // and we need to include a call to lookupPackageUris here.
    return _manager._adapter.convertPathToOrgDartlangSdk(filePath) ??
        Uri.file(filePath);
  }

  /// Batch resolves source URIs from the VM to a file path for the package lib
  /// folder.
  ///
  /// This method is more performant than repeatedly calling
  /// [resolveUrisToPackageLibPath] because it resolves multiple URIs in a
  /// single request to the VM.
  ///
  /// Results are cached and shared with [resolveUrisToPackageLibPath] (and
  /// [resolveUriToPath]) so it's reasonable to call this method up-front and
  /// then use [resolveUrisToPackageLibPath] (and [resolveUriToPath]) to read
  /// the results later.
  Future<List<String?>> resolveUrisToPackageLibPathsBatch(
    List<Uri> uris,
  ) async {
    final results = await resolveUrisToPathsBatch(uris);
    return results
        .mapIndexed((i, filePath) => _trimPathToLibFolder(filePath, uris[i]))
        .toList();
  }

  /// Batch resolves source URIs from the VM to a file path.
  ///
  /// This method is more performant than repeatedly calling [resolveUriToPath]
  /// because it resolves multiple URIs in a single request to the VM.
  ///
  /// Results are cached and shared with [resolveUriToPath] so it's reasonable
  /// to call this method up-front and then use [resolveUriToPath] to read
  /// the results later.
  Future<List<String?>> resolveUrisToPathsBatch(List<Uri> uris) async {
    // First find the set of URIs we don't already have results for.
    final requiredUris = uris
        .where(isResolvableUri)
        .where((uri) => !_resolvedPaths.containsKey(uri.toString()))
        .toSet() // Take only distinct values.
        .toList();

    if (requiredUris.isNotEmpty) {
      // Populate completers for each URI before we start the request so that
      // concurrent calls to this method will not start their own requests.
      final completers = Map<String, Completer<String?>>.fromEntries(
        requiredUris.map((uri) => MapEntry('$uri', Completer<String?>())),
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
        completers.forEach((uri, completer) => completer.completeError(e));

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
      return uri.isScheme('file')
          ? uri.toFilePath()
          : await _resolvedPaths[uri.toString()]!;
    });
    return Future.wait(futures);
  }

  /// Resolves a source URI to a file path for the lib folder of its package.
  ///
  /// package:foo/a/b/c/d.dart -> /code/packages/foo/lib
  ///
  /// This method is an optimisation over calling [resolveUriToPath] where only
  /// the package root is required (for example when determining whether a
  /// package is within the users workspace). This method allows results to be
  /// cached per-package to avoid hitting the VM Service for each individual
  /// library within a package.
  Future<String?> resolveUriToPackageLibPath(Uri uri) async {
    final result = await resolveUrisToPackageLibPathsBatch([uri]);
    return result.first;
  }

  /// Resolves a source URI from the VM to a file path.
  ///
  /// dart:core/print.dart -> sdk-path/lib/core/print.dart
  ///
  /// This is required so that when the user stops (or navigates via a stack
  /// frame) we open the same file on their local disk. If we downloaded the
  /// source from the VM, they would end up seeing two copies of files (and they
  /// would each have their own breakpoints) which can be confusing.
  Future<String?> resolveUriToPath(Uri uri) async {
    final result = await resolveUrisToPathsBatch([uri]);
    return result.first;
  }

  /// Stores some basic data indexed by an integer for use in "reference" fields
  /// that are round-tripped to the client.
  int storeData(Object data) => _manager.storeData(this, data);

  Uri? _convertPathToGoogle3Uri(String input) {
    const search = '/google3/';
    if (input.startsWith('/google') && input.contains(search)) {
      var idx = input.indexOf(search);
      var remainingPath = input.substring(idx + search.length);
      return Uri(
        scheme: 'google3',
        host: '',
        path: remainingPath,
      );
    }

    return null;
  }

  /// Converts a URI to a file path.
  ///
  /// Supports file:// URIs and org-dartlang-sdk:// URIs.
  String? _convertUriToFilePath(Uri? input) {
    if (input == null) {
      return null;
    } else if (input.isScheme('file')) {
      return input.toFilePath();
    } else {
      return _manager._adapter.convertOrgDartlangSdkToPath(input);
    }
  }

  /// Helper to remove a libraries path from the a file path so it points at the
  /// lib folder.
  ///
  /// [uri] should be the equivalent package: URI and is used to know how many
  /// segments to remove from the file path to get to the lib folder.
  String? _trimPathToLibFolder(String? filePath, Uri uri) {
    if (filePath == null) {
      return null;
    }

    final fileUri = Uri.file(filePath);

    // Track how many segments from the path are from the lib folder to the
    // library that will need to be removed later.
    final libraryPathSegments = uri.pathSegments.length - 1;

    // It should never be the case that the returned value doesn't have at
    // least as many segments as the path of the URI.
    assert(fileUri.pathSegments.length > libraryPathSegments);
    if (fileUri.pathSegments.length <= libraryPathSegments) {
      return filePath;
    }

    // Strip off the correct number of segments to the resulting path points
    // to the root of the package:/ URI.
    final keepSegments = fileUri.pathSegments.length - libraryPathSegments;
    return fileUri
        .replace(pathSegments: fileUri.pathSegments.sublist(0, keepSegments))
        .toFilePath();
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

  ClientBreakpoint(this.breakpoint) : id = _nextId++;
}

class StoredData {
  final ThreadInfo thread;
  final Object data;

  StoredData(this.thread, this.data);
}
