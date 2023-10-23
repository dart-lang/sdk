// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a generated file. To regenerate, run `dart tool/generate.dart`.

/// A library providing an interface to implement the VM Service Protocol.
library;

// ignore_for_file: overridden_fields

import 'dart:async';

import 'package:vm_service/vm_service.dart'
    hide ServiceExtensionRegistry, VmServerConnection, VmServiceInterface;

import 'service_extension_registry.dart';

export 'service_extension_registry.dart' show ServiceExtensionRegistry;

const String vmServiceVersion = '4.13.0';

/// A class representation of the Dart VM Service Protocol.
abstract interface class VmServiceInterface {
  /// Returns the stream for a given stream id.
  ///
  /// This is not a part of the spec, but is needed for both the client and
  /// server to get access to the real event streams.
  Stream<Event> onEvent(String streamId);

  /// Handler for calling extra service extensions.
  Future<Response> callServiceExtension(String method,
      {String? isolateId, Map<String, dynamic>? args});

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
  Future<Breakpoint> addBreakpointAtEntry(String isolateId, String functionId);

  /// Clears all CPU profiling samples.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> clearCpuSamples(String isolateId);

  /// Clears all VM timeline events.
  ///
  /// See [Success].
  Future<Success> clearVMTimeline();

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
      {bool? reset, bool? gc});

  /// The `getAllocationTraces` RPC allows for the retrieval of allocation
  /// traces for objects of a specific set of types (see
  /// [VmServiceInterface.setTraceClassAllocation]). Only samples collected in
  /// the time range `[timeOriginMicros, timeOriginMicros + timeExtentMicros]`
  /// will be reported.
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
  Future<ClassList> getClassList(String isolateId);

  /// The `getCpuSamples` RPC is used to retrieve samples collected by the CPU
  /// profiler. See [CpuSamples] for a detailed description of the response.
  ///
  /// The `timeOriginMicros` parameter is the beginning of the time range used
  /// to filter samples. It uses the same monotonic clock as dart:developer's
  /// `Timeline.now` and the VM embedding API's `Dart_TimelineGetMicros`. See
  /// [VmServiceInterface.getVMTimelineMicros] for access to this clock through
  /// the service protocol.
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
      String isolateId, int timeOriginMicros, int timeExtentMicros);

  /// The `getFlagList` RPC returns a list of all command line flags in the VM
  /// along with their current values.
  ///
  /// See [FlagList].
  Future<FlagList> getFlagList();

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
      String isolateId, String targetId, int limit);

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
  Future<Isolate> getIsolate(String isolateId);

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
  Future<IsolateGroup> getIsolateGroup(String isolateGroupId);

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
  Future<Event> getIsolatePauseEvent(String isolateId);

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
  Future<MemoryUsage> getMemoryUsage(String isolateId);

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
  Future<MemoryUsage> getIsolateGroupMemoryUsage(String isolateGroupId);

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
  Future<ScriptList> getScripts(String isolateId);

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
  });

  /// The `getPerfettoCpuSamples` RPC is used to retrieve samples collected by
  /// the CPU profiler, serialized in Perfetto's proto format. See
  /// [PerfettoCpuSamples] for a detailed description of the response.
  ///
  /// The `timeOriginMicros` parameter is the beginning of the time range used
  /// to filter samples. It uses the same monotonic clock as dart:developer's
  /// `Timeline.now` and the VM embedding API's `Dart_TimelineGetMicros`. See
  /// [VmServiceInterface.getVMTimelineMicros] for access to this clock through
  /// the service protocol.
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
      {int? timeOriginMicros, int? timeExtentMicros});

  /// The `getPerfettoVMTimeline` RPC is used to retrieve an object which
  /// contains a VM timeline trace represented in Perfetto's proto format. See
  /// [PerfettoTimeline] for a detailed description of the response.
  ///
  /// The `timeOriginMicros` parameter is the beginning of the time range used
  /// to filter timeline events. It uses the same monotonic clock as
  /// dart:developer's `Timeline.now` and the VM embedding API's
  /// `Dart_TimelineGetMicros`. See [VmServiceInterface.getVMTimelineMicros] for
  /// access to this clock through the service protocol.
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
      {int? timeOriginMicros, int? timeExtentMicros});

  /// The `getPorts` RPC is used to retrieve the list of `ReceivePort` instances
  /// for a given isolate.
  ///
  /// See [PortList].
  Future<PortList> getPorts(String isolateId);

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
      String isolateId, String targetId, int limit);

  /// Returns a description of major uses of memory known to the VM.
  ///
  /// Adding or removing buckets is considered a backwards-compatible change for
  /// the purposes of versioning. A client must gracefully handle the removal or
  /// addition of any bucket.
  Future<ProcessMemoryUsage> getProcessMemoryUsage();

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
  Future<Stack> getStack(String isolateId, {int? limit});

  /// The `getSupportedProtocols` RPC is used to determine which protocols are
  /// supported by the current server.
  ///
  /// The result of this call should be intercepted by any middleware that
  /// extends the core VM service protocol and should add its own protocol to
  /// the list of protocols before forwarding the response to the client.
  ///
  /// See [ProtocolList].
  Future<ProtocolList> getSupportedProtocols();

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
  });

  /// The `getVersion` RPC is used to determine what version of the Service
  /// Protocol is served by a VM.
  ///
  /// See [Version].
  Future<Version> getVersion();

  /// The `getVM` RPC returns global information about a Dart virtual machine.
  ///
  /// See [VM].
  Future<VM> getVM();

  /// The `getVMTimeline` RPC is used to retrieve an object which contains VM
  /// timeline events. See [Timeline] for a detailed description of the
  /// response.
  ///
  /// The `timeOriginMicros` parameter is the beginning of the time range used
  /// to filter timeline events. It uses the same monotonic clock as
  /// dart:developer's `Timeline.now` and the VM embedding API's
  /// `Dart_TimelineGetMicros`. See [VmServiceInterface.getVMTimelineMicros] for
  /// access to this clock through the service protocol.
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
      {int? timeOriginMicros, int? timeExtentMicros});

  /// The `getVMTimelineFlags` RPC returns information about the current VM
  /// timeline configuration.
  ///
  /// To change which timeline streams are currently enabled, see
  /// [VmServiceInterface.setVMTimelineFlags].
  ///
  /// See [TimelineFlags].
  Future<TimelineFlags> getVMTimelineFlags();

  /// The `getVMTimelineMicros` RPC returns the current time stamp from the
  /// clock used by the timeline, similar to `Timeline.now` in `dart:developer`
  /// and `Dart_TimelineGetMicros` in the VM embedding API.
  ///
  /// See [Timestamp] and [VmServiceInterface.getVMTimeline].
  Future<Timestamp> getVMTimelineMicros();

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
  Future<Success> pause(String isolateId);

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
  Future<Success> kill(String isolateId);

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
      {bool? local});

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
  Future<UriList> lookupPackageUris(String isolateId, List<String> uris);

  /// Registers a service that can be invoked by other VM service clients, where
  /// `service` is the name of the service to advertise and `alias` is an
  /// alternative name for the registered service.
  ///
  /// Requests made to the new service will be forwarded to the client which
  /// originally registered the service.
  ///
  /// See [Success].
  Future<Success> registerService(String service, String alias);

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
  Future<Success> removeBreakpoint(String isolateId, String breakpointId);

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
  Future<Success> requestHeapSnapshot(String isolateId);

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
      {/*StepOption*/ String? step, int? frameIndex});

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
      String isolateId, String breakpointId, bool enable);

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
      String isolateId, /*ExceptionPauseMode*/ String mode);

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
      bool? shouldPauseOnExit});

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
  Future<Response> setFlag(String name, String value);

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
      String isolateId, String libraryId, bool isDebuggable);

  /// The `setName` RPC is used to change the debugging name for an isolate.
  ///
  /// If `isolateId` refers to an isolate which has exited, then the `Collected`
  /// [Sentinel] is returned.
  ///
  /// See [Success].
  ///
  /// This method will throw a [SentinelException] in the case a [Sentinel] is
  /// returned.
  Future<Success> setName(String isolateId, String name);

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
      String isolateId, String classId, bool enable);

  /// The `setVMName` RPC is used to change the debugging name for the vm.
  ///
  /// See [Success].
  Future<Success> setVMName(String name);

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
  /// [VmServiceInterface.getVMTimelineFlags].
  ///
  /// See [Success].
  Future<Success> setVMTimelineFlags(List<String> recordedStreams);

  /// The `streamCancel` RPC cancels a stream subscription in the VM.
  ///
  /// If the client is not subscribed to the stream, the `104` (Stream not
  /// subscribed) RPC error code is returned.
  ///
  /// See [Success].
  Future<Success> streamCancel(String streamId);

  /// The `streamCpuSamplesWithUserTag` RPC allows for clients to specify which
  /// CPU samples collected by the profiler should be sent over the `Profiler`
  /// stream. When called, the VM will stream `CpuSamples` events containing
  /// `CpuSample`'s collected while a user tag contained in `userTags` was
  /// active.
  ///
  /// See [Success].
  Future<Success> streamCpuSamplesWithUserTag(List<String> userTags);

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
  Future<Success> streamListen(String streamId);
}

