// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a generated file. To regenerate, run `dart tool/generate.dart`.

/// A library to access the VM Service API.
///
/// The main entry-point for this library is the [VmService] class.
library;

// ignore_for_file: overridden_fields

import 'dart:async';
import 'dart:convert'
    show base64, jsonDecode, JsonDecoder, jsonEncode, utf8, Utf8Decoder;
import 'dart:typed_data';

export 'snapshot_graph.dart'
    show
        HeapSnapshotClass,
        HeapSnapshotExternalProperty,
        HeapSnapshotField,
        HeapSnapshotGraph,
        HeapSnapshotObject,
        HeapSnapshotObjectLengthData,
        HeapSnapshotObjectNoData,
        HeapSnapshotObjectNullData;

const String vmServiceVersion = '4.16.0';

/// @optional
const String optional = 'optional';

/// Decode a string in Base64 encoding into the equivalent non-encoded string.
/// This is useful for handling the results of the Stdout or Stderr events.
String decodeBase64(String str) => utf8.decode(base64.decode(str));

// Returns true if a response is the Dart `null` instance.
bool _isNullInstance(Map json) =>
    ((json['type'] == '@Instance') && (json['kind'] == 'Null'));

Object? createServiceObject(dynamic json, List<String> expectedTypes) {
  if (json == null) return null;

  if (json is List) {
    return json.map((e) => createServiceObject(e, expectedTypes)).toList();
  } else if (json is Map<String, dynamic>) {
    String? type = json['type'];

    // Not a Response type.
    if (type == null) {
      // If there's only one expected type, we'll just use that type.
      if (expectedTypes.length == 1) {
        type = expectedTypes.first;
      } else {
        return Response.parse(json);
      }
    } else if (_isNullInstance(json) &&
        (!expectedTypes.contains('InstanceRef'))) {
      // Replace null instances with null when we don't expect an instance to
      // be returned.
      return null;
    }
    final typeFactory = _typeFactories[type];
    if (typeFactory == null) {
      return null;
    } else {
      return typeFactory(json);
    }
  } else {
    // Handle simple types.
    return json;
  }
}

dynamic _createSpecificObject(
    dynamic json, dynamic Function(Map<String, dynamic> map) creator) {
  if (json == null) return null;

  if (json is List) {
    return json.map((e) => creator(e)).toList();
  } else if (json is Map) {
    return creator({
      for (String key in json.keys) key: json[key],
    });
  } else {
    // Handle simple types.
    return json;
  }
}

Future<T> extensionCallHelper<T>(
    VmService service, String method, Map<String, dynamic> args) {
  return service._call(method, args);
}

typedef ServiceCallback = Future<Map<String, dynamic>> Function(
    Map<String, dynamic> params);

void addTypeFactory(String name, Function factory) {
  if (_typeFactories.containsKey(name)) {
    throw StateError('Factory already registered for $name');
  }
  _typeFactories[name] = factory;
}

final _typeFactories = <String, Function>{
  'AllocationProfile': AllocationProfile.parse,
  'BoundField': BoundField.parse,
  'BoundVariable': BoundVariable.parse,
  'Breakpoint': Breakpoint.parse,
  '@Class': ClassRef.parse,
  'Class': Class.parse,
  'ClassHeapStats': ClassHeapStats.parse,
  'ClassList': ClassList.parse,
  '@Code': CodeRef.parse,
  'Code': Code.parse,
  '@Context': ContextRef.parse,
  'Context': Context.parse,
  'ContextElement': ContextElement.parse,
  'CpuSamples': CpuSamples.parse,
  'CpuSamplesEvent': CpuSamplesEvent.parse,
  'CpuSample': CpuSample.parse,
  '@Error': ErrorRef.parse,
  'Error': Error.parse,
  'Event': Event.parse,
  'ExtensionData': ExtensionData.parse,
  '@Field': FieldRef.parse,
  'Field': Field.parse,
  'Flag': Flag.parse,
  'FlagList': FlagList.parse,
  'Frame': Frame.parse,
  '@Function': FuncRef.parse,
  'Function': Func.parse,
  '@Instance': InstanceRef.parse,
  'Instance': Instance.parse,
  '@Isolate': IsolateRef.parse,
  'Isolate': Isolate.parse,
  'IsolateFlag': IsolateFlag.parse,
  '@IsolateGroup': IsolateGroupRef.parse,
  'IsolateGroup': IsolateGroup.parse,
  'InboundReferences': InboundReferences.parse,
  'InboundReference': InboundReference.parse,
  'InstanceSet': InstanceSet.parse,
  '@Library': LibraryRef.parse,
  'Library': Library.parse,
  'LibraryDependency': LibraryDependency.parse,
  'LogRecord': LogRecord.parse,
  'MapAssociation': MapAssociation.parse,
  'MemoryUsage': MemoryUsage.parse,
  'Message': Message.parse,
  'NativeFunction': NativeFunction.parse,
  '@Null': NullValRef.parse,
  'Null': NullVal.parse,
  '@Object': ObjRef.parse,
  'Object': Obj.parse,
  'Parameter': Parameter.parse,
  'PerfettoCpuSamples': PerfettoCpuSamples.parse,
  'PerfettoTimeline': PerfettoTimeline.parse,
  'PortList': PortList.parse,
  'ProfileFunction': ProfileFunction.parse,
  'ProtocolList': ProtocolList.parse,
  'Protocol': Protocol.parse,
  'ProcessMemoryUsage': ProcessMemoryUsage.parse,
  'ProcessMemoryItem': ProcessMemoryItem.parse,
  'ReloadReport': ReloadReport.parse,
  'RetainingObject': RetainingObject.parse,
  'RetainingPath': RetainingPath.parse,
  'Response': Response.parse,
  'Sentinel': Sentinel.parse,
  '@Script': ScriptRef.parse,
  'Script': Script.parse,
  'ScriptList': ScriptList.parse,
  'SourceLocation': SourceLocation.parse,
  'SourceReport': SourceReport.parse,
  'SourceReportCoverage': SourceReportCoverage.parse,
  'SourceReportRange': SourceReportRange.parse,
  'Stack': Stack.parse,
  'Success': Success.parse,
  'Timeline': Timeline.parse,
  'TimelineEvent': TimelineEvent.parse,
  'TimelineFlags': TimelineFlags.parse,
  'Timestamp': Timestamp.parse,
  '@TypeArguments': TypeArgumentsRef.parse,
  'TypeArguments': TypeArguments.parse,
  '@TypeParameters': TypeParametersRef.parse,
  'TypeParameters': TypeParameters.parse,
  'UnresolvedSourceLocation': UnresolvedSourceLocation.parse,
  'UriList': UriList.parse,
  'Version': Version.parse,
  '@VM': VMRef.parse,
  'VM': VM.parse,
};

final _methodReturnTypes = <String, List<String>>{
  'addBreakpoint': const ['Breakpoint'],
  'addBreakpointWithScriptUri': const ['Breakpoint'],
  'addBreakpointAtEntry': const ['Breakpoint'],
  'clearCpuSamples': const ['Success'],
  'clearVMTimeline': const ['Success'],
  'invoke': const ['InstanceRef', 'ErrorRef'],
  'evaluate': const ['InstanceRef', 'ErrorRef'],
  'evaluateInFrame': const ['InstanceRef', 'ErrorRef'],
  'getAllocationProfile': const ['AllocationProfile'],
  'getAllocationTraces': const ['CpuSamples'],
  'getClassList': const ['ClassList'],
  'getCpuSamples': const ['CpuSamples'],
  'getFlagList': const ['FlagList'],
  'getInboundReferences': const ['InboundReferences'],
  'getInstances': const ['InstanceSet'],
  'getInstancesAsList': const ['InstanceRef'],
  'getIsolate': const ['Isolate'],
  'getIsolateGroup': const ['IsolateGroup'],
  'getIsolatePauseEvent': const ['Event'],
  'getMemoryUsage': const ['MemoryUsage'],
  'getIsolateGroupMemoryUsage': const ['MemoryUsage'],
  'getScripts': const ['ScriptList'],
  'getObject': const ['Obj'],
  'getPerfettoCpuSamples': const ['PerfettoCpuSamples'],
  'getPerfettoVMTimeline': const ['PerfettoTimeline'],
  'getPorts': const ['PortList'],
  'getRetainingPath': const ['RetainingPath'],
  'getProcessMemoryUsage': const ['ProcessMemoryUsage'],
  'getStack': const ['Stack'],
  'getSupportedProtocols': const ['ProtocolList'],
  'getSourceReport': const ['SourceReport'],
  'getVersion': const ['Version'],
  'getVM': const ['VM'],
  'getVMTimeline': const ['Timeline'],
  'getVMTimelineFlags': const ['TimelineFlags'],
  'getVMTimelineMicros': const ['Timestamp'],
  'pause': const ['Success'],
  'kill': const ['Success'],
  'lookupResolvedPackageUris': const ['UriList'],
  'lookupPackageUris': const ['UriList'],
  'registerService': const ['Success'],
  'reloadSources': const ['ReloadReport'],
  'removeBreakpoint': const ['Success'],
  'requestHeapSnapshot': const ['Success'],
  'resume': const ['Success'],
  'setBreakpointState': const ['Breakpoint'],
  'setExceptionPauseMode': const ['Success'],
  'setIsolatePauseMode': const ['Success'],
  'setFlag': const ['Success', 'Error'],
  'setLibraryDebuggable': const ['Success'],
  'setName': const ['Success'],
  'setTraceClassAllocation': const ['Success'],
  'setVMName': const ['Success'],
  'setVMTimelineFlags': const ['Success'],
  'streamCancel': const ['Success'],
  'streamCpuSamplesWithUserTag': const ['Success'],
  'streamListen': const ['Success'],
};

class _OutstandingRequest<T> {
  _OutstandingRequest(this.method);
  static int _idCounter = 0;
  final id = '${_idCounter++}';
  final String method;
  final _stackTrace = StackTrace.current;
  final _completer = Completer<T>();

  Future<T> get future => _completer.future;

  void complete(T value) => _completer.complete(value);
  void completeError(Object error) =>
      _completer.completeError(error, _stackTrace);
}

typedef VmServiceFactory<T extends VmService> = T Function({
  required Stream<dynamic> /*String|List<int>*/ inStream,
  required void Function(String message) writeMessage,
  Log? log,
  DisposeHandler? disposeHandler,
  Future? streamClosed,
  String? wsUri,
});

class VmService {
  late final StreamSubscription _streamSub;
  late final Function _writeMessage;
  final _outstandingRequests = <String, _OutstandingRequest>{};
  final _services = <String, ServiceCallback>{};
  late final Log _log;

  /// The web socket URI pointing to the target VM service instance.
  final String? wsUri;

  Stream<String> get onSend => _onSend.stream;
  final _onSend = StreamController<String>.broadcast(sync: true);

  Stream<String> get onReceive => _onReceive.stream;
  final _onReceive = StreamController<String>.broadcast(sync: true);

  Future<void> get onDone => _onDoneCompleter.future;
  final _onDoneCompleter = Completer<void>();

  bool _disposed = false;

  final _eventControllers = <String, StreamController<Event>>{};

  StreamController<Event> _getEventController(String eventName) {
    StreamController<Event>? controller = _eventControllers[eventName];
    if (controller == null) {
      controller = StreamController.broadcast();
      _eventControllers[eventName] = controller;
    }
    return controller;
  }

  late final DisposeHandler? _disposeHandler;

  VmService(
    Stream<dynamic> /*String|List<int>*/ inStream,
    void Function(String message) writeMessage, {
    Log? log,
    DisposeHandler? disposeHandler,
    Future? streamClosed,
    this.wsUri,
  }) {
    _streamSub = inStream.listen(
      _processMessage,
      onDone: () async => await dispose(),
    );
    _writeMessage = writeMessage;
    _log = log ?? _NullLog();
    _disposeHandler = disposeHandler;
    streamClosed?.then((_) async => await dispose());
  }

  static VmService defaultFactory({
    required Stream<dynamic> /*String|List<int>*/ inStream,
    required void Function(String message) writeMessage,
    Log? log,
    DisposeHandler? disposeHandler,
    Future? streamClosed,
    String? wsUri,
  }) {
    return VmService(
      inStream,
      writeMessage,
      log: log,
      disposeHandler: disposeHandler,
      streamClosed: streamClosed,
      wsUri: wsUri,
    );
  }

  Stream<Event> onEvent(String streamId) =>
      _getEventController(streamId).stream;

  // VMUpdate, VMFlagUpdate
  Stream<Event> get onVMEvent => _getEventController('VM').stream;

  // IsolateStart, IsolateRunnable, IsolateExit, IsolateUpdate, IsolateReload, ServiceExtensionAdded
  Stream<Event> get onIsolateEvent => _getEventController('Isolate').stream;

  // PauseStart, PauseExit, PauseBreakpoint, PauseInterrupted, PauseException, PausePostRequest, Resume, BreakpointAdded, BreakpointResolved, BreakpointRemoved, BreakpointUpdated, Inspect, None
  Stream<Event> get onDebugEvent => _getEventController('Debug').stream;

  // CpuSamples, UserTagChanged
  Stream<Event> get onProfilerEvent => _getEventController('Profiler').stream;

  // GC
  Stream<Event> get onGCEvent => _getEventController('GC').stream;

  // Extension
  Stream<Event> get onExtensionEvent => _getEventController('Extension').stream;

  // TimelineEvents, TimelineStreamsSubscriptionUpdate
  Stream<Event> get onTimelineEvent => _getEventController('Timeline').stream;

  // Logging
  Stream<Event> get onLoggingEvent => _getEventController('Logging').stream;

  // ServiceRegistered, ServiceUnregistered
  Stream<Event> get onServiceEvent => _getEventController('Service').stream;

  // HeapSnapshot
  Stream<Event> get onHeapSnapshotEvent =>
      _getEventController('HeapSnapshot').stream;

  // WriteEvent
  Stream<Event> get onStdoutEvent => _getEventController('Stdout').stream;

  // WriteEvent
  Stream<Event> get onStderrEvent => _getEventController('Stderr').stream;