class _PendingServiceRequest {
  Future<Map<String, Object?>> get future => _completer.future;
  final _completer = Completer<Map<String, Object?>>();

  final dynamic originalId;

  _PendingServiceRequest(this.originalId);

  void complete(Map<String, Object?> response) {
    response['id'] = originalId;
    _completer.complete(response);
  }
}

/// A Dart VM Service Protocol connection that delegates requests to a
/// [VmServiceInterface] implementation.
///
/// One of these should be created for each client, but they should generally
/// share the same [VmServiceInterface] and [ServiceExtensionRegistry]
/// instances.
class VmServerConnection {
  final Stream<Map<String, Object>> _requestStream;
  final StreamSink<Map<String, Object?>> _responseSink;
  final ServiceExtensionRegistry _serviceExtensionRegistry;
  final VmServiceInterface _serviceImplementation;

  /// Used to create unique ids when acting as a proxy between clients.
  int _nextServiceRequestId = 0;

  /// Manages streams for `streamListen` and `streamCancel` requests.
  final _streamSubscriptions = <String, StreamSubscription>{};

  /// Completes when [_requestStream] is done.
  Future<void> get done => _doneCompleter.future;
  final _doneCompleter = Completer<void>();

  /// Pending service extension requests to this client by id.
  final _pendingServiceExtensionRequests = <dynamic, _PendingServiceRequest>{};