  /// The `addBreakpoint` RPC is used to add a breakpoint at a specific line of
  /// some script.
  ///
  /// The `scriptId` parameter is used to specify the target script.
  ///
  /// The `line` parameter is used to specify the target line for the
  /// breakpoint. If there are multiple possible breakpoints on the target line,
  /// then the VM will place the breakpoint at the location which would execute
  /// soonest. If it is not possible to set a breakpoint at the target line, the
  /// breakpoint will be added at the next possible breakpoint location within
  /// the same function.
  ///
  /// The `column` parameter may be optionally specified. This is useful for
  /// targeting a specific breakpoint on a line with multiple possible
  /// breakpoints.
  ///
  /// If no breakpoint is possible at that line, the `102` (Cannot add
  /// breakpoint) RPC error code is returned.
  ///
  /// Note that breakpoints are added and removed on a per-isolate basis.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Breakpoint].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Breakpoint> addBreakpoint(
    String isolateId,
    String scriptId,
    int line, {
    int? column,
  }) =>
      _call('addBreakpoint', {
        'isolateId': isolateId,
        'scriptId': scriptId,
        'line': line,
        if (column != null) 'column': column,
      });

  /// The `addBreakpoint` RPC is used to add a breakpoint at a specific line of
  /// some script. This RPC is useful when a script has not yet been assigned an
  /// id, for example, if a script is in a deferred library which has not yet
  /// been loaded.
  ///
  /// The `scriptUri` parameter is used to specify the target script.
  ///
  /// The `line` parameter is used to specify the target line for the
  /// breakpoint. If there are multiple possible breakpoints on the target line,
  /// then the VM will place the breakpoint at the location which would execute
  /// soonest. If it is not possible to set a breakpoint at the target line, the
  /// breakpoint will be added at the next possible breakpoint location within
  /// the same function.
  ///
  /// The `column` parameter may be optionally specified. This is useful for
  /// targeting a specific breakpoint on a line with multiple possible
  /// breakpoints.
  ///
  /// If no breakpoint is possible at that line, the `102` (Cannot add
  /// breakpoint) RPC error code is returned.
  ///
  /// Note that breakpoints are added and removed on a per-isolate basis.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Breakpoint].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Breakpoint> addBreakpointWithScriptUri(
    String isolateId,
    String scriptUri,
    int line, {
    int? column,
  }) =>
      _call('addBreakpointWithScriptUri', {
        'isolateId': isolateId,
        'scriptUri': scriptUri,
        'line': line,
        if (column != null) 'column': column,
      });

  /// The `addBreakpointAtEntry` RPC is used to add a breakpoint at the
  /// entrypoint of some function.
  ///
  /// If no breakpoint is possible at the function entry, the `102` (Cannot add
  /// breakpoint) RPC error code is returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Breakpoint].
  ///
  /// Note that breakpoints are added and removed on a per-isolate basis.
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Breakpoint> addBreakpointAtEntry(
          String isolateId, String functionId) =>
      _call('addBreakpointAtEntry',
          {'isolateId': isolateId, 'functionId': functionId});

  /// Clears all CPU profiling samples.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> clearCpuSamples(String isolateId) =>
      _call('clearCpuSamples', {'isolateId': isolateId});

  /// Clears all VM timeline events.
  ///
  /// See [Success].
  Future<Success> clearVMTimeline() => _call('clearVMTimeline');

  /// The `invoke` RPC is used to perform regular method invocation on some
  /// receiver, as if by dart:mirror's ObjectMirror.invoke. Note this does not
  /// provide a way to perform getter, setter or constructor invocation.
  ///
  /// `targetId` may refer to a [Library], [Class], or [Instance].
  ///
  /// Each elements of `argumentId` may refer to an [Instance].
  ///
  /// If `disableBreakpoints` is provided and set to true, any breakpoints hit
  /// as a result of this invocation are ignored, including pauses resulting
  /// from a call to `debugger()` from `dart:developer`. Defaults to false if
  /// not provided.
  ///
  /// If `targetId` or any element of `argumentIds` is a temporary id which has
  /// expired, then the `Expired` [Sentinel] is returned.
  ///
  /// If `targetId` or any element of `argumentIds` refers to an object which
  /// has been collected by the VM's garbage collector, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// If invocation triggers a failed compilation then [RPCError] 113
  /// "Expression compilation error" is returned.
  ///
  /// If a runtime error occurs while evaluating the invocation, an [ErrorRef]
  /// reference will be returned.
  ///
  /// If the invocation is evaluated successfully, an [InstanceRef] reference
  /// will be returned.
  ///
  /// The return value can be one of [InstanceRef] or [ErrorRef].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Response> invoke(
    String isolateId,
    String targetId,
    String selector,
    List<String> argumentIds, {
    bool? disableBreakpoints,
  }) =>
      _call('invoke', {
        'isolateId': isolateId,
        'targetId': targetId,
        'selector': selector,
        'argumentIds': argumentIds,
        if (disableBreakpoints != null)
          'disableBreakpoints': disableBreakpoints,
      });

  /// The `evaluate` RPC is used to evaluate an expression in the context of
  /// some target.
  ///
  /// `targetId` may refer to a [Library], [Class], or [Instance].
  ///
  /// If `targetId` is a temporary id which has expired, then the `Expired`
  /// [Sentinel] is returned.
  ///
  /// If `targetId` refers to an object which has been collected by the VM's
  /// garbage collector, then the `Collected` [Sentinel] is returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// If `scope` is provided, it should be a map from identifiers to object ids.
  /// These bindings will be added to the scope in which the expression is
  /// evaluated, which is a child scope of the class or library for
  /// instance/class or library targets respectively. This means bindings
  /// provided in `scope` may shadow instance members, class members and
  /// top-level members.
  ///
  /// If `disableBreakpoints` is provided and set to true, any breakpoints hit
  /// as a result of this evaluation are ignored. Defaults to false if not
  /// provided.
  ///
  /// If the expression fails to parse and compile, then [RPCError] 113
  /// "Expression compilation error" is returned.
  ///
  /// If an error occurs while evaluating the expression, an [ErrorRef]
  /// reference will be returned.
  ///
  /// If the expression is evaluated successfully, an [InstanceRef] reference
  /// will be returned.
  ///
  /// The return value can be one of [InstanceRef] or [ErrorRef].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Response> evaluate(
    String isolateId,
    String targetId,
    String expression, {
    Map<String, String>? scope,
    bool? disableBreakpoints,
  }) =>
      _call('evaluate', {
        'isolateId': isolateId,
        'targetId': targetId,
        'expression': expression,
        if (scope != null) 'scope': scope,
        if (disableBreakpoints != null)
          'disableBreakpoints': disableBreakpoints,
      });

  /// The `evaluateInFrame` RPC is used to evaluate an expression in the context
  /// of a particular stack frame. `frameIndex` is the index of the desired
  /// [Frame], with an index of `0` indicating the top (most recent) frame.
  ///
  /// If `scope` is provided, it should be a map from identifiers to object ids.
  /// These bindings will be added to the scope in which the expression is
  /// evaluated, which is a child scope of the frame's current scope. This means
  /// bindings provided in `scope` may shadow instance members, class members,
  /// top-level members, parameters and locals.
  ///
  /// If `disableBreakpoints` is provided and set to true, any breakpoints hit
  /// as a result of this evaluation are ignored. Defaults to false if not
  /// provided.
  ///
  /// If the expression fails to parse and compile, then [RPCError] 113
  /// "Expression compilation error" is returned.
  ///
  /// If an error occurs while evaluating the expression, an [ErrorRef]
  /// reference will be returned.
  ///
  /// If the expression is evaluated successfully, an [InstanceRef] reference
  /// will be returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// The return value can be one of [InstanceRef] or [ErrorRef].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Response> evaluateInFrame(
    String isolateId,
    int frameIndex,
    String expression, {
    Map<String, String>? scope,
    bool? disableBreakpoints,
  }) =>
      _call('evaluateInFrame', {
        'isolateId': isolateId,
        'frameIndex': frameIndex,
        'expression': expression,
        if (scope != null) 'scope': scope,
        if (disableBreakpoints != null)
          'disableBreakpoints': disableBreakpoints,
      });

  /// The `getAllocationProfile` RPC is used to retrieve allocation information
  /// for a given isolate.
  ///
  /// If `reset` is provided and is set to true, the allocation accumulators
  /// will be reset before collecting allocation information.
  ///
  /// If `gc` is provided and is set to true, a garbage collection will be
  /// attempted before collecting allocation information. There is no guarantee
  /// that a garbage collection will be actually be performed.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<AllocationProfile> getAllocationProfile(String isolateId,
          {bool? reset, bool? gc}) =>
      _call('getAllocationProfile', {
        'isolateId': isolateId,
        if (reset != null && reset) 'reset': reset,
        if (gc != null && gc) 'gc': gc,
      });

  /// The `getAllocationTraces` RPC allows for the retrieval of allocation
  /// traces for objects of a specific set of types (see
  /// [VmService.setTraceClassAllocation]). Only samples collected in the time
  /// range `[timeOriginMicros, timeOriginMicros + timeExtentMicros]` will be
  /// reported.
  ///
  /// If `classId` is provided, only traces for allocations with the matching
  /// `classId` will be reported.
  ///
  /// If the profiler is disabled, an RPC error response will be returned.
  ///
  /// If isolateId refers to an isolate which has exited, then the Collected
  /// Sentinel is returned.
  ///
  /// See [CpuSamples].
  Future<CpuSamples> getAllocationTraces(
    String isolateId, {
    int? timeOriginMicros,
    int? timeExtentMicros,
    String? classId,
  }) =>
      _call('getAllocationTraces', {
        'isolateId': isolateId,
        if (timeOriginMicros != null) 'timeOriginMicros': timeOriginMicros,
        if (timeExtentMicros != null) 'timeExtentMicros': timeExtentMicros,
        if (classId != null) 'classId': classId,
      });

  /// The `getClassList` RPC is used to retrieve a `ClassList` containing all
  /// classes for an isolate based on the isolate's `isolateId`.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [ClassList].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<ClassList> getClassList(String isolateId) =>
      _call('getClassList', {'isolateId': isolateId});

  /// The `getCpuSamples` RPC is used to retrieve samples collected by the CPU
  /// profiler. See [CpuSamples] for a detailed description of the response.
  ///
  /// The `timeOriginMicros` parameter is the beginning of the time range used
  /// to filter samples. It uses the same monotonic clock as dart:developer's
  /// `Timeline.now` and the VM embedding API's `Dart_TimelineGetMicros`. See
  /// [VmService.getVMTimelineMicros] for access to this clock through the
  /// service protocol.
  ///
  /// The `timeExtentMicros` parameter specifies how large the time range used
  /// to filter samples should be.
  ///
  /// For example, given `timeOriginMicros` and `timeExtentMicros`, only samples
  /// from the following time range will be returned: `(timeOriginMicros,
  /// timeOriginMicros + timeExtentMicros)`.
  ///
  /// If the profiler is disabled, an [RPCError] response will be returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<CpuSamples> getCpuSamples(
          String isolateId, int timeOriginMicros, int timeExtentMicros) =>
      _call('getCpuSamples', {
        'isolateId': isolateId,
        'timeOriginMicros': timeOriginMicros,
        'timeExtentMicros': timeExtentMicros
      });

  /// The `getFlagList` RPC returns a list of all command line flags in the VM
  /// along with their current values.
  ///
  /// See [FlagList].
  Future<FlagList> getFlagList() => _call('getFlagList');

  /// Returns a set of inbound references to the object specified by `targetId`.
  /// Up to `limit` references will be returned.
  ///
  /// The order of the references is undefined (i.e., not related to allocation
  /// order) and unstable (i.e., multiple invocations of this method against the
  /// same object can give different answers even if no Dart code has executed
  /// between the invocations).
  ///
  /// The references may include multiple `objectId`s that designate the same
  /// object.
  ///
  /// The references may include objects that are unreachable but have not yet
  /// been garbage collected.
  ///
  /// If `targetId` is a temporary id which has expired, then the `Expired`
  /// [Sentinel] is returned.
  ///
  /// If `targetId` refers to an object which has been collected by the VM's
  /// garbage collector, then the `Collected` [Sentinel] is returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [InboundReferences].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<InboundReferences> getInboundReferences(
          String isolateId, String targetId, int limit) =>
      _call('getInboundReferences',
          {'isolateId': isolateId, 'targetId': targetId, 'limit': limit});

  /// The `getInstances` RPC is used to retrieve a set of instances which are of
  /// a specific class.
  ///
  /// The order of the instances is undefined (i.e., not related to allocation
  /// order) and unstable (i.e., multiple invocations of this method against the
  /// same class can give different answers even if no Dart code has executed
  /// between the invocations).
  ///
  /// The set of instances may include objects that are unreachable but have not
  /// yet been garbage collected.
  ///
  /// `objectId` is the ID of the `Class` to retrieve instances for. `objectId`
  /// must be the ID of a `Class`, otherwise an [RPCError] is returned.
  ///
  /// `limit` is the maximum number of instances to be returned.
  ///
  /// If `includeSubclasses` is true, instances of subclasses of the specified
  /// class will be included in the set.
  ///
  /// If `includeImplementers` is true, instances of implementers of the
  /// specified class will be included in the set. Note that subclasses of a
  /// class are also considered implementers of that class.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [InstanceSet].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<InstanceSet> getInstances(
    String isolateId,
    String objectId,
    int limit, {
    bool? includeSubclasses,
    bool? includeImplementers,
  }) =>
      _call('getInstances', {
        'isolateId': isolateId,
        'objectId': objectId,
        'limit': limit,
        if (includeSubclasses != null) 'includeSubclasses': includeSubclasses,
        if (includeImplementers != null)
          'includeImplementers': includeImplementers,
      });

  /// The `getInstancesAsList` RPC is used to retrieve a set of instances which
  /// are of a specific class. This RPC returns an `InstanceRef` corresponding
  /// to a Dart `List<dynamic>` that contains the requested instances. This
  /// `List` is not growable, but it is otherwise mutable. The response type is
  /// what distinguishes this RPC from `getInstances`, which returns an
  /// `InstanceSet`.
  ///
  /// The order of the instances is undefined (i.e., not related to allocation
  /// order) and unstable (i.e., multiple invocations of this method against the
  /// same class can give different answers even if no Dart code has executed
  /// between the invocations).
  ///
  /// The set of instances may include objects that are unreachable but have not
  /// yet been garbage collected.
  ///
  /// `objectId` is the ID of the `Class` to retrieve instances for. `objectId`
  /// must be the ID of a `Class`, otherwise an [RPCError] is returned.
  ///
  /// If `includeSubclasses` is true, instances of subclasses of the specified
  /// class will be included in the set.
  ///
  /// If `includeImplementers` is true, instances of implementers of the
  /// specified class will be included in the set. Note that subclasses of a
  /// class are also considered implementers of that class.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<InstanceRef> getInstancesAsList(
    String isolateId,
    String objectId, {
    bool? includeSubclasses,
    bool? includeImplementers,
  }) =>
      _call('getInstancesAsList', {
        'isolateId': isolateId,
        'objectId': objectId,
        if (includeSubclasses != null) 'includeSubclasses': includeSubclasses,
        if (includeImplementers != null)
          'includeImplementers': includeImplementers,
      });

  /// The `getIsolate` RPC is used to lookup an `Isolate` object by its `id`.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Isolate].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Isolate> getIsolate(String isolateId) =>
      _call('getIsolate', {'isolateId': isolateId});

  /// The `getIsolateGroup` RPC is used to lookup an `IsolateGroup` object by
  /// its `id`.
  ///
  /// If `isolateGroupId` refers to an isolate group which has exited, then the
  /// `Expired` [Sentinel] is returned.
  ///
  /// `IsolateGroup` `id` is an opaque identifier that can be fetched from an
  /// `IsolateGroup`. List of active `IsolateGroup`'s, for example, is available
  /// on `VM` object.
  ///
  /// See [IsolateGroup], [VM].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<IsolateGroup> getIsolateGroup(String isolateGroupId) =>
      _call('getIsolateGroup', {'isolateGroupId': isolateGroupId});

  /// The `getIsolatePauseEvent` RPC is used to lookup an isolate's pause event
  /// by its `id`.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Isolate].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Event> getIsolatePauseEvent(String isolateId) =>
      _call('getIsolatePauseEvent', {'isolateId': isolateId});

  /// The `getMemoryUsage` RPC is used to lookup an isolate's memory usage
  /// statistics by its `id`.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Isolate].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<MemoryUsage> getMemoryUsage(String isolateId) =>
      _call('getMemoryUsage', {'isolateId': isolateId});

  /// The `getIsolateGroupMemoryUsage` RPC is used to lookup an isolate group's
  /// memory usage statistics by its `id`.
  ///
  /// If `isolateGroupId` refers to an isolate group which has exited, then the
  /// `Expired` [Sentinel] is returned.
  ///
  /// See [IsolateGroup].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<MemoryUsage> getIsolateGroupMemoryUsage(String isolateGroupId) =>
      _call('getIsolateGroupMemoryUsage', {'isolateGroupId': isolateGroupId});

  /// The `getScripts` RPC is used to retrieve a `ScriptList` containing all
  /// scripts for an isolate based on the isolate's `isolateId`.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [ScriptList].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<ScriptList> getScripts(String isolateId) =>
      _call('getScripts', {'isolateId': isolateId});

  /// The `getObject` RPC is used to lookup an `object` from some isolate by its
  /// `id`.
  ///
  /// If `objectId` is a temporary id which has expired, then the `Expired`
  /// [Sentinel] is returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// If `objectId` refers to a heap object which has been collected by the VM's
  /// garbage collector, then the `Collected` [Sentinel] is returned.
  ///
  /// If `objectId` refers to a non-heap object which has been deleted, then the
  /// `Collected` [Sentinel] is returned.
  ///
  /// If the object handle has not expired and the object has not been
  /// collected, then an [Obj] will be returned.
  ///
  /// The `offset` and `count` parameters are used to request subranges of
  /// Instance objects with the kinds: String, List, Map, Set, Uint8ClampedList,
  /// Uint8List, Uint16List, Uint32List, Uint64List, Int8List, Int16List,
  /// Int32List, Int64List, Float32List, Float64List, Inst32x3List,
  /// Float32x4List, and Float64x2List. These parameters are otherwise ignored.
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Obj> getObject(
    String isolateId,
    String objectId, {
    int? offset,
    int? count,
  }) =>
      _call('getObject', {
        'isolateId': isolateId,
        'objectId': objectId,
        if (offset != null) 'offset': offset,
        if (count != null) 'count': count,
      });

  /// The `getPerfettoCpuSamples` RPC is used to retrieve samples collected by
  /// the CPU profiler, serialized in Perfetto's proto format. See
  /// [PerfettoCpuSamples] for a detailed description of the response.
  ///
  /// The `timeOriginMicros` parameter is the beginning of the time range used
  /// to filter samples. It uses the same monotonic clock as dart:developer's
  /// `Timeline.now` and the VM embedding API's `Dart_TimelineGetMicros`. See
  /// [VmService.getVMTimelineMicros] for access to this clock through the
  /// service protocol.
  ///
  /// The `timeExtentMicros` parameter specifies how large the time range used
  /// to filter samples should be.
  ///
  /// For example, given `timeOriginMicros` and `timeExtentMicros`, only samples
  /// from the following time range will be returned: `(timeOriginMicros,
  /// timeOriginMicros + timeExtentMicros)`.
  ///
  /// If the profiler is disabled, an [RPCError] response will be returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<PerfettoCpuSamples> getPerfettoCpuSamples(String isolateId,
          {int? timeOriginMicros, int? timeExtentMicros}) =>
      _call('getPerfettoCpuSamples', {
        'isolateId': isolateId,
        if (timeOriginMicros != null) 'timeOriginMicros': timeOriginMicros,
        if (timeExtentMicros != null) 'timeExtentMicros': timeExtentMicros,
      });

  /// The `getPerfettoVMTimeline` RPC is used to retrieve an object which
  /// contains a VM timeline trace represented in Perfetto's proto format. See
  /// [PerfettoTimeline] for a detailed description of the response.
  ///
  /// The `timeOriginMicros` parameter is the beginning of the time range used
  /// to filter timeline events. It uses the same monotonic clock as
  /// dart:developer's `Timeline.now` and the VM embedding API's
  /// `Dart_TimelineGetMicros`. See [VmService.getVMTimelineMicros] for access
  /// to this clock through the service protocol.
  ///
  /// The `timeExtentMicros` parameter specifies how large the time range used
  /// to filter timeline events should be.
  ///
  /// For example, given `timeOriginMicros` and `timeExtentMicros`, only
  /// timeline events from the following time range will be returned:
  /// `(timeOriginMicros, timeOriginMicros + timeExtentMicros)`.
  ///
  /// If `getPerfettoVMTimeline` is invoked while the current recorder is
  /// Callback, an [RPCError] with error code `114`, `invalid timeline request`,
  /// will be returned as timeline events are handled by the embedder in this
  /// mode.
  ///
  /// If `getPerfettoVMTimeline` is invoked while the current recorder is one of
  /// Fuchsia or Macos or Systrace, an [RPCError] with error code `114`,
  /// `invalid timeline request`, will be returned as timeline events are
  /// handled by the OS in these modes.
  ///
  /// If `getPerfettoVMTimeline` is invoked while the current recorder is File
  /// or Perfettofile, an [RPCError] with error code `114`, `invalid timeline
  /// request`, will be returned as timeline events are written directly to a
  /// file, and thus cannot be retrieved through the VM Service, in these modes.
  Future<PerfettoTimeline> getPerfettoVMTimeline(
          {int? timeOriginMicros, int? timeExtentMicros}) =>
      _call('getPerfettoVMTimeline', {
        if (timeOriginMicros != null) 'timeOriginMicros': timeOriginMicros,
        if (timeExtentMicros != null) 'timeExtentMicros': timeExtentMicros,
      });

  /// The `getPorts` RPC is used to retrieve the list of `ReceivePort` instances
  /// for a given isolate.
  ///
  /// See [PortList].
  Future<PortList> getPorts(String isolateId) =>
      _call('getPorts', {'isolateId': isolateId});

  /// The `getRetainingPath` RPC is used to lookup a path from an object
  /// specified by `targetId` to a GC root (i.e., the object which is preventing
  /// this object from being garbage collected).
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// If `targetId` refers to a heap object which has been collected by the VM's
  /// garbage collector, then the `Collected` [Sentinel] is returned.
  ///
  /// If `targetId` refers to a non-heap object which has been deleted, then the
  /// `Collected` [Sentinel] is returned.
  ///
  /// If the object handle has not expired and the object has not been
  /// collected, then an [RetainingPath] will be returned.
  ///
  /// The `limit` parameter specifies the maximum path length to be reported as
  /// part of the retaining path. If a path is longer than `limit`, it will be
  /// truncated at the root end of the path.
  ///
  /// See [RetainingPath].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<RetainingPath> getRetainingPath(
          String isolateId, String targetId, int limit) =>
      _call('getRetainingPath',
          {'isolateId': isolateId, 'targetId': targetId, 'limit': limit});

  /// Returns a description of major uses of memory known to the VM.
  ///
  /// Adding or removing buckets is considered a backwards-compatible change for
  /// the purposes of versioning. A client must gracefully handle the removal or
  /// addition of any bucket.
  Future<ProcessMemoryUsage> getProcessMemoryUsage() =>
      _call('getProcessMemoryUsage');

  /// The `getStack` RPC is used to retrieve the current execution stack and
  /// message queue for an isolate. The isolate does not need to be paused.
  ///
  /// If `limit` is provided, up to `limit` frames from the top of the stack
  /// will be returned. If the stack depth is smaller than `limit` the entire
  /// stack is returned. Note: this limit also applies to the
  /// `asyncCausalFrames` stack representation in the `Stack` response.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Stack].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Stack> getStack(String isolateId, {int? limit}) => _call('getStack', {
        'isolateId': isolateId,
        if (limit != null) 'limit': limit,
      });

  /// The `getSupportedProtocols` RPC is used to determine which protocols are
  /// supported by the current server.
  ///
  /// The result of this call should be intercepted by any middleware that
  /// extends the core VM service protocol and should add its own protocol to
  /// the list of protocols before forwarding the response to the client.
  ///
  /// See [ProtocolList].
  Future<ProtocolList> getSupportedProtocols() =>
      _call('getSupportedProtocols');

  /// The `getSourceReport` RPC is used to generate a set of reports tied to
  /// source locations in an isolate.
  ///
  /// The `reports` parameter is used to specify which reports should be
  /// generated. The `reports` parameter is a list, which allows multiple
  /// reports to be generated simultaneously from a consistent isolate state.
  /// The `reports` parameter is allowed to be empty (this might be used to
  /// force compilation of a particular subrange of some script).
  ///
  /// The available report kinds are:
  ///
  /// report kind | meaning
  /// ----------- | -------
  /// Coverage | Provide code coverage information
  /// PossibleBreakpoints | Provide a list of token positions which correspond
  /// to possible breakpoints.
  ///
  /// The `scriptId` parameter is used to restrict the report to a particular
  /// script. When analyzing a particular script, either or both of the
  /// `tokenPos` and `endTokenPos` parameters may be provided to restrict the
  /// analysis to a subrange of a script (for example, these can be used to
  /// restrict the report to the range of a particular class or function).
  ///
  /// If the `scriptId` parameter is not provided then the reports are generated
  /// for all loaded scripts and the `tokenPos` and `endTokenPos` parameters are
  /// disallowed.
  ///
  /// The `forceCompilation` parameter can be used to force compilation of all
  /// functions in the range of the report. Forcing compilation can cause a
  /// compilation error, which could terminate the running Dart program. If this
  /// parameter is not provided, it is considered to have the value `false`.
  ///
  /// The `reportLines` parameter changes the token positions in
  /// `SourceReportRange.possibleBreakpoints` and `SourceReportCoverage` to be
  /// line numbers. This is designed to reduce the number of RPCs that need to
  /// be performed in the case that the client is only interested in line
  /// numbers. If this parameter is not provided, it is considered to have the
  /// value `false`.
  ///
  /// The `libraryFilters` parameter is intended to be used when gathering
  /// coverage for the whole isolate. If it is provided, the `SourceReport` will
  /// only contain results from scripts with URIs that start with one of the
  /// filter strings. For example, pass `["package:foo/"]` to only include
  /// scripts from the foo package.
  ///
  /// The `librariesAlreadyCompiled` parameter overrides the `forceCompilation`
  /// parameter on a per-library basis, setting it to `false` for any libary in
  /// this list. This is useful for cases where multiple `getSourceReport` RPCs
  /// are sent with `forceCompilation` enabled, to avoid recompiling the same
  /// libraries repeatedly. To use this parameter, enable `forceCompilation`,
  /// cache the results of each `getSourceReport` RPC, and pass all the
  /// libraries mentioned in the `SourceReport` to subsequent RPCs in the
  /// `librariesAlreadyCompiled`.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [SourceReport].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<SourceReport> getSourceReport(
    String isolateId,
    /*List<SourceReportKind>*/ List<String> reports, {
    String? scriptId,
    int? tokenPos,
    int? endTokenPos,
    bool? forceCompile,
    bool? reportLines,
    List<String>? libraryFilters,
    List<String>? librariesAlreadyCompiled,
  }) =>
      _call('getSourceReport', {
        'isolateId': isolateId,
        'reports': reports,
        if (scriptId != null) 'scriptId': scriptId,
        if (tokenPos != null) 'tokenPos': tokenPos,
        if (endTokenPos != null) 'endTokenPos': endTokenPos,
        if (forceCompile != null) 'forceCompile': forceCompile,
        if (reportLines != null) 'reportLines': reportLines,
        if (libraryFilters != null) 'libraryFilters': libraryFilters,
        if (librariesAlreadyCompiled != null)
          'librariesAlreadyCompiled': librariesAlreadyCompiled,
      });

  /// The `getVersion` RPC is used to determine what version of the Service
  /// Protocol is served by a VM.
  ///
  /// See [Version].
  Future<Version> getVersion() => _call('getVersion');

  /// The `getVM` RPC returns global information about a Dart virtual machine.
  ///
  /// See [VM].
  Future<VM> getVM() => _call('getVM');

  /// The `getVMTimeline` RPC is used to retrieve an object which contains VM
  /// timeline events. See [Timeline] for a detailed description of the
  /// response.
  ///
  /// The `timeOriginMicros` parameter is the beginning of the time range used
  /// to filter timeline events. It uses the same monotonic clock as
  /// dart:developer's `Timeline.now` and the VM embedding API's
  /// `Dart_TimelineGetMicros`. See [VmService.getVMTimelineMicros] for access
  /// to this clock through the service protocol.
  ///
  /// The `timeExtentMicros` parameter specifies how large the time range used
  /// to filter timeline events should be.
  ///
  /// For example, given `timeOriginMicros` and `timeExtentMicros`, only
  /// timeline events from the following time range will be returned:
  /// `(timeOriginMicros, timeOriginMicros + timeExtentMicros)`.
  ///
  /// If `getVMTimeline` is invoked while the current recorder is Callback, an
  /// [RPCError] with error code `114`, `invalid timeline request`, will be
  /// returned as timeline events are handled by the embedder in this mode.
  ///
  /// If `getVMTimeline` is invoked while the current recorder is one of Fuchsia
  /// or Macos or Systrace, an [RPCError] with error code `114`, `invalid
  /// timeline request`, will be returned as timeline events are handled by the
  /// OS in these modes.
  ///
  /// If `getVMTimeline` is invoked while the current recorder is File or
  /// Perfettofile, an [RPCError] with error code `114`, `invalid timeline
  /// request`, will be returned as timeline events are written directly to a
  /// file, and thus cannot be retrieved through the VM Service, in these modes.
  Future<Timeline> getVMTimeline(
          {int? timeOriginMicros, int? timeExtentMicros}) =>
      _call('getVMTimeline', {
        if (timeOriginMicros != null) 'timeOriginMicros': timeOriginMicros,
        if (timeExtentMicros != null) 'timeExtentMicros': timeExtentMicros,
      });

  /// The `getVMTimelineFlags` RPC returns information about the current VM
  /// timeline configuration.
  ///
  /// To change which timeline streams are currently enabled, see
  /// [VmService.setVMTimelineFlags].
  ///
  /// See [TimelineFlags].
  Future<TimelineFlags> getVMTimelineFlags() => _call('getVMTimelineFlags');

  /// The `getVMTimelineMicros` RPC returns the current time stamp from the
  /// clock used by the timeline, similar to `Timeline.now` in `dart:developer`
  /// and `Dart_TimelineGetMicros` in the VM embedding API.
  ///
  /// See [Timestamp] and [VmService.getVMTimeline].
  Future<Timestamp> getVMTimelineMicros() => _call('getVMTimelineMicros');

  /// The `pause` RPC is used to interrupt a running isolate. The RPC enqueues
  /// the interrupt request and potentially returns before the isolate is
  /// paused.
  ///
  /// When the isolate is paused an event will be sent on the `Debug` stream.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> pause(String isolateId) =>
      _call('pause', {'isolateId': isolateId});

  /// The `kill` RPC is used to kill an isolate as if by dart:isolate's
  /// `Isolate.kill(IMMEDIATE)`.
  ///
  /// The isolate is killed regardless of whether it is paused or running.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> kill(String isolateId) =>
      _call('kill', {'isolateId': isolateId});

  /// The `lookupResolvedPackageUris` RPC is used to convert a list of URIs to
  /// their resolved (or absolute) paths. For example, URIs passed to this RPC
  /// are mapped in the following ways:
  ///
  /// - `dart:io` -> `org-dartlang-sdk:///sdk/lib/io/io.dart`
  /// - `package:test/test.dart` ->
  /// `file:///$PACKAGE_INSTALLATION_DIR/lib/test.dart`
  /// - `file:///foo/bar/bazz.dart` -> `file:///foo/bar/bazz.dart`
  ///
  /// If a URI is not known, the corresponding entry in the [UriList] response
  /// will be `null`.
  ///
  /// If `local` is true, the VM will attempt to return local file paths instead
  /// of relative paths, but this is not guaranteed.
  ///
  /// See [UriList].
  Future<UriList> lookupResolvedPackageUris(String isolateId, List<String> uris,
          {bool? local}) =>
      _call('lookupResolvedPackageUris', {
        'isolateId': isolateId,
        'uris': uris,
        if (local != null) 'local': local,
      });

  /// The `lookupPackageUris` RPC is used to convert a list of URIs to their
  /// unresolved paths. For example, URIs passed to this RPC are mapped in the
  /// following ways:
  ///
  /// - `org-dartlang-sdk:///sdk/lib/io/io.dart` -> `dart:io`
  /// - `file:///$PACKAGE_INSTALLATION_DIR/lib/test.dart` ->
  /// `package:test/test.dart`
  /// - `file:///foo/bar/bazz.dart` -> `file:///foo/bar/bazz.dart`
  ///
  /// If a URI is not known, the corresponding entry in the [UriList] response
  /// will be `null`.
  ///
  /// See [UriList].
  Future<UriList> lookupPackageUris(String isolateId, List<String> uris) =>
      _call('lookupPackageUris', {'isolateId': isolateId, 'uris': uris});

  /// Registers a service that can be invoked by other VM service clients, where
  /// `service` is the name of the service to advertise and `alias` is an
  /// alternative name for the registered service.
  ///
  /// Requests made to the new service will be forwarded to the client which
  /// originally registered the service.
  ///
  /// See [Success].
  Future<Success> registerService(String service, String alias) =>
      _call('registerService', {'service': service, 'alias': alias});

  /// The `reloadSources` RPC is used to perform a hot reload of the sources of
  /// all isolates in the same isolate group as the isolate specified by
  /// `isolateId`.
  ///
  /// If the `force` parameter is provided, it indicates that all sources should
  /// be reloaded regardless of modification time.
  ///
  /// The `pause` parameter has been deprecated, so providing it no longer has
  /// any effect.
  ///
  /// If the `rootLibUri` parameter is provided, it indicates the new uri to the
  /// isolate group's root library.
  ///
  /// If the `packagesUri` parameter is provided, it indicates the new uri to
  /// the isolate group's package map (.packages) file.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<ReloadReport> reloadSources(
    String isolateId, {
    bool? force,
    bool? pause,
    String? rootLibUri,
    String? packagesUri,
  }) =>
      _call('reloadSources', {
        'isolateId': isolateId,
        if (force != null) 'force': force,
        if (pause != null) 'pause': pause,
        if (rootLibUri != null) 'rootLibUri': rootLibUri,
        if (packagesUri != null) 'packagesUri': packagesUri,
      });

  /// The `removeBreakpoint` RPC is used to remove a breakpoint by its `id`.
  ///
  /// Note that breakpoints are added and removed on a per-isolate basis.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> removeBreakpoint(String isolateId, String breakpointId) =>
      _call('removeBreakpoint',
          {'isolateId': isolateId, 'breakpointId': breakpointId});

  /// Requests a dump of the Dart heap of the given isolate.
  ///
  /// This method immediately returns success. The VM will then begin delivering
  /// binary events on the `HeapSnapshot` event stream. The binary data in these
  /// events, when concatenated together, conforms to the [HeapSnapshotGraph]
  /// type. The splitting of the SnapshotGraph into events can happen at any
  /// byte offset.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> requestHeapSnapshot(String isolateId) =>
      _call('requestHeapSnapshot', {'isolateId': isolateId});

  /// The `resume` RPC is used to resume execution of a paused isolate.
  ///
  /// If the `step` parameter is not provided, the program will resume regular
  /// execution.
  ///
  /// If the `step` parameter is provided, it indicates what form of
  /// single-stepping to use.
  ///
  /// step | meaning
  /// ---- | -------
  /// Into | Single step, entering function calls
  /// Over | Single step, skipping over function calls
  /// Out | Single step until the current function exits
  /// Rewind | Immediately exit the top frame(s) without executing any code.
  /// Isolate will be paused at the call of the last exited function.
  ///
  /// The `frameIndex` parameter is only used when the `step` parameter is
  /// Rewind. It specifies the stack frame to rewind to. Stack frame 0 is the
  /// currently executing function, so `frameIndex` must be at least 1.
  ///
  /// If the `frameIndex` parameter is not provided, it defaults to 1.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success], [StepOption].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> resume(String isolateId,
          {/*StepOption*/ String? step, int? frameIndex}) =>
      _call('resume', {
        'isolateId': isolateId,
        if (step != null) 'step': step,
        if (frameIndex != null) 'frameIndex': frameIndex,
      });

  /// The `setBreakpointState` RPC allows for breakpoints to be enabled or
  /// disabled, without requiring for the breakpoint to be completely removed.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// The returned [Breakpoint] is the updated breakpoint with its new values.
  ///
  /// See [Breakpoint].
  Future<Breakpoint> setBreakpointState(
          String isolateId, String breakpointId, bool enable) =>
      _call('setBreakpointState', {
        'isolateId': isolateId,
        'breakpointId': breakpointId,
        'enable': enable
      });

  /// The `setExceptionPauseMode` RPC is used to control if an isolate pauses
  /// when an exception is thrown.
  ///
  /// mode | meaning
  /// ---- | -------
  /// None | Do not pause isolate on thrown exceptions
  /// Unhandled | Pause isolate on unhandled exceptions
  /// All  | Pause isolate on all thrown exceptions
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  @Deprecated('Use setIsolatePauseMode instead')
  Future<Success> setExceptionPauseMode(
          String isolateId, /*ExceptionPauseMode*/ String mode) =>
      _call('setExceptionPauseMode', {'isolateId': isolateId, 'mode': mode});

  /// The `setIsolatePauseMode` RPC is used to control if or when an isolate
  /// will pause due to a change in execution state.
  ///
  /// The `shouldPauseOnExit` parameter specify whether the target isolate
  /// should pause on exit.
  ///
  /// mode | meaning
  /// ---- | -------
  /// None | Do not pause isolate on thrown exceptions
  /// Unhandled | Pause isolate on unhandled exceptions
  /// All  | Pause isolate on all thrown exceptions
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> setIsolatePauseMode(String isolateId,
          {/*ExceptionPauseMode*/ String? exceptionPauseMode,
          bool? shouldPauseOnExit}) =>
      _call('setIsolatePauseMode', {
        'isolateId': isolateId,
        if (exceptionPauseMode != null)
          'exceptionPauseMode': exceptionPauseMode,
        if (shouldPauseOnExit != null) 'shouldPauseOnExit': shouldPauseOnExit,
      });

  /// The `setFlag` RPC is used to set a VM flag at runtime. Returns an error if
  /// the named flag does not exist, the flag may not be set at runtime, or the
  /// value is of the wrong type for the flag.
  ///
  /// The following flags may be set at runtime:
  ///
  /// - pause_isolates_on_start
  /// - pause_isolates_on_exit
  /// - pause_isolates_on_unhandled_exceptions
  /// - profile_period
  /// - profiler
  ///
  /// Notes:
  ///
  /// - `profile_period` can be set to a minimum value of 50. Attempting to set
  /// `profile_period` to a lower value will result in a value of 50 being set.
  /// - Setting `profiler` will enable or disable the profiler depending on the
  /// provided value. If set to false when the profiler is already running, the
  /// profiler will be stopped but may not free its sample buffer depending on
  /// platform limitations.
  /// - Isolate pause settings will only be applied to newly spawned isolates.
  ///
  /// See [Success].
  ///
  /// The return value can be one of [Success] or [Error].
  Future<Response> setFlag(String name, String value) =>
      _call('setFlag', {'name': name, 'value': value});

  /// The `setLibraryDebuggable` RPC is used to enable or disable whether
  /// breakpoints and stepping work for a given library.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> setLibraryDebuggable(
          String isolateId, String libraryId, bool isDebuggable) =>
      _call('setLibraryDebuggable', {
        'isolateId': isolateId,
        'libraryId': libraryId,
        'isDebuggable': isDebuggable
      });

  /// The `setName` RPC is used to change the debugging name for an isolate.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> setName(String isolateId, String name) =>
      _call('setName', {'isolateId': isolateId, 'name': name});

  /// The `setTraceClassAllocation` RPC allows for enabling or disabling
  /// allocation tracing for a specific type of object. Allocation traces can be
  /// retrieved with the `getAllocationTraces` RPC.
  ///
  /// If `enable` is true, allocations of objects of the class represented by
  /// `classId` will be traced.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> setTraceClassAllocation(
          String isolateId, String classId, bool enable) =>
      _call('setTraceClassAllocation',
          {'isolateId': isolateId, 'classId': classId, 'enable': enable});

  /// The `setVMName` RPC is used to change the debugging name for the vm.
  ///
  /// See [Success].
  Future<Success> setVMName(String name) => _call('setVMName', {'name': name});

  /// The `setVMTimelineFlags` RPC is used to set which timeline streams are
  /// enabled.
  ///
  /// The `recordedStreams` parameter is the list of all timeline streams which
  /// are to be enabled. Streams not explicitly specified will be disabled.
  /// Invalid stream names are ignored.
  ///
  /// A `TimelineStreamSubscriptionsUpdate` event is sent on the `Timeline`
  /// stream as a result of invoking this RPC.
  ///
  /// To get the list of currently enabled timeline streams, see
  /// [VmService.getVMTimelineFlags].
  ///
  /// See [Success].
  Future<Success> setVMTimelineFlags(List<String> recordedStreams) =>
      _call('setVMTimelineFlags', {'recordedStreams': recordedStreams});

  /// The `streamCancel` RPC cancels a stream subscription in the VM.
  ///
  /// If the client is not subscribed to the stream, the `104` (Stream not
  /// subscribed) RPC error code is returned.
  ///
  /// See [Success].
  Future<Success> streamCancel(String streamId) =>
      _call('streamCancel', {'streamId': streamId});

  /// The `streamCpuSamplesWithUserTag` RPC allows for clients to specify which
  /// CPU samples collected by the profiler should be sent over the `Profiler`
  /// stream. When called, the VM will stream `CpuSamples` events containing
  /// `CpuSample`'s collected while a user tag contained in `userTags` was
  /// active.
  ///
  /// See [Success].
  Future<Success> streamCpuSamplesWithUserTag(List<String> userTags) =>
      _call('streamCpuSamplesWithUserTag', {'userTags': userTags});

  /// The `streamListen` RPC subscribes to a stream in the VM. Once subscribed,
  /// the client will begin receiving events from the stream.
  ///
  /// If the client is already subscribed to the stream, the `103` (Stream
  /// already subscribed) RPC error code is returned.
  ///
  /// The `streamId` parameter may have the following published values:
  ///
  /// streamId | event types provided
  /// -------- | -----------
  /// VM | VMUpdate, VMFlagUpdate
  /// Isolate | IsolateStart, IsolateRunnable, IsolateExit, IsolateUpdate,
  /// IsolateReload, ServiceExtensionAdded
  /// Debug | PauseStart, PauseExit, PauseBreakpoint, PauseInterrupted,
  /// PauseException, PausePostRequest, Resume, BreakpointAdded,
  /// BreakpointResolved, BreakpointRemoved, BreakpointUpdated, Inspect, None
  /// Profiler | CpuSamples, UserTagChanged
  /// GC | GC
  /// Extension | Extension
  /// Timeline | TimelineEvents, TimelineStreamsSubscriptionUpdate
  /// Logging | Logging
  /// Service | ServiceRegistered, ServiceUnregistered
  /// HeapSnapshot | HeapSnapshot
  ///
  /// Additionally, some embedders provide the `Stdout` and `Stderr` streams.
  /// These streams allow the client to subscribe to writes to stdout and
  /// stderr.
  ///
  /// streamId | event types provided
  /// -------- | -----------
  /// Stdout | WriteEvent
  /// Stderr | WriteEvent
  ///
  /// It is considered a `backwards compatible` change to add a new type of
  /// event to an existing stream. Clients should be written to handle this
  /// gracefully, perhaps by warning and ignoring.
  ///
  /// See [Success].
  Future<Success> streamListen(String streamId) =>
      _call('streamListen', {'streamId': streamId});

  /// Call an arbitrary service protocol method. This allows clients to call
  /// methods not explicitly exposed by this library.
  Future<Response> callMethod(String method,
      {String? isolateId, Map<String, dynamic>? args}) {
    return callServiceExtension(method, isolateId: isolateId, args: args);
  }

  /// Invoke a specific service protocol extension method.
  ///
  /// See https://api.dart.dev/stable/dart-developer/dart-developer-library.html.
  Future<Response> callServiceExtension(String method,
      {String? isolateId, Map<String, dynamic>? args}) {
    if (args == null && isolateId == null) {
      return _call(method);
    } else if (args == null) {
      return _call(method, {'isolateId': isolateId!});
    } else {
      args = Map.from(args);
      if (isolateId != null) {
        args['isolateId'] = isolateId;
      }
      return _call(method, args);
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _streamSub.cancel();
    _outstandingRequests.forEach((id, request) {
      request.completeError(RPCError(
        request.method,
        RPCErrorKind.kServerError.code,
        'Service connection disposed',
      ));
    });
    _outstandingRequests.clear();
    final handler = _disposeHandler;
    if (handler != null) {
      await handler();
    }
    assert(!_onDoneCompleter.isCompleted);
    _onDoneCompleter.complete();
  }

  /// When overridden, this method wraps [future] with logic.
  ///
  /// [wrapFuture] is called by [_call], which is the method that each VM
  /// service endpoint eventually goes through.
  ///
  /// This method should be overridden if subclasses of [VmService] need to do
  /// anything special upon calling the VM service, like tracking futures or
  /// logging requests.
  Future<T> wrapFuture<T>(String name, Future<T> future) {
    return future;
  }

  Future<T> _call<T>(String method, [Map args = const {}]) {
    if (_disposed) {
      throw RPCError(
        method,
        RPCErrorKind.kServerError.code,
        'Service connection disposed',
      );
    }
    return wrapFuture<T>(
      method,
      () {
        final request = _OutstandingRequest<T>(method);
        _outstandingRequests[request.id] = request;
        Map m = {
          'jsonrpc': '2.0',
          'id': request.id,
          'method': method,
          'params': args,
        };
        String message = jsonEncode(m);
        _onSend.add(message);
        _writeMessage(message);
        return request.future;
      }(),
    );
  }

  /// Register a service for invocation.
  void registerServiceCallback(String service, ServiceCallback cb) {
    if (_services.containsKey(service)) {
      throw Exception('Service \'$service\' already registered');
    }
    _services[service] = cb;
  }

  void _processMessage(dynamic message) {
    // Expect a String, an int[], or a ByteData.
    if (message is String) {
      _processMessageStr(message);
    } else if (message is Uint8List) {
      _processMessageByteData(ByteData.view(
          message.buffer, message.offsetInBytes, message.lengthInBytes));
    } else if (message is List<int>) {
      final list = Uint8List.fromList(message);
      _processMessageByteData(ByteData.view(list.buffer));
    } else if (message is ByteData) {
      _processMessageByteData(message);
    } else {
      _log.warning('unknown message type: ${message.runtimeType}');
    }
  }

  void _processMessageByteData(ByteData bytes) {
    final int metaOffset = 4;
    final int dataOffset = bytes.getUint32(0, Endian.little);
    final metaLength = dataOffset - metaOffset;
    final dataLength = bytes.lengthInBytes - dataOffset;
    final decoder = (const Utf8Decoder()).fuse(const JsonDecoder());
    final map = decoder.convert(Uint8List.view(
        bytes.buffer, bytes.offsetInBytes + metaOffset, metaLength)) as dynamic;
    final data = ByteData.view(
        bytes.buffer, bytes.offsetInBytes + dataOffset, dataLength);
    if (map['method'] == 'streamNotify') {
      final streamId = map['params']['streamId'];
      final event = map['params']['event'];
      event['data'] = data;
      _getEventController(streamId)
          .add(createServiceObject(event, const ['Event'])! as Event);
    }
  }

  void _processMessageStr(String message) {
    try {
      _onReceive.add(message);
      final json = jsonDecode(message)!;
      if (json.containsKey('method')) {
        if (json.containsKey('id')) {
          _processRequest(json);
        } else {
          _processNotification(json);
        }
      } else if (json.containsKey('id') &&
          (json.containsKey('result') || json.containsKey('error'))) {
        _processResponse(json);
      } else {
        _log.severe('unknown message type: $message');
      }
    } catch (e, s) {
      _log.severe('unable to decode message: $message, $e\n$s');
      return;
    }
  }

  void _processResponse(Map<String, dynamic> json) {
    final request = _outstandingRequests.remove(json['id']);
    if (request == null) {
      _log.severe('unmatched request response: ${jsonEncode(json)}');
    } else if (json['error'] != null) {
      request.completeError(RPCError.parse(request.method, json['error']));
    } else {
      final result = json['result'] as Map<String, dynamic>;
      final type = result['type'];
      if (type == 'Sentinel') {
        request.completeError(SentinelException.parse(request.method, result));
      } else if (_typeFactories[type] == null) {
        request.complete(Response.parse(result));
      } else {
        final returnTypes = _methodReturnTypes[request.method] ?? <String>[];
        request.complete(createServiceObject(result, returnTypes));
      }
    }
  }

  Future _processRequest(Map<String, dynamic> json) async {
    final result = await _routeRequest(
        json['method'], json['params'] ?? <String, dynamic>{});
    result['id'] = json['id'];
    result['jsonrpc'] = '2.0';
    String message = jsonEncode(result);
    _onSend.add(message);
    _writeMessage(message);
  }

  Future _processNotification(Map<String, dynamic> json) async {
    final method = json['method'];
    final params = json['params'] ?? <String, dynamic>{};
    if (method == 'streamNotify') {
      final streamId = params['streamId'];
      _getEventController(streamId)
          .add(createServiceObject(params['event'], const ['Event'])! as Event);
    } else {
      await _routeRequest(method, params);
    }
  }

  Future<Map> _routeRequest(String method, Map<String, dynamic> params) async {
    final service = _services[method];
    if (service == null) {
      final error = RPCError(method, RPCErrorKind.kMethodNotFound.code,
          'method not found \'$method\'');
      return {'error': error.toMap()};
    }

    try {
      return await service(params);
    } catch (e, st) {
      RPCError error = RPCError.withDetails(
        method,
        RPCErrorKind.kServerError.code,
        '$e',
        details: '$st',
      );
      return {'error': error.toMap()};
    }
  }
}