  VmServerConnection(this._requestStream, this._responseSink,
      this._serviceExtensionRegistry, this._serviceImplementation) {
    _requestStream.listen(_delegateRequest, onDone: _doneCompleter.complete);
    done.then((_) {
      for (var sub in _streamSubscriptions.values) {
        sub.cancel();
      }
    });
  }

  /// Invoked when the current client has registered some extension, and
  /// another client sends an RPC request for that extension.
  ///
  /// We don't attempt to do any serialization or deserialization of the
  /// request or response in this case
  Future<Map<String, Object?>> _forwardServiceExtensionRequest(
      Map<String, Object?> request) {
    final originalId = request['id'];
    request = Map<String, Object?>.of(request);
    // Modify the request ID to ensure we don't have conflicts between
    // multiple clients ids.
    final newId = '${_nextServiceRequestId++}:$originalId';
    request['id'] = newId;
    var pendingRequest = _PendingServiceRequest(originalId);
    _pendingServiceExtensionRequests[newId] = pendingRequest;
    _responseSink.add(request);
    return pendingRequest.future;
  }

  void _delegateRequest(Map<String, Object?> request) async {
    try {
      var id = request['id'];
      // Check if this is actually a response to a pending request.
      if (_pendingServiceExtensionRequests.containsKey(id)) {
        final pending = _pendingServiceExtensionRequests[id]!;
        pending.complete(Map<String, Object?>.of(request));
        return;
      }
      final method = request['method'] as String?;
      if (method == null) {
        throw RPCError(null, RPCErrorKind.kInvalidRequest.code,
            'Invalid Request', request);
      }
      final params = request['params'] as Map<String, dynamic>?;
      late Response response;

      switch (method) {
        case 'registerService':
          _serviceExtensionRegistry.registerExtension(params!['service'], this);
          response = Success();
          break;
        case 'addBreakpoint':
          response = await _serviceImplementation.addBreakpoint(
            params!['isolateId'],
            params['scriptId'],
            params['line'],
            column: params['column'],
          );
          break;
        case 'addBreakpointWithScriptUri':
          response = await _serviceImplementation.addBreakpointWithScriptUri(
            params!['isolateId'],
            params['scriptUri'],
            params['line'],
            column: params['column'],
          );
          break;
        case 'addBreakpointAtEntry':
          response = await _serviceImplementation.addBreakpointAtEntry(
            params!['isolateId'],
            params['functionId'],
          );
          break;
        case 'clearCpuSamples':
          response = await _serviceImplementation.clearCpuSamples(
            params!['isolateId'],
          );
          break;
        case 'clearVMTimeline':
          response = await _serviceImplementation.clearVMTimeline();
          break;
        case 'invoke':
          response = await _serviceImplementation.invoke(
            params!['isolateId'],
            params['targetId'],
            params['selector'],
            List<String>.from(params['argumentIds'] ?? []),
            disableBreakpoints: params['disableBreakpoints'],
          );
          break;
        case 'evaluate':
          response = await _serviceImplementation.evaluate(
            params!['isolateId'],
            params['targetId'],
            params['expression'],
            scope: params['scope']?.cast<String, String>(),
            disableBreakpoints: params['disableBreakpoints'],
          );
          break;
        case 'evaluateInFrame':
          response = await _serviceImplementation.evaluateInFrame(
            params!['isolateId'],
            params['frameIndex'],
            params['expression'],
            scope: params['scope']?.cast<String, String>(),
            disableBreakpoints: params['disableBreakpoints'],
          );
          break;
        case 'getAllocationProfile':
          response = await _serviceImplementation.getAllocationProfile(
            params!['isolateId'],
            reset: params['reset'],
            gc: params['gc'],
          );
          break;
        case 'getAllocationTraces':
          response = await _serviceImplementation.getAllocationTraces(
            params!['isolateId'],
            timeOriginMicros: params['timeOriginMicros'],
            timeExtentMicros: params['timeExtentMicros'],
            classId: params['classId'],
          );
          break;
        case 'getClassList':
          response = await _serviceImplementation.getClassList(
            params!['isolateId'],
          );
          break;
        case 'getCpuSamples':
          response = await _serviceImplementation.getCpuSamples(
            params!['isolateId'],
            params['timeOriginMicros'],
            params['timeExtentMicros'],
          );
          break;
        case 'getFlagList':
          response = await _serviceImplementation.getFlagList();
          break;
        case 'getInboundReferences':
          response = await _serviceImplementation.getInboundReferences(
            params!['isolateId'],
            params['targetId'],
            params['limit'],
          );
          break;
        case 'getInstances':
          response = await _serviceImplementation.getInstances(
            params!['isolateId'],
            params['objectId'],
            params['limit'],
            includeSubclasses: params['includeSubclasses'],
            includeImplementers: params['includeImplementers'],
          );
          break;
        case 'getInstancesAsList':
          response = await _serviceImplementation.getInstancesAsList(
            params!['isolateId'],
            params['objectId'],
            includeSubclasses: params['includeSubclasses'],
            includeImplementers: params['includeImplementers'],
          );
          break;
        case 'getIsolate':
          response = await _serviceImplementation.getIsolate(
            params!['isolateId'],
          );
          break;
        case 'getIsolateGroup':
          response = await _serviceImplementation.getIsolateGroup(
            params!['isolateGroupId'],
          );
          break;
        case 'getIsolatePauseEvent':
          response = await _serviceImplementation.getIsolatePauseEvent(
            params!['isolateId'],
          );
          break;
        case 'getMemoryUsage':
          response = await _serviceImplementation.getMemoryUsage(
            params!['isolateId'],
          );
          break;
        case 'getIsolateGroupMemoryUsage':
          response = await _serviceImplementation.getIsolateGroupMemoryUsage(
            params!['isolateGroupId'],
          );
          break;
        case 'getScripts':
          response = await _serviceImplementation.getScripts(
            params!['isolateId'],
          );
          break;
        case 'getObject':
          response = await _serviceImplementation.getObject(
            params!['isolateId'],
            params['objectId'],
            offset: params['offset'],
            count: params['count'],
          );
          break;
        case 'getPerfettoCpuSamples':
          response = await _serviceImplementation.getPerfettoCpuSamples(
            params!['isolateId'],
            timeOriginMicros: params['timeOriginMicros'],
            timeExtentMicros: params['timeExtentMicros'],
          );
          break;
        case 'getPerfettoVMTimeline':
          response = await _serviceImplementation.getPerfettoVMTimeline(
            timeOriginMicros: params!['timeOriginMicros'],
            timeExtentMicros: params['timeExtentMicros'],
          );
          break;
        case 'getPorts':
          response = await _serviceImplementation.getPorts(
            params!['isolateId'],
          );
          break;
        case 'getRetainingPath':
          response = await _serviceImplementation.getRetainingPath(
            params!['isolateId'],
            params['targetId'],
            params['limit'],
          );
          break;
        case 'getProcessMemoryUsage':
          response = await _serviceImplementation.getProcessMemoryUsage();
          break;
        case 'getStack':
          response = await _serviceImplementation.getStack(
            params!['isolateId'],
            limit: params['limit'],
          );
          break;
        case 'getSupportedProtocols':
          response = await _serviceImplementation.getSupportedProtocols();
          break;
        case 'getSourceReport':
          response = await _serviceImplementation.getSourceReport(
            params!['isolateId'],
            List<String>.from(params['reports'] ?? []),
            scriptId: params['scriptId'],
            tokenPos: params['tokenPos'],
            endTokenPos: params['endTokenPos'],
            forceCompile: params['forceCompile'],
            reportLines: params['reportLines'],
            libraryFilters: params['libraryFilters'],
            librariesAlreadyCompiled: params['librariesAlreadyCompiled'],
          );
          break;
        case 'getVersion':
          response = await _serviceImplementation.getVersion();
          break;
        case 'getVM':
          response = await _serviceImplementation.getVM();
          break;
        case 'getVMTimeline':
          response = await _serviceImplementation.getVMTimeline(
            timeOriginMicros: params!['timeOriginMicros'],
            timeExtentMicros: params['timeExtentMicros'],
          );
          break;
        case 'getVMTimelineFlags':
          response = await _serviceImplementation.getVMTimelineFlags();
          break;
        case 'getVMTimelineMicros':
          response = await _serviceImplementation.getVMTimelineMicros();
          break;
        case 'pause':
          response = await _serviceImplementation.pause(
            params!['isolateId'],
          );
          break;
        case 'kill':
          response = await _serviceImplementation.kill(
            params!['isolateId'],
          );
          break;
        case 'lookupResolvedPackageUris':
          response = await _serviceImplementation.lookupResolvedPackageUris(
            params!['isolateId'],
            List<String>.from(params['uris'] ?? []),
            local: params['local'],
          );
          break;
        case 'lookupPackageUris':
          response = await _serviceImplementation.lookupPackageUris(
            params!['isolateId'],
            List<String>.from(params['uris'] ?? []),
          );
          break;
        case 'reloadSources':
          response = await _serviceImplementation.reloadSources(
            params!['isolateId'],
            force: params['force'],
            pause: params['pause'],
            rootLibUri: params['rootLibUri'],
            packagesUri: params['packagesUri'],
          );
          break;
        case 'removeBreakpoint':
          response = await _serviceImplementation.removeBreakpoint(
            params!['isolateId'],
            params['breakpointId'],
          );
          break;
        case 'requestHeapSnapshot':
          response = await _serviceImplementation.requestHeapSnapshot(
            params!['isolateId'],
          );
          break;
        case 'resume':
          response = await _serviceImplementation.resume(
            params!['isolateId'],
            step: params['step'],
            frameIndex: params['frameIndex'],
          );
          break;
        case 'setBreakpointState':
          response = await _serviceImplementation.setBreakpointState(
            params!['isolateId'],
            params['breakpointId'],
            params['enable'],
          );
          break;
        case 'setExceptionPauseMode':
          // ignore: deprecated_member_use_from_same_package
          response = await _serviceImplementation.setExceptionPauseMode(
            params!['isolateId'],
            params['mode'],
          );
          break;
        case 'setIsolatePauseMode':
          response = await _serviceImplementation.setIsolatePauseMode(
            params!['isolateId'],
            exceptionPauseMode: params['exceptionPauseMode'],
            shouldPauseOnExit: params['shouldPauseOnExit'],
          );
          break;
        case 'setFlag':
          response = await _serviceImplementation.setFlag(
            params!['name'],
            params['value'],
          );
          break;
        case 'setLibraryDebuggable':
          response = await _serviceImplementation.setLibraryDebuggable(
            params!['isolateId'],
            params['libraryId'],
            params['isDebuggable'],
          );
          break;
        case 'setName':
          response = await _serviceImplementation.setName(
            params!['isolateId'],
            params['name'],
          );
          break;
        case 'setTraceClassAllocation':
          response = await _serviceImplementation.setTraceClassAllocation(
            params!['isolateId'],
            params['classId'],
            params['enable'],
          );
          break;
        case 'setVMName':
          response = await _serviceImplementation.setVMName(
            params!['name'],
          );
          break;
        case 'setVMTimelineFlags':
          response = await _serviceImplementation.setVMTimelineFlags(
            List<String>.from(params!['recordedStreams'] ?? []),
          );
          break;
        case 'streamCancel':
          var id = params!['streamId'];
          var existing = _streamSubscriptions.remove(id);
          if (existing == null) {
            throw RPCError.withDetails(
              'streamCancel',
              104,
              'Stream not subscribed',
              details: "The stream '$id' is not subscribed",
            );
          }
          await existing.cancel();
          response = Success();
          break;
        case 'streamCpuSamplesWithUserTag':
          response = await _serviceImplementation.streamCpuSamplesWithUserTag(
            List<String>.from(params!['userTags'] ?? []),
          );
          break;
        case 'streamListen':
          var id = params!['streamId'];
          if (_streamSubscriptions.containsKey(id)) {
            throw RPCError.withDetails(
              'streamListen',
              103,
              'Stream already subscribed',
              details: "The stream '$id' is already subscribed",
            );
          }

          var stream = id == 'Service'
              ? _serviceExtensionRegistry.onExtensionEvent
              : _serviceImplementation.onEvent(id);
          _streamSubscriptions[id] = stream.listen((e) {
            _responseSink.add({
              'jsonrpc': '2.0',
              'method': 'streamNotify',
              'params': {
                'streamId': id,
                'event': e.toJson(),
              },
            });
          });
          response = Success();
          break;
        default:
          final registeredClient = _serviceExtensionRegistry.clientFor(method);
          if (registeredClient != null) {
            // Check for any client which has registered this extension, if we
            // have one then delegate the request to that client.
            _responseSink.add(await registeredClient
                ._forwardServiceExtensionRequest(request));
            // Bail out early in this case, we are just acting as a proxy and
            // never get a `Response` instance.
            return;
          } else if (method.startsWith('ext.')) {
            // Remaining methods with `ext.` are assumed to be registered via
            // dart:developer, which the service implementation handles.
            final args =
                params == null ? null : Map<String, dynamic>.of(params);
            final isolateId = args?.remove('isolateId');
            response = await _serviceImplementation.callServiceExtension(method,
                isolateId: isolateId, args: args);
          } else {
            throw RPCError(method, RPCErrorKind.kMethodNotFound.code,
                'Method not found', request);
          }
      }
      _responseSink.add({
        'jsonrpc': '2.0',
        'id': id,
        'result': response.toJson(),
      });
    } on SentinelException catch (e) {
      _responseSink.add({
        'jsonrpc': '2.0',
        'id': request['id'],
        'result': e.sentinel.toJson(),
      });
    } catch (e, st) {
      final error = e is RPCError
          ? e.toMap()
          : {
              'code': RPCErrorKind.kInternalError.code,
              'message': '${request['method']}: $e',
              'data': {'details': '$st'},
            };
      _responseSink.add({
        'jsonrpc': '2.0',
        'id': request['id'],
        'error': error,
      });
    }
  }
}