typedef DisposeHandler = Future Function();

// These error codes must be kept in sync with those in vm/json_stream.h and
// vmservice.dart.
enum RPCErrorKind {
  /// Application specific error code.
  kServerError(code: -32000, message: 'Application error'),

  /// Service connection disposed.
  ///
  /// This may indicate the connection was closed while a request was in-flight.
  kConnectionDisposed(code: -32010, message: 'Service connection disposed'),

  /// The JSON sent is not a valid Request object.
  kInvalidRequest(code: -32600, message: 'Invalid request object'),

  /// The method does not exist or is not available.
  kMethodNotFound(code: -32601, message: 'Method not found'),

  /// Invalid method parameter(s), such as a mismatched type.
  kInvalidParams(code: -32602, message: 'Invalid method parameters'),

  /// Internal JSON-RPC error.
  kInternalError(code: -32603, message: 'Internal JSON-RPC error'),

  /// The requested feature is disabled.
  kFeatureDisabled(code: 100, message: 'Feature is disabled'),

  /// The VM must be paused when performing this operation.
  kVmMustBePaused(code: 101, message: 'The VM must be paused'),

  /// Unable to add a breakpoint at the specified line or function.
  kCannotAddBreakpoint(
      code: 102,
      message: 'Unable to add breakpoint at specified line or function'),

  /// The stream has already been subscribed to.
  kStreamAlreadySubscribed(code: 103, message: 'Stream already subscribed'),

  /// The stream has not been subscribed to.
  kStreamNotSubscribed(code: 104, message: 'Stream not subscribed'),

  /// Isolate must first be runnable.
  kIsolateMustBeRunnable(code: 105, message: 'Isolate must be runnable'),

  /// Isolate must first be paused.
  kIsolateMustBePaused(code: 106, message: 'Isolate must be paused'),

  /// The isolate could not be resumed.
  kIsolateCannotBeResumed(
      code: 107, message: 'The isolate could not be resumed'),

  /// The isolate is currently reloading.
  kIsolateIsReloading(code: 108, message: 'The isolate is currently reloading'),

  /// The isolate could not be reloaded due to an unhandled exception.
  kIsolateCannotReload(code: 109, message: 'The isolate could not be reloaded'),

  /// The isolate reload resulted in no changes being applied.
  kIsolateNoReloadChangesApplied(
      code: 110, message: 'No reload changes applied'),

  /// The service has already been registered.
  kServiceAlreadyRegistered(code: 111, message: 'Service already registered'),

  /// The service no longer exists.
  kServiceDisappeared(code: 112, message: 'Service has disappeared'),

  /// There was an error in the expression compiler.
  kExpressionCompilationError(
      code: 113, message: 'Expression compilation error'),

  /// The timeline related request could not be completed due to the current configuration.
  kInvalidTimelineRequest(
      code: 114,
      message:
          'Invalid timeline request for the current timeline configuration'),

  /// The custom stream does not exist.
  kCustomStreamDoesNotExist(code: 130, message: 'Custom stream does not exist'),

  /// The core stream is not allowed.
  kCoreStreamNotAllowed(code: 131, message: 'Core streams are not allowed');

  const RPCErrorKind({required this.code, required this.message});

  final int code;

  final String message;

  static final _codeToErrorMap =
      RPCErrorKind.values.fold(<int, RPCErrorKind>{}, (map, error) {
    map[error.code] = error;
    return map;
  });

  static RPCErrorKind? fromCode(int code) {
    return _codeToErrorMap[code];
  }
}

class RPCError implements Exception {
  static RPCError parse(String callingMethod, dynamic json) {
    return RPCError(callingMethod, json['code'], json['message'], json['data']);
  }

  final String? callingMethod;
  final int code;
  final String message;
  final Map? data;

  RPCError(this.callingMethod, this.code, [message, this.data])
      : message =
            message ?? RPCErrorKind.fromCode(code)?.message ?? 'Unknown error';

  RPCError.withDetails(this.callingMethod, this.code, this.message,
      {Object? details})
      : data = details == null ? null : <String, dynamic>{} {
    if (details != null) {
      data!['details'] = details;
    }
  }

  String? get details => data == null ? null : data!['details'];

  /// Return a map representation of this error suitable for conversion to
  /// json.
  Map<String, dynamic> toMap() => <String, Object?>{
        'code': code,
        'message': message,
        if (data != null) 'data': data,
      };

  @override
  String toString() {
    if (details == null) {
      return '$callingMethod: ($code) $message';
    } else {
      return '$callingMethod: ($code) $message\n$details';
    }
  }
}

/// Thrown when an RPC response is a [Sentinel].
class SentinelException implements Exception {
  final String callingMethod;
  final Sentinel sentinel;

  SentinelException.parse(this.callingMethod, Map<String, dynamic> data)
      : sentinel = Sentinel.parse(data)!;

  @override
  String toString() => '$sentinel from $callingMethod()';
}

/// An `ExtensionData` is an arbitrary map that can have any contents.
class ExtensionData {
  static ExtensionData? parse(Map<String, dynamic>? json) =>
      json == null ? null : ExtensionData._fromJson(json);

  final Map<String, dynamic> data;

  ExtensionData() : data = <String, dynamic>{};

  ExtensionData._fromJson(this.data);

  @override
  String toString() => '[ExtensionData $data]';
}

/// A logging handler you can pass to a [VmService] instance in order to get
/// notifications of non-fatal service protocol warnings and errors.
abstract class Log {
  /// Log a warning level message.
  void warning(String message);

  /// Log an error level message.
  void severe(String message);
}

class _NullLog implements Log {
  @override
  void warning(String message) {}
  @override
  void severe(String message) {}
}

// enums

abstract class CodeKind {
  static const String kDart = 'Dart';
  static const String kNative = 'Native';
  static const String kStub = 'Stub';
  static const String kTag = 'Tag';
  static const String kCollected = 'Collected';
}

abstract class ErrorKind {
  /// The isolate has encountered an unhandled Dart exception.
  static const String kUnhandledException = 'UnhandledException';

  /// The isolate has encountered a Dart language error in the program.
  static const String kLanguageError = 'LanguageError';

  /// The isolate has encountered an internal error. These errors should be
  /// reported as bugs.
  static const String kInternalError = 'InternalError';

  /// The isolate has been terminated by an external source.
  static const String kTerminationError = 'TerminationError';
}

/// An enum of available event streams.
abstract class EventStreams {
  static const String kVM = 'VM';
  static const String kIsolate = 'Isolate';
  static const String kDebug = 'Debug';
  static const String kProfiler = 'Profiler';
  static const String kGC = 'GC';
  static const String kExtension = 'Extension';
  static const String kTimeline = 'Timeline';
  static const String kLogging = 'Logging';
  static const String kService = 'Service';
  static const String kHeapSnapshot = 'HeapSnapshot';
  static const String kStdout = 'Stdout';
  static const String kStderr = 'Stderr';
}

/// Adding new values to `EventKind` is considered a backwards compatible
/// change. Clients should ignore unrecognized events.
abstract class EventKind {
  /// Notification that VM identifying information has changed. Currently used
  /// to notify of changes to the VM debugging name via setVMName.
  static const String kVMUpdate = 'VMUpdate';

  /// Notification that a VM flag has been changed via the service protocol.
  static const String kVMFlagUpdate = 'VMFlagUpdate';

  /// Notification that a new isolate has started.
  static const String kIsolateStart = 'IsolateStart';

  /// Notification that an isolate is ready to run.
  static const String kIsolateRunnable = 'IsolateRunnable';

  /// Notification that an isolate has exited.
  static const String kIsolateExit = 'IsolateExit';

  /// Notification that isolate identifying information has changed. Currently
  /// used to notify of changes to the isolate debugging name via setName.
  static const String kIsolateUpdate = 'IsolateUpdate';

  /// Notification that an isolate has been reloaded.
  static const String kIsolateReload = 'IsolateReload';

  /// Notification that an extension RPC was registered on an isolate.
  static const String kServiceExtensionAdded = 'ServiceExtensionAdded';

  /// An isolate has paused at start, before executing code.
  static const String kPauseStart = 'PauseStart';

  /// An isolate has paused at exit, before terminating.
  static const String kPauseExit = 'PauseExit';

  /// An isolate has paused at a breakpoint or due to stepping.
  static const String kPauseBreakpoint = 'PauseBreakpoint';

  /// An isolate has paused due to interruption via pause.
  static const String kPauseInterrupted = 'PauseInterrupted';

  /// An isolate has paused due to an exception.
  static const String kPauseException = 'PauseException';

  /// An isolate has paused after a service request.
  static const String kPausePostRequest = 'PausePostRequest';

  /// An isolate has started or resumed execution.
  static const String kResume = 'Resume';

  /// Indicates an isolate is not yet runnable. Only appears in an Isolate's
  /// pauseEvent. Never sent over a stream.
  static const String kNone = 'None';

  /// A breakpoint has been added for an isolate.
  static const String kBreakpointAdded = 'BreakpointAdded';

  /// An unresolved breakpoint has been resolved for an isolate.
  static const String kBreakpointResolved = 'BreakpointResolved';

  /// A breakpoint has been removed.
  static const String kBreakpointRemoved = 'BreakpointRemoved';

  /// A breakpoint has been updated.
  static const String kBreakpointUpdated = 'BreakpointUpdated';

  /// A garbage collection event.
  static const String kGC = 'GC';

  /// Notification of bytes written, for example, to stdout/stderr.
  static const String kWriteEvent = 'WriteEvent';

  /// Notification from dart:developer.inspect.
  static const String kInspect = 'Inspect';

  /// Event from dart:developer.postEvent.
  static const String kExtension = 'Extension';

  /// Event from dart:developer.log.
  static const String kLogging = 'Logging';

  /// A block of timeline events has been completed.
  ///
  /// This service event is not sent for individual timeline events. It is
  /// subject to buffering, so the most recent timeline events may never be
  /// included in any TimelineEvents event if no timeline events occur later to
  /// complete the block.
  static const String kTimelineEvents = 'TimelineEvents';

  /// The set of active timeline streams was changed via `setVMTimelineFlags`.
  static const String kTimelineStreamSubscriptionsUpdate =
      'TimelineStreamSubscriptionsUpdate';

  /// Notification that a Service has been registered into the Service Protocol
  /// from another client.
  static const String kServiceRegistered = 'ServiceRegistered';

  /// Notification that a Service has been removed from the Service Protocol
  /// from another client.
  static const String kServiceUnregistered = 'ServiceUnregistered';

  /// Notification that the UserTag for an isolate has been changed.
  static const String kUserTagChanged = 'UserTagChanged';

  /// A block of recently collected CPU samples.
  static const String kCpuSamples = 'CpuSamples';
}

/// Adding new values to `InstanceKind` is considered a backwards compatible
/// change. Clients should treat unrecognized instance kinds as `PlainInstance`.
abstract class InstanceKind {
  /// A general instance of the Dart class Object.
  static const String kPlainInstance = 'PlainInstance';

  /// null instance.
  static const String kNull = 'Null';

  /// true or false.
  static const String kBool = 'Bool';

  /// An instance of the Dart class double.
  static const String kDouble = 'Double';

  /// An instance of the Dart class int.
  static const String kInt = 'Int';

  /// An instance of the Dart class String.
  static const String kString = 'String';

  /// An instance of the built-in VM List implementation. User-defined Lists
  /// will be PlainInstance.
  static const String kList = 'List';

  /// An instance of the built-in VM Map implementation. User-defined Maps will
  /// be PlainInstance.
  static const String kMap = 'Map';

  /// An instance of the built-in VM Set implementation. User-defined Sets will
  /// be PlainInstance.
  static const String kSet = 'Set';

  /// Vector instance kinds.
  static const String kFloat32x4 = 'Float32x4';
  static const String kFloat64x2 = 'Float64x2';
  static const String kInt32x4 = 'Int32x4';

  /// An instance of the built-in VM TypedData implementations. User-defined
  /// TypedDatas will be PlainInstance.
  static const String kUint8ClampedList = 'Uint8ClampedList';
  static const String kUint8List = 'Uint8List';
  static const String kUint16List = 'Uint16List';
  static const String kUint32List = 'Uint32List';
  static const String kUint64List = 'Uint64List';
  static const String kInt8List = 'Int8List';
  static const String kInt16List = 'Int16List';
  static const String kInt32List = 'Int32List';
  static const String kInt64List = 'Int64List';
  static const String kFloat32List = 'Float32List';
  static const String kFloat64List = 'Float64List';
  static const String kInt32x4List = 'Int32x4List';
  static const String kFloat32x4List = 'Float32x4List';
  static const String kFloat64x2List = 'Float64x2List';

  /// An instance of the Dart class Record.
  static const String kRecord = 'Record';

  /// An instance of the Dart class StackTrace.
  static const String kStackTrace = 'StackTrace';

  /// An instance of the built-in VM Closure implementation. User-defined
  /// Closures will be PlainInstance.
  static const String kClosure = 'Closure';

  /// An instance of the Dart class MirrorReference.
  static const String kMirrorReference = 'MirrorReference';

  /// An instance of the Dart class RegExp.
  static const String kRegExp = 'RegExp';

  /// An instance of the Dart class WeakProperty.
  static const String kWeakProperty = 'WeakProperty';

  /// An instance of the Dart class WeakReference.
  static const String kWeakReference = 'WeakReference';

  /// An instance of the Dart class Type.
  static const String kType = 'Type';

  /// An instance of the Dart class TypeParameter.
  static const String kTypeParameter = 'TypeParameter';

  /// An instance of the Dart class TypeRef. Note: this object kind is
  /// deprecated and will be removed.
  static const String kTypeRef = 'TypeRef';

  /// An instance of the Dart class FunctionType.
  static const String kFunctionType = 'FunctionType';

  /// An instance of the Dart class RecordType.
  static const String kRecordType = 'RecordType';

  /// An instance of the Dart class BoundedType.
  static const String kBoundedType = 'BoundedType';

  /// An instance of the Dart class ReceivePort.
  static const String kReceivePort = 'ReceivePort';

  /// An instance of the Dart class UserTag.
  static const String kUserTag = 'UserTag';

  /// An instance of the Dart class Finalizer.
  static const String kFinalizer = 'Finalizer';

  /// An instance of the Dart class NativeFinalizer.
  static const String kNativeFinalizer = 'NativeFinalizer';

  /// An instance of the Dart class FinalizerEntry.
  static const String kFinalizerEntry = 'FinalizerEntry';
}

/// A `SentinelKind` is used to distinguish different kinds of `Sentinel`
/// objects.
///
/// Adding new values to `SentinelKind` is considered a backwards compatible
/// change. Clients must handle this gracefully.
abstract class SentinelKind {
  /// Indicates that the object referred to has been collected by the GC.
  static const String kCollected = 'Collected';

  /// Indicates that an object id has expired.
  static const String kExpired = 'Expired';

  /// Indicates that a variable or field has not been initialized.
  static const String kNotInitialized = 'NotInitialized';

  /// Deprecated, no longer used.
  static const String kBeingInitialized = 'BeingInitialized';

  /// Indicates that a variable has been eliminated by the optimizing compiler.
  static const String kOptimizedOut = 'OptimizedOut';

  /// Reserved for future use.
  static const String kFree = 'Free';
}

/// A `FrameKind` is used to distinguish different kinds of `Frame` objects.
abstract class FrameKind {
  static const String kRegular = 'Regular';
  static const String kAsyncCausal = 'AsyncCausal';
  static const String kAsyncSuspensionMarker = 'AsyncSuspensionMarker';

  /// Deprecated since version 4.7 of the protocol. Will not occur in responses.
  static const String kAsyncActivation = 'AsyncActivation';
}

abstract class SourceReportKind {
  /// Used to request a code coverage information.
  static const String kCoverage = 'Coverage';

  /// Used to request a list of token positions of possible breakpoints.
  static const String kPossibleBreakpoints = 'PossibleBreakpoints';

  /// Used to request branch coverage information.
  static const String kBranchCoverage = 'BranchCoverage';
}

/// An `ExceptionPauseMode` indicates how the isolate pauses when an exception
/// is thrown.
abstract class ExceptionPauseMode {
  static const String kNone = 'None';
  static const String kUnhandled = 'Unhandled';
  static const String kAll = 'All';
}

/// A `StepOption` indicates which form of stepping is requested in a [resume]
/// RPC.
abstract class StepOption {
  static const String kInto = 'Into';
  static const String kOver = 'Over';
  static const String kOverAsyncSuspension = 'OverAsyncSuspension';
  static const String kOut = 'Out';
  static const String kRewind = 'Rewind';
}

// types

class AllocationProfile extends Response {
  static AllocationProfile? parse(Map<String, dynamic>? json) =>
      json == null ? null : AllocationProfile._fromJson(json);

  /// Allocation information for all class types.
  List<ClassHeapStats>? members;

  /// Information about memory usage for the isolate.
  MemoryUsage? memoryUsage;

  /// The timestamp of the last accumulator reset.
  ///
  /// If the accumulators have not been reset, this field is not present.
  @optional
  int? dateLastAccumulatorReset;

  /// The timestamp of the last manually triggered GC.
  ///
  /// If a GC has not been triggered manually, this field is not present.
  @optional
  int? dateLastServiceGC;

  AllocationProfile({
    this.members,
    this.memoryUsage,
    this.dateLastAccumulatorReset,
    this.dateLastServiceGC,
  });

  AllocationProfile._fromJson(Map<String, dynamic> json)
      : super._fromJson(json) {
    members = List<ClassHeapStats>.from(
        createServiceObject(json['members'], const ['ClassHeapStats'])
                as List? ??
            []);
    memoryUsage =
        createServiceObject(json['memoryUsage'], const ['MemoryUsage'])
            as MemoryUsage?;
    dateLastAccumulatorReset = json['dateLastAccumulatorReset'] is String
        ? int.parse(json['dateLastAccumulatorReset'])
        : json['dateLastAccumulatorReset'];
    dateLastServiceGC = json['dateLastServiceGC'] is String
        ? int.parse(json['dateLastServiceGC'])
        : json['dateLastServiceGC'];
  }

  @override
  String get type => 'AllocationProfile';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'members': members?.map((f) => f.toJson()).toList(),
        'memoryUsage': memoryUsage?.toJson(),
        if (dateLastAccumulatorReset case final dateLastAccumulatorResetValue?)
          'dateLastAccumulatorReset': dateLastAccumulatorResetValue,
        if (dateLastServiceGC case final dateLastServiceGCValue?)
          'dateLastServiceGC': dateLastServiceGCValue,
      };

  @override
  String toString() =>
      '[AllocationProfile members: $members, memoryUsage: $memoryUsage]';
}

/// A `BoundField` represents a field bound to a particular value in an
/// `Instance`.
///
/// If the field is uninitialized, the `value` will be the `NotInitialized`
/// [Sentinel].
class BoundField {
  static BoundField? parse(Map<String, dynamic>? json) =>
      json == null ? null : BoundField._fromJson(json);

  /// Provided for fields of instances that are NOT of the following instance
  /// kinds:
  ///  - Record
  ///
  /// Note: this property is deprecated and will be replaced by `name`.
  FieldRef? decl;

  /// [name] can be one of [String] or [int].
  dynamic name;

  /// [value] can be one of [InstanceRef] or [Sentinel].
  dynamic value;

  BoundField({
    this.decl,
    this.name,
    this.value,
  });

  BoundField._fromJson(Map<String, dynamic> json) {
    decl = createServiceObject(json['decl'], const ['FieldRef']) as FieldRef?;
    name =
        createServiceObject(json['name'], const ['String', 'int']) as dynamic;
    value =
        createServiceObject(json['value'], const ['InstanceRef', 'Sentinel'])
            as dynamic;
  }

  Map<String, dynamic> toJson() => <String, Object?>{
        'decl': decl?.toJson(),
        'name': name,
        'value': value?.toJson(),
      };

  @override
  String toString() => '[BoundField decl: $decl, name: $name, value: $value]';
}

/// A `BoundVariable` represents a local variable bound to a particular value in
/// a `Frame`.
///
/// If the variable is uninitialized, the `value` will be the `NotInitialized`
/// [Sentinel].
///
/// If the variable has been optimized out by the compiler, the `value` will be
/// the `OptimizedOut` [Sentinel].
class BoundVariable extends Response {
  static BoundVariable? parse(Map<String, dynamic>? json) =>
      json == null ? null : BoundVariable._fromJson(json);

  String? name;

  /// [value] can be one of [InstanceRef], [TypeArgumentsRef] or [Sentinel].
  dynamic value;

  /// The token position where this variable was declared.
  int? declarationTokenPos;

  /// The first token position where this variable is visible to the scope.
  int? scopeStartTokenPos;

  /// The last token position where this variable is visible to the scope.
  int? scopeEndTokenPos;

  BoundVariable({
    this.name,
    this.value,
    this.declarationTokenPos,
    this.scopeStartTokenPos,
    this.scopeEndTokenPos,
  });

  BoundVariable._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    value = createServiceObject(json['value'],
        const ['InstanceRef', 'TypeArgumentsRef', 'Sentinel']) as dynamic;
    declarationTokenPos = json['declarationTokenPos'] ?? -1;
    scopeStartTokenPos = json['scopeStartTokenPos'] ?? -1;
    scopeEndTokenPos = json['scopeEndTokenPos'] ?? -1;
  }

  @override
  String get type => 'BoundVariable';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'name': name ?? '',
        'value': value?.toJson(),
        'declarationTokenPos': declarationTokenPos ?? -1,
        'scopeStartTokenPos': scopeStartTokenPos ?? -1,
        'scopeEndTokenPos': scopeEndTokenPos ?? -1,
      };

  @override
  String toString() => '[BoundVariable ' //
      'name: $name, value: $value, declarationTokenPos: $declarationTokenPos, ' //
      'scopeStartTokenPos: $scopeStartTokenPos, scopeEndTokenPos: $scopeEndTokenPos]';
}

/// A `Breakpoint` describes a debugger breakpoint.
///
/// A breakpoint is `resolved` when it has been assigned to a specific program
/// location. A breakpoint my remain unresolved when it is in code which has not
/// yet been compiled or in a library which has not been loaded (i.e. a deferred
/// library).
class Breakpoint extends Obj {
  static Breakpoint? parse(Map<String, dynamic>? json) =>
      json == null ? null : Breakpoint._fromJson(json);

  /// A number identifying this breakpoint to the user.
  int? breakpointNumber;

  /// Is this breakpoint enabled?
  bool? enabled;

  /// Has this breakpoint been assigned to a specific program location?
  bool? resolved;

  /// Note: this property is deprecated and is always absent from the response.
  @optional
  bool? isSyntheticAsyncContinuation;

  /// SourceLocation when breakpoint is resolved, UnresolvedSourceLocation when
  /// a breakpoint is not resolved.
  ///
  /// [location] can be one of [SourceLocation] or [UnresolvedSourceLocation].
  dynamic location;

  Breakpoint({
    this.breakpointNumber,
    this.enabled,
    this.resolved,
    this.location,
    required String id,
    this.isSyntheticAsyncContinuation,
  }) : super(
          id: id,
        );

  Breakpoint._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    breakpointNumber = json['breakpointNumber'] ?? -1;
    enabled = json['enabled'] ?? false;
    resolved = json['resolved'] ?? false;
    isSyntheticAsyncContinuation = json['isSyntheticAsyncContinuation'];
    location = createServiceObject(json['location'],
        const ['SourceLocation', 'UnresolvedSourceLocation']) as dynamic;
  }

  @override
  String get type => 'Breakpoint';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'breakpointNumber': breakpointNumber ?? -1,
        'enabled': enabled ?? false,
        'resolved': resolved ?? false,
        'location': location?.toJson(),
        if (isSyntheticAsyncContinuation
            case final isSyntheticAsyncContinuationValue?)
          'isSyntheticAsyncContinuation': isSyntheticAsyncContinuationValue,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Breakpoint && id == other.id;

  @override
  String toString() => '[Breakpoint ' //
      'id: $id, breakpointNumber: $breakpointNumber, enabled: $enabled, ' //
      'resolved: $resolved, location: $location]';
}

/// `ClassRef` is a reference to a `Class`.
class ClassRef extends ObjRef {
  static ClassRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : ClassRef._fromJson(json);

  /// The name of this class.
  String? name;

  /// The location of this class in the source code.
  @optional
  SourceLocation? location;

  /// The library which contains this class.
  LibraryRef? library;

  /// The type parameters for the class.
  ///
  /// Provided if the class is generic.
  @optional
  List<InstanceRef>? typeParameters;

  ClassRef({
    this.name,
    this.library,
    required String id,
    this.location,
    this.typeParameters,
  }) : super(
          id: id,
        );

  ClassRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    location = createServiceObject(json['location'], const ['SourceLocation'])
        as SourceLocation?;
    library = createServiceObject(json['library'], const ['LibraryRef'])
        as LibraryRef?;
    typeParameters = json['typeParameters'] == null
        ? null
        : List<InstanceRef>.from(
            createServiceObject(json['typeParameters'], const ['InstanceRef'])!
                as List);
  }

  @override
  String get type => '@Class';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'name': name ?? '',
        'library': library?.toJson(),
        if (location?.toJson() case final locationValue?)
          'location': locationValue,
        if (typeParameters?.map((f) => f.toJson()).toList()
            case final typeParametersValue?)
          'typeParameters': typeParametersValue,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is ClassRef && id == other.id;

  @override
  String toString() => '[ClassRef id: $id, name: $name, library: $library]';
}

/// A `Class` provides information about a Dart language class.
class Class extends Obj implements ClassRef {
  static Class? parse(Map<String, dynamic>? json) =>
      json == null ? null : Class._fromJson(json);

  /// The name of this class.
  @override
  String? name;

  /// The location of this class in the source code.
  @optional
  @override
  SourceLocation? location;

  /// The library which contains this class.
  @override
  LibraryRef? library;

  /// The type parameters for the class.
  ///
  /// Provided if the class is generic.
  @optional
  @override
  List<InstanceRef>? typeParameters;

  /// The error which occurred during class finalization, if it exists.
  @optional
  ErrorRef? error;

  /// Is this an abstract class?
  bool? isAbstract;

  /// Is this a const class?
  bool? isConst;

  /// Is this a sealed class?
  bool? isSealed;

  /// Is this a mixin class?
  bool? isMixinClass;

  /// Is this a base class?
  bool? isBaseClass;

  /// Is this an interface class?
  bool? isInterfaceClass;

  /// Is this a final class?
  bool? isFinal;

  /// Are allocations of this class being traced?
  bool? traceAllocations;

  /// The superclass of this class, if any.
  @optional
  ClassRef? superClass;

  /// The supertype for this class, if any.
  ///
  /// The value will be of the kind: Type.
  @optional
  InstanceRef? superType;

  /// A list of interface types for this class.
  ///
  /// The values will be of the kind: Type.
  List<InstanceRef>? interfaces;

  /// The mixin type for this class, if any.
  ///
  /// The value will be of the kind: Type.
  @optional
  InstanceRef? mixin;

  /// A list of fields in this class. Does not include fields from superclasses.
  List<FieldRef>? fields;

  /// A list of functions in this class. Does not include functions from
  /// superclasses.
  List<FuncRef>? functions;

  /// A list of subclasses of this class.
  List<ClassRef>? subclasses;

  Class({
    this.name,
    this.library,
    this.isAbstract,
    this.isConst,
    this.isSealed,
    this.isMixinClass,
    this.isBaseClass,
    this.isInterfaceClass,
    this.isFinal,
    this.traceAllocations,
    this.interfaces,
    this.fields,
    this.functions,
    this.subclasses,
    required String id,
    this.location,
    this.typeParameters,
    this.error,
    this.superClass,
    this.superType,
    this.mixin,
  }) : super(
          id: id,
        );

  Class._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    location = createServiceObject(json['location'], const ['SourceLocation'])
        as SourceLocation?;
    library = createServiceObject(json['library'], const ['LibraryRef'])
        as LibraryRef?;
    typeParameters = json['typeParameters'] == null
        ? null
        : List<InstanceRef>.from(
            createServiceObject(json['typeParameters'], const ['InstanceRef'])!
                as List);
    error = createServiceObject(json['error'], const ['ErrorRef']) as ErrorRef?;
    isAbstract = json['abstract'] ?? false;
    isConst = json['const'] ?? false;
    isSealed = json['isSealed'] ?? false;
    isMixinClass = json['isMixinClass'] ?? false;
    isBaseClass = json['isBaseClass'] ?? false;
    isInterfaceClass = json['isInterfaceClass'] ?? false;
    isFinal = json['isFinal'] ?? false;
    traceAllocations = json['traceAllocations'] ?? false;
    superClass =
        createServiceObject(json['super'], const ['ClassRef']) as ClassRef?;
    superType = createServiceObject(json['superType'], const ['InstanceRef'])
        as InstanceRef?;
    interfaces = List<InstanceRef>.from(
        createServiceObject(json['interfaces'], const ['InstanceRef'])
                as List? ??
            []);
    mixin = createServiceObject(json['mixin'], const ['InstanceRef'])
        as InstanceRef?;
    fields = List<FieldRef>.from(
        createServiceObject(json['fields'], const ['FieldRef']) as List? ?? []);
    functions = List<FuncRef>.from(
        createServiceObject(json['functions'], const ['FuncRef']) as List? ??
            []);
    subclasses = List<ClassRef>.from(
        createServiceObject(json['subclasses'], const ['ClassRef']) as List? ??
            []);
  }

  @override
  String get type => 'Class';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'name': name ?? '',
        'library': library?.toJson(),
        'abstract': isAbstract ?? false,
        'const': isConst ?? false,
        'isSealed': isSealed ?? false,
        'isMixinClass': isMixinClass ?? false,
        'isBaseClass': isBaseClass ?? false,
        'isInterfaceClass': isInterfaceClass ?? false,
        'isFinal': isFinal ?? false,
        'traceAllocations': traceAllocations ?? false,
        'interfaces': interfaces?.map((f) => f.toJson()).toList(),
        'fields': fields?.map((f) => f.toJson()).toList(),
        'functions': functions?.map((f) => f.toJson()).toList(),
        'subclasses': subclasses?.map((f) => f.toJson()).toList(),
        if (location?.toJson() case final locationValue?)
          'location': locationValue,
        if (typeParameters?.map((f) => f.toJson()).toList()
            case final typeParametersValue?)
          'typeParameters': typeParametersValue,
        if (error?.toJson() case final errorValue?) 'error': errorValue,
        if (superClass?.toJson() case final superValue?) 'super': superValue,
        if (superType?.toJson() case final superTypeValue?)
          'superType': superTypeValue,
        if (mixin?.toJson() case final mixinValue?) 'mixin': mixinValue,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Class && id == other.id;

  @override
  String toString() => '[Class]';
}

class ClassHeapStats extends Response {
  static ClassHeapStats? parse(Map<String, dynamic>? json) =>
      json == null ? null : ClassHeapStats._fromJson(json);

  /// The class for which this memory information is associated.
  ClassRef? classRef;

  /// The number of bytes allocated for instances of class since the accumulator
  /// was last reset.
  int? accumulatedSize;

  /// The number of bytes currently allocated for instances of class.
  int? bytesCurrent;

  /// The number of instances of class which have been allocated since the
  /// accumulator was last reset.
  int? instancesAccumulated;

  /// The number of instances of class which are currently alive.
  int? instancesCurrent;

  ClassHeapStats({
    this.classRef,
    this.accumulatedSize,
    this.bytesCurrent,
    this.instancesAccumulated,
    this.instancesCurrent,
  });

  ClassHeapStats._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    classRef =
        createServiceObject(json['class'], const ['ClassRef']) as ClassRef?;
    accumulatedSize = json['accumulatedSize'] ?? -1;
    bytesCurrent = json['bytesCurrent'] ?? -1;
    instancesAccumulated = json['instancesAccumulated'] ?? -1;
    instancesCurrent = json['instancesCurrent'] ?? -1;
  }

  @override
  String get type => 'ClassHeapStats';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'class': classRef?.toJson(),
        'accumulatedSize': accumulatedSize ?? -1,
        'bytesCurrent': bytesCurrent ?? -1,
        'instancesAccumulated': instancesAccumulated ?? -1,
        'instancesCurrent': instancesCurrent ?? -1,
      };

  @override
  String toString() => '[ClassHeapStats ' //
      'classRef: $classRef, accumulatedSize: $accumulatedSize, bytesCurrent: $bytesCurrent, ' //
      'instancesAccumulated: $instancesAccumulated, instancesCurrent: $instancesCurrent]';
}

class ClassList extends Response {
  static ClassList? parse(Map<String, dynamic>? json) =>
      json == null ? null : ClassList._fromJson(json);

  List<ClassRef>? classes;

  ClassList({
    this.classes,
  });

  ClassList._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    classes = List<ClassRef>.from(
        createServiceObject(json['classes'], const ['ClassRef']) as List? ??
            []);
  }

  @override
  String get type => 'ClassList';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'classes': classes?.map((f) => f.toJson()).toList(),
      };

  @override
  String toString() => '[ClassList classes: $classes]';
}

/// `CodeRef` is a reference to a `Code` object.
class CodeRef extends ObjRef {
  static CodeRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : CodeRef._fromJson(json);

  /// A name for this code object.
  String? name;

  /// What kind of code object is this?
  /*CodeKind*/ String? kind;

  /// This code object's corresponding function.
  @optional
  FuncRef? function;

  CodeRef({
    this.name,
    this.kind,
    required String id,
    this.function,
  }) : super(
          id: id,
        );

  CodeRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    kind = json['kind'] ?? '';
    function =
        createServiceObject(json['function'], const ['FuncRef']) as FuncRef?;
  }

  @override
  String get type => '@Code';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'name': name ?? '',
        'kind': kind ?? '',
        if (function?.toJson() case final functionValue?)
          'function': functionValue,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is CodeRef && id == other.id;

  @override
  String toString() => '[CodeRef id: $id, name: $name, kind: $kind]';
}

/// A `Code` object represents compiled code in the Dart VM.
class Code extends Obj implements CodeRef {
  static Code? parse(Map<String, dynamic>? json) =>
      json == null ? null : Code._fromJson(json);

  /// A name for this code object.
  @override
  String? name;

  /// What kind of code object is this?
  @override
  /*CodeKind*/ String? kind;

  /// This code object's corresponding function.
  @optional
  @override
  FuncRef? function;

  Code({
    this.name,
    this.kind,
    required String id,
    this.function,
  }) : super(
          id: id,
        );

  Code._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    kind = json['kind'] ?? '';
    function =
        createServiceObject(json['function'], const ['FuncRef']) as FuncRef?;
  }

  @override
  String get type => 'Code';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'name': name ?? '',
        'kind': kind ?? '',
        if (function?.toJson() case final functionValue?)
          'function': functionValue,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Code && id == other.id;

  @override
  String toString() => '[Code id: $id, name: $name, kind: $kind]';
}

class ContextRef extends ObjRef {
  static ContextRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : ContextRef._fromJson(json);

  /// The number of variables in this context.
  int? length;

  ContextRef({
    this.length,
    required String id,
  }) : super(
          id: id,
        );

  ContextRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    length = json['length'] ?? -1;
  }

  @override
  String get type => '@Context';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'length': length ?? -1,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is ContextRef && id == other.id;

  @override
  String toString() => '[ContextRef id: $id, length: $length]';
}

/// A `Context` is a data structure which holds the captured variables for some
/// closure.
class Context extends Obj implements ContextRef {
  static Context? parse(Map<String, dynamic>? json) =>
      json == null ? null : Context._fromJson(json);

  /// The number of variables in this context.
  @override
  int? length;

  /// The enclosing context for this context.
  @optional
  ContextRef? parent;

  /// The variables in this context object.
  List<ContextElement>? variables;

  Context({
    this.length,
    this.variables,
    required String id,
    this.parent,
  }) : super(
          id: id,
        );

  Context._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    length = json['length'] ?? -1;
    parent = createServiceObject(json['parent'], const ['ContextRef'])
        as ContextRef?;
    variables = List<ContextElement>.from(
        createServiceObject(json['variables'], const ['ContextElement'])
                as List? ??
            []);
  }

  @override
  String get type => 'Context';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'length': length ?? -1,
        'variables': variables?.map((f) => f.toJson()).toList(),
        if (parent?.toJson() case final parentValue?) 'parent': parentValue,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Context && id == other.id;

  @override
  String toString() =>
      '[Context id: $id, length: $length, variables: $variables]';
}

class ContextElement {
  static ContextElement? parse(Map<String, dynamic>? json) =>
      json == null ? null : ContextElement._fromJson(json);

  /// [value] can be one of [InstanceRef] or [Sentinel].
  dynamic value;

  ContextElement({
    this.value,
  });

  ContextElement._fromJson(Map<String, dynamic> json) {
    value =
        createServiceObject(json['value'], const ['InstanceRef', 'Sentinel'])
            as dynamic;
  }

  Map<String, dynamic> toJson() => <String, Object?>{
        'value': value?.toJson(),
      };

  @override
  String toString() => '[ContextElement value: $value]';
}

/// See [VmService.getCpuSamples] and [CpuSample].
class CpuSamples extends Response {
  static CpuSamples? parse(Map<String, dynamic>? json) =>
      json == null ? null : CpuSamples._fromJson(json);

  /// The sampling rate for the profiler in microseconds.
  int? samplePeriod;

  /// The maximum possible stack depth for samples.
  int? maxStackDepth;

  /// The number of samples returned.
  int? sampleCount;

  /// The start of the period of time in which the returned samples were
  /// collected.
  int? timeOriginMicros;

  /// The duration of time covered by the returned samples.
  int? timeExtentMicros;

  /// The process ID for the VM.
  int? pid;

  /// A list of functions seen in the relevant samples. These references can be
  /// looked up using the indices provided in a `CpuSample` `stack` to determine
  /// which function was on the stack.
  List<ProfileFunction>? functions;

  /// A list of samples collected in the range `[timeOriginMicros,
  /// timeOriginMicros + timeExtentMicros]`
  List<CpuSample>? samples;

  CpuSamples({
    this.samplePeriod,
    this.maxStackDepth,
    this.sampleCount,
    this.timeOriginMicros,
    this.timeExtentMicros,
    this.pid,
    this.functions,
    this.samples,
  });

  CpuSamples._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    samplePeriod = json['samplePeriod'] ?? -1;
    maxStackDepth = json['maxStackDepth'] ?? -1;
    sampleCount = json['sampleCount'] ?? -1;
    timeOriginMicros = json['timeOriginMicros'] ?? -1;
    timeExtentMicros = json['timeExtentMicros'] ?? -1;
    pid = json['pid'] ?? -1;
    functions = List<ProfileFunction>.from(
        createServiceObject(json['functions'], const ['ProfileFunction'])
                as List? ??
            []);
    samples = List<CpuSample>.from(
        createServiceObject(json['samples'], const ['CpuSample']) as List? ??
            []);
  }

  @override
  String get type => 'CpuSamples';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'samplePeriod': samplePeriod ?? -1,
        'maxStackDepth': maxStackDepth ?? -1,
        'sampleCount': sampleCount ?? -1,
        'timeOriginMicros': timeOriginMicros ?? -1,
        'timeExtentMicros': timeExtentMicros ?? -1,
        'pid': pid ?? -1,
        'functions': functions?.map((f) => f.toJson()).toList(),
        'samples': samples?.map((f) => f.toJson()).toList(),
      };

  @override
  String toString() => '[CpuSamples ' //
      'samplePeriod: $samplePeriod, maxStackDepth: $maxStackDepth, ' //
      'sampleCount: $sampleCount, timeOriginMicros: $timeOriginMicros, timeExtentMicros: $timeExtentMicros, pid: $pid, functions: $functions, samples: $samples]';
}

class CpuSamplesEvent {
  static CpuSamplesEvent? parse(Map<String, dynamic>? json) =>
      json == null ? null : CpuSamplesEvent._fromJson(json);

  /// The sampling rate for the profiler in microseconds.
  int? samplePeriod;

  /// The maximum possible stack depth for samples.
  int? maxStackDepth;

  /// The number of samples returned.
  int? sampleCount;

  /// The start of the period of time in which the returned samples were
  /// collected.
  int? timeOriginMicros;

  /// The duration of time covered by the returned samples.
  int? timeExtentMicros;

  /// The process ID for the VM.
  int? pid;

  /// A list of references to functions seen in the relevant samples. These
  /// references can be looked up using the indices provided in a `CpuSample`
  /// `stack` to determine which function was on the stack.
  List<dynamic>? functions;

  /// A list of samples collected in the range `[timeOriginMicros,
  /// timeOriginMicros + timeExtentMicros]`
  List<CpuSample>? samples;

  CpuSamplesEvent({
    this.samplePeriod,
    this.maxStackDepth,
    this.sampleCount,
    this.timeOriginMicros,
    this.timeExtentMicros,
    this.pid,
    this.functions,
    this.samples,
  });

  CpuSamplesEvent._fromJson(Map<String, dynamic> json) {
    samplePeriod = json['samplePeriod'] ?? -1;
    maxStackDepth = json['maxStackDepth'] ?? -1;
    sampleCount = json['sampleCount'] ?? -1;
    timeOriginMicros = json['timeOriginMicros'] ?? -1;
    timeExtentMicros = json['timeExtentMicros'] ?? -1;
    pid = json['pid'] ?? -1;
    functions = List<dynamic>.from(
        createServiceObject(json['functions'], const ['dynamic']) as List? ??
            []);
    samples = List<CpuSample>.from(
        createServiceObject(json['samples'], const ['CpuSample']) as List? ??
            []);
  }

  Map<String, dynamic> toJson() => <String, Object?>{
        'samplePeriod': samplePeriod ?? -1,
        'maxStackDepth': maxStackDepth ?? -1,
        'sampleCount': sampleCount ?? -1,
        'timeOriginMicros': timeOriginMicros ?? -1,
        'timeExtentMicros': timeExtentMicros ?? -1,
        'pid': pid ?? -1,
        'functions': functions?.map((f) => f.toJson()).toList(),
        'samples': samples?.map((f) => f.toJson()).toList(),
      };

  @override
  String toString() => '[CpuSamplesEvent ' //
      'samplePeriod: $samplePeriod, maxStackDepth: $maxStackDepth, ' //
      'sampleCount: $sampleCount, timeOriginMicros: $timeOriginMicros, timeExtentMicros: $timeExtentMicros, pid: $pid, functions: $functions, samples: $samples]';
}

/// See [VmService.getCpuSamples] and [CpuSamples].
class CpuSample {
  static CpuSample? parse(Map<String, dynamic>? json) =>
      json == null ? null : CpuSample._fromJson(json);

  /// The thread ID representing the thread on which this sample was collected.
  int? tid;

  /// The time this sample was collected in microseconds.
  int? timestamp;

  /// The name of VM tag set when this sample was collected. Omitted if the VM
  /// tag for the sample is not considered valid.
  @optional
  String? vmTag;

  /// The name of the User tag set when this sample was collected. Omitted if no
  /// User tag was set when this sample was collected.
  @optional
  String? userTag;

  /// Provided and set to true if the sample's stack was truncated. This can
  /// happen if the stack is deeper than the `stackDepth` in the `CpuSamples`
  /// response.
  @optional
  bool? truncated;

  /// The call stack at the time this sample was collected. The stack is to be
  /// interpreted as top to bottom. Each element in this array is a key into the
  /// `functions` array in `CpuSamples`.
  ///
  /// Example:
  ///
  /// `functions[stack[0]] = @Function(bar())` `functions[stack[1]] =
  /// @Function(foo())` `functions[stack[2]] = @Function(main())`
  List<int>? stack;

  /// The identityHashCode assigned to the allocated object. This hash code is
  /// the same as the hash code provided in HeapSnapshot. Provided for CpuSample
  /// instances returned from a getAllocationTraces().
  @optional
  int? identityHashCode;

  /// Matches the index of a class in HeapSnapshot.classes. Provided for
  /// CpuSample instances returned from a getAllocationTraces().
  @optional
  int? classId;

  CpuSample({
    this.tid,
    this.timestamp,
    this.stack,
    this.vmTag,
    this.userTag,
    this.truncated,
    this.identityHashCode,
    this.classId,
  });

  CpuSample._fromJson(Map<String, dynamic> json) {
    tid = json['tid'] ?? -1;
    timestamp = json['timestamp'] ?? -1;
    vmTag = json['vmTag'];
    userTag = json['userTag'];
    truncated = json['truncated'];
    stack = List<int>.from(json['stack']);
    identityHashCode = json['identityHashCode'];
    classId = json['classId'];
  }

  Map<String, dynamic> toJson() => <String, Object?>{
        'tid': tid ?? -1,
        'timestamp': timestamp ?? -1,
        'stack': stack?.map((f) => f).toList(),
        if (vmTag case final vmTagValue?) 'vmTag': vmTagValue,
        if (userTag case final userTagValue?) 'userTag': userTagValue,
        if (truncated case final truncatedValue?) 'truncated': truncatedValue,
        if (identityHashCode case final identityHashCodeValue?)
          'identityHashCode': identityHashCodeValue,
        if (classId case final classIdValue?) 'classId': classIdValue,
      };

  @override
  String toString() =>
      '[CpuSample tid: $tid, timestamp: $timestamp, stack: $stack]';
}

/// `ErrorRef` is a reference to an `Error`.
class ErrorRef extends ObjRef {
  static ErrorRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : ErrorRef._fromJson(json);

  /// What kind of error is this?
  /*ErrorKind*/ String? kind;

  /// A description of the error.
  String? message;

  ErrorRef({
    this.kind,
    this.message,
    required String id,
  }) : super(
          id: id,
        );

  ErrorRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    kind = json['kind'] ?? '';
    message = json['message'] ?? '';
  }

  @override
  String get type => '@Error';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'kind': kind ?? '',
        'message': message ?? '',
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is ErrorRef && id == other.id;

  @override
  String toString() => '[ErrorRef id: $id, kind: $kind, message: $message]';
}

/// An `Error` represents a Dart language level error. This is distinct from an
/// [RPCError].
class Error extends Obj implements ErrorRef {
  static Error? parse(Map<String, dynamic>? json) =>
      json == null ? null : Error._fromJson(json);

  /// What kind of error is this?
  @override
  /*ErrorKind*/ String? kind;

  /// A description of the error.
  @override
  String? message;

  /// If this error is due to an unhandled exception, this is the exception
  /// thrown.
  @optional
  InstanceRef? exception;

  /// If this error is due to an unhandled exception, this is the stacktrace
  /// object.
  @optional
  InstanceRef? stacktrace;

  Error({
    this.kind,
    this.message,
    required String id,
    this.exception,
    this.stacktrace,
  }) : super(
          id: id,
        );

  Error._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    kind = json['kind'] ?? '';
    message = json['message'] ?? '';
    exception = createServiceObject(json['exception'], const ['InstanceRef'])
        as InstanceRef?;
    stacktrace = createServiceObject(json['stacktrace'], const ['InstanceRef'])
        as InstanceRef?;
  }

  @override
  String get type => 'Error';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'kind': kind ?? '',
        'message': message ?? '',
        if (exception?.toJson() case final exceptionValue?)
          'exception': exceptionValue,
        if (stacktrace?.toJson() case final stacktraceValue?)
          'stacktrace': stacktraceValue,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Error && id == other.id;

  @override
  String toString() => '[Error id: $id, kind: $kind, message: $message]';
}

/// An `Event` is an asynchronous notification from the VM. It is delivered only
/// when the client has subscribed to an event stream using the [streamListen]
/// RPC.
///
/// For more information, see [events].
class Event extends Response {
  static Event? parse(Map<String, dynamic>? json) =>
      json == null ? null : Event._fromJson(json);

  /// What kind of event is this?
  /*EventKind*/ String? kind;

  /// The isolate group with which this event is associated.
  ///
  /// This is provided for all event kinds except for:
  /// - VMUpdate, VMFlagUpdate, TimelineStreamSubscriptionsUpdate,
  /// TimelineEvents
  @optional
  IsolateGroupRef? isolateGroup;

  /// The isolate with which this event is associated.
  ///
  /// This is provided for all event kinds except for:
  ///  - VMUpdate, VMFlagUpdate, TimelineStreamSubscriptionsUpdate,
  ///  - TimelineEvents, IsolateReload
  @optional
  IsolateRef? isolate;

  /// The vm with which this event is associated.
  ///
  /// This is provided for the event kind:
  ///  - VMUpdate, VMFlagUpdate
  @optional
  VMRef? vm;

  /// The timestamp (in milliseconds since the epoch) associated with this
  /// event. For some isolate pause events, the timestamp is from when the
  /// isolate was paused. For other events, the timestamp is from when the event
  /// was created.
  int? timestamp;

  /// The breakpoint which was added, removed, or resolved.
  ///
  /// This is provided for the event kinds:
  ///  - PauseBreakpoint
  ///  - BreakpointAdded
  ///  - BreakpointRemoved
  ///  - BreakpointResolved
  ///  - BreakpointUpdated
  @optional
  Breakpoint? breakpoint;

  /// The list of breakpoints at which we are currently paused for a
  /// PauseBreakpoint event.
  ///
  /// This list may be empty. For example, while single-stepping, the VM sends a
  /// PauseBreakpoint event with no breakpoints.
  ///
  /// If there is more than one breakpoint set at the program position, then all
  /// of them will be provided.
  ///
  /// This is provided for the event kinds:
  ///  - PauseBreakpoint
  @optional
  List<Breakpoint>? pauseBreakpoints;

  /// The top stack frame associated with this event, if applicable.
  ///
  /// This is provided for the event kinds:
  ///  - PauseBreakpoint
  ///  - PauseInterrupted
  ///  - PauseException
  ///
  /// For PauseInterrupted events, there will be no top frame if the isolate is
  /// idle (waiting in the message loop).
  ///
  /// For the Resume event, the top frame is provided at all times except for
  /// the initial resume event that is delivered when an isolate begins
  /// execution.
  @optional
  Frame? topFrame;

  /// The exception associated with this event, if this is a PauseException
  /// event.
  @optional
  InstanceRef? exception;

  /// An array of bytes, encoded as a base64 string.
  ///
  /// This is provided for the WriteEvent event.
  @optional
  String? bytes;

  /// The argument passed to dart:developer.inspect.
  ///
  /// This is provided for the Inspect event.
  @optional
  InstanceRef? inspectee;

  /// The garbage collection (GC) operation performed.
  ///
  /// This is provided for the event kinds:
  ///  - GC
  @optional
  String? gcType;

  /// The RPC name of the extension that was added.
  ///
  /// This is provided for the ServiceExtensionAdded event.
  @optional
  String? extensionRPC;

  /// The extension event kind.
  ///
  /// This is provided for the Extension event.
  @optional
  String? extensionKind;

  /// The extension event data.
  ///
  /// This is provided for the Extension event.
  @optional
  ExtensionData? extensionData;

  /// An array of TimelineEvents
  ///
  /// This is provided for the TimelineEvents event.
  @optional
  List<TimelineEvent>? timelineEvents;

  /// The new set of recorded timeline streams.
  ///
  /// This is provided for the TimelineStreamSubscriptionsUpdate event.
  @optional
  List<String>? updatedStreams;

  /// Is the isolate paused at an await, yield, or yield* statement?
  ///
  /// This is provided for the event kinds:
  ///  - PauseBreakpoint
  ///  - PauseInterrupted
  @optional
  bool? atAsyncSuspension;

  /// The status (success or failure) related to the event. This is provided for
  /// the event kinds:
  ///  - IsolateReloaded
  @optional
  String? status;

  /// The reason why reloading the sources in the isolate group associated with
  /// this event failed.
  ///
  /// Only provided for events of kind IsolateReload.
  @optional
  String? reloadFailureReason;

  /// LogRecord data.
  ///
  /// This is provided for the Logging event.
  @optional
  LogRecord? logRecord;

  /// The service identifier.
  ///
  /// This is provided for the event kinds:
  ///  - ServiceRegistered
  ///  - ServiceUnregistered
  @optional
  String? service;

  /// The RPC method that should be used to invoke the service.
  ///
  /// This is provided for the event kinds:
  ///  - ServiceRegistered
  ///  - ServiceUnregistered
  @optional
  String? method;

  /// The alias of the registered service.
  ///
  /// This is provided for the event kinds:
  ///  - ServiceRegistered
  @optional
  String? alias;

  /// The name of the changed flag.
  ///
  /// This is provided for the event kinds:
  ///  - VMFlagUpdate
  @optional
  String? flag;

  /// The new value of the changed flag.
  ///
  /// This is provided for the event kinds:
  ///  - VMFlagUpdate
  @optional
  String? newValue;

  /// Specifies whether this event is the last of a group of events.
  ///
  /// This is provided for the event kinds:
  ///  - HeapSnapshot
  @optional
  bool? last;

  /// The current UserTag label.
  @optional
  String? updatedTag;

  /// The previous UserTag label.
  @optional
  String? previousTag;

  /// A CPU profile containing recent samples.
  @optional
  CpuSamplesEvent? cpuSamples;

  /// Binary data associated with the event.
  ///
  /// This is provided for the event kinds:
  ///   - HeapSnapshot
  @optional
  ByteData? data;

  Event({
    this.kind,
    this.timestamp,
    this.isolateGroup,
    this.isolate,
    this.vm,
    this.breakpoint,
    this.pauseBreakpoints,
    this.topFrame,
    this.exception,
    this.bytes,
    this.inspectee,
    this.gcType,
    this.extensionRPC,
    this.extensionKind,
    this.extensionData,
    this.timelineEvents,
    this.updatedStreams,
    this.atAsyncSuspension,
    this.status,
    this.reloadFailureReason,
    this.logRecord,
    this.service,
    this.method,
    this.alias,
    this.flag,
    this.newValue,
    this.last,
    this.updatedTag,
    this.previousTag,
    this.cpuSamples,
    this.data,
  });

  Event._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    kind = json['kind'] ?? '';
    isolateGroup =
        createServiceObject(json['isolateGroup'], const ['IsolateGroupRef'])
            as IsolateGroupRef?;
    isolate = createServiceObject(json['isolate'], const ['IsolateRef'])
        as IsolateRef?;
    vm = createServiceObject(json['vm'], const ['VMRef']) as VMRef?;
    timestamp = json['timestamp'] ?? -1;
    breakpoint = createServiceObject(json['breakpoint'], const ['Breakpoint'])
        as Breakpoint?;
    pauseBreakpoints = json['pauseBreakpoints'] == null
        ? null
        : List<Breakpoint>.from(
            createServiceObject(json['pauseBreakpoints'], const ['Breakpoint'])!
                as List);
    topFrame = createServiceObject(json['topFrame'], const ['Frame']) as Frame?;
    exception = createServiceObject(json['exception'], const ['InstanceRef'])
        as InstanceRef?;
    bytes = json['bytes'];
    inspectee = createServiceObject(json['inspectee'], const ['InstanceRef'])
        as InstanceRef?;
    gcType = json['gcType'];
    extensionRPC = json['extensionRPC'];
    extensionKind = json['extensionKind'];
    extensionData = ExtensionData.parse(json['extensionData']);
    timelineEvents = json['timelineEvents'] == null
        ? null
        : List<TimelineEvent>.from(createServiceObject(
            json['timelineEvents'], const ['TimelineEvent'])! as List);
    updatedStreams = json['updatedStreams'] == null
        ? null
        : List<String>.from(json['updatedStreams']);
    atAsyncSuspension = json['atAsyncSuspension'];
    status = json['status'];
    reloadFailureReason = json['reloadFailureReason'];
    logRecord = createServiceObject(json['logRecord'], const ['LogRecord'])
        as LogRecord?;
    service = json['service'];
    method = json['method'];
    alias = json['alias'];
    flag = json['flag'];
    newValue = json['newValue'];
    last = json['last'];
    updatedTag = json['updatedTag'];
    previousTag = json['previousTag'];
    cpuSamples =
        createServiceObject(json['cpuSamples'], const ['CpuSamplesEvent'])
            as CpuSamplesEvent?;
    data = json['data'];
  }

  @override
  String get type => 'Event';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'kind': kind ?? '',
        'timestamp': timestamp ?? -1,
        if (isolateGroup?.toJson() case final isolateGroupValue?)
          'isolateGroup': isolateGroupValue,
        if (isolate?.toJson() case final isolateValue?) 'isolate': isolateValue,
        if (vm?.toJson() case final vmValue?) 'vm': vmValue,
        if (breakpoint?.toJson() case final breakpointValue?)
          'breakpoint': breakpointValue,
        if (pauseBreakpoints?.map((f) => f.toJson()).toList()
            case final pauseBreakpointsValue?)
          'pauseBreakpoints': pauseBreakpointsValue,
        if (topFrame?.toJson() case final topFrameValue?)
          'topFrame': topFrameValue,
        if (exception?.toJson() case final exceptionValue?)
          'exception': exceptionValue,
        if (bytes case final bytesValue?) 'bytes': bytesValue,
        if (inspectee?.toJson() case final inspecteeValue?)
          'inspectee': inspecteeValue,
        if (gcType case final gcTypeValue?) 'gcType': gcTypeValue,
        if (extensionRPC case final extensionRPCValue?)
          'extensionRPC': extensionRPCValue,
        if (extensionKind case final extensionKindValue?)
          'extensionKind': extensionKindValue,
        if (extensionData?.data case final extensionDataValue?)
          'extensionData': extensionDataValue,
        if (timelineEvents?.map((f) => f.toJson()).toList()
            case final timelineEventsValue?)
          'timelineEvents': timelineEventsValue,
        if (updatedStreams?.map((f) => f).toList()
            case final updatedStreamsValue?)
          'updatedStreams': updatedStreamsValue,
        if (atAsyncSuspension case final atAsyncSuspensionValue?)
          'atAsyncSuspension': atAsyncSuspensionValue,
        if (status case final statusValue?) 'status': statusValue,
        if (reloadFailureReason case final reloadFailureReasonValue?)
          'reloadFailureReason': reloadFailureReasonValue,
        if (logRecord?.toJson() case final logRecordValue?)
          'logRecord': logRecordValue,
        if (service case final serviceValue?) 'service': serviceValue,
        if (method case final methodValue?) 'method': methodValue,
        if (alias case final aliasValue?) 'alias': aliasValue,
        if (flag case final flagValue?) 'flag': flagValue,
        if (newValue case final newValueValue?) 'newValue': newValueValue,
        if (last case final lastValue?) 'last': lastValue,
        if (updatedTag case final updatedTagValue?)
          'updatedTag': updatedTagValue,
        if (previousTag case final previousTagValue?)
          'previousTag': previousTagValue,
        if (cpuSamples?.toJson() case final cpuSamplesValue?)
          'cpuSamples': cpuSamplesValue,
        if (data case final dataValue?) 'data': dataValue,
      };

  @override
  String toString() => '[Event kind: $kind, timestamp: $timestamp]';
}

/// An `FieldRef` is a reference to a `Field`.
class FieldRef extends ObjRef {
  static FieldRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : FieldRef._fromJson(json);

  /// The name of this field.
  String? name;

  /// The owner of this field, which can be either a Library or a Class.
  ///
  /// Note: the location of `owner` may not agree with `location` if this is a
  /// field from a mixin application, patched class, etc.
  ObjRef? owner;

  /// The declared type of this field.
  ///
  /// The value will always be of one of the kinds: Type, TypeParameter,
  /// RecordType, FunctionType, BoundedType.
  InstanceRef? declaredType;

  /// Is this field const?
  bool? isConst;

  /// Is this field final?
  bool? isFinal;

  /// Is this field static?
  bool? isStatic;

  /// The location of this field in the source code.
  ///
  /// Note: this may not agree with the location of `owner` if this is a field
  /// from a mixin application, patched class, etc.
  @optional
  SourceLocation? location;

  FieldRef({
    this.name,
    this.owner,
    this.declaredType,
    this.isConst,
    this.isFinal,
    this.isStatic,
    required String id,
    this.location,
  }) : super(
          id: id,
        );

  FieldRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    owner = createServiceObject(json['owner'], const ['ObjRef']) as ObjRef?;
    declaredType =
        createServiceObject(json['declaredType'], const ['InstanceRef'])
            as InstanceRef?;
    isConst = json['const'] ?? false;
    isFinal = json['final'] ?? false;
    isStatic = json['static'] ?? false;
    location = createServiceObject(json['location'], const ['SourceLocation'])
        as SourceLocation?;
  }

  @override
  String get type => '@Field';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'name': name ?? '',
        'owner': owner?.toJson(),
        'declaredType': declaredType?.toJson(),
        'const': isConst ?? false,
        'final': isFinal ?? false,
        'static': isStatic ?? false,
        if (location?.toJson() case final locationValue?)
          'location': locationValue,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is FieldRef && id == other.id;

  @override
  String toString() => '[FieldRef ' //
      'id: $id, name: $name, owner: $owner, declaredType: $declaredType, ' //
      'isConst: $isConst, isFinal: $isFinal, isStatic: $isStatic]';
}

/// A `Field` provides information about a Dart language field or variable.
class Field extends Obj implements FieldRef {
  static Field? parse(Map<String, dynamic>? json) =>
      json == null ? null : Field._fromJson(json);

  /// The name of this field.
  @override
  String? name;

  /// The owner of this field, which can be either a Library or a Class.
  ///
  /// Note: the location of `owner` may not agree with `location` if this is a
  /// field from a mixin application, patched class, etc.
  @override
  ObjRef? owner;

  /// The declared type of this field.
  ///
  /// The value will always be of one of the kinds: Type, TypeParameter,
  /// RecordType, FunctionType, BoundedType.
  @override
  InstanceRef? declaredType;

  /// Is this field const?
  @override
  bool? isConst;

  /// Is this field final?
  @override
  bool? isFinal;

  /// Is this field static?
  @override
  bool? isStatic;

  /// The location of this field in the source code.
  ///
  /// Note: this may not agree with the location of `owner` if this is a field
  /// from a mixin application, patched class, etc.
  @optional
  @override
  SourceLocation? location;

  /// The value of this field, if the field is static. If uninitialized, this
  /// will take the value of an uninitialized Sentinel.
  ///
  /// [staticValue] can be one of [InstanceRef] or [Sentinel].
  @optional
  dynamic staticValue;

  Field({
    this.name,
    this.owner,
    this.declaredType,
    this.isConst,
    this.isFinal,
    this.isStatic,
    required String id,
    this.location,
    this.staticValue,
  }) : super(
          id: id,
        );

  Field._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    owner = createServiceObject(json['owner'], const ['ObjRef']) as ObjRef?;
    declaredType =
        createServiceObject(json['declaredType'], const ['InstanceRef'])
            as InstanceRef?;
    isConst = json['const'] ?? false;
    isFinal = json['final'] ?? false;
    isStatic = json['static'] ?? false;
    location = createServiceObject(json['location'], const ['SourceLocation'])
        as SourceLocation?;
    staticValue = createServiceObject(
        json['staticValue'], const ['InstanceRef', 'Sentinel']) as dynamic;
  }

  @override
  String get type => 'Field';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'name': name ?? '',
        'owner': owner?.toJson(),
        'declaredType': declaredType?.toJson(),
        'const': isConst ?? false,
        'final': isFinal ?? false,
        'static': isStatic ?? false,
        if (location?.toJson() case final locationValue?)
          'location': locationValue,
        if (staticValue?.toJson() case final staticValueValue?)
          'staticValue': staticValueValue,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Field && id == other.id;

  @override
  String toString() => '[Field ' //
      'id: $id, name: $name, owner: $owner, declaredType: $declaredType, ' //
      'isConst: $isConst, isFinal: $isFinal, isStatic: $isStatic]';
}

/// A `Flag` represents a single VM command line flag.
class Flag {
  static Flag? parse(Map<String, dynamic>? json) =>
      json == null ? null : Flag._fromJson(json);

  /// The name of the flag.
  String? name;

  /// A description of the flag.
  String? comment;

  /// Has this flag been modified from its default setting?
  bool? modified;

  /// The value of this flag as a string.
  ///
  /// If this property is absent, then the value of the flag was nullptr.
  @optional
  String? valueAsString;

  Flag({
    this.name,
    this.comment,
    this.modified,
    this.valueAsString,
  });

  Flag._fromJson(Map<String, dynamic> json) {
    name = json['name'] ?? '';
    comment = json['comment'] ?? '';
    modified = json['modified'] ?? false;
    valueAsString = json['valueAsString'];
  }

  Map<String, dynamic> toJson() => <String, Object?>{
        'name': name ?? '',
        'comment': comment ?? '',
        'modified': modified ?? false,
        if (valueAsString case final valueAsStringValue?)
          'valueAsString': valueAsStringValue,
      };

  @override
  String toString() =>
      '[Flag name: $name, comment: $comment, modified: $modified]';
}

/// A `FlagList` represents the complete set of VM command line flags.
class FlagList extends Response {
  static FlagList? parse(Map<String, dynamic>? json) =>
      json == null ? null : FlagList._fromJson(json);

  /// A list of all flags in the VM.
  List<Flag>? flags;

  FlagList({
    this.flags,
  });

  FlagList._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    flags = List<Flag>.from(
        createServiceObject(json['flags'], const ['Flag']) as List? ?? []);
  }

  @override
  String get type => 'FlagList';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'flags': flags?.map((f) => f.toJson()).toList(),
      };

  @override
  String toString() => '[FlagList flags: $flags]';
}

class Frame extends Response {
  static Frame? parse(Map<String, dynamic>? json) =>
      json == null ? null : Frame._fromJson(json);

  int? index;

  @optional
  FuncRef? function;

  @optional
  CodeRef? code;

  @optional
  SourceLocation? location;

  @optional
  List<BoundVariable>? vars;

  @optional
  /*FrameKind*/ String? kind;

  Frame({
    this.index,
    this.function,
    this.code,
    this.location,
    this.vars,
    this.kind,
  });

  Frame._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    index = json['index'] ?? -1;
    function =
        createServiceObject(json['function'], const ['FuncRef']) as FuncRef?;
    code = createServiceObject(json['code'], const ['CodeRef']) as CodeRef?;
    location = createServiceObject(json['location'], const ['SourceLocation'])
        as SourceLocation?;
    vars = json['vars'] == null
        ? null
        : List<BoundVariable>.from(
            createServiceObject(json['vars'], const ['BoundVariable'])!
                as List);
    kind = json['kind'];
  }

  @override
  String get type => 'Frame';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'index': index ?? -1,
        if (function?.toJson() case final functionValue?)
          'function': functionValue,
        if (code?.toJson() case final codeValue?) 'code': codeValue,
        if (location?.toJson() case final locationValue?)
          'location': locationValue,
        if (vars?.map((f) => f.toJson()).toList() case final varsValue?)
          'vars': varsValue,
        if (kind case final kindValue?) 'kind': kindValue,
      };

  @override
  String toString() => '[Frame index: $index]';
}

/// An `FuncRef` is a reference to a `Func`.
class FuncRef extends ObjRef {
  static FuncRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : FuncRef._fromJson(json);

  /// The name of this function.
  String? name;

  /// The owner of this function, which can be a Library, Class, or a Function.
  ///
  /// Note: the location of `owner` may not agree with `location` if this is a
  /// function from a mixin application, expression evaluation, patched class,
  /// etc.
  ///
  /// [owner] can be one of [LibraryRef], [ClassRef] or [FuncRef].
  dynamic owner;

  /// Is this function static?
  bool? isStatic;

  /// Is this function const?
  bool? isConst;

  /// Is this function implicitly defined (e.g., implicit getter/setter)?
  bool? implicit;

  /// Is this function an abstract method?
  bool? isAbstract;

  /// Is this function a getter?
  bool? isGetter;

  /// Is this function a setter?
  bool? isSetter;

  /// The location of this function in the source code.
  ///
  /// Note: this may not agree with the location of `owner` if this is a
  /// function from a mixin application, expression evaluation, patched class,
  /// etc.
  @optional
  SourceLocation? location;

  FuncRef({
    this.name,
    this.owner,
    this.isStatic,
    this.isConst,
    this.implicit,
    this.isAbstract,
    this.isGetter,
    this.isSetter,
    required String id,
    this.location,
  }) : super(
          id: id,
        );

  FuncRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    owner = createServiceObject(
        json['owner'], const ['LibraryRef', 'ClassRef', 'FuncRef']) as dynamic;
    isStatic = json['static'] ?? false;
    isConst = json['const'] ?? false;
    implicit = json['implicit'] ?? false;
    isAbstract = json['abstract'] ?? false;
    isGetter = json['isGetter'] ?? false;
    isSetter = json['isSetter'] ?? false;
    location = createServiceObject(json['location'], const ['SourceLocation'])
        as SourceLocation?;
  }

  @override
  String get type => '@Function';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'name': name ?? '',
        'owner': owner?.toJson(),
        'static': isStatic ?? false,
        'const': isConst ?? false,
        'implicit': implicit ?? false,
        'abstract': isAbstract ?? false,
        'isGetter': isGetter ?? false,
        'isSetter': isSetter ?? false,
        if (location?.toJson() case final locationValue?)
          'location': locationValue,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is FuncRef && id == other.id;

  @override
  String toString() => '[FuncRef]';
}

/// A `Func` represents a Dart language function.
class Func extends Obj implements FuncRef {
  static Func? parse(Map<String, dynamic>? json) =>
      json == null ? null : Func._fromJson(json);

  /// The name of this function.
  @override
  String? name;

  /// The owner of this function, which can be a Library, Class, or a Function.
  ///
  /// Note: the location of `owner` may not agree with `location` if this is a
  /// function from a mixin application, expression evaluation, patched class,
  /// etc.
  ///
  /// [owner] can be one of [LibraryRef], [ClassRef] or [FuncRef].
  @override
  dynamic owner;

  /// Is this function static?
  @override
  bool? isStatic;

  /// Is this function const?
  @override
  bool? isConst;

  /// Is this function implicitly defined (e.g., implicit getter/setter)?
  @override
  bool? implicit;

  /// Is this function an abstract method?
  @override
  bool? isAbstract;

  /// Is this function a getter?
  @override
  bool? isGetter;

  /// Is this function a setter?
  @override
  bool? isSetter;

  /// The location of this function in the source code.
  ///
  /// Note: this may not agree with the location of `owner` if this is a
  /// function from a mixin application, expression evaluation, patched class,
  /// etc.
  @optional
  @override
  SourceLocation? location;

  /// The signature of the function.
  InstanceRef? signature;

  /// The compiled code associated with this function.
  @optional
  CodeRef? code;

  Func({
    this.name,
    this.owner,
    this.isStatic,
    this.isConst,
    this.implicit,
    this.isAbstract,
    this.isGetter,
    this.isSetter,
    this.signature,
    required String id,
    this.location,
    this.code,
  }) : super(
          id: id,
        );

  Func._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    owner = createServiceObject(
        json['owner'], const ['LibraryRef', 'ClassRef', 'FuncRef']) as dynamic;
    isStatic = json['static'] ?? false;
    isConst = json['const'] ?? false;
    implicit = json['implicit'] ?? false;
    isAbstract = json['abstract'] ?? false;
    isGetter = json['isGetter'] ?? false;
    isSetter = json['isSetter'] ?? false;
    location = createServiceObject(json['location'], const ['SourceLocation'])
        as SourceLocation?;
    signature = createServiceObject(json['signature'], const ['InstanceRef'])
        as InstanceRef?;
    code = createServiceObject(json['code'], const ['CodeRef']) as CodeRef?;
  }

  @override
  String get type => 'Function';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'name': name ?? '',
        'owner': owner?.toJson(),
        'static': isStatic ?? false,
        'const': isConst ?? false,
        'implicit': implicit ?? false,
        'abstract': isAbstract ?? false,
        'isGetter': isGetter ?? false,
        'isSetter': isSetter ?? false,
        'signature': signature?.toJson(),
        if (location?.toJson() case final locationValue?)
          'location': locationValue,
        if (code?.toJson() case final codeValue?) 'code': codeValue,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Func && id == other.id;

  @override
  String toString() => '[Func]';
}

/// `InstanceRef` is a reference to an `Instance`.
class InstanceRef extends ObjRef {
  static InstanceRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : InstanceRef._fromJson(json);

  /// What kind of instance is this?
  /*InstanceKind*/ String? kind;

  /// The identityHashCode assigned to the allocated object. This hash code is
  /// the same as the hash code provided in HeapSnapshot and CpuSample's
  /// returned by getAllocationTraces().
  int? identityHashCode;

  /// Instance references always include their class.
  ClassRef? classRef;

  /// The value of this instance as a string.
  ///
  /// Provided for the instance kinds:
  ///  - Null (null)
  ///  - Bool (true or false)
  ///  - Double (suitable for passing to Double.parse())
  ///  - Int (suitable for passing to int.parse())
  ///  - String (value may be truncated)
  ///  - Float32x4
  ///  - Float64x2
  ///  - Int32x4
  ///  - StackTrace
  @optional
  String? valueAsString;

  /// The valueAsString for String references may be truncated. If so, this
  /// property is added with the value 'true'.
  ///
  /// New code should use 'length' and 'count' instead.
  @optional
  bool? valueAsStringIsTruncated;

  /// The number of (non-static) fields of a PlainInstance, or the length of a
  /// List, or the number of associations in a Map, or the number of codeunits
  /// in a String, or the total number of fields (positional and named) in a
  /// Record.
  ///
  /// Provided for instance kinds:
  ///  - PlainInstance
  ///  - String
  ///  - List
  ///  - Map
  ///  - Set
  ///  - Uint8ClampedList
  ///  - Uint8List
  ///  - Uint16List
  ///  - Uint32List
  ///  - Uint64List
  ///  - Int8List
  ///  - Int16List
  ///  - Int32List
  ///  - Int64List
  ///  - Float32List
  ///  - Float64List
  ///  - Int32x4List
  ///  - Float32x4List
  ///  - Float64x2List
  ///  - Record
  @optional
  int? length;

  /// The name of a Type instance.
  ///
  /// Provided for instance kinds:
  ///  - Type
  @optional
  String? name;

  /// The corresponding Class if this Type has a resolved typeClass.
  ///
  /// Provided for instance kinds:
  ///  - Type
  @optional
  ClassRef? typeClass;

  /// The parameterized class of a type parameter.
  ///
  /// Provided for instance kinds:
  ///  - TypeParameter
  @optional
  ClassRef? parameterizedClass;

  /// The return type of a function.
  ///
  /// Provided for instance kinds:
  ///  - FunctionType
  @optional
  InstanceRef? returnType;

  /// The list of parameter types for a function.
  ///
  /// Provided for instance kinds:
  ///  - FunctionType
  @optional
  List<Parameter>? parameters;

  /// The type parameters for a function.
  ///
  /// Provided for instance kinds:
  ///  - FunctionType
  @optional
  List<InstanceRef>? typeParameters;

  /// The pattern of a RegExp instance.
  ///
  /// The pattern is always an instance of kind String.
  ///
  /// Provided for instance kinds:
  ///  - RegExp
  @optional
  InstanceRef? pattern;

  /// The function associated with a Closure instance.
  ///
  /// Provided for instance kinds:
  ///  - Closure
  @optional
  FuncRef? closureFunction;

  /// The context associated with a Closure instance.
  ///
  /// Provided for instance kinds:
  ///  - Closure
  @optional
  ContextRef? closureContext;

  /// The receiver captured by tear-off Closure instance.
  ///
  /// Provided for instance kinds:
  ///  - Closure
  @optional
  InstanceRef? closureReceiver;

  /// The port ID for a ReceivePort.
  ///
  /// Provided for instance kinds:
  ///  - ReceivePort
  @optional
  int? portId;

  /// The stack trace associated with the allocation of a ReceivePort.
  ///
  /// Provided for instance kinds:
  ///  - ReceivePort
  @optional
  InstanceRef? allocationLocation;

  /// A name associated with a ReceivePort used for debugging purposes.
  ///
  /// Provided for instance kinds:
  ///  - ReceivePort
  @optional
  String? debugName;

  /// The label associated with a UserTag.
  ///
  /// Provided for instance kinds:
  ///  - UserTag
  @optional
  String? label;

  InstanceRef({
    this.kind,
    this.identityHashCode,
    this.classRef,
    required String id,
    this.valueAsString,
    this.valueAsStringIsTruncated,
    this.length,
    this.name,
    this.typeClass,
    this.parameterizedClass,
    this.returnType,
    this.parameters,
    this.typeParameters,
    this.pattern,
    this.closureFunction,
    this.closureContext,
    this.closureReceiver,
    this.portId,
    this.allocationLocation,
    this.debugName,
    this.label,
  }) : super(
          id: id,
        );

  InstanceRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    kind = json['kind'] ?? '';
    identityHashCode = json['identityHashCode'] ?? -1;
    classRef =
        createServiceObject(json['class'], const ['ClassRef']) as ClassRef?;
    valueAsString = json['valueAsString'];
    valueAsStringIsTruncated = json['valueAsStringIsTruncated'];
    length = json['length'];
    name = json['name'];
    typeClass =
        createServiceObject(json['typeClass'], const ['ClassRef']) as ClassRef?;
    parameterizedClass =
        createServiceObject(json['parameterizedClass'], const ['ClassRef'])
            as ClassRef?;
    returnType = createServiceObject(json['returnType'], const ['InstanceRef'])
        as InstanceRef?;
    parameters = json['parameters'] == null
        ? null
        : List<Parameter>.from(
            createServiceObject(json['parameters'], const ['Parameter'])!
                as List);
    typeParameters = json['typeParameters'] == null
        ? null
        : List<InstanceRef>.from(
            createServiceObject(json['typeParameters'], const ['InstanceRef'])!
                as List);
    pattern = createServiceObject(json['pattern'], const ['InstanceRef'])
        as InstanceRef?;
    closureFunction =
        createServiceObject(json['closureFunction'], const ['FuncRef'])
            as FuncRef?;
    closureContext =
        createServiceObject(json['closureContext'], const ['ContextRef'])
            as ContextRef?;
    closureReceiver =
        createServiceObject(json['closureReceiver'], const ['InstanceRef'])
            as InstanceRef?;
    portId = json['portId'];
    allocationLocation =
        createServiceObject(json['allocationLocation'], const ['InstanceRef'])
            as InstanceRef?;
    debugName = json['debugName'];
    label = json['label'];
  }

  @override
  String get type => '@Instance';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'kind': kind ?? '',
        'identityHashCode': identityHashCode ?? -1,
        'class': classRef?.toJson(),
        if (valueAsString case final valueAsStringValue?)
          'valueAsString': valueAsStringValue,
        if (valueAsStringIsTruncated case final valueAsStringIsTruncatedValue?)
          'valueAsStringIsTruncated': valueAsStringIsTruncatedValue,
        if (length case final lengthValue?) 'length': lengthValue,
        if (name case final nameValue?) 'name': nameValue,
        if (typeClass?.toJson() case final typeClassValue?)
          'typeClass': typeClassValue,
        if (parameterizedClass?.toJson() case final parameterizedClassValue?)
          'parameterizedClass': parameterizedClassValue,
        if (returnType?.toJson() case final returnTypeValue?)
          'returnType': returnTypeValue,
        if (parameters?.map((f) => f.toJson()).toList()
            case final parametersValue?)
          'parameters': parametersValue,
        if (typeParameters?.map((f) => f.toJson()).toList()
            case final typeParametersValue?)
          'typeParameters': typeParametersValue,
        if (pattern?.toJson() case final patternValue?) 'pattern': patternValue,
        if (closureFunction?.toJson() case final closureFunctionValue?)
          'closureFunction': closureFunctionValue,
        if (closureContext?.toJson() case final closureContextValue?)
          'closureContext': closureContextValue,
        if (closureReceiver?.toJson() case final closureReceiverValue?)
          'closureReceiver': closureReceiverValue,
        if (portId case final portIdValue?) 'portId': portIdValue,
        if (allocationLocation?.toJson() case final allocationLocationValue?)
          'allocationLocation': allocationLocationValue,
        if (debugName case final debugNameValue?) 'debugName': debugNameValue,
        if (label case final labelValue?) 'label': labelValue,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is InstanceRef && id == other.id;

  @override
  String toString() => '[InstanceRef ' //
      'id: $id, kind: $kind, identityHashCode: $identityHashCode, ' //
      'classRef: $classRef]';
}

/// An `Instance` represents an instance of the Dart language class `Obj`.
class Instance extends Obj implements InstanceRef {
  static Instance? parse(Map<String, dynamic>? json) =>
      json == null ? null : Instance._fromJson(json);

  /// What kind of instance is this?
  @override
  /*InstanceKind*/ String? kind;

  /// The identityHashCode assigned to the allocated object. This hash code is
  /// the same as the hash code provided in HeapSnapshot and CpuSample's
  /// returned by getAllocationTraces().
  @override
  int? identityHashCode;

  /// Instance references always include their class.
  @override
  ClassRef? classRef;

  /// The value of this instance as a string.
  ///
  /// Provided for the instance kinds:
  ///  - Bool (true or false)
  ///  - Double (suitable for passing to Double.parse())
  ///  - Int (suitable for passing to int.parse())
  ///  - String (value may be truncated)
  ///  - StackTrace
  @optional
  @override
  String? valueAsString;

  /// The valueAsString for String references may be truncated. If so, this
  /// property is added with the value 'true'.
  ///
  /// New code should use 'length' and 'count' instead.
  @optional
  @override
  bool? valueAsStringIsTruncated;

  /// The number of (non-static) fields of a PlainInstance, or the length of a
  /// List, or the number of associations in a Map, or the number of codeunits
  /// in a String, or the total number of fields (positional and named) in a
  /// Record.
  ///
  /// Provided for instance kinds:
  ///  - PlainInstance
  ///  - String
  ///  - List
  ///  - Map
  ///  - Set
  ///  - Uint8ClampedList
  ///  - Uint8List
  ///  - Uint16List
  ///  - Uint32List
  ///  - Uint64List
  ///  - Int8List
  ///  - Int16List
  ///  - Int32List
  ///  - Int64List
  ///  - Float32List
  ///  - Float64List
  ///  - Int32x4List
  ///  - Float32x4List
  ///  - Float64x2List
  ///  - Record
  @optional
  @override
  int? length;

  /// The index of the first element or association or codeunit returned. This
  /// is only provided when it is non-zero.
  ///
  /// Provided for instance kinds:
  ///  - String
  ///  - List
  ///  - Map
  ///  - Set
  ///  - Uint8ClampedList
  ///  - Uint8List
  ///  - Uint16List
  ///  - Uint32List
  ///  - Uint64List
  ///  - Int8List
  ///  - Int16List
  ///  - Int32List
  ///  - Int64List
  ///  - Float32List
  ///  - Float64List
  ///  - Int32x4List
  ///  - Float32x4List
  ///  - Float64x2List
  @optional
  int? offset;

  /// The number of elements or associations or codeunits returned. This is only
  /// provided when it is less than length.
  ///
  /// Provided for instance kinds:
  ///  - String
  ///  - List
  ///  - Map
  ///  - Set
  ///  - Uint8ClampedList
  ///  - Uint8List
  ///  - Uint16List
  ///  - Uint32List
  ///  - Uint64List
  ///  - Int8List
  ///  - Int16List
  ///  - Int32List
  ///  - Int64List
  ///  - Float32List
  ///  - Float64List
  ///  - Int32x4List
  ///  - Float32x4List
  ///  - Float64x2List
  @optional
  int? count;

  /// The name of a Type instance.
  ///
  /// Provided for instance kinds:
  ///  - Type
  @optional
  @override
  String? name;

  /// The corresponding Class if this Type is canonical.
  ///
  /// Provided for instance kinds:
  ///  - Type
  @optional
  @override
  ClassRef? typeClass;

  /// The parameterized class of a type parameter:
  ///
  /// Provided for instance kinds:
  ///  - TypeParameter
  @optional
  @override
  ClassRef? parameterizedClass;

  /// The return type of a function.
  ///
  /// Provided for instance kinds:
  ///  - FunctionType
  @optional
  @override
  InstanceRef? returnType;

  /// The list of parameter types for a function.
  ///
  /// Provided for instance kinds:
  ///  - FunctionType
  @optional
  @override
  List<Parameter>? parameters;

  /// The type parameters for a function.
  ///
  /// Provided for instance kinds:
  ///  - FunctionType
  @optional
  @override
  List<InstanceRef>? typeParameters;

  /// The (non-static) fields of this Instance.
  ///
  /// Provided for instance kinds:
  ///  - PlainInstance
  ///  - Record
  @optional
  List<BoundField>? fields;

  /// The elements of a List or Set instance.
  ///
  /// Provided for instance kinds:
  ///  - List
  ///  - Set
  @optional
  List<dynamic>? elements;

  /// The elements of a Map instance.
  ///
  /// Provided for instance kinds:
  ///  - Map
  @optional
  List<MapAssociation>? associations;

  /// The bytes of a TypedData instance.
  ///
  /// The data is provided as a Base64 encoded string.
  ///
  /// Provided for instance kinds:
  ///  - Uint8ClampedList
  ///  - Uint8List
  ///  - Uint16List
  ///  - Uint32List
  ///  - Uint64List
  ///  - Int8List
  ///  - Int16List
  ///  - Int32List
  ///  - Int64List
  ///  - Float32List
  ///  - Float64List
  ///  - Int32x4List
  ///  - Float32x4List
  ///  - Float64x2List
  @optional
  String? bytes;

  /// The referent of a MirrorReference instance.
  ///
  /// Provided for instance kinds:
  ///  - MirrorReference
  @optional
  ObjRef? mirrorReferent;

  /// The pattern of a RegExp instance.
  ///
  /// Provided for instance kinds:
  ///  - RegExp
  @optional
  @override
  InstanceRef? pattern;

  /// The function associated with a Closure instance.
  ///
  /// Provided for instance kinds:
  ///  - Closure
  @optional
  @override
  FuncRef? closureFunction;

  /// The context associated with a Closure instance.
  ///
  /// Provided for instance kinds:
  ///  - Closure
  @optional
  @override
  ContextRef? closureContext;

  /// The receiver captured by tear-off Closure instance.
  ///
  /// Provided for instance kinds:
  ///  - Closure
  @optional
  @override
  InstanceRef? closureReceiver;

  /// Whether this regular expression is case sensitive.
  ///
  /// Provided for instance kinds:
  ///  - RegExp
  @optional
  bool? isCaseSensitive;

  /// Whether this regular expression matches multiple lines.
  ///
  /// Provided for instance kinds:
  ///  - RegExp
  @optional
  bool? isMultiLine;

  /// The key for a WeakProperty instance.
  ///
  /// Provided for instance kinds:
  ///  - WeakProperty
  @optional
  ObjRef? propertyKey;

  /// The key for a WeakProperty instance.
  ///
  /// Provided for instance kinds:
  ///  - WeakProperty
  @optional
  ObjRef? propertyValue;

  /// The target for a WeakReference instance.
  ///
  /// Provided for instance kinds:
  ///  - WeakReference
  @optional
  ObjRef? target;

  /// The type arguments for this type.
  ///
  /// Provided for instance kinds:
  ///  - Type
  @optional
  TypeArgumentsRef? typeArguments;

  /// The index of a TypeParameter instance.
  ///
  /// Provided for instance kinds:
  ///  - TypeParameter
  @optional
  int? parameterIndex;

  /// The type bounded by a BoundedType instance.
  ///
  /// The value will always be of one of the kinds: Type, TypeParameter,
  /// RecordType, FunctionType, BoundedType.
  ///
  /// Provided for instance kinds:
  ///  - BoundedType
  @optional
  InstanceRef? targetType;

  /// The bound of a TypeParameter or BoundedType.
  ///
  /// The value will always be of one of the kinds: Type, TypeParameter,
  /// RecordType, FunctionType, BoundedType.
  ///
  /// Provided for instance kinds:
  ///  - BoundedType
  ///  - TypeParameter
  @optional
  InstanceRef? bound;

  /// The port ID for a ReceivePort.
  ///
  /// Provided for instance kinds:
  ///  - ReceivePort
  @optional
  @override
  int? portId;

  /// The stack trace associated with the allocation of a ReceivePort.
  ///
  /// Provided for instance kinds:
  ///  - ReceivePort
  @optional
  @override
  InstanceRef? allocationLocation;

  /// A name associated with a ReceivePort used for debugging purposes.
  ///
  /// Provided for instance kinds:
  ///  - ReceivePort
  @optional
  @override
  String? debugName;

  /// The label associated with a UserTag.
  ///
  /// Provided for instance kinds:
  ///  - UserTag
  @optional
  @override
  String? label;

  /// The callback for a Finalizer instance.
  ///
  /// Provided for instance kinds:
  ///  - Finalizer
  @optional
  InstanceRef? callback;

  /// The callback for a NativeFinalizer instance.
  ///
  /// Provided for instance kinds:
  ///  - NativeFinalizer
  @optional
  InstanceRef? callbackAddress;

  /// The entries for a (Native)Finalizer instance.
  ///
  /// A set.
  ///
  /// Provided for instance kinds:
  ///  - Finalizer
  ///  - NativeFinalizer
  @optional
  InstanceRef? allEntries;

  /// The value being watched for finalization for a FinalizerEntry instance.
  ///
  /// Provided for instance kinds:
  ///  - FinalizerEntry
  @optional
  InstanceRef? value;

  /// The token passed to the finalizer callback for a FinalizerEntry instance.
  ///
  /// Provided for instance kinds:
  ///  - FinalizerEntry
  @optional
  InstanceRef? token;

  /// The detach key for a FinalizerEntry instance.
  ///
  /// Provided for instance kinds:
  ///  - FinalizerEntry
  @optional
  InstanceRef? detach;

  Instance({
    this.kind,
    this.identityHashCode,
    this.classRef,
    required String id,
    this.valueAsString,
    this.valueAsStringIsTruncated,
    this.length,
    this.offset,
    this.count,
    this.name,
    this.typeClass,
    this.parameterizedClass,
    this.returnType,
    this.parameters,
    this.typeParameters,
    this.fields,
    this.elements,
    this.associations,
    this.bytes,
    this.mirrorReferent,
    this.pattern,
    this.closureFunction,
    this.closureContext,
    this.closureReceiver,
    this.isCaseSensitive,
    this.isMultiLine,
    this.propertyKey,
    this.propertyValue,
    this.target,
    this.typeArguments,
    this.parameterIndex,
    this.targetType,
    this.bound,
    this.portId,
    this.allocationLocation,
    this.debugName,
    this.label,
    this.callback,
    this.callbackAddress,
    this.allEntries,
    this.value,
    this.token,
    this.detach,
  }) : super(
          id: id,
          classRef: classRef,
        );

  Instance._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    kind = json['kind'] ?? '';
    identityHashCode = json['identityHashCode'] ?? -1;
    classRef =
        createServiceObject(json['class'], const ['ClassRef']) as ClassRef?;
    valueAsString = json['valueAsString'];
    valueAsStringIsTruncated = json['valueAsStringIsTruncated'];
    length = json['length'];
    offset = json['offset'];
    count = json['count'];
    name = json['name'];
    typeClass =
        createServiceObject(json['typeClass'], const ['ClassRef']) as ClassRef?;
    parameterizedClass =
        createServiceObject(json['parameterizedClass'], const ['ClassRef'])
            as ClassRef?;
    returnType = createServiceObject(json['returnType'], const ['InstanceRef'])
        as InstanceRef?;
    parameters = json['parameters'] == null
        ? null
        : List<Parameter>.from(
            createServiceObject(json['parameters'], const ['Parameter'])!
                as List);
    typeParameters = json['typeParameters'] == null
        ? null
        : List<InstanceRef>.from(
            createServiceObject(json['typeParameters'], const ['InstanceRef'])!
                as List);
    fields = json['fields'] == null
        ? null
        : List<BoundField>.from(
            createServiceObject(json['fields'], const ['BoundField'])! as List);
    elements = json['elements'] == null
        ? null
        : List<dynamic>.from(
            createServiceObject(json['elements'], const ['dynamic'])! as List);
    associations = json['associations'] == null
        ? null
        : List<MapAssociation>.from(
            _createSpecificObject(json['associations'], MapAssociation.parse));
    bytes = json['bytes'];
    mirrorReferent =
        createServiceObject(json['mirrorReferent'], const ['ObjRef'])
            as ObjRef?;
    pattern = createServiceObject(json['pattern'], const ['InstanceRef'])
        as InstanceRef?;
    closureFunction =
        createServiceObject(json['closureFunction'], const ['FuncRef'])
            as FuncRef?;
    closureContext =
        createServiceObject(json['closureContext'], const ['ContextRef'])
            as ContextRef?;
    closureReceiver =
        createServiceObject(json['closureReceiver'], const ['InstanceRef'])
            as InstanceRef?;
    isCaseSensitive = json['isCaseSensitive'];
    isMultiLine = json['isMultiLine'];
    propertyKey =
        createServiceObject(json['propertyKey'], const ['ObjRef']) as ObjRef?;
    propertyValue =
        createServiceObject(json['propertyValue'], const ['ObjRef']) as ObjRef?;
    target = createServiceObject(json['target'], const ['ObjRef']) as ObjRef?;
    typeArguments =
        createServiceObject(json['typeArguments'], const ['TypeArgumentsRef'])
            as TypeArgumentsRef?;
    parameterIndex = json['parameterIndex'];
    targetType = createServiceObject(json['targetType'], const ['InstanceRef'])
        as InstanceRef?;
    bound = createServiceObject(json['bound'], const ['InstanceRef'])
        as InstanceRef?;
    portId = json['portId'];
    allocationLocation =
        createServiceObject(json['allocationLocation'], const ['InstanceRef'])
            as InstanceRef?;
    debugName = json['debugName'];
    label = json['label'];
    callback = createServiceObject(json['callback'], const ['InstanceRef'])
        as InstanceRef?;
    callbackAddress =
        createServiceObject(json['callbackAddress'], const ['InstanceRef'])
            as InstanceRef?;
    allEntries = createServiceObject(json['allEntries'], const ['InstanceRef'])
        as InstanceRef?;
    value = createServiceObject(json['value'], const ['InstanceRef'])
        as InstanceRef?;
    token = createServiceObject(json['token'], const ['InstanceRef'])
        as InstanceRef?;
    detach = createServiceObject(json['detach'], const ['InstanceRef'])
        as InstanceRef?;
  }

  @override
  String get type => 'Instance';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'kind': kind ?? '',
        'identityHashCode': identityHashCode ?? -1,
        'class': classRef?.toJson(),
        if (valueAsString case final valueAsStringValue?)
          'valueAsString': valueAsStringValue,
        if (valueAsStringIsTruncated case final valueAsStringIsTruncatedValue?)
          'valueAsStringIsTruncated': valueAsStringIsTruncatedValue,
        if (length case final lengthValue?) 'length': lengthValue,
        if (offset case final offsetValue?) 'offset': offsetValue,
        if (count case final countValue?) 'count': countValue,
        if (name case final nameValue?) 'name': nameValue,
        if (typeClass?.toJson() case final typeClassValue?)
          'typeClass': typeClassValue,
        if (parameterizedClass?.toJson() case final parameterizedClassValue?)
          'parameterizedClass': parameterizedClassValue,
        if (returnType?.toJson() case final returnTypeValue?)
          'returnType': returnTypeValue,
        if (parameters?.map((f) => f.toJson()).toList()
            case final parametersValue?)
          'parameters': parametersValue,
        if (typeParameters?.map((f) => f.toJson()).toList()
            case final typeParametersValue?)
          'typeParameters': typeParametersValue,
        if (fields?.map((f) => f.toJson()).toList() case final fieldsValue?)
          'fields': fieldsValue,
        if (elements?.map((f) => f.toJson()).toList() case final elementsValue?)
          'elements': elementsValue,
        if (associations?.map((f) => f.toJson()).toList()
            case final associationsValue?)
          'associations': associationsValue,
        if (bytes case final bytesValue?) 'bytes': bytesValue,
        if (mirrorReferent?.toJson() case final mirrorReferentValue?)
          'mirrorReferent': mirrorReferentValue,
        if (pattern?.toJson() case final patternValue?) 'pattern': patternValue,
        if (closureFunction?.toJson() case final closureFunctionValue?)
          'closureFunction': closureFunctionValue,
        if (closureContext?.toJson() case final closureContextValue?)
          'closureContext': closureContextValue,
        if (closureReceiver?.toJson() case final closureReceiverValue?)
          'closureReceiver': closureReceiverValue,
        if (isCaseSensitive case final isCaseSensitiveValue?)
          'isCaseSensitive': isCaseSensitiveValue,
        if (isMultiLine case final isMultiLineValue?)
          'isMultiLine': isMultiLineValue,
        if (propertyKey?.toJson() case final propertyKeyValue?)
          'propertyKey': propertyKeyValue,
        if (propertyValue?.toJson() case final propertyValueValue?)
          'propertyValue': propertyValueValue,
        if (target?.toJson() case final targetValue?) 'target': targetValue,
        if (typeArguments?.toJson() case final typeArgumentsValue?)
          'typeArguments': typeArgumentsValue,
        if (parameterIndex case final parameterIndexValue?)
          'parameterIndex': parameterIndexValue,
        if (targetType?.toJson() case final targetTypeValue?)
          'targetType': targetTypeValue,
        if (bound?.toJson() case final boundValue?) 'bound': boundValue,
        if (portId case final portIdValue?) 'portId': portIdValue,
        if (allocationLocation?.toJson() case final allocationLocationValue?)
          'allocationLocation': allocationLocationValue,
        if (debugName case final debugNameValue?) 'debugName': debugNameValue,
        if (label case final labelValue?) 'label': labelValue,
        if (callback?.toJson() case final callbackValue?)
          'callback': callbackValue,
        if (callbackAddress?.toJson() case final callbackAddressValue?)
          'callbackAddress': callbackAddressValue,
        if (allEntries?.toJson() case final allEntriesValue?)
          'allEntries': allEntriesValue,
        if (value?.toJson() case final valueValue?) 'value': valueValue,
        if (token?.toJson() case final tokenValue?) 'token': tokenValue,
        if (detach?.toJson() case final detachValue?) 'detach': detachValue,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Instance && id == other.id;

  @override
  String toString() => '[Instance ' //
      'id: $id, kind: $kind, identityHashCode: $identityHashCode, ' //
      'classRef: $classRef]';
}

/// `IsolateRef` is a reference to an `Isolate` object.
class IsolateRef extends Response {
  static IsolateRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : IsolateRef._fromJson(json);

  /// The id which is passed to the getIsolate RPC to load this isolate.
  String? id;

  /// A numeric id for this isolate, represented as a string. Unique.
  String? number;

  /// A name identifying this isolate. Not guaranteed to be unique.
  String? name;

  /// Specifies whether the isolate was spawned by the VM or embedder for
  /// internal use. If `false`, this isolate is likely running user code.
  bool? isSystemIsolate;

  /// The id of the isolate group that this isolate belongs to.
  String? isolateGroupId;

  IsolateRef({
    this.id,
    this.number,
    this.name,
    this.isSystemIsolate,
    this.isolateGroupId,
  });

  IsolateRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    id = json['id'] ?? '';
    number = json['number'] ?? '';
    name = json['name'] ?? '';
    isSystemIsolate = json['isSystemIsolate'] ?? false;
    isolateGroupId = json['isolateGroupId'] ?? '';
  }

  @override
  String get type => '@Isolate';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'id': id ?? '',
        'number': number ?? '',
        'name': name ?? '',
        'isSystemIsolate': isSystemIsolate ?? false,
        'isolateGroupId': isolateGroupId ?? '',
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is IsolateRef && id == other.id;

  @override
  String toString() => '[IsolateRef ' //
      'id: $id, number: $number, name: $name, isSystemIsolate: $isSystemIsolate, ' //
      'isolateGroupId: $isolateGroupId]';
}

/// An `Isolate` object provides information about one isolate in the VM.
class Isolate extends Response implements IsolateRef {
  static Isolate? parse(Map<String, dynamic>? json) =>
      json == null ? null : Isolate._fromJson(json);

  /// The id which is passed to the getIsolate RPC to reload this isolate.
  @override
  String? id;

  /// A numeric id for this isolate, represented as a string. Unique.
  @override
  String? number;

  /// A name identifying this isolate. Not guaranteed to be unique.
  @override
  String? name;

  /// Specifies whether the isolate was spawned by the VM or embedder for
  /// internal use. If `false`, this isolate is likely running user code.
  @override
  bool? isSystemIsolate;

  /// The id of the isolate group that this isolate belongs to.
  @override
  String? isolateGroupId;

  /// The list of isolate flags provided to this isolate. See Dart_IsolateFlags
  /// in dart_api.h for the list of accepted isolate flags.
  List<IsolateFlag>? isolateFlags;

  /// The time that the VM started in milliseconds since the epoch.
  ///
  /// Suitable to pass to DateTime.fromMillisecondsSinceEpoch.
  int? startTime;

  /// Is the isolate in a runnable state?
  bool? runnable;

  /// The number of live ports for this isolate.
  int? livePorts;

  /// Will this isolate pause when exiting?
  bool? pauseOnExit;

  /// The last pause event delivered to the isolate. If the isolate is running,
  /// this will be a resume event.
  Event? pauseEvent;

  /// The root library for this isolate.
  ///
  /// Guaranteed to be initialized when the IsolateRunnable event fires.
  @optional
  LibraryRef? rootLib;

  /// A list of all libraries for this isolate.
  ///
  /// Guaranteed to be initialized when the IsolateRunnable event fires.
  List<LibraryRef>? libraries;

  /// A list of all breakpoints for this isolate.
  List<Breakpoint>? breakpoints;

  /// The error that is causing this isolate to exit, if applicable.
  @optional
  Error? error;

  /// The current pause on exception mode for this isolate.
  /*ExceptionPauseMode*/ String? exceptionPauseMode;

  /// The list of service extension RPCs that are registered for this isolate,
  /// if any.
  @optional
  List<String>? extensionRPCs;

  Isolate({
    this.id,
    this.number,
    this.name,
    this.isSystemIsolate,
    this.isolateGroupId,
    this.isolateFlags,
    this.startTime,
    this.runnable,
    this.livePorts,
    this.pauseOnExit,
    this.pauseEvent,
    this.libraries,
    this.breakpoints,
    this.exceptionPauseMode,
    this.rootLib,
    this.error,
    this.extensionRPCs,
  });

  Isolate._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    id = json['id'] ?? '';
    number = json['number'] ?? '';
    name = json['name'] ?? '';
    isSystemIsolate = json['isSystemIsolate'] ?? false;
    isolateGroupId = json['isolateGroupId'] ?? '';
    isolateFlags = List<IsolateFlag>.from(
        createServiceObject(json['isolateFlags'], const ['IsolateFlag'])
                as List? ??
            []);
    startTime = json['startTime'] ?? -1;
    runnable = json['runnable'] ?? false;
    livePorts = json['livePorts'] ?? -1;
    pauseOnExit = json['pauseOnExit'] ?? false;
    pauseEvent =
        createServiceObject(json['pauseEvent'], const ['Event']) as Event?;
    rootLib = createServiceObject(json['rootLib'], const ['LibraryRef'])
        as LibraryRef?;
    libraries = List<LibraryRef>.from(
        createServiceObject(json['libraries'], const ['LibraryRef']) as List? ??
            []);
    breakpoints = List<Breakpoint>.from(
        createServiceObject(json['breakpoints'], const ['Breakpoint'])
                as List? ??
            []);
    error = createServiceObject(json['error'], const ['Error']) as Error?;
    exceptionPauseMode = json['exceptionPauseMode'] ?? '';
    extensionRPCs = json['extensionRPCs'] == null
        ? null
        : List<String>.from(json['extensionRPCs']);
  }

  @override
  String get type => 'Isolate';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'id': id ?? '',
        'number': number ?? '',
        'name': name ?? '',
        'isSystemIsolate': isSystemIsolate ?? false,
        'isolateGroupId': isolateGroupId ?? '',
        'isolateFlags': isolateFlags?.map((f) => f.toJson()).toList(),
        'startTime': startTime ?? -1,
        'runnable': runnable ?? false,
        'livePorts': livePorts ?? -1,
        'pauseOnExit': pauseOnExit ?? false,
        'pauseEvent': pauseEvent?.toJson(),
        'libraries': libraries?.map((f) => f.toJson()).toList(),
        'breakpoints': breakpoints?.map((f) => f.toJson()).toList(),
        'exceptionPauseMode': exceptionPauseMode ?? '',
        if (rootLib?.toJson() case final rootLibValue?) 'rootLib': rootLibValue,
        if (error?.toJson() case final errorValue?) 'error': errorValue,
        if (extensionRPCs?.map((f) => f).toList()
            case final extensionRPCsValue?)
          'extensionRPCs': extensionRPCsValue,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Isolate && id == other.id;

  @override
  String toString() => '[Isolate]';
}

/// Represents the value of a single isolate flag. See [Isolate].
class IsolateFlag {
  static IsolateFlag? parse(Map<String, dynamic>? json) =>
      json == null ? null : IsolateFlag._fromJson(json);

  /// The name of the flag.
  String? name;

  /// The value of this flag as a string.
  String? valueAsString;

  IsolateFlag({
    this.name,
    this.valueAsString,
  });

  IsolateFlag._fromJson(Map<String, dynamic> json) {
    name = json['name'] ?? '';
    valueAsString = json['valueAsString'] ?? '';
  }

  Map<String, dynamic> toJson() => <String, Object?>{
        'name': name ?? '',
        'valueAsString': valueAsString ?? '',
      };

  @override
  String toString() =>
      '[IsolateFlag name: $name, valueAsString: $valueAsString]';
}

/// `IsolateGroupRef` is a reference to an `IsolateGroup` object.
class IsolateGroupRef extends Response {
  static IsolateGroupRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : IsolateGroupRef._fromJson(json);

  /// The id which is passed to the getIsolateGroup RPC to load this isolate
  /// group.
  String? id;

  /// A numeric id for this isolate group, represented as a string. Unique.
  String? number;

  /// A name identifying this isolate group. Not guaranteed to be unique.
  String? name;

  /// Specifies whether the isolate group was spawned by the VM or embedder for
  /// internal use. If `false`, this isolate group is likely running user code.
  bool? isSystemIsolateGroup;

  IsolateGroupRef({
    this.id,
    this.number,
    this.name,
    this.isSystemIsolateGroup,
  });

  IsolateGroupRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    id = json['id'] ?? '';
    number = json['number'] ?? '';
    name = json['name'] ?? '';
    isSystemIsolateGroup = json['isSystemIsolateGroup'] ?? false;
  }

  @override
  String get type => '@IsolateGroup';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'id': id ?? '',
        'number': number ?? '',
        'name': name ?? '',
        'isSystemIsolateGroup': isSystemIsolateGroup ?? false,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is IsolateGroupRef && id == other.id;

  @override
  String toString() => '[IsolateGroupRef ' //
      'id: $id, number: $number, name: $name, isSystemIsolateGroup: $isSystemIsolateGroup]';
}

/// An `IsolateGroup` object provides information about an isolate group in the
/// VM.
class IsolateGroup extends Response implements IsolateGroupRef {
  static IsolateGroup? parse(Map<String, dynamic>? json) =>
      json == null ? null : IsolateGroup._fromJson(json);

  /// The id which is passed to the getIsolateGroup RPC to reload this isolate.
  @override
  String? id;

  /// A numeric id for this isolate, represented as a string. Unique.
  @override
  String? number;

  /// A name identifying this isolate group. Not guaranteed to be unique.
  @override
  String? name;

  /// Specifies whether the isolate group was spawned by the VM or embedder for
  /// internal use. If `false`, this isolate group is likely running user code.
  @override
  bool? isSystemIsolateGroup;

  /// A list of all isolates in this isolate group.
  List<IsolateRef>? isolates;

  IsolateGroup({
    this.id,
    this.number,
    this.name,
    this.isSystemIsolateGroup,
    this.isolates,
  });

  IsolateGroup._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    id = json['id'] ?? '';
    number = json['number'] ?? '';
    name = json['name'] ?? '';
    isSystemIsolateGroup = json['isSystemIsolateGroup'] ?? false;
    isolates = List<IsolateRef>.from(
        createServiceObject(json['isolates'], const ['IsolateRef']) as List? ??
            []);
  }

  @override
  String get type => 'IsolateGroup';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'id': id ?? '',
        'number': number ?? '',
        'name': name ?? '',
        'isSystemIsolateGroup': isSystemIsolateGroup ?? false,
        'isolates': isolates?.map((f) => f.toJson()).toList(),
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is IsolateGroup && id == other.id;

  @override
  String toString() => '[IsolateGroup ' //
      'id: $id, number: $number, name: $name, isSystemIsolateGroup: $isSystemIsolateGroup, ' //
      'isolates: $isolates]';
}

/// See [VmService.getInboundReferences].
class InboundReferences extends Response {
  static InboundReferences? parse(Map<String, dynamic>? json) =>
      json == null ? null : InboundReferences._fromJson(json);

  /// An array of inbound references to an object.
  List<InboundReference>? references;

  InboundReferences({
    this.references,
  });

  InboundReferences._fromJson(Map<String, dynamic> json)
      : super._fromJson(json) {
    references = List<InboundReference>.from(
        createServiceObject(json['references'], const ['InboundReference'])
                as List? ??
            []);
  }

  @override
  String get type => 'InboundReferences';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'references': references?.map((f) => f.toJson()).toList(),
      };

  @override
  String toString() => '[InboundReferences references: $references]';
}

/// See [VmService.getInboundReferences].
class InboundReference {
  static InboundReference? parse(Map<String, dynamic>? json) =>
      json == null ? null : InboundReference._fromJson(json);

  /// The object holding the inbound reference.
  ObjRef? source;

  /// If source is a List, parentListIndex is the index of the inbound reference
  /// (deprecated).
  ///
  /// Note: this property is deprecated and will be replaced by `parentField`.
  @optional
  int? parentListIndex;

  /// If `source` is a `List`, `parentField` is the index of the inbound
  /// reference. If `source` is a record, `parentField` is the field name of the
  /// inbound reference. If `source` is an instance of any other kind,
  /// `parentField` is the field containing the inbound reference.
  ///
  /// Note: In v5.0 of the spec, `@Field` will no longer be a part of this
  /// property's type, i.e. the type will become `string|int`.
  ///
  /// [parentField] can be one of [FieldRef], [String] or [int].
  @optional
  dynamic parentField;

  InboundReference({
    this.source,
    this.parentListIndex,
    this.parentField,
  });

  InboundReference._fromJson(Map<String, dynamic> json) {
    source = createServiceObject(json['source'], const ['ObjRef']) as ObjRef?;
    parentListIndex = json['parentListIndex'];
    parentField = createServiceObject(
        json['parentField'], const ['FieldRef', 'String', 'int']) as dynamic;
  }

  Map<String, dynamic> toJson() => <String, Object?>{
        'source': source?.toJson(),
        if (parentListIndex case final parentListIndexValue?)
          'parentListIndex': parentListIndexValue,
        if (parentField is String || parentField is int
                ? parentField
                : parentField?.toJson()
            case final parentFieldValue?)
          'parentField': parentFieldValue,
      };

  @override
  String toString() => '[InboundReference source: $source]';
}

/// See [VmService.getInstances].
class InstanceSet extends Response {
  static InstanceSet? parse(Map<String, dynamic>? json) =>
      json == null ? null : InstanceSet._fromJson(json);

  /// The number of instances of the requested type currently allocated.
  int? totalCount;

  /// An array of instances of the requested type.
  List<ObjRef>? instances;

  InstanceSet({
    this.totalCount,
    this.instances,
  });

  InstanceSet._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    totalCount = json['totalCount'] ?? -1;
    instances = List<ObjRef>.from(createServiceObject(
            (json['instances'] ?? json['samples']!) as List, const ['ObjRef'])!
        as List);
  }

  @override
  String get type => 'InstanceSet';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'totalCount': totalCount ?? -1,
        'instances': instances?.map((f) => f.toJson()).toList(),
      };

  @override
  String toString() =>
      '[InstanceSet totalCount: $totalCount, instances: $instances]';
}

/// `LibraryRef` is a reference to a `Library`.
class LibraryRef extends ObjRef {
  static LibraryRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : LibraryRef._fromJson(json);

  /// The name of this library.
  String? name;

  /// The uri of this library.
  String? uri;

  LibraryRef({
    this.name,
    this.uri,
    required String id,
  }) : super(
          id: id,
        );

  LibraryRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    uri = json['uri'] ?? '';
  }

  @override
  String get type => '@Library';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'name': name ?? '',
        'uri': uri ?? '',
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is LibraryRef && id == other.id;

  @override
  String toString() => '[LibraryRef id: $id, name: $name, uri: $uri]';
}

/// A `Library` provides information about a Dart language library.
///
/// See [VmService.setLibraryDebuggable].
class Library extends Obj implements LibraryRef {
  static Library? parse(Map<String, dynamic>? json) =>
      json == null ? null : Library._fromJson(json);

  /// The name of this library.
  @override
  String? name;

  /// The uri of this library.
  @override
  String? uri;

  /// Is this library debuggable? Default true.
  bool? debuggable;

  /// A list of the imports for this library.
  List<LibraryDependency>? dependencies;

  /// A list of the scripts which constitute this library.
  List<ScriptRef>? scripts;

  /// A list of the top-level variables in this library.
  List<FieldRef>? variables;

  /// A list of the top-level functions in this library.
  List<FuncRef>? functions;

  /// A list of all classes in this library.
  List<ClassRef>? classes;

  Library({
    this.name,
    this.uri,
    this.debuggable,
    this.dependencies,
    this.scripts,
    this.variables,
    this.functions,
    this.classes,
    required String id,
  }) : super(
          id: id,
        );

  Library._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    uri = json['uri'] ?? '';
    debuggable = json['debuggable'] ?? false;
    dependencies = List<LibraryDependency>.from(
        _createSpecificObject(json['dependencies']!, LibraryDependency.parse));
    scripts = List<ScriptRef>.from(
        createServiceObject(json['scripts'], const ['ScriptRef']) as List? ??
            []);
    variables = List<FieldRef>.from(
        createServiceObject(json['variables'], const ['FieldRef']) as List? ??
            []);
    functions = List<FuncRef>.from(
        createServiceObject(json['functions'], const ['FuncRef']) as List? ??
            []);
    classes = List<ClassRef>.from(
        createServiceObject(json['classes'], const ['ClassRef']) as List? ??
            []);
  }

  @override
  String get type => 'Library';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'name': name ?? '',
        'uri': uri ?? '',
        'debuggable': debuggable ?? false,
        'dependencies': dependencies?.map((f) => f.toJson()).toList(),
        'scripts': scripts?.map((f) => f.toJson()).toList(),
        'variables': variables?.map((f) => f.toJson()).toList(),
        'functions': functions?.map((f) => f.toJson()).toList(),
        'classes': classes?.map((f) => f.toJson()).toList(),
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Library && id == other.id;

  @override
  String toString() => '[Library]';
}

/// A `LibraryDependency` provides information about an import or export.
class LibraryDependency {
  static LibraryDependency? parse(Map<String, dynamic>? json) =>
      json == null ? null : LibraryDependency._fromJson(json);

  /// Is this dependency an import (rather than an export)?
  bool? isImport;

  /// Is this dependency deferred?
  bool? isDeferred;

  /// The prefix of an 'as' import, or null.
  String? prefix;

  /// The library being imported or exported.
  LibraryRef? target;

  /// The list of symbols made visible from this dependency.
  @optional
  List<String>? shows;

  /// The list of symbols hidden from this dependency.
  @optional
  List<String>? hides;

  LibraryDependency({
    this.isImport,
    this.isDeferred,
    this.prefix,
    this.target,
    this.shows,
    this.hides,
  });

  LibraryDependency._fromJson(Map<String, dynamic> json) {
    isImport = json['isImport'] ?? false;
    isDeferred = json['isDeferred'] ?? false;
    prefix = json['prefix'] ?? '';
    target = createServiceObject(json['target'], const ['LibraryRef'])
        as LibraryRef?;
    shows = json['shows'] == null ? null : List<String>.from(json['shows']);
    hides = json['hides'] == null ? null : List<String>.from(json['hides']);
  }

  Map<String, dynamic> toJson() => <String, Object?>{
        'isImport': isImport ?? false,
        'isDeferred': isDeferred ?? false,
        'prefix': prefix ?? '',
        'target': target?.toJson(),
        if (shows?.map((f) => f).toList() case final showsValue?)
          'shows': showsValue,
        if (hides?.map((f) => f).toList() case final hidesValue?)
          'hides': hidesValue,
      };

  @override
  String toString() => '[LibraryDependency ' //
      'isImport: $isImport, isDeferred: $isDeferred, prefix: $prefix, ' //
      'target: $target]';
}

class LogRecord extends Response {
  static LogRecord? parse(Map<String, dynamic>? json) =>
      json == null ? null : LogRecord._fromJson(json);

  /// The log message.
  InstanceRef? message;

  /// The timestamp.
  int? time;

  /// The severity level (a value between 0 and 2000).
  ///
  /// See the package:logging `Level` class for an overview of the possible
  /// values.
  int? level;

  /// A monotonically increasing sequence number.
  int? sequenceNumber;

  /// The name of the source of the log message.
  InstanceRef? loggerName;

  /// The zone where the log was emitted.
  InstanceRef? zone;

  /// An error object associated with this log event.
  InstanceRef? error;

  /// A stack trace associated with this log event.
  InstanceRef? stackTrace;

  LogRecord({
    this.message,
    this.time,
    this.level,
    this.sequenceNumber,
    this.loggerName,
    this.zone,
    this.error,
    this.stackTrace,
  });

  LogRecord._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    message = createServiceObject(json['message'], const ['InstanceRef'])
        as InstanceRef?;
    time = json['time'] ?? -1;
    level = json['level'] ?? -1;
    sequenceNumber = json['sequenceNumber'] ?? -1;
    loggerName = createServiceObject(json['loggerName'], const ['InstanceRef'])
        as InstanceRef?;
    zone = createServiceObject(json['zone'], const ['InstanceRef'])
        as InstanceRef?;
    error = createServiceObject(json['error'], const ['InstanceRef'])
        as InstanceRef?;
    stackTrace = createServiceObject(json['stackTrace'], const ['InstanceRef'])
        as InstanceRef?;
  }

  @override
  String get type => 'LogRecord';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'message': message?.toJson(),
        'time': time ?? -1,
        'level': level ?? -1,
        'sequenceNumber': sequenceNumber ?? -1,
        'loggerName': loggerName?.toJson(),
        'zone': zone?.toJson(),
        'error': error?.toJson(),
        'stackTrace': stackTrace?.toJson(),
      };

  @override
  String toString() => '[LogRecord ' //
      'message: $message, time: $time, level: $level, sequenceNumber: $sequenceNumber, ' //
      'loggerName: $loggerName, zone: $zone, error: $error, stackTrace: $stackTrace]';
}

class MapAssociation {
  static MapAssociation? parse(Map<String, dynamic>? json) =>
      json == null ? null : MapAssociation._fromJson(json);

  /// [key] can be one of [InstanceRef] or [Sentinel].
  dynamic key;

  /// [value] can be one of [InstanceRef] or [Sentinel].
  dynamic value;

  MapAssociation({
    this.key,
    this.value,
  });

  MapAssociation._fromJson(Map<String, dynamic> json) {
    key = createServiceObject(json['key'], const ['InstanceRef', 'Sentinel'])
        as dynamic;
    value =
        createServiceObject(json['value'], const ['InstanceRef', 'Sentinel'])
            as dynamic;
  }

  Map<String, dynamic> toJson() => <String, Object?>{
        'key': key?.toJson(),
        'value': value?.toJson(),
      };

  @override
  String toString() => '[MapAssociation key: $key, value: $value]';
}

/// A `MemoryUsage` object provides heap usage information for a specific
/// isolate at a given point in time.
class MemoryUsage extends Response {
  static MemoryUsage? parse(Map<String, dynamic>? json) =>
      json == null ? null : MemoryUsage._fromJson(json);

  /// The amount of non-Dart memory that is retained by Dart objects. For
  /// example, memory associated with Dart objects through APIs such as
  /// Dart_NewFinalizableHandle, Dart_NewWeakPersistentHandle and
  /// Dart_NewExternalTypedData.  This usage is only as accurate as the values
  /// supplied to these APIs from the VM embedder. This external memory applies
  /// GC pressure, but is separate from heapUsage and heapCapacity.
  int? externalUsage;

  /// The total capacity of the heap in bytes. This is the amount of memory used
  /// by the Dart heap from the perspective of the operating system.
  int? heapCapacity;

  /// The current heap memory usage in bytes. Heap usage is always less than or
  /// equal to the heap capacity.
  int? heapUsage;

  MemoryUsage({
    this.externalUsage,
    this.heapCapacity,
    this.heapUsage,
  });

  MemoryUsage._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    externalUsage = json['externalUsage'] ?? -1;
    heapCapacity = json['heapCapacity'] ?? -1;
    heapUsage = json['heapUsage'] ?? -1;
  }

  @override
  String get type => 'MemoryUsage';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'externalUsage': externalUsage ?? -1,
        'heapCapacity': heapCapacity ?? -1,
        'heapUsage': heapUsage ?? -1,
      };

  @override
  String toString() => '[MemoryUsage ' //
      'externalUsage: $externalUsage, heapCapacity: $heapCapacity, ' //
      'heapUsage: $heapUsage]';
}

/// A `Message` provides information about a pending isolate message and the
/// function that will be invoked to handle it.
class Message extends Response {
  static Message? parse(Map<String, dynamic>? json) =>
      json == null ? null : Message._fromJson(json);

  /// The index in the isolate's message queue. The 0th message being the next
  /// message to be processed.
  int? index;

  /// An advisory name describing this message.
  String? name;

  /// An instance id for the decoded message. This id can be passed to other
  /// RPCs, for example, getObject or evaluate.
  String? messageObjectId;

  /// The size (bytes) of the encoded message.
  int? size;

  /// A reference to the function that will be invoked to handle this message.
  @optional
  FuncRef? handler;

  /// The source location of handler.
  @optional
  SourceLocation? location;

  Message({
    this.index,
    this.name,
    this.messageObjectId,
    this.size,
    this.handler,
    this.location,
  });

  Message._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    index = json['index'] ?? -1;
    name = json['name'] ?? '';
    messageObjectId = json['messageObjectId'] ?? '';
    size = json['size'] ?? -1;
    handler =
        createServiceObject(json['handler'], const ['FuncRef']) as FuncRef?;
    location = createServiceObject(json['location'], const ['SourceLocation'])
        as SourceLocation?;
  }

  @override
  String get type => 'Message';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'index': index ?? -1,
        'name': name ?? '',
        'messageObjectId': messageObjectId ?? '',
        'size': size ?? -1,
        if (handler?.toJson() case final handlerValue?) 'handler': handlerValue,
        if (location?.toJson() case final locationValue?)
          'location': locationValue,
      };

  @override
  String toString() => '[Message ' //
      'index: $index, name: $name, messageObjectId: $messageObjectId, ' //
      'size: $size]';
}

/// A `NativeFunction` object is used to represent native functions in profiler
/// samples. See [CpuSamples];
class NativeFunction {
  static NativeFunction? parse(Map<String, dynamic>? json) =>
      json == null ? null : NativeFunction._fromJson(json);

  /// The name of the native function this object represents.
  String? name;

  NativeFunction({
    this.name,
  });

  NativeFunction._fromJson(Map<String, dynamic> json) {
    name = json['name'] ?? '';
  }

  Map<String, dynamic> toJson() => <String, Object?>{
        'name': name ?? '',
      };

  @override
  String toString() => '[NativeFunction name: $name]';
}

/// `NullValRef` is a reference to an a `NullVal`.
class NullValRef extends InstanceRef {
  static NullValRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : NullValRef._fromJson(json);

  /// Always 'null'.
  @override
  String? valueAsString;

  NullValRef({
    this.valueAsString,
  }) : super(
          id: 'instance/null',
          identityHashCode: 0,
          kind: InstanceKind.kNull,
          classRef: ClassRef(
            id: 'class/null',
            library: LibraryRef(
              id: '',
              name: 'dart:core',
              uri: 'dart:core',
            ),
            name: 'Null',
          ),
        );

  NullValRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    valueAsString = json['valueAsString'] ?? '';
  }

  @override
  String get type => '@Null';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'valueAsString': valueAsString ?? '',
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is NullValRef && id == other.id;

  @override
  String toString() => '[NullValRef ' //
      'id: $id, kind: $kind, identityHashCode: $identityHashCode, ' //
      'classRef: $classRef, valueAsString: $valueAsString]';
}

/// A `NullVal` object represents the Dart language value null.
class NullVal extends Instance implements NullValRef {
  static NullVal? parse(Map<String, dynamic>? json) =>
      json == null ? null : NullVal._fromJson(json);

  /// Always 'null'.
  @override
  String? valueAsString;

  NullVal({
    this.valueAsString,
  }) : super(
          id: 'instance/null',
          identityHashCode: 0,
          kind: InstanceKind.kNull,
          classRef: ClassRef(
            id: 'class/null',
            library: LibraryRef(
              id: '',
              name: 'dart:core',
              uri: 'dart:core',
            ),
            name: 'Null',
          ),
        );

  NullVal._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    valueAsString = json['valueAsString'] ?? '';
  }

  @override
  String get type => 'Null';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'valueAsString': valueAsString ?? '',
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is NullVal && id == other.id;

  @override
  String toString() => '[NullVal ' //
      'id: $id, kind: $kind, identityHashCode: $identityHashCode, ' //
      'classRef: $classRef, valueAsString: $valueAsString]';
}

/// `ObjRef` is a reference to a `Obj`.
class ObjRef extends Response {
  static ObjRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : ObjRef._fromJson(json);

  /// A unique identifier for an Object. Passed to the getObject RPC to load
  /// this Object.
  String? id;

  /// Provided and set to true if the id of an Object is fixed. If true, the id
  /// of an Object is guaranteed not to change or expire. The object may,
  /// however, still be _Collected_.
  @optional
  bool? fixedId;

  ObjRef({
    this.id,
    this.fixedId,
  });

  ObjRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    id = json['id'] ?? '';
    fixedId = json['fixedId'];
  }

  @override
  String get type => '@Object';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'id': id ?? '',
        if (fixedId case final fixedIdValue?) 'fixedId': fixedIdValue,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is ObjRef && id == other.id;

  @override
  String toString() => '[ObjRef id: $id]';
}

/// An `Obj` is a persistent object that is owned by some isolate.
class Obj extends Response implements ObjRef {
  static Obj? parse(Map<String, dynamic>? json) =>
      json == null ? null : Obj._fromJson(json);

  /// A unique identifier for an Object. Passed to the getObject RPC to reload
  /// this Object.
  ///
  /// Some objects may get a new id when they are reloaded.
  @override
  String? id;

  /// Provided and set to true if the id of an Object is fixed. If true, the id
  /// of an Object is guaranteed not to change or expire. The object may,
  /// however, still be _Collected_.
  @optional
  @override
  bool? fixedId;

  /// If an object is allocated in the Dart heap, it will have a corresponding
  /// class object.
  ///
  /// The class of a non-instance is not a Dart class, but is instead an
  /// internal vm object.
  ///
  /// Moving an Object into or out of the heap is considered a backwards
  /// compatible change for types other than Instance.
  @optional
  ClassRef? classRef;

  /// The size of this object in the heap.
  ///
  /// If an object is not heap-allocated, then this field is omitted.
  ///
  /// Note that the size can be zero for some objects. In the current VM
  /// implementation, this occurs for small integers, which are stored entirely
  /// within their object pointers.
  @optional
  int? size;

  Obj({
    this.id,
    this.fixedId,
    this.classRef,
    this.size,
  });

  Obj._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    id = json['id'] ?? '';
    fixedId = json['fixedId'];
    classRef =
        createServiceObject(json['class'], const ['ClassRef']) as ClassRef?;
    size = json['size'];
  }

  @override
  String get type => 'Object';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'id': id ?? '',
        if (fixedId case final fixedIdValue?) 'fixedId': fixedIdValue,
        if (classRef?.toJson() case final classValue?) 'class': classValue,
        if (size case final sizeValue?) 'size': sizeValue,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Obj && id == other.id;

  @override
  String toString() => '[Obj id: $id]';
}

/// A `Parameter` is a representation of a function parameter.
///
/// See [Instance].
class Parameter {
  static Parameter? parse(Map<String, dynamic>? json) =>
      json == null ? null : Parameter._fromJson(json);

  /// The type of the parameter.
  InstanceRef? parameterType;

  /// Represents whether or not this parameter is fixed or optional.
  bool? fixed;

  /// The name of a named optional parameter.
  @optional
  String? name;

  /// Whether or not this named optional parameter is marked as required.
  @optional
  bool? required;

  Parameter({
    this.parameterType,
    this.fixed,
    this.name,
    this.required,
  });

  Parameter._fromJson(Map<String, dynamic> json) {
    parameterType =
        createServiceObject(json['parameterType'], const ['InstanceRef'])
            as InstanceRef?;
    fixed = json['fixed'] ?? false;
    name = json['name'];
    required = json['required'];
  }

  Map<String, dynamic> toJson() => <String, Object?>{
        'parameterType': parameterType?.toJson(),
        'fixed': fixed ?? false,
        if (name case final nameValue?) 'name': nameValue,
        if (required case final requiredValue?) 'required': requiredValue,
      };

  @override
  String toString() =>
      '[Parameter parameterType: $parameterType, fixed: $fixed]';
}

/// See [VmService.getPerfettoCpuSamples].
class PerfettoCpuSamples extends Response {
  static PerfettoCpuSamples? parse(Map<String, dynamic>? json) =>
      json == null ? null : PerfettoCpuSamples._fromJson(json);

  /// The sampling rate for the profiler in microseconds.
  int? samplePeriod;

  /// The maximum possible stack depth for samples.
  int? maxStackDepth;

  /// The number of samples returned.
  int? sampleCount;

  /// The start of the period of time in which the returned samples were
  /// collected.
  int? timeOriginMicros;

  /// The duration of time covered by the returned samples.
  int? timeExtentMicros;

  /// The process ID for the VM.
  int? pid;

  /// A Base64 string representing the requested samples in Perfetto's proto
  /// format.
  String? samples;

  PerfettoCpuSamples({
    this.samplePeriod,
    this.maxStackDepth,
    this.sampleCount,
    this.timeOriginMicros,
    this.timeExtentMicros,
    this.pid,
    this.samples,
  });

  PerfettoCpuSamples._fromJson(Map<String, dynamic> json)
      : super._fromJson(json) {
    samplePeriod = json['samplePeriod'] ?? -1;
    maxStackDepth = json['maxStackDepth'] ?? -1;
    sampleCount = json['sampleCount'] ?? -1;
    timeOriginMicros = json['timeOriginMicros'] ?? -1;
    timeExtentMicros = json['timeExtentMicros'] ?? -1;
    pid = json['pid'] ?? -1;
    samples = json['samples'] ?? '';
  }

  @override
  String get type => 'PerfettoCpuSamples';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'samplePeriod': samplePeriod ?? -1,
        'maxStackDepth': maxStackDepth ?? -1,
        'sampleCount': sampleCount ?? -1,
        'timeOriginMicros': timeOriginMicros ?? -1,
        'timeExtentMicros': timeExtentMicros ?? -1,
        'pid': pid ?? -1,
        'samples': samples ?? '',
      };

  @override
  String toString() => '[PerfettoCpuSamples ' //
      'samplePeriod: $samplePeriod, maxStackDepth: $maxStackDepth, ' //
      'sampleCount: $sampleCount, timeOriginMicros: $timeOriginMicros, timeExtentMicros: $timeExtentMicros, pid: $pid, samples: $samples]';
}

/// See [VmService.getPerfettoVMTimeline];
class PerfettoTimeline extends Response {
  static PerfettoTimeline? parse(Map<String, dynamic>? json) =>
      json == null ? null : PerfettoTimeline._fromJson(json);

  /// A Base64 string representing the requested timeline trace in Perfetto's
  /// proto format.
  String? trace;

  /// The start of the period of time covered by the trace.
  int? timeOriginMicros;

  /// The duration of time covered by the trace.
  int? timeExtentMicros;

  PerfettoTimeline({
    this.trace,
    this.timeOriginMicros,
    this.timeExtentMicros,
  });

  PerfettoTimeline._fromJson(Map<String, dynamic> json)
      : super._fromJson(json) {
    trace = json['trace'] ?? '';
    timeOriginMicros = json['timeOriginMicros'] ?? -1;
    timeExtentMicros = json['timeExtentMicros'] ?? -1;
  }

  @override
  String get type => 'PerfettoTimeline';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'trace': trace ?? '',
        'timeOriginMicros': timeOriginMicros ?? -1,
        'timeExtentMicros': timeExtentMicros ?? -1,
      };

  @override
  String toString() => '[PerfettoTimeline ' //
      'trace: $trace, timeOriginMicros: $timeOriginMicros, timeExtentMicros: $timeExtentMicros]';
}

/// A `PortList` contains a list of ports associated with some isolate.
///
/// See [VmService.getPorts].
class PortList extends Response {
  static PortList? parse(Map<String, dynamic>? json) =>
      json == null ? null : PortList._fromJson(json);

  List<InstanceRef>? ports;

  PortList({
    this.ports,
  });

  PortList._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    ports = List<InstanceRef>.from(
        createServiceObject(json['ports'], const ['InstanceRef']) as List? ??
            []);
  }

  @override
  String get type => 'PortList';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'ports': ports?.map((f) => f.toJson()).toList(),
      };

  @override
  String toString() => '[PortList ports: $ports]';
}

/// A `ProfileFunction` contains profiling information about a Dart or native
/// function.
///
/// See [CpuSamples].
class ProfileFunction {
  static ProfileFunction? parse(Map<String, dynamic>? json) =>
      json == null ? null : ProfileFunction._fromJson(json);

  /// The kind of function this object represents.
  String? kind;

  /// The number of times function appeared on the stack during sampling events.
  int? inclusiveTicks;

  /// The number of times function appeared on the top of the stack during
  /// sampling events.
  int? exclusiveTicks;

  /// The resolved URL for the script containing function.
  String? resolvedUrl;

  /// The function captured during profiling.
  dynamic function;

  ProfileFunction({
    this.kind,
    this.inclusiveTicks,
    this.exclusiveTicks,
    this.resolvedUrl,
    this.function,
  });

  ProfileFunction._fromJson(Map<String, dynamic> json) {
    kind = json['kind'] ?? '';
    inclusiveTicks = json['inclusiveTicks'] ?? -1;
    exclusiveTicks = json['exclusiveTicks'] ?? -1;
    resolvedUrl = json['resolvedUrl'] ?? '';
    function =
        createServiceObject(json['function'], const ['dynamic']) as dynamic;
  }

  Map<String, dynamic> toJson() => <String, Object?>{
        'kind': kind ?? '',
        'inclusiveTicks': inclusiveTicks ?? -1,
        'exclusiveTicks': exclusiveTicks ?? -1,
        'resolvedUrl': resolvedUrl ?? '',
        'function': function?.toJson(),
      };

  @override
  String toString() => '[ProfileFunction ' //
      'kind: $kind, inclusiveTicks: $inclusiveTicks, exclusiveTicks: $exclusiveTicks, ' //
      'resolvedUrl: $resolvedUrl, function: $function]';
}

/// A `ProtocolList` contains a list of all protocols supported by the service
/// instance.
///
/// See [Protocol] and [VmService.getSupportedProtocols].
class ProtocolList extends Response {
  static ProtocolList? parse(Map<String, dynamic>? json) =>
      json == null ? null : ProtocolList._fromJson(json);

  /// A list of supported protocols provided by this service.
  List<Protocol>? protocols;

  ProtocolList({
    this.protocols,
  });

  ProtocolList._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    protocols = List<Protocol>.from(
        createServiceObject(json['protocols'], const ['Protocol']) as List? ??
            []);
  }

  @override
  String get type => 'ProtocolList';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'protocols': protocols?.map((f) => f.toJson()).toList(),
      };

  @override
  String toString() => '[ProtocolList protocols: $protocols]';
}

/// See [VmService.getSupportedProtocols].
class Protocol {
  static Protocol? parse(Map<String, dynamic>? json) =>
      json == null ? null : Protocol._fromJson(json);

  /// The name of the supported protocol.
  String? protocolName;

  /// The major revision of the protocol.
  int? major;

  /// The minor revision of the protocol.
  int? minor;

  Protocol({
    this.protocolName,
    this.major,
    this.minor,
  });

  Protocol._fromJson(Map<String, dynamic> json) {
    protocolName = json['protocolName'] ?? '';
    major = json['major'] ?? -1;
    minor = json['minor'] ?? -1;
  }

  Map<String, dynamic> toJson() => <String, Object?>{
        'protocolName': protocolName ?? '',
        'major': major ?? -1,
        'minor': minor ?? -1,
      };

  @override
  String toString() =>
      '[Protocol protocolName: $protocolName, major: $major, minor: $minor]';
}

/// See [VmService.getProcessMemoryUsage].
class ProcessMemoryUsage extends Response {
  static ProcessMemoryUsage? parse(Map<String, dynamic>? json) =>
      json == null ? null : ProcessMemoryUsage._fromJson(json);

  ProcessMemoryItem? root;

  ProcessMemoryUsage({
    this.root,
  });

  ProcessMemoryUsage._fromJson(Map<String, dynamic> json)
      : super._fromJson(json) {
    root = createServiceObject(json['root'], const ['ProcessMemoryItem'])
        as ProcessMemoryItem?;
  }

  @override
  String get type => 'ProcessMemoryUsage';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'root': root?.toJson(),
      };

  @override
  String toString() => '[ProcessMemoryUsage root: $root]';
}

class ProcessMemoryItem {
  static ProcessMemoryItem? parse(Map<String, dynamic>? json) =>
      json == null ? null : ProcessMemoryItem._fromJson(json);

  /// A short name for this bucket of memory.
  String? name;

  /// A longer description for this item.
  String? description;

  /// The amount of memory in bytes. This is a retained size, not a shallow
  /// size. That is, it includes the size of children.
  int? size;

  /// Subdivisions of this bucket of memory.
  List<ProcessMemoryItem>? children;

  ProcessMemoryItem({
    this.name,
    this.description,
    this.size,
    this.children,
  });

  ProcessMemoryItem._fromJson(Map<String, dynamic> json) {
    name = json['name'] ?? '';
    description = json['description'] ?? '';
    size = json['size'] ?? -1;
    children = List<ProcessMemoryItem>.from(
        createServiceObject(json['children'], const ['ProcessMemoryItem'])
                as List? ??
            []);
  }

  Map<String, dynamic> toJson() => <String, Object?>{
        'name': name ?? '',
        'description': description ?? '',
        'size': size ?? -1,
        'children': children?.map((f) => f.toJson()).toList(),
      };

  @override
  String toString() => '[ProcessMemoryItem ' //
      'name: $name, description: $description, size: $size, children: $children]';
}

class ReloadReport extends Response {
  static ReloadReport? parse(Map<String, dynamic>? json) =>
      json == null ? null : ReloadReport._fromJson(json);

  /// Did the reload succeed or fail?
  bool? success;

  ReloadReport({
    this.success,
  });

  ReloadReport._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    success = json['success'] ?? false;
  }

  @override
  String get type => 'ReloadReport';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'success': success ?? false,
      };

  @override
  String toString() => '[ReloadReport success: $success]';
}

/// See [RetainingPath].
class RetainingObject {
  static RetainingObject? parse(Map<String, dynamic>? json) =>
      json == null ? null : RetainingObject._fromJson(json);

  /// An object that is part of a retaining path.
  ObjRef? value;

  /// If `value` is a List, `parentListIndex` is the index where the previous
  /// object on the retaining path is located (deprecated).
  ///
  /// Note: this property is deprecated and will be replaced by `parentField`.
  @optional
  int? parentListIndex;

  /// If `value` is a Map, `parentMapKey` is the key mapping to the previous
  /// object on the retaining path.
  @optional
  ObjRef? parentMapKey;

  /// If `value` is a non-List, non-Map object, `parentField` is the name of the
  /// field containing the previous object on the retaining path.
  ///
  /// [parentField] can be one of [String] or [int].
  @optional
  dynamic parentField;

  RetainingObject({
    this.value,
    this.parentListIndex,
    this.parentMapKey,
    this.parentField,
  });

  RetainingObject._fromJson(Map<String, dynamic> json) {
    value = createServiceObject(json['value'], const ['ObjRef']) as ObjRef?;
    parentListIndex = json['parentListIndex'];
    parentMapKey =
        createServiceObject(json['parentMapKey'], const ['ObjRef']) as ObjRef?;
    parentField =
        createServiceObject(json['parentField'], const ['String', 'int'])
            as dynamic;
  }

  Map<String, dynamic> toJson() => <String, Object?>{
        'value': value?.toJson(),
        if (parentListIndex case final parentListIndexValue?)
          'parentListIndex': parentListIndexValue,
        if (parentMapKey?.toJson() case final parentMapKeyValue?)
          'parentMapKey': parentMapKeyValue,
        if (parentField case final parentFieldValue?)
          'parentField': parentFieldValue,
      };

  @override
  String toString() => '[RetainingObject value: $value]';
}

/// See [VmService.getRetainingPath].
class RetainingPath extends Response {
  static RetainingPath? parse(Map<String, dynamic>? json) =>
      json == null ? null : RetainingPath._fromJson(json);

  /// The length of the retaining path.
  int? length;

  /// The type of GC root which is holding a reference to the specified object.
  /// Possible values include:  * class table  * local handle  * persistent
  /// handle  * stack  * user global  * weak persistent handle  * unknown
  String? gcRootType;

  /// The chain of objects which make up the retaining path.
  List<RetainingObject>? elements;

  RetainingPath({
    this.length,
    this.gcRootType,
    this.elements,
  });

  RetainingPath._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    length = json['length'] ?? -1;
    gcRootType = json['gcRootType'] ?? '';
    elements = List<RetainingObject>.from(
        createServiceObject(json['elements'], const ['RetainingObject'])
                as List? ??
            []);
  }

  @override
  String get type => 'RetainingPath';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'length': length ?? -1,
        'gcRootType': gcRootType ?? '',
        'elements': elements?.map((f) => f.toJson()).toList(),
      };

  @override
  String toString() => '[RetainingPath ' //
      'length: $length, gcRootType: $gcRootType, elements: $elements]';
}

/// Every non-error response returned by the Service Protocol extends
/// `Response`. By using the `type` property, the client can determine which
/// [type] of response has been provided.
class Response {
  static Response? parse(Map<String, dynamic>? json) =>
      json == null ? null : Response._fromJson(json);

  Map<String, dynamic>? json;

  Response();

  Response._fromJson(Map<String, dynamic> this.json);

  String get type => 'Response';

  Map<String, dynamic> toJson() => <String, Object?>{
        ...?json,
        'type': type,
      };

  @override
  String toString() => '[Response]';
}

/// A `Sentinel` is used to indicate that the normal response is not available.
///
/// We use a `Sentinel` instead of an [error] for these cases because they do
/// not represent a problematic condition. They are normal.
class Sentinel extends Response {
  static Sentinel? parse(Map<String, dynamic>? json) =>
      json == null ? null : Sentinel._fromJson(json);

  /// What kind of sentinel is this?
  /*SentinelKind*/ String? kind;

  /// A reasonable string representation of this sentinel.
  String? valueAsString;

  Sentinel({
    this.kind,
    this.valueAsString,
  });

  Sentinel._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    kind = json['kind'] ?? '';
    valueAsString = json['valueAsString'] ?? '';
  }

  @override
  String get type => 'Sentinel';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'kind': kind ?? '',
        'valueAsString': valueAsString ?? '',
      };

  @override
  String toString() => '[Sentinel kind: $kind, valueAsString: $valueAsString]';
}

/// `ScriptRef` is a reference to a `Script`.
class ScriptRef extends ObjRef {
  static ScriptRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : ScriptRef._fromJson(json);

  /// The uri from which this script was loaded.
  String? uri;

  ScriptRef({
    this.uri,
    required String id,
  }) : super(
          id: id,
        );

  ScriptRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    uri = json['uri'] ?? '';
  }

  @override
  String get type => '@Script';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'uri': uri ?? '',
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is ScriptRef && id == other.id;

  @override
  String toString() => '[ScriptRef id: $id, uri: $uri]';
}

/// A `Script` provides information about a Dart language script.
///
/// The `tokenPosTable` is an array of int arrays. Each subarray consists of a
/// line number followed by `(tokenPos, columnNumber)` pairs:
///
/// ```
/// [lineNumber, (tokenPos, columnNumber)*]
/// ```
///
/// The `tokenPos` is an arbitrary integer value that is used to represent a
/// location in the source code. A `tokenPos` value is not meaningful in itself
/// and code should not rely on the exact values returned.
///
/// For example, a `tokenPosTable` with the value...
///
/// ```
/// [[1, 100, 5, 101, 8],[2, 102, 7]]
/// ```
///
/// ...encodes the mapping:
///
/// tokenPos | line | column
/// -------- | ---- | ------
/// 100 | 1 | 5
/// 101 | 1 | 8
/// 102 | 2 | 7
class Script extends Obj implements ScriptRef {
  static Script? parse(Map<String, dynamic>? json) =>
      json == null ? null : Script._fromJson(json);

  final _tokenToLine = <int, int>{};
  final _tokenToColumn = <int, int>{};

  /// The uri from which this script was loaded.
  @override
  String? uri;

  /// The library which owns this script.
  LibraryRef? library;

  @optional
  int? lineOffset;

  @optional
  int? columnOffset;

  /// The source code for this script. This can be null for certain built-in
  /// scripts.
  @optional
  String? source;

  /// A table encoding a mapping from token position to line and column. This
  /// field is null if sources aren't available.
  @optional
  List<List<int>>? tokenPosTable;

  Script({
    this.uri,
    this.library,
    required String id,
    this.lineOffset,
    this.columnOffset,
    this.source,
    this.tokenPosTable,
  }) : super(
          id: id,
        );

  Script._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    uri = json['uri'] ?? '';
    library = createServiceObject(json['library'], const ['LibraryRef'])
        as LibraryRef?;
    lineOffset = json['lineOffset'];
    columnOffset = json['columnOffset'];
    source = json['source'];
    tokenPosTable = json['tokenPosTable'] == null
        ? null
        : List<List<int>>.from(
            json['tokenPosTable']!.map((dynamic list) => List<int>.from(list)));
    _parseTokenPosTable();
  }

  /// This function maps a token position to a line number.
  /// The VM considers the first line to be line 1.
  int? getLineNumberFromTokenPos(int tokenPos) => _tokenToLine[tokenPos];

  /// This function maps a token position to a column number.
  /// The VM considers the first column to be column 1.
  int? getColumnNumberFromTokenPos(int tokenPos) => _tokenToColumn[tokenPos];

  void _parseTokenPosTable() {
    final tokenPositionTable = tokenPosTable;
    if (tokenPositionTable == null) {
      return;
    }
    final lineSet = <int>{};
    for (List line in tokenPositionTable) {
      // Each entry begins with a line number...
      int lineNumber = line[0];
      lineSet.add(lineNumber);
      for (var pos = 1; pos < line.length; pos += 2) {
        // ...and is followed by (token offset, col number) pairs.
        final int tokenOffset = line[pos];
        final int colNumber = line[pos + 1];
        _tokenToLine[tokenOffset] = lineNumber;
        _tokenToColumn[tokenOffset] = colNumber;
      }
    }
  }

  @override
  String get type => 'Script';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'uri': uri ?? '',
        'library': library?.toJson(),
        if (lineOffset case final lineOffsetValue?)
          'lineOffset': lineOffsetValue,
        if (columnOffset case final columnOffsetValue?)
          'columnOffset': columnOffsetValue,
        if (source case final sourceValue?) 'source': sourceValue,
        if (tokenPosTable?.map((f) => f.toList()).toList()
            case final tokenPosTableValue?)
          'tokenPosTable': tokenPosTableValue,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Script && id == other.id;

  @override
  String toString() => '[Script id: $id, uri: $uri, library: $library]';
}

class ScriptList extends Response {
  static ScriptList? parse(Map<String, dynamic>? json) =>
      json == null ? null : ScriptList._fromJson(json);

  List<ScriptRef>? scripts;

  ScriptList({
    this.scripts,
  });

  ScriptList._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    scripts = List<ScriptRef>.from(
        createServiceObject(json['scripts'], const ['ScriptRef']) as List? ??
            []);
  }

  @override
  String get type => 'ScriptList';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'scripts': scripts?.map((f) => f.toJson()).toList(),
      };

  @override
  String toString() => '[ScriptList scripts: $scripts]';
}

/// The `SourceLocation` class is used to designate a position or range in some
/// script.
class SourceLocation extends Response {
  static SourceLocation? parse(Map<String, dynamic>? json) =>
      json == null ? null : SourceLocation._fromJson(json);

  /// The script containing the source location.
  ScriptRef? script;

  /// The first token of the location.
  int? tokenPos;

  /// The last token of the location if this is a range.
  @optional
  int? endTokenPos;

  /// The line associated with this location. Only provided for non-synthetic
  /// token positions.
  @optional
  int? line;

  /// The column associated with this location. Only provided for non-synthetic
  /// token positions.
  @optional
  int? column;

  SourceLocation({
    this.script,
    this.tokenPos,
    this.endTokenPos,
    this.line,
    this.column,
  });

  SourceLocation._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    script =
        createServiceObject(json['script'], const ['ScriptRef']) as ScriptRef?;
    tokenPos = json['tokenPos'] ?? -1;
    endTokenPos = json['endTokenPos'];
    line = json['line'];
    column = json['column'];
  }

  @override
  String get type => 'SourceLocation';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'script': script?.toJson(),
        'tokenPos': tokenPos ?? -1,
        if (endTokenPos case final endTokenPosValue?)
          'endTokenPos': endTokenPosValue,
        if (line case final lineValue?) 'line': lineValue,
        if (column case final columnValue?) 'column': columnValue,
      };

  @override
  String toString() => '[SourceLocation script: $script, tokenPos: $tokenPos]';
}

/// The `SourceReport` class represents a set of reports tied to source
/// locations in an isolate.
class SourceReport extends Response {
  static SourceReport? parse(Map<String, dynamic>? json) =>
      json == null ? null : SourceReport._fromJson(json);

  /// A list of ranges in the program source.  These ranges correspond to ranges
  /// of executable code in the user's program (functions, methods,
  /// constructors, etc.)
  ///
  /// Note that ranges may nest in other ranges, in the case of nested
  /// functions.
  ///
  /// Note that ranges may be duplicated, in the case of mixins.
  List<SourceReportRange>? ranges;

  /// A list of scripts, referenced by index in the report's ranges.
  List<ScriptRef>? scripts;

  SourceReport({
    this.ranges,
    this.scripts,
  });

  SourceReport._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    ranges = List<SourceReportRange>.from(
        _createSpecificObject(json['ranges']!, SourceReportRange.parse));
    scripts = List<ScriptRef>.from(
        createServiceObject(json['scripts'], const ['ScriptRef']) as List? ??
            []);
  }

  @override
  String get type => 'SourceReport';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'ranges': ranges?.map((f) => f.toJson()).toList(),
        'scripts': scripts?.map((f) => f.toJson()).toList(),
      };

  @override
  String toString() => '[SourceReport ranges: $ranges, scripts: $scripts]';
}

/// The `SourceReportCoverage` class represents coverage information for one
/// [SourceReportRange].
///
/// Note that `SourceReportCoverage` does not extend [Response] and therefore
/// will not contain a `type` property.
class SourceReportCoverage {
  static SourceReportCoverage? parse(Map<String, dynamic>? json) =>
      json == null ? null : SourceReportCoverage._fromJson(json);

  /// A list of token positions (or line numbers if reportLines was enabled) in
  /// a SourceReportRange which have been executed.  The list is sorted.
  List<int>? hits;

  /// A list of token positions (or line numbers if reportLines was enabled) in
  /// a SourceReportRange which have not been executed.  The list is sorted.
  List<int>? misses;

  SourceReportCoverage({
    this.hits,
    this.misses,
  });

  SourceReportCoverage._fromJson(Map<String, dynamic> json) {
    hits = List<int>.from(json['hits']);
    misses = List<int>.from(json['misses']);
  }

  Map<String, dynamic> toJson() => <String, Object?>{
        'hits': hits?.map((f) => f).toList(),
        'misses': misses?.map((f) => f).toList(),
      };

  @override
  String toString() => '[SourceReportCoverage hits: $hits, misses: $misses]';
}

/// The `SourceReportRange` class represents a range of executable code
/// (function, method, constructor, etc) in the running program. It is part of a
/// [SourceReport].
///
/// Note that `SourceReportRange` does not extend [Response] and therefore will
/// not contain a `type` property.
class SourceReportRange {
  static SourceReportRange? parse(Map<String, dynamic>? json) =>
      json == null ? null : SourceReportRange._fromJson(json);

  /// An index into the script table of the SourceReport, indicating which
  /// script contains this range of code.
  int? scriptIndex;

  /// The token position at which this range begins.
  int? startPos;

  /// The token position at which this range ends.  Inclusive.
  int? endPos;

  /// Has this range been compiled by the Dart VM?
  bool? compiled;

  /// The error while attempting to compile this range, if this report was
  /// generated with forceCompile=true.
  @optional
  ErrorRef? error;

  /// Code coverage information for this range.  Provided only when the Coverage
  /// report has been requested and the range has been compiled.
  @optional
  SourceReportCoverage? coverage;

  /// Possible breakpoint information for this range, represented as a sorted
  /// list of token positions (or line numbers if reportLines was enabled).
  /// Provided only when the when the PossibleBreakpoint report has been
  /// requested and the range has been compiled.
  @optional
  List<int>? possibleBreakpoints;

  /// Branch coverage information for this range.  Provided only when the
  /// BranchCoverage report has been requested and the range has been compiled.
  @optional
  SourceReportCoverage? branchCoverage;

  SourceReportRange({
    this.scriptIndex,
    this.startPos,
    this.endPos,
    this.compiled,
    this.error,
    this.coverage,
    this.possibleBreakpoints,
    this.branchCoverage,
  });

  SourceReportRange._fromJson(Map<String, dynamic> json) {
    scriptIndex = json['scriptIndex'] ?? -1;
    startPos = json['startPos'] ?? -1;
    endPos = json['endPos'] ?? -1;
    compiled = json['compiled'] ?? false;
    error = createServiceObject(json['error'], const ['ErrorRef']) as ErrorRef?;
    coverage =
        _createSpecificObject(json['coverage'], SourceReportCoverage.parse);
    possibleBreakpoints = json['possibleBreakpoints'] == null
        ? null
        : List<int>.from(json['possibleBreakpoints']);
    branchCoverage = createServiceObject(
            json['branchCoverage'], const ['SourceReportCoverage'])
        as SourceReportCoverage?;
  }

  Map<String, dynamic> toJson() => <String, Object?>{
        'scriptIndex': scriptIndex ?? -1,
        'startPos': startPos ?? -1,
        'endPos': endPos ?? -1,
        'compiled': compiled ?? false,
        if (error?.toJson() case final errorValue?) 'error': errorValue,
        if (coverage?.toJson() case final coverageValue?)
          'coverage': coverageValue,
        if (possibleBreakpoints?.map((f) => f).toList()
            case final possibleBreakpointsValue?)
          'possibleBreakpoints': possibleBreakpointsValue,
        if (branchCoverage?.toJson() case final branchCoverageValue?)
          'branchCoverage': branchCoverageValue,
      };

  @override
  String toString() => '[SourceReportRange ' //
      'scriptIndex: $scriptIndex, startPos: $startPos, endPos: $endPos, ' //
      'compiled: $compiled]';
}

/// The `Stack` class represents the various components of a Dart stack trace
/// for a given isolate.
///
/// See [VmService.getStack].
class Stack extends Response {
  static Stack? parse(Map<String, dynamic>? json) =>
      json == null ? null : Stack._fromJson(json);

  /// A list of frames that make up the synchronous stack, rooted at the message
  /// loop (i.e., the frames since the last asynchronous gap or the isolate's
  /// entrypoint).
  List<Frame>? frames;

  /// A list of frames which contains both synchronous part and the asynchronous
  /// continuation e.g. `async` functions awaiting completion of the currently
  /// running `async` function. Asynchronous frames are separated from each
  /// other and synchronous prefix via frames of kind
  /// FrameKind.kAsyncSuspensionMarker.
  ///
  /// The name is historic and misleading: despite what *causal* implies, this
  /// stack does not reflect the stack at the moment when asynchronous operation
  /// was started (i.e. the stack that *caused* it), but instead reflects the
  /// chain of listeners which will run when asynchronous operation is completed
  /// (i.e. its *awaiters*).
  ///
  /// This field is absent if currently running code does not have an
  /// asynchronous continuation.
  @optional
  List<Frame>? asyncCausalFrames;

  /// Deprecated since version 4.7 of the protocol. Will be always absent in the
  /// response.
  ///
  /// Used to contain information about asynchronous continuation, similar to
  /// the one in asyncCausalFrame but with a slightly different encoding.
  @optional
  List<Frame>? awaiterFrames;

  /// A list of messages in the isolate's message queue.
  List<Message>? messages;

  /// Specifies whether or not this stack is complete or has been artificially
  /// truncated.
  bool? truncated;

  Stack({
    this.frames,
    this.messages,
    this.truncated,
    this.asyncCausalFrames,
    this.awaiterFrames,
  });

  Stack._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    frames = List<Frame>.from(
        createServiceObject(json['frames'], const ['Frame']) as List? ?? []);
    asyncCausalFrames = json['asyncCausalFrames'] == null
        ? null
        : List<Frame>.from(
            createServiceObject(json['asyncCausalFrames'], const ['Frame'])!
                as List);
    awaiterFrames = json['awaiterFrames'] == null
        ? null
        : List<Frame>.from(
            createServiceObject(json['awaiterFrames'], const ['Frame'])!
                as List);
    messages = List<Message>.from(
        createServiceObject(json['messages'], const ['Message']) as List? ??
            []);
    truncated = json['truncated'] ?? false;
  }

  @override
  String get type => 'Stack';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'frames': frames?.map((f) => f.toJson()).toList(),
        'messages': messages?.map((f) => f.toJson()).toList(),
        'truncated': truncated ?? false,
        if (asyncCausalFrames?.map((f) => f.toJson()).toList()
            case final asyncCausalFramesValue?)
          'asyncCausalFrames': asyncCausalFramesValue,
        if (awaiterFrames?.map((f) => f.toJson()).toList()
            case final awaiterFramesValue?)
          'awaiterFrames': awaiterFramesValue,
      };

  @override
  String toString() =>
      '[Stack frames: $frames, messages: $messages, truncated: $truncated]';
}

/// The `Success` type is used to indicate that an operation completed
/// successfully.
class Success extends Response {
  static Success? parse(Map<String, dynamic>? json) =>
      json == null ? null : Success._fromJson(json);

  Success();

  Success._fromJson(super.json) : super._fromJson();

  @override
  String get type => 'Success';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
      };

  @override
  String toString() => '[Success]';
}

/// See [VmService.getVMTimeline];
class Timeline extends Response {
  static Timeline? parse(Map<String, dynamic>? json) =>
      json == null ? null : Timeline._fromJson(json);

  /// A list of timeline events. No order is guaranteed for these events; in
  /// particular, these events may be unordered with respect to their
  /// timestamps.
  List<TimelineEvent>? traceEvents;

  /// The start of the period of time in which traceEvents were collected.
  int? timeOriginMicros;

  /// The duration of time covered by the timeline.
  int? timeExtentMicros;

  Timeline({
    this.traceEvents,
    this.timeOriginMicros,
    this.timeExtentMicros,
  });

  Timeline._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    traceEvents = List<TimelineEvent>.from(
        createServiceObject(json['traceEvents'], const ['TimelineEvent'])
                as List? ??
            []);
    timeOriginMicros = json['timeOriginMicros'] ?? -1;
    timeExtentMicros = json['timeExtentMicros'] ?? -1;
  }

  @override
  String get type => 'Timeline';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'traceEvents': traceEvents?.map((f) => f.toJson()).toList(),
        'timeOriginMicros': timeOriginMicros ?? -1,
        'timeExtentMicros': timeExtentMicros ?? -1,
      };

  @override
  String toString() => '[Timeline ' //
      'traceEvents: $traceEvents, timeOriginMicros: $timeOriginMicros, ' //
      'timeExtentMicros: $timeExtentMicros]';
}

/// An `TimelineEvent` is an arbitrary map that contains a [Trace Event Format]
/// event.
class TimelineEvent {
  static TimelineEvent? parse(Map<String, dynamic>? json) =>
      json == null ? null : TimelineEvent._fromJson(json);

  Map<String, dynamic>? json;

  TimelineEvent();

  TimelineEvent._fromJson(Map<String, dynamic> this.json);

  Map<String, dynamic> toJson() => <String, Object?>{
        ...?json,
        'type': 'TimelineEvent',
      };

  @override
  String toString() => '[TimelineEvent]';
}

class TimelineFlags extends Response {
  static TimelineFlags? parse(Map<String, dynamic>? json) =>
      json == null ? null : TimelineFlags._fromJson(json);

  /// The name of the recorder currently in use. Recorder types include, but are
  /// not limited to: Callback, Endless, Fuchsia, Macos, Ring, Startup, and
  /// Systrace. Set to "null" if no recorder is currently set.
  String? recorderName;

  /// The list of all available timeline streams.
  List<String>? availableStreams;

  /// The list of timeline streams that are currently enabled.
  List<String>? recordedStreams;

  TimelineFlags({
    this.recorderName,
    this.availableStreams,
    this.recordedStreams,
  });

  TimelineFlags._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    recorderName = json['recorderName'] ?? '';
    availableStreams = List<String>.from(json['availableStreams']);
    recordedStreams = List<String>.from(json['recordedStreams']);
  }

  @override
  String get type => 'TimelineFlags';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'recorderName': recorderName ?? '',
        'availableStreams': availableStreams?.map((f) => f).toList(),
        'recordedStreams': recordedStreams?.map((f) => f).toList(),
      };

  @override
  String toString() => '[TimelineFlags ' //
      'recorderName: $recorderName, availableStreams: $availableStreams, ' //
      'recordedStreams: $recordedStreams]';
}

class Timestamp extends Response {
  static Timestamp? parse(Map<String, dynamic>? json) =>
      json == null ? null : Timestamp._fromJson(json);

  /// A timestamp in microseconds since epoch.
  int? timestamp;

  Timestamp({
    this.timestamp,
  });

  Timestamp._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    timestamp = json['timestamp'] ?? -1;
  }

  @override
  String get type => 'Timestamp';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'timestamp': timestamp ?? -1,
      };

  @override
  String toString() => '[Timestamp timestamp: $timestamp]';
}

/// `TypeArgumentsRef` is a reference to a `TypeArguments` object.
class TypeArgumentsRef extends ObjRef {
  static TypeArgumentsRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : TypeArgumentsRef._fromJson(json);

  /// A name for this type argument list.
  String? name;

  TypeArgumentsRef({
    this.name,
    required String id,
  }) : super(
          id: id,
        );

  TypeArgumentsRef._fromJson(Map<String, dynamic> json)
      : super._fromJson(json) {
    name = json['name'] ?? '';
  }

  @override
  String get type => '@TypeArguments';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'name': name ?? '',
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is TypeArgumentsRef && id == other.id;

  @override
  String toString() => '[TypeArgumentsRef id: $id, name: $name]';
}

/// A `TypeArguments` object represents the type argument vector for some
/// instantiated generic type.
class TypeArguments extends Obj implements TypeArgumentsRef {
  static TypeArguments? parse(Map<String, dynamic>? json) =>
      json == null ? null : TypeArguments._fromJson(json);

  /// A name for this type argument list.
  @override
  String? name;

  /// A list of types.
  ///
  /// The value will always be one of the kinds: Type, TypeParameter,
  /// RecordType, FunctionType, BoundedType.
  List<InstanceRef>? types;

  TypeArguments({
    this.name,
    this.types,
    required String id,
  }) : super(
          id: id,
        );

  TypeArguments._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    types = List<InstanceRef>.from(
        createServiceObject(json['types'], const ['InstanceRef']) as List? ??
            []);
  }

  @override
  String get type => 'TypeArguments';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'name': name ?? '',
        'types': types?.map((f) => f.toJson()).toList(),
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is TypeArguments && id == other.id;

  @override
  String toString() => '[TypeArguments id: $id, name: $name, types: $types]';
}

/// `TypeParametersRef` is a reference to a `TypeParameters` object.
class TypeParametersRef extends ObjRef {
  static TypeParametersRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : TypeParametersRef._fromJson(json);

  TypeParametersRef({
    required String id,
  }) : super(
          id: id,
        );

  TypeParametersRef._fromJson(super.json) : super._fromJson();

  @override
  String get type => '@TypeParameters';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      other is TypeParametersRef && id == other.id;

  @override
  String toString() => '[TypeParametersRef id: $id]';
}

/// A `TypeParameters` object represents the type argument vector for some
/// uninstantiated generic type.
class TypeParameters extends Obj implements TypeParametersRef {
  static TypeParameters? parse(Map<String, dynamic>? json) =>
      json == null ? null : TypeParameters._fromJson(json);

  /// The names of the type parameters.
  InstanceRef? names;

  /// The bounds set on each type parameter.
  TypeArgumentsRef? bounds;

  /// The default types for each type parameter.
  TypeArgumentsRef? defaults;

  TypeParameters({
    this.names,
    this.bounds,
    this.defaults,
    required String id,
  }) : super(
          id: id,
        );

  TypeParameters._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    names = createServiceObject(json['names'], const ['InstanceRef'])
        as InstanceRef?;
    bounds = createServiceObject(json['bounds'], const ['TypeArgumentsRef'])
        as TypeArgumentsRef?;
    defaults = createServiceObject(json['defaults'], const ['TypeArgumentsRef'])
        as TypeArgumentsRef?;
  }

  @override
  String get type => 'TypeParameters';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        ...super.toJson(),
        'type': type,
        'names': names?.toJson(),
        'bounds': bounds?.toJson(),
        'defaults': defaults?.toJson(),
      };

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is TypeParameters && id == other.id;

  @override
  String toString() =>
      '[TypeParameters id: $id, names: $names, bounds: $bounds, defaults: $defaults]';
}

/// The `UnresolvedSourceLocation` class is used to refer to an unresolved
/// breakpoint location. As such, it is meant to approximate the final location
/// of the breakpoint but it is not exact.
///
/// Either the `script` or the `scriptUri` field will be present.
///
/// Either the `tokenPos` or the `line` field will be present.
///
/// The `column` field will only be present when the breakpoint was specified
/// with a specific column number.
class UnresolvedSourceLocation extends Response {
  static UnresolvedSourceLocation? parse(Map<String, dynamic>? json) =>
      json == null ? null : UnresolvedSourceLocation._fromJson(json);

  /// The script containing the source location if the script has been loaded.
  @optional
  ScriptRef? script;

  /// The uri of the script containing the source location if the script has yet
  /// to be loaded.
  @optional
  String? scriptUri;

  /// An approximate token position for the source location. This may change
  /// when the location is resolved.
  @optional
  int? tokenPos;

  /// An approximate line number for the source location. This may change when
  /// the location is resolved.
  @optional
  int? line;

  /// An approximate column number for the source location. This may change when
  /// the location is resolved.
  @optional
  int? column;

  UnresolvedSourceLocation({
    this.script,
    this.scriptUri,
    this.tokenPos,
    this.line,
    this.column,
  });

  UnresolvedSourceLocation._fromJson(Map<String, dynamic> json)
      : super._fromJson(json) {
    script =
        createServiceObject(json['script'], const ['ScriptRef']) as ScriptRef?;
    scriptUri = json['scriptUri'];
    tokenPos = json['tokenPos'];
    line = json['line'];
    column = json['column'];
  }

  @override
  String get type => 'UnresolvedSourceLocation';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        if (script?.toJson() case final scriptValue?) 'script': scriptValue,
        if (scriptUri case final scriptUriValue?) 'scriptUri': scriptUriValue,
        if (tokenPos case final tokenPosValue?) 'tokenPos': tokenPosValue,
        if (line case final lineValue?) 'line': lineValue,
        if (column case final columnValue?) 'column': columnValue,
      };

  @override
  String toString() => '[UnresolvedSourceLocation]';
}

class UriList extends Response {
  static UriList? parse(Map<String, dynamic>? json) =>
      json == null ? null : UriList._fromJson(json);

  /// A list of URIs.
  List<String?>? uris;

  UriList({
    this.uris,
  });

  UriList._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    uris = List<String?>.from(json['uris']);
  }

  @override
  String get type => 'UriList';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'uris': uris?.map((f) => f).toList(),
      };

  @override
  String toString() => '[UriList uris: $uris]';
}

/// See [Versioning].
class Version extends Response {
  static Version? parse(Map<String, dynamic>? json) =>
      json == null ? null : Version._fromJson(json);

  /// The major version number is incremented when the protocol is changed in a
  /// potentially incompatible way.
  int? major;

  /// The minor version number is incremented when the protocol is changed in a
  /// backwards compatible way.
  int? minor;

  Version({
    this.major,
    this.minor,
  });

  Version._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    major = json['major'] ?? -1;
    minor = json['minor'] ?? -1;
  }

  @override
  String get type => 'Version';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'major': major ?? -1,
        'minor': minor ?? -1,
      };

  @override
  String toString() => '[Version major: $major, minor: $minor]';
}

/// `VMRef` is a reference to a `VM` object.
class VMRef extends Response {
  static VMRef? parse(Map<String, dynamic>? json) =>
      json == null ? null : VMRef._fromJson(json);

  /// A name identifying this vm. Not guaranteed to be unique.
  String? name;

  VMRef({
    this.name,
  });

  VMRef._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
  }

  @override
  String get type => '@VM';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'name': name ?? '',
      };

  @override
  String toString() => '[VMRef name: $name]';
}

class VM extends Response implements VMRef {
  static VM? parse(Map<String, dynamic>? json) =>
      json == null ? null : VM._fromJson(json);

  /// A name identifying this vm. Not guaranteed to be unique.
  @override
  String? name;

  /// Word length on target architecture (e.g. 32, 64).
  int? architectureBits;

  /// The CPU we are actually running on.
  String? hostCPU;

  /// The operating system we are running on.
  String? operatingSystem;

  /// The CPU we are generating code for.
  String? targetCPU;

  /// The Dart VM version string.
  String? version;

  /// The process id for the VM.
  int? pid;

  /// The time that the VM started in milliseconds since the epoch.
  ///
  /// Suitable to pass to DateTime.fromMillisecondsSinceEpoch.
  int? startTime;

  /// A list of isolates running in the VM.
  List<IsolateRef>? isolates;

  /// A list of isolate groups running in the VM.
  List<IsolateGroupRef>? isolateGroups;

  /// A list of system isolates running in the VM.
  List<IsolateRef>? systemIsolates;

  /// A list of isolate groups which contain system isolates running in the VM.
  List<IsolateGroupRef>? systemIsolateGroups;

  VM({
    this.name,
    this.architectureBits,
    this.hostCPU,
    this.operatingSystem,
    this.targetCPU,
    this.version,
    this.pid,
    this.startTime,
    this.isolates,
    this.isolateGroups,
    this.systemIsolates,
    this.systemIsolateGroups,
  });

  VM._fromJson(Map<String, dynamic> json) : super._fromJson(json) {
    name = json['name'] ?? '';
    architectureBits = json['architectureBits'] ?? -1;
    hostCPU = json['hostCPU'] ?? '';
    operatingSystem = json['operatingSystem'] ?? '';
    targetCPU = json['targetCPU'] ?? '';
    version = json['version'] ?? '';
    pid = json['pid'] ?? -1;
    startTime = json['startTime'] ?? -1;
    isolates = List<IsolateRef>.from(
        createServiceObject(json['isolates'], const ['IsolateRef']) as List? ??
            []);
    isolateGroups = List<IsolateGroupRef>.from(
        createServiceObject(json['isolateGroups'], const ['IsolateGroupRef'])
                as List? ??
            []);
    systemIsolates = List<IsolateRef>.from(
        createServiceObject(json['systemIsolates'], const ['IsolateRef'])
                as List? ??
            []);
    systemIsolateGroups = List<IsolateGroupRef>.from(createServiceObject(
            json['systemIsolateGroups'], const ['IsolateGroupRef']) as List? ??
        []);
  }

  @override
  String get type => 'VM';

  @override
  Map<String, dynamic> toJson() => <String, Object?>{
        'type': type,
        'name': name ?? '',
        'architectureBits': architectureBits ?? -1,
        'hostCPU': hostCPU ?? '',
        'operatingSystem': operatingSystem ?? '',
        'targetCPU': targetCPU ?? '',
        'version': version ?? '',
        'pid': pid ?? -1,
        'startTime': startTime ?? -1,
        'isolates': isolates?.map((f) => f.toJson()).toList(),
        'isolateGroups': isolateGroups?.map((f) => f.toJson()).toList(),
        'systemIsolates': systemIsolates?.map((f) => f.toJson()).toList(),
        'systemIsolateGroups':
            systemIsolateGroups?.map((f) => f.toJson()).toList(),
      };

  @override
  String toString() => '[VM]';
}
