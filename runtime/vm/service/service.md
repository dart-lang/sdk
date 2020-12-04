# Dart VM Service Protocol 3.42

> Please post feedback to the [observatory-discuss group][discuss-list]

This document describes of _version 3.42_ of the Dart VM Service Protocol. This
protocol is used to communicate with a running Dart Virtual Machine.

To use the Service Protocol, start the VM with the *--observe* flag.
The VM will start a webserver which services protocol requests via WebSocket.
It is possible to make HTTP (non-WebSocket) requests,
but this does not allow access to VM _events_ and is not documented
here.

[Service Protocol Extension](service_extension.md) provides similar ways to
communicate with the VM except these may be only accessible through some
libraries.

The Service Protocol uses [JSON-RPC 2.0][].

[JSON-RPC 2.0]: http://www.jsonrpc.org/specification

**Table of Contents**

- [RPCs, Requests, and Responses](#rpcs-requests-and-responses)
- [Events](#events)
- [Types](#types)
- [IDs and Names](#ids-and-names)
- [Versioning](#versioning)
- [Private RPCs, Types, and Properties](#private-rpcs-types-and-properties)
- [Middleware Support](#middleware-support)
  - [Single Client Mode](#single-client-mode)
  - [Protocol Extensions](#protocol-extensions)
- [Public RPCs](#public-rpcs)
  - [addBreakpoint](#addbreakpoint)
  - [addBreakpointWithScriptUri](#addbreakpointwithscripturi)
  - [addBreakpointAtEntry](#addbreakpointatentry)
  - [clearCpuSamples](#clearcpusamples)
  - [clearVMTimeline](#clearvmtimeline)
  - [evaluate](#evaluate)
  - [evaluateInFrame](#evaluateinframe)
  - [getAllocationProfile](#getallocationprofile)
  - [getCpuSamples](#getcpusamples)
  - [getFlagList](#getflaglist)
  - [getInstances](#getinstances)
  - [getInboundReferences](#getinboundreferences)
  - [getIsolate](#getisolate)
  - [getIsolateGroup](#getisolategroup)
  - [getMemoryUsage](#getmemoryusage)
  - [getObject](#getobject)
  - [getPorts](#getports)
  - [getProcessMemoryUsage](#getprocessmemoryusage)
  - [getRetainingPath](#getretainingpath)
  - [getScripts](#getscripts)
  - [getSourceReport](#getsourcereport)
  - [getStack](#getstack)
  - [getSupportedProtocols](#getsupportedprotocols)
  - [getVersion](#getversion)
  - [getVM](#getvm)
  - [getVMTimeline](#getvmtimeline)
  - [getVMTimelineFlags](#getvmtimelineflags)
  - [getVMTimelineMicros](#getvmtimelinemicros)
  - [invoke](#invoke)
  - [pause](#pause)
  - [kill](#kill)
  - [registerService](#registerService)
  - [reloadSources](#reloadsources)
  - [removeBreakpoint](#removebreakpoint)
  - [resume](#resume)
  - [setExceptionPauseMode](#setexceptionpausemode)
  - [setFlag](#setflag)
  - [setLibraryDebuggable](#setlibrarydebuggable)
  - [setName](#setname)
  - [setVMName](#setvmname)
  - [setVMTimelineFlags](#setvmtimelineflags)
  - [streamCancel](#streamcancel)
  - [streamListen](#streamlisten)
- [Public Types](#public-types)
  - [AllocationProfile](#allocationprofile)
  - [BoundField](#boundfield)
  - [BoundVariable](#boundvariable)
  - [Breakpoint](#breakpoint)
  - [Class](#class)
  - [ClassHeapStats](#classheapstats)
  - [ClassList](#classlist)
  - [Code](#code)
  - [CodeKind](#codekind)
  - [Context](#context)
  - [ContextElement](#contextelement)
  - [CpuSamples](#cpusamples)
  - [CpuSample](#cpusample)
  - [Error](#error)
  - [ErrorKind](#errorkind)
  - [Event](#event)
  - [EventKind](#eventkind)
  - [ExtensionData](#extensiondata)
  - [Field](#field)
  - [Flag](#flag)
  - [FlagList](#flaglist)
  - [Frame](#frame)
  - [Function](#function)
  - [InboundReferences](#inboundreferences)
  - [InboundReference](#inboundreference)
  - [Instance](#instance)
  - [InstanceSet](#instanceset)
  - [Isolate](#isolate)
  - [IsolateFlag](#isolateflag)
  - [IsolateGroup](#isolategroup)
  - [Library](#library)
  - [LibraryDependency](#librarydependency)
  - [LogRecord](#logrecord)
  - [MapAssociation](#mapassociation)
  - [MemoryUsage](#memoryusage)
  - [Message](#message)
  - [NativeFunction](#nativefunction)
  - [Null](#null)
  - [Object](#object)
  - [PortList](#portlist)
  - [ReloadReport](#reloadreport)
  - [Response](#response)
  - [RetainingObject](#retainingobject)
  - [RetainingPath](#retainingpath)
  - [Sentinel](#sentinel)
  - [SentinelKind](#sentinelkind)
  - [Script](#script)
  - [ScriptList](#scriptlist)
  - [SourceLocation](#sourcelocation)
  - [SourceReport](#sourcereport)
  - [SourceReportCoverage](#sourcereportcoverage)
  - [SourceReportKind](#sourcereportkind)
  - [SourceReportRange](#sourcereportrange)
  - [Stack](#stack)
  - [StepOption](#stepoption)
  - [Success](#success)
  - [Timeline](#timeline)
  - [TimelineEvent](#timelineevent)
  - [TimelineFlags](#timelineflags)
  - [Timestamp](#timestamp)
  - [TypeArguments](#typearguments)
  - [UresolvedSourceLocation](#unresolvedsourcelocation)
  - [Version](#version)
  - [VM](#vm)
  - [WebSocketTarget](#websockettarget)
- [Revision History](#revision-history)

## RPCs, Requests, and Responses

An RPC request is a JSON object sent to the server. Here is an
example [getVersion](#getversion) request:

```
{
  "jsonrpc": "2.0",
  "method": "getVersion",
  "params": {},
  "id": "1"
}
```

The _id_ property must be a string, number, or `null`. The Service Protocol
optionally accepts requests without the _jsonprc_ property.

An RPC response is a JSON object (http://json.org/). The response always specifies an
_id_ property to pair it with the corresponding request. If the RPC
was successful, the _result_ property provides the result.

Here is an example response for our [getVersion](#getversion) request above:

```
{
  "jsonrpc": "2.0",
  "result": {
    "type": "Version",
    "major": 3,
    "minor": 5
  }
  "id": "1"
}
```

Parameters for RPC requests are always provided as _named_ parameters.
The JSON-RPC spec provides for _positional_ parameters as well, but they
are not supported by the Dart VM.

By convention, every response returned by the Service Protocol is a subtype
of [Response](#response) and provides a _type_ parameter which can be used
to distinguish the exact return type. In the example above, the
[Version](#version) type is returned.

Here is an example [streamListen](#streamlisten) request which provides
a parameter:

```
{
  "jsonrpc": "2.0",
  "method": "streamListen",
  "params": {
    "streamId": "GC"
  },
  "id": "2"
}
```

<a name="rpc-error"></a>
When an RPC encounters an error, it is provided in the _error_
property of the response object. JSON-RPC errors always provide
_code_, _message_, and _data_ properties.

Here is an example error response for our [streamListen](#streamlisten)
request above. This error would be generated if we were attempting to
subscribe to the _GC_ stream multiple times from the same client.

```
{
  "jsonrpc": "2.0",
  "error": {
    "code": 103,
    "message": "Stream already subscribed",
    "data": {
      "details": "The stream 'GC' is already subscribed"
    }
  }
  "id": "2"
}
```

In addition to the [error codes](http://www.jsonrpc.org/specification#error_object) specified in the JSON-RPC spec, we use the following application specific error codes:

code | message | meaning
---- | ------- | -------
100 | Feature is disabled | The operation is unable to complete because a feature is disabled
101 | VM must be paused | This operation is only valid when the VM is paused
102 | Cannot add breakpoint | The VM is unable to add a breakpoint at the specified line or function
103 | Stream already subscribed | The client is already subscribed to the specified _streamId_
104 | Stream not subscribed | The client is not subscribed to the specified _streamId_
105 | Isolate must be runnable | This operation cannot happen until the isolate is runnable
106 | Isolate must be paused | This operation is only valid when the isolate is paused
107 | Cannot resume execution | The isolate could not be resumed
108 | Isolate is reloading | The isolate is currently processing another reload request
109 | Isolate cannot be reloaded | The isolate has an unhandled exception and can no longer be reloaded
110 | Isolate must have reloaded | Failed to find differences in last hot reload request
111 | Service already registered | Service with such name has already been registered by this client
112 | Service disappeared | Failed to fulfill service request, likely service handler is no longer available
113 | Expression compilation error | Request to compile expression failed
114 | Invalid timeline request | The timeline related request could not be completed due to the current configuration

## Events

By using the [streamListen](#streamlisten) and [streamCancel](#streamcancel) RPCs, a client may
request to be notified when an _event_ is posted to a specific
_stream_ in the VM. Every stream has an associated _stream id_ which
is used to name that stream.

Each stream provides access to certain kinds of events. For example the _Isolate_ stream provides
access to events pertaining to isolate births, deaths, and name changes. See [streamListen](#streamlisten)
for a list of the well-known stream ids and their associated events.

Stream events arrive asynchronously over the WebSocket. They're structured as
JSON-RPC 2.0 requests with no _id_ property. The _method_ property will be
_streamNotify_, and the _params_ will have _streamId_ and _event_ properties:

```json
{
  "json-rpc": "2.0",
  "method": "streamNotify",
  "params": {
    "streamId": "Isolate",
    "event": {
      "type": "Event",
      "kind": "IsolateExit",
      "isolate": {
        "type": "@Isolate",
        "id": "isolates/33",
        "number": "51048743613",
        "name": "worker-isolate"
      }
    }
  }
}
```

It is considered a _backwards compatible_ change to add a new type of event to an existing stream.
Clients should be written to handle this gracefully.

## Binary Events

Some events are associated with bulk binary data. These events are delivered as
WebSocket binary frames instead of text frames. A binary event's metadata
should be interpreted as UTF-8 encoded JSON, with the same properties as
described above for ordinary events.

```
type BinaryEvent {
  dataOffset : uint32,
  metadata : uint8[dataOffset-4],
  data : uint8[],
}
```

## Types

By convention, every result and event provided by the Service Protocol
is a subtype of [Response](#response) and has the _type_ property.
This allows the client to distinguish different kinds of responses. For example,
information about a Dart function is returned using the [Function](#function) type.

If the type of a response begins with the _@_ character, then that
response is a _reference_. If the type name of a response does not
begin with the _@_ character, it is an _object_. A reference is
intended to be a subset of an object which provides enough information
to generate a reasonable looking reference to the object.

For example, an [@Isolate](#isolate) reference has the _type_, _id_, _name_ and
_number_ properties:

```
  "result": {
    "type": "@Isolate",
    "id": "isolates/33",
    "number": "51048743613"
    "name": "worker-isolate"
  }
```

But an [Isolate](#isolate) object has more information:

```
  "result": {
    "type": "Isolate",
    "id": "isolates/33",
    "number": "51048743613"
    "name": "worker-isolate"
    "rootLib": { ... }
    "entry": ...
    "heaps": ...
     ...
  }
```

## IDs and Names

Many responses returned by the Service Protocol have an _id_ property.
This is an identifier used to request an object from an isolate using
the [getObject](#getobject) RPC. If two responses have the same _id_ then they
refer to the same object. The converse is not true: the same object
may sometimes be returned with two different values for _id_.

The _id_ property should be treated as an opaque string by the client:
it is not meant to be parsed.

An id can be either _temporary_ or _fixed_:

* A _temporary_ id can expire over time. The VM allocates certain ids
  in a ring which evicts old ids over time.

* A _fixed_ id will never expire, but the object it refers to may
  be collected. The VM uses fixed ids for objects like scripts,
  libraries, and classes.

If an id is fixed, the _fixedId_ property will be true. If an id is temporary
the _fixedId_ property will be omitted.

Sometimes a temporary id may expire. In this case, some RPCs may return
an _Expired_ [Sentinel](#sentinel) to indicate this.

The object referred to by an id may be collected by the VM's garbage
collector. In this case, some RPCs may return a _Collected_ [Sentinel](#sentinel)
to indicate this.

Many objects also have a _name_ property. This is provided so that
objects can be displayed in a way that a Dart language programmer
would find familiar. Names are not unique.

## Versioning

The [getVersion](#getversion) RPC can be used to find the version of the protocol
returned by a VM. The _Version_ response has a major and a minor
version number:

```
  "result": {
    "type": "Version",
    "major": 3,
    "minor": 5
  }
```

The major version number is incremented when the protocol is changed
in a potentially _incompatible_ way. An example of an incompatible
change is removing a non-optional property from a result.

The minor version number is incremented when the protocol is changed
in a _backwards compatible_ way. An example of a backwards compatible
change is adding a property to a result.

Certain changes that would normally not be backwards compatible are
considered backwards compatible for the purposes of versioning.
Specifically, additions can be made to the [EventKind](#eventkind) and
[InstanceKind](#instancekind) enumerated types and the client must
handle this gracefully. See the notes on these enumerated types for more
information.

## Private RPCs, Types, and Properties

Any RPC, type, or property which begins with an underscore is said to
be _private_. These RPCs, types, and fields can be changed at any
time without changing major or minor version numbers.

The intention is that the Service Protocol will evolve by adding
private RPCs which may, over time, migrate to the public api as they
become stable. Some private types and properties expose VM specific
implementation state and will never be appropriate to add to
the public api.

## Middleware Support

### Single Client Mode

The VM service allows for an extended feature set via the Dart Development
Service (DDS) that forward all core VM service RPCs described in this
document to the true VM service.

When DDS connects to the VM service, the VM service enters single client
mode and will no longer accept incoming web socket connections, instead forwarding
the web socket connection request to DDS. If DDS disconnects from the VM service,
the VM service will once again start accepting incoming web socket connections.

The VM service forwards the web socket connection by issuing a redirect 

### Protocol Extensions

Middleware like the Dart Development Service have the option of providing
functionality which builds on or extends the VM service protocol. Middleware
which offer protocol extensions should intercept calls to
[getSupportedProtocols](#getsupportedprotocols) and modify the resulting
[ProtocolList](#protocolist) to include their own [Protocol](#protocol)
information before responding to the requesting client.

## Public RPCs

The following is a list of all public RPCs supported by the Service Protocol.

An RPC is described using the following format:

```
ReturnType methodName(parameterType1 parameterName1,
                      parameterType2 parameterName2,
                      ...)
```

If an RPC says it returns type _T_ it may actually return _T_ or any
[subtype](#public-types) of _T_. For example, an
RPC which is declared to return [@Object](#object) may actually
return [@Instance](#instance).

If an RPC can return one or more independent types, this is indicated
with the vertical bar:

```
ReturnType1|ReturnType2
```

Any RPC may return an [RPC error](#rpc-error) response.

Some parameters are optional. This is indicated by the text
_[optional]_ following the parameter name:

```
ReturnType methodName(parameterType parameterName [optional])
```

A description of the return types and parameter types is provided
in the section on [public types](#public-types).

### addBreakpoint

```
Breakpoint|Sentinel addBreakpoint(string isolateId,
                                  string scriptId,
                                  int line,
                                  int column [optional])
```

The _addBreakpoint_ RPC is used to add a breakpoint at a specific line
of some script.

The _scriptId_ parameter is used to specify the target script.

The _line_ parameter is used to specify the target line for the
breakpoint. If there are multiple possible breakpoints on the target
line, then the VM will place the breakpoint at the location which
would execute soonest. If it is not possible to set a breakpoint at
the target line, the breakpoint will be added at the next possible
breakpoint location within the same function.

The _column_ parameter may be optionally specified.  This is useful
for targeting a specific breakpoint on a line with multiple possible
breakpoints.

If no breakpoint is possible at that line, the _102_ (Cannot add
breakpoint) [RPC error](#rpc-error) code is returned.

Note that breakpoints are added and removed on a per-isolate basis.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [Breakpoint](#breakpoint).

### addBreakpointWithScriptUri

```
Breakpoint|Sentinel addBreakpointWithScriptUri(string isolateId,
                                               string scriptUri,
                                               int line,
                                               int column [optional])
```

The _addBreakpoint_ RPC is used to add a breakpoint at a specific line
of some script.  This RPC is useful when a script has not yet been
assigned an id, for example, if a script is in a deferred library
which has not yet been loaded.

The _scriptUri_ parameter is used to specify the target script.

The _line_ parameter is used to specify the target line for the
breakpoint. If there are multiple possible breakpoints on the target
line, then the VM will place the breakpoint at the location which
would execute soonest. If it is not possible to set a breakpoint at
the target line, the breakpoint will be added at the next possible
breakpoint location within the same function.

The _column_ parameter may be optionally specified.  This is useful
for targeting a specific breakpoint on a line with multiple possible
breakpoints.

If no breakpoint is possible at that line, the _102_ (Cannot add
breakpoint) [RPC error](#rpc-error) code is returned.

Note that breakpoints are added and removed on a per-isolate basis.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [Breakpoint](#breakpoint).

### addBreakpointAtEntry

```
Breakpoint|Sentinel addBreakpointAtEntry(string isolateId,
                                         string functionId)
```
The _addBreakpointAtEntry_ RPC is used to add a breakpoint at the
entrypoint of some function.

If no breakpoint is possible at the function entry, the _102_ (Cannot add
breakpoint) [RPC error](#rpc-error) code is returned.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [Breakpoint](#breakpoint).

Note that breakpoints are added and removed on a per-isolate basis.

### clearCpuSamples

```
Success|Sentinel clearCpuSamples(string isolateId)
```

Clears all CPU profiling samples.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [Success](#success).

### clearVMTimeline

```
Success clearVMTimeline()
```

Clears all VM timeline events.

See [Success](#success).

### invoke

```
@Instance|@Error|Sentinel invoke(string isolateId,
                                 string targetId,
                                 string selector,
                                 string[] argumentIds,
                                 bool disableBreakpoints [optional])
```

The _invoke_ RPC is used to perform regular method invocation on some receiver,
as if by dart:mirror's ObjectMirror.invoke. Note this does not provide a way to
perform getter, setter or constructor invocation.

_targetId_ may refer to a [Library](#library), [Class](#class), or
[Instance](#instance).

Each elements of _argumentId_ may refer to an [Instance](#instance).

If _disableBreakpoints_ is provided and set to true, any breakpoints hit as a
result of this invocation are ignored, including pauses resulting from a call
to `debugger()` from `dart:developer`. Defaults to false if not provided.

If _targetId_ or any element of _argumentIds_ is a temporary id which has
expired, then the _Expired_ [Sentinel](#sentinel) is returned.

If _targetId_ or any element of _argumentIds_ refers to an object which has been
collected by the VM's garbage collector, then the _Collected_
[Sentinel](#sentinel) is returned.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

If invocation triggers a failed compilation then [RPC error](#rpc-error) 113
"Expression compilation error" is returned.

If a runtime error occurs while evaluating the invocation, an [@Error](#error)
reference will be returned.

If the invocation is evaluated successfully, an [@Instance](#instance)
reference will be returned.

### evaluate

```
@Instance|@Error|Sentinel evaluate(string isolateId,
                                   string targetId,
                                   string expression,
                                   map<string,string> scope [optional],
                                   bool disableBreakpoints [optional])
```

The _evaluate_ RPC is used to evaluate an expression in the context of
some target.

_targetId_ may refer to a [Library](#library), [Class](#class), or
[Instance](#instance).

If _targetId_ is a temporary id which has expired, then the _Expired_
[Sentinel](#sentinel) is returned.

If _targetId_ refers to an object which has been collected by the VM's
garbage collector, then the _Collected_ [Sentinel](#sentinel) is
returned.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

If _scope_ is provided, it should be a map from identifiers to object ids.
These bindings will be added to the scope in which the expression is evaluated,
which is a child scope of the class or library for instance/class or library
targets respectively. This means bindings provided in _scope_ may shadow
instance members, class members and top-level members.

If _disableBreakpoints_ is provided and set to true, any breakpoints hit as a
result of this evaluation are ignored. Defaults to false if not provided.

If the expression fails to parse and compile, then [RPC error](#rpc-error) 113
"Expression compilation error" is returned.

If an error occurs while evaluating the expression, an [@Error](#error)
reference will be returned.

If the expression is evaluated successfully, an [@Instance](#instance)
reference will be returned.

### evaluateInFrame

```
@Instance|@Error|Sentinel evaluateInFrame(string isolateId,
                                          int frameIndex,
                                          string expression,
                                          map<string,string> scope [optional],
                                          bool disableBreakpoints [optional])
```

The _evaluateInFrame_ RPC is used to evaluate an expression in the
context of a particular stack frame. _frameIndex_ is the index of the
desired [Frame](#frame), with an index of _0_ indicating the top (most
recent) frame.

If _scope_ is provided, it should be a map from identifiers to object ids.
These bindings will be added to the scope in which the expression is evaluated,
which is a child scope of the frame's current scope. This means bindings
provided in _scope_ may shadow instance members, class members, top-level
members, parameters and locals.

If _disableBreakpoints_ is provided and set to true, any breakpoints hit as a
result of this evaluation are ignored. Defaults to false if not provided.

If the expression fails to parse and compile, then [RPC error](#rpc-error) 113
"Expression compilation error" is returned.

If an error occurs while evaluating the expression, an [@Error](#error)
reference will be returned.

If the expression is evaluated successfully, an [@Instance](#instance)
reference will be returned.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

### getAllocationProfile

```
AllocationProfile|Sentinel getAllocationProfile(string isolateId,
                                                bool reset [optional],
                                                bool gc [optional])
```

The _getAllocationProfile_ RPC is used to retrieve allocation information for a
given isolate.

If _reset_ is provided and is set to true, the allocation accumulators will be reset
before collecting allocation information.

If _gc_ is provided and is set to true, a garbage collection will be attempted
before collecting allocation information. There is no guarantee that a garbage
collection will be actually be performed.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

### getClassList

```
ClassList|Sentinel getClassList(string isolateId)
```

The _getClassList_ RPC is used to retrieve a _ClassList_ containing all
classes for an isolate based on the isolate's _isolateId_.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [ClassList](#classlist).

### getCpuSamples

```
CpuSamples|Sentinel getCpuSamples(string isolateId,
                                  int timeOriginMicros,
                                  int timeExtentMicros)
```

The _getCpuSamples_ RPC is used to retrieve samples collected by the CPU
profiler. Only samples collected in the time range `[timeOriginMicros,
timeOriginMicros + timeExtentMicros]` will be reported.

If the profiler is disabled, an [RPC error](#rpc-error) response will be returned.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [CpuSamples](#cpusamples).

### getFlagList

```
FlagList getFlagList()
```

The _getFlagList_ RPC returns a list of all command line flags in the
VM along with their current values.

See [FlagList](#flaglist).

### getInboundReferences

```
InboundReferences|Sentinel getInboundReferences(string isolateId,
                                                string targetId,
                                                int limit)
```

Returns a set of inbound references to the object specified by _targetId_. Up to
_limit_ references will be returned.

The order of the references is undefined (i.e., not related to allocation order)
and unstable (i.e., multiple invocations of this method against the same object
can give different answers even if no Dart code has executed between the invocations).

The references may include multiple `objectId`s that designate the same object.

The references may include objects that are unreachable but have not yet been garbage collected.

If _targetId_ is a temporary id which has expired, then the _Expired_
[Sentinel](#sentinel) is returned.

If _targetId_ refers to an object which has been collected by the VM's
garbage collector, then the _Collected_ [Sentinel](#sentinel) is
returned.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [InboundReferences](#inboundreferences).

### getInstances

```
InstanceSet|Sentinel getInstances(string isolateId,
                                  string objectId,
                                  int limit)
```

The _getInstances_ RPC is used to retrieve a set of instances which are of a
specific class. This does not include instances of subclasses of the given
class.

The order of the instances is undefined (i.e., not related to allocation order)
and unstable (i.e., multiple invocations of this method against the same class
can give different answers even if no Dart code has executed between the
invocations).

The set of instances may include objects that are unreachable but have not yet
been garbage collected.

_objectId_ is the ID of the `Class` to retrieve instances for. _objectId_ must
be the ID of a `Class`, otherwise an [RPC error](#rpc-error) is returned.

_limit_ is the maximum number of instances to be returned.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [InstanceSet](#instanceset).

### getIsolate

```
Isolate|Sentinel getIsolate(string isolateId)
```

The _getIsolate_ RPC is used to lookup an _Isolate_ object by its _id_.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [Isolate](#isolate).

### getIsolateGroup

```
IsolateGroup|Sentinel getIsolateGroup(string isolateGroupId)
```

The _getIsolateGroup_ RPC is used to lookup an _IsolateGroup_ object by its _id_.

If _isolateGroupId_ refers to an isolate group which has exited, then the
_Expired_ [Sentinel](#sentinel) is returned.

_IsolateGroup_ _id_ is an opaque identifier that can be fetched from an
 _IsolateGroup_. List of active _IsolateGroup_'s, for example, is available on _VM_ object.

See [IsolateGroup](#isolategroup), [VM](#vm).

### getMemoryUsage

```
MemoryUsage|Sentinel getMemoryUsage(string isolateId)
```

The _getMemoryUsage_ RPC is used to lookup an isolate's memory usage
statistics by its _id_.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [Isolate](#isolate).

### getIsolateGroupMemoryUsage

```
MemoryUsage|Sentinel getIsolateGroupMemoryUsage(string isolateGroupId)
```

The _getIsolateGroupMemoryUsage_ RPC is used to lookup an isolate
group's memory usage statistics by its _id_.

If _isolateGroupId_ refers to an isolate group which has exited, then the _Expired_ [Sentinel](#sentinel) is returned.

See [IsolateGroup](#isolategroup).

### getScripts

```
ScriptList|Sentinel getScripts(string isolateId)
```

The _getScripts_ RPC is used to retrieve a _ScriptList_ containing all
scripts for an isolate based on the isolate's _isolateId_.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [ScriptList](#scriptlist).

### getObject

```
Object|Sentinel getObject(string isolateId,
                          string objectId,
                          int offset [optional],
                          int count [optional])
```

The _getObject_ RPC is used to lookup an _object_ from some isolate by
its _id_.

If _objectId_ is a temporary id which has expired, then the _Expired_
[Sentinel](#sentinel) is returned.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

If _objectId_ refers to a heap object which has been collected by the VM's
garbage collector, then the _Collected_ [Sentinel](#sentinel) is
returned.

If _objectId_ refers to a non-heap object which has been deleted, then
the _Collected_ [Sentinel](#sentinel) is returned.

If the object handle has not expired and the object has not been
collected, then an [Object](#object) will be returned.

The _offset_ and _count_ parameters are used to request subranges of
Instance objects with the kinds: String, List, Map, Uint8ClampedList,
Uint8List, Uint16List, Uint32List, Uint64List, Int8List, Int16List,
Int32List, Int64List, Flooat32List, Float64List, Inst32x3List,
Float32x4List, and Float64x2List.  These parameters are otherwise
ignored.

### getPorts

```
PortList getPorts(string isolateId)
```

The _getPorts_ RPC is used to retrieve the list of `ReceivePort` instances for a
given isolate.

See [PortList](#portlist).

### getRetainingPath

```
RetainingPath|Sentinel getRetainingPath(string isolateId,
                                        string targetId,
                                        int limit)
```

The _getRetainingPath_ RPC is used to lookup a path from an object specified by
_targetId_ to a GC root (i.e., the object which is preventing this object from
being garbage collected).

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

If _targetId_ refers to a heap object which has been collected by the VM's
garbage collector, then the _Collected_ [Sentinel](#sentinel) is returned.

If _targetId_ refers to a non-heap object which has been deleted, then the
_Collected_ [Sentinel](#sentinel) is returned.

If the object handle has not expired and the object has not been collected, then
an [RetainingPath](#retainingpath) will be returned.

The _limit_ parameter specifies the maximum path length to be reported as part
of the retaining path. If a path is longer than _limit_, it will be truncated at
the root end of the path.

See [RetainingPath](#retainingpath).


### getProcessMemoryUsage

```
ProcessMemoryUsage getProcessMemoryUsage()
```

Returns a description of major uses of memory known to the VM.

Adding or removing buckets is considered a backwards-compatible change
for the purposes of versioning. A client must gracefully handle the
removal or addition of any bucket.

### getStack

```
Stack|Sentinel getStack(string isolateId, int limit [optional])
```

The _getStack_ RPC is used to retrieve the current execution stack and
message queue for an isolate. The isolate does not need to be paused.

If _limit_ is provided, up to _limit_ frames from the top of the stack will be
returned. If the stack depth is smaller than _limit_ the entire stack is
returned. Note: this limit also applies to the `asyncCausalFrames` and
`awaiterFrames` stack representations in the _Stack_ response.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [Stack](#stack).

### getSupportedProtocols

```
ProtocolList getSupportedProtocols()
```

The _getSupportedProtocols_ RPC is used to determine which protocols are
supported by the current server.

The result of this call should be intercepted by any middleware that extends
the core VM service protocol and should add its own protocol to the list of
protocols before forwarding the response to the client.

See [ProtocolList](#protocollist).

### getSourceReport

```
SourceReport|Sentinel getSourceReport(string isolateId,
                                      SourceReportKind[] reports,
                                      string scriptId [optional],
                                      int tokenPos [optional],
                                      int endTokenPos [optional],
                                      bool forceCompile [optional])
```

The _getSourceReport_ RPC is used to generate a set of reports tied to
source locations in an isolate.

The _reports_ parameter is used to specify which reports should be
generated.  The _reports_ parameter is a list, which allows multiple
reports to be generated simultaneously from a consistent isolate
state.  The _reports_ parameter is allowed to be empty (this might be
used to force compilation of a particular subrange of some script).

The available report kinds are:

report kind | meaning
----------- | -------
Coverage | Provide code coverage information
PossibleBreakpoints | Provide a list of token positions which correspond to possible breakpoints.

The _scriptId_ parameter is used to restrict the report to a
particular script.  When analyzing a particular script, either or both
of the _tokenPos_ and _endTokenPos_ parameters may be provided to
restrict the analysis to a subrange of a script (for example, these
can be used to restrict the report to the range of a particular class
or function).

If the _scriptId_ parameter is not provided then the reports are
generated for all loaded scripts and the _tokenPos_ and _endTokenPos_
parameters are disallowed.

The _forceCompilation_ parameter can be used to force compilation of
all functions in the range of the report.  Forcing compilation can
cause a compilation error, which could terminate the running Dart
program.  If this parameter is not provided, it is considered to have
the value _false_.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [SourceReport](#sourcereport).

### getVersion

```
Version getVersion()
```

The _getVersion_ RPC is used to determine what version of the Service Protocol is served by a VM.

See [Version](#version).

### getVM

```
VM getVM()
```

The _getVM_ RPC returns global information about a Dart virtual machine.

See [VM](#vm).


### getVMTimeline

```
Timeline getVMTimeline(int timeOriginMicros [optional],
                       int timeExtentMicros [optional])
```

The _getVMTimeline_ RPC is used to retrieve an object which contains VM timeline
events.

The _timeOriginMicros_ parameter is the beginning of the time range used to filter
timeline events. It uses the same monotonic clock as dart:developer's `Timeline.now`
and the VM embedding API's `Dart_TimelineGetMicros`. See [getVMTimelineMicros](#getvmtimelinemicros)
for access to this clock through the service protocol.

The _timeExtentMicros_ parameter specifies how large the time range used to filter
timeline events should be.

For example, given _timeOriginMicros_ and _timeExtentMicros_, only timeline events
from the following time range will be returned: `(timeOriginMicros, timeOriginMicros + timeExtentMicros)`.

If _getVMTimeline_ is invoked while the current recorder is one of Fuchsia or Macos or
Systrace, an [RPC error](#rpc-error) with error code _114_, `invalid timeline request`, will be returned as
timeline events are handled by the OS in these modes.

### getVMTimelineFlags

```
TimelineFlags getVMTimelineFlags()
```

The _getVMTimelineFlags_ RPC returns information about the current VM timeline configuration.

To change which timeline streams are currently enabled, see [setVMTimelineFlags](#setvmtimelineflags).

See [TimelineFlags](#timelineflags).

### getVMTimelineMicros

```
Timestamp getVMTimelineMicros()
```

The _getVMTimelineMicros_ RPC returns the current time stamp from the clock used by the timeline,
similar to `Timeline.now` in `dart:developer` and `Dart_TimelineGetMicros` in the VM embedding API.

See [Timestamp](#timestamp) and [getVMTimeline](#getvmtimeline).

### pause

```
Success|Sentinel pause(string isolateId)
```

The _pause_ RPC is used to interrupt a running isolate. The RPC enqueues the interrupt request and potentially returns before the isolate is paused.

When the isolate is paused an event will be sent on the _Debug_ stream.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [Success](#success).

### kill

```
Success|Sentinel kill(string isolateId)
```

The _kill_ RPC is used to kill an isolate as if by dart:isolate's `Isolate.kill(IMMEDIATE)`.

The isolate is killed regardless of whether it is paused or running.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [Success](#success).

### registerService

```
Success registerService(string service, string alias)
```

Registers a service that can be invoked by other VM service clients, where
`service` is the name of the service to advertise and `alias` is an alternative
name for the registered service.

Requests made to the new service will be forwarded to the client which originally
registered the service.

See [Success](#success).

### reloadSources

```
ReloadReport|Sentinel reloadSources(string isolateId,
                                    bool force [optional],
                                    bool pause [optional],
                                    string rootLibUri [optional],
                                    string packagesUri [optional])
```

The _reloadSources_ RPC is used to perform a hot reload of an Isolate's sources.

if the _force_ parameter is provided, it indicates that all of the Isolate's
sources should be reloaded regardless of modification time.

if the _pause_ parameter is provided, the isolate will pause immediately
after the reload.

if the _rootLibUri_ parameter is provided, it indicates the new uri to the
Isolate's root library.

if the _packagesUri_ parameter is provided, it indicates the new uri to the
Isolate's package map (.packages) file.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

### removeBreakpoint

```
Success|Sentinel removeBreakpoint(string isolateId,
                                  string breakpointId)
```

The _removeBreakpoint_ RPC is used to remove a breakpoint by its _id_.

Note that breakpoints are added and removed on a per-isolate basis.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [Success](#success).

### requestHeapSnapshot

```
Success|Sentinel requestHeapSnapshot(string isolateId)
```

Requests a dump of the Dart heap of the given isolate.

This method immediately returns success. The VM will then begin delivering
binary events on the `HeapSnapshot` event stream. The binary data in these
events, when concatenated together, conforms to the [SnapshotGraph](heap_snapshot.md)
type. The splitting of the SnapshotGraph into events can happen at any byte
offset.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

### resume

```
Success|Sentinel resume(string isolateId,
                        StepOption step [optional],
                        int frameIndex [optional])
```

The _resume_ RPC is used to resume execution of a paused isolate.

If the _step_ parameter is not provided, the program will resume
regular execution.

If the _step_ parameter is provided, it indicates what form of
single-stepping to use.

step | meaning
---- | -------
Into | Single step, entering function calls
Over | Single step, skipping over function calls
Out | Single step until the current function exits
Rewind | Immediately exit the top frame(s) without executing any code. Isolate will be paused at the call of the last exited function.

The _frameIndex_ parameter is only used when the _step_ parameter is Rewind. It
specifies the stack frame to rewind to. Stack frame 0 is the currently executing
function, so _frameIndex_ must be at least 1.

If the _frameIndex_ parameter is not provided, it defaults to 1.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [Success](#success), [StepOption](#StepOption).

### setExceptionPauseMode

```
Success|Sentinel setExceptionPauseMode(string isolateId,
                                       ExceptionPauseMode mode)
```

The _setExceptionPauseMode_ RPC is used to control if an isolate pauses when
an exception is thrown.

mode | meaning
---- | -------
None | Do not pause isolate on thrown exceptions
Unhandled | Pause isolate on unhandled exceptions
All  | Pause isolate on all thrown exceptions

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

### setFlag

```
Success|Error setFlag(string name,
                      string value)
```

The _setFlag_ RPC is used to set a VM flag at runtime. Returns an error if the
named flag does not exist, the flag may not be set at runtime, or the value is
of the wrong type for the flag.

The following flags may be set at runtime:

 * pause_isolates_on_start
 * pause_isolates_on_exit
 * pause_isolates_on_unhandled_exceptions
 * profile_period
 * profiler

Notes:
 * `profile_period` can be set to a minimum value of 50. Attempting to set
   `profile_period` to a lower value will result in a value of 50 being set.
 * Setting `profiler` will enable or disable the profiler depending on the
   provided value. If set to false when the profiler is already running, the
   profiler will be stopped but may not free its sample buffer depending on
   platform limitations.

See [Success](#success).

### setLibraryDebuggable

```
Success|Sentinel setLibraryDebuggable(string isolateId,
                                      string libraryId,
                                      bool isDebuggable)
```

The _setLibraryDebuggable_ RPC is used to enable or disable whether
breakpoints and stepping work for a given library.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [Success](#success).

### setName

```
Success|Sentinel setName(string isolateId,
                         string name)
```

The _setName_ RPC is used to change the debugging name for an isolate.

If _isolateId_ refers to an isolate which has exited, then the
_Collected_ [Sentinel](#sentinel) is returned.

See [Success](#success).

### setVMName

```
Success setVMName(string name)
```

The _setVMName_ RPC is used to change the debugging name for the vm.

See [Success](#success).

### setVMTimelineFlags

```
Success setVMTimelineFlags(string[] recordedStreams)
```

The _setVMTimelineFlags_ RPC is used to set which timeline streams are enabled.

The _recordedStreams_ parameter is the list of all timeline streams which are
to be enabled. Streams not explicitly specified will be disabled. Invalid stream
names are ignored.

A `TimelineStreamSubscriptionsUpdate` event is sent on the `Timeline` stream as
a result of invoking this RPC.

To get the list of currently enabled timeline streams, see [getVMTimelineFlags](#getvmtimelineflags).

See [Success](#success).

### streamCancel

```
Success streamCancel(string streamId)
```

The _streamCancel_ RPC cancels a stream subscription in the VM.

If the client is not subscribed to the stream, the _104_ (Stream not
subscribed) [RPC error](#rpc-error) code is returned.

See [Success](#success).

### streamListen

```
Success streamListen(string streamId)
```

The _streamListen_ RPC subscribes to a stream in the VM. Once
subscribed, the client will begin receiving events from the stream.

If the client is already subscribed to the stream, the _103_ (Stream already
subscribed) [RPC error](#rpc-error) code is returned.

The _streamId_ parameter may have the following published values:

streamId | event types provided
-------- | -----------
VM | VMUpdate, VMFlagUpdate
Isolate | IsolateStart, IsolateRunnable, IsolateExit, IsolateUpdate, IsolateReload, ServiceExtensionAdded
Debug | PauseStart, PauseExit, PauseBreakpoint, PauseInterrupted, PauseException, PausePostRequest, Resume, BreakpointAdded, BreakpointResolved, BreakpointRemoved, Inspect, None
GC | GC
Extension | Extension
Timeline | TimelineEvents, TimelineStreamsSubscriptionUpdate
Logging | Logging
Service | ServiceRegistered, ServiceUnregistered
HeapSnapshot | HeapSnapshot

Additionally, some embedders provide the _Stdout_ and _Stderr_
streams.  These streams allow the client to subscribe to writes to
stdout and stderr.

streamId | event types provided
-------- | -----------
Stdout | WriteEvent
Stderr | WriteEvent

It is considered a _backwards compatible_ change to add a new type of event to an existing stream.
Clients should be written to handle this gracefully, perhaps by warning and ignoring.

See [Success](#success).

## Public Types

The following is a list of all public types produced by the Service Protocol.

We define a small set of primitive types, based on JSON equivalents.

type | meaning
---- | -------
string | JSON string values
bool | JSON _true_, _false_
int | JSON numbers without fractions or exponents
float | any JSON number

Note that the Service Protocol does not use JSON _null_.

We describe the format of our JSON objects with the following class format:

```
class T {
  string name;
  int count;
  ...
}
```

This describes a JSON object type _T_ with some set of expected properties.

Types are organized into an inheritance hierarchy. If type _T_
extends type _S_...

```
class S {
  string a;
}

class T extends S {
  string b;
}
```

...then that means that all properties of _S_ are also present in type
_T_. In the example above, type _T_ would have the expected
properties _a_ and _b_.

If a property has an _Array_ type, it is written with brackets:

```
  PropertyType[] arrayProperty;
```

If a property is optional, it is suffixed with the text _[optional]_:

```
  PropertyType optionalProperty [optional];
```

If a property can have multiple independent types, we denote this with
a vertical bar:

```
  PropertyType1|PropertyType2 complexProperty;
```

We also allow parenthesis on type expressions.  This is useful when a property
is an _Array_ of multiple independent types:

```
  (PropertyType1|PropertyType2)[]
```

When a string is only permitted to take one of a certain set of values,
we indicate this by the use of the _enum_ format:

```
enum PermittedValues {
  Value1,
  Value2
}
```

This means that _PermittedValues_ is a _string_ with two potential values,
_Value1_ and _Value2_.

### AllocationProfile

```
class AllocationProfile extends Response {
  // Allocation information for all class types.
  ClassHeapStats[] members;

  // Information about memory usage for the isolate.
  MemoryUsage memoryUsage;

  // The timestamp of the last accumulator reset.
  //
  // If the accumulators have not been reset, this field is not present.
  int dateLastAccumulatorReset [optional];

  // The timestamp of the last manually triggered GC.
  //
  // If a GC has not been triggered manually, this field is not present.
  int dateLastServiceGC [optional];
}
```

### BoundField

```
class BoundField {
  @Field decl;
  @Instance|Sentinel value;
}
```

A _BoundField_ represents a field bound to a particular value in an
_Instance_.

If the field is uninitialized, the _value_ will be the
_NotInitialized_ [Sentinel](#sentinel).

If the field is being initialized, the _value_ will be the
_BeingInitialized_ [Sentinel](#sentinel).

### BoundVariable

```
class BoundVariable extends Response {
  string name;
  @Instance|@TypeArguments|Sentinel value;

  // The token position where this variable was declared.
  int declarationTokenPos;

  // The first token position where this variable is visible to the scope.
  int scopeStartTokenPos;

  // The last token position where this variable is visible to the scope.
  int scopeEndTokenPos;
}
```

A _BoundVariable_ represents a local variable bound to a particular value
in a _Frame_.

If the variable is uninitialized, the _value_ will be the
_NotInitialized_ [Sentinel](#sentinel).

If the variable is being initialized, the _value_ will be the
_BeingInitialized_ [Sentinel](#sentinel).

If the variable has been optimized out by the compiler, the _value_
will be the _OptimizedOut_ [Sentinel](#sentinel).

### Breakpoint

```
class Breakpoint extends Object {
  // A number identifying this breakpoint to the user.
  int breakpointNumber;

  // Has this breakpoint been assigned to a specific program location?
  bool resolved;

  // Is this a breakpoint that was added synthetically as part of a step
  // OverAsyncSuspension resume command?
  bool isSyntheticAsyncContinuation [optional];

  // SourceLocation when breakpoint is resolved, UnresolvedSourceLocation
  // when a breakpoint is not resolved.
  SourceLocation|UnresolvedSourceLocation location;
}
```

A _Breakpoint_ describes a debugger breakpoint.

A breakpoint is _resolved_ when it has been assigned to a specific
program location.  A breakpoint my remain unresolved when it is in
code which has not yet been compiled or in a library which has not
been loaded (i.e. a deferred library).

### Class

```
class @Class extends @Object {
  // The name of this class.
  string name;
}
```

_@Class_ is a reference to a _Class_.

```
class Class extends Object {
  // The name of this class.
  string name;

  // The error which occurred during class finalization, if it exists.
  @Error error [optional];

  // Is this an abstract class?
  bool abstract;

  // Is this a const class?
  bool const;

  // The library which contains this class.
  @Library library;

  // The location of this class in the source code.
  SourceLocation location [optional];

  // The superclass of this class, if any.
  @Class super [optional];

  // The supertype for this class, if any.
  //
  // The value will be of the kind: Type.
  @Instance superType [optional];

  // A list of interface types for this class.
  //
  // The values will be of the kind: Type.
  @Instance[] interfaces;

  // The mixin type for this class, if any.
  //
  // The value will be of the kind: Type.
  @Instance mixin [optional];

  // A list of fields in this class. Does not include fields from
  // superclasses.
  @Field[] fields;

  // A list of functions in this class. Does not include functions
  // from superclasses.
  @Function[] functions;

  // A list of subclasses of this class.
  @Class[] subclasses;
}
```

A _Class_ provides information about a Dart language class.

### ClassHeapStats

```
class ClassHeapStats extends Response {
  // The class for which this memory information is associated.
  @Class class;

  // The number of bytes allocated for instances of class since the
  // accumulator was last reset.
  int accumulatedSize;

  // The number of bytes currently allocated for instances of class.
  int bytesCurrent;

  // The number of instances of class which have been allocated since
  // the accumulator was last reset.
  int instancesAccumulated;

  // The number of instances of class which are currently alive.
  int instancesCurrent;
}
```

### ClassList

```
class ClassList extends Response {
  @Class[] classes;
}
```

### Code

```
class @Code extends @Object {
  // A name for this code object.
  string name;

  // What kind of code object is this?
  CodeKind kind;
}
```

_@Code_ is a reference to a _Code_ object.

```
class Code extends @Object {
  // A name for this code object.
  string name;

  // What kind of code object is this?
  CodeKind kind;
}
```

A _Code_ object represents compiled code in the Dart VM.

### CodeKind

```
enum CodeKind {
  Dart,
  Native,
  Stub,
  Tag,
  Collected
}
```

### Context

```
class @Context extends @Object {
  // The number of variables in this context.
  int length;
}
```

```
class Context extends Object {
  // The number of variables in this context.
  int length;

  // The enclosing context for this context.
  Context parent [optional];

  // The variables in this context object.
  ContextElement[] variables;
}
```

A _Context_ is a data structure which holds the captured variables for
some closure.

### ContextElement

```
class ContextElement {
  @Instance|Sentinel value;
}
```

### CpuSamples

```
class CpuSamples extends Response {
  // The sampling rate for the profiler in microseconds.
  int samplePeriod;

  // The maximum possible stack depth for samples.
  int maxStackDepth;

  // The number of samples returned.
  int sampleCount;

  // The timespan the set of returned samples covers, in microseconds.
  int timeSpan;

  // The start of the period of time in which the returned samples were
  // collected.
  int timeOriginMicros;

  // The duration of time covered by the returned samples.
  int timeExtentMicros;

  // The process ID for the VM.
  int pid;

  // A list of functions seen in the relevant samples. These references can be
  // looked up using the indicies provided in a `CpuSample` `stack` to determine
  // which function was on the stack.
  ProfileFunction[] functions;

  // A list of samples collected in the range
  // `[timeOriginMicros, timeOriginMicros + timeExtentMicros]`
  CpuSample[] samples;
}
```

See [getCpuSamples](#getcpusamples) and [CpuSample](#cpusample).

### CpuSample

```
class CpuSample {
  // The thread ID representing the thread on which this sample was collected.
  int tid;

  // The time this sample was collected in microseconds.
  int timestamp;

  // The name of VM tag set when this sample was collected. Omitted if the VM
  // tag for the sample is not considered valid.
  string vmTag [optional];

  // The name of the User tag set when this sample was collected. Omitted if no
  // User tag was set when this sample was collected.
  string userTag [optional];

  // Provided and set to true if the sample's stack was truncated. This can
  // happen if the stack is deeper than the `stackDepth` in the `CpuSamples`
  // response.
  bool truncated [optional];

  // The call stack at the time this sample was collected. The stack is to be
  // interpreted as top to bottom. Each element in this array is a key into the
  // `functions` array in `CpuSamples`.
  //
  // Example:
  //
  // `functions[stack[0]] = @Function(bar())`
  // `functions[stack[1]] = @Function(foo())`
  // `functions[stack[2]] = @Function(main())`
  int[] stack;
}
```

See [getCpuSamples](#getcpusamples) and [CpuSamples](#cpusamples).

### Error

```
class @Error extends @Object {
  // What kind of error is this?
  ErrorKind kind;

  // A description of the error.
  string message;
}
```

_@Error_ is a reference to an _Error_.

```
class Error extends Object {
  // What kind of error is this?
  ErrorKind kind;

  // A description of the error.
  string message;

  // If this error is due to an unhandled exception, this
  // is the exception thrown.
  @Instance exception [optional];

  // If this error is due to an unhandled exception, this
  // is the stacktrace object.
  @Instance stacktrace [optional];
}
```

An _Error_ represents a Dart language level error. This is distinct from an
[RPC error](#rpc-error).

### ErrorKind

```
enum ErrorKind {
  // The isolate has encountered an unhandled Dart exception.
  UnhandledException,

  // The isolate has encountered a Dart language error in the program.
  LanguageError,

  // The isolate has encountered an internal error. These errors should be
  // reported as bugs.
  InternalError,

  // The isolate has been terminated by an external source.
  TerminationError
}
```

### Event

```
class Event extends Response {
  // What kind of event is this?
  EventKind kind;

  // The isolate with which this event is associated.
  //
  // This is provided for all event kinds except for:
  //   VMUpdate, VMFlagUpdate
  @Isolate isolate [optional];

  // The vm with which this event is associated.
  //
  // This is provided for the event kind:
  //   VMUpdate, VMFlagUpdate
  @VM vm [optional];

  // The timestamp (in milliseconds since the epoch) associated with this event.
  // For some isolate pause events, the timestamp is from when the isolate was
  // paused. For other events, the timestamp is from when the event was created.
  int timestamp;

  // The breakpoint which was added, removed, or resolved.
  //
  // This is provided for the event kinds:
  //   PauseBreakpoint
  //   BreakpointAdded
  //   BreakpointRemoved
  //   BreakpointResolved
  Breakpoint breakpoint [optional];

  // The list of breakpoints at which we are currently paused
  // for a PauseBreakpoint event.
  //
  // This list may be empty. For example, while single-stepping, the
  // VM sends a PauseBreakpoint event with no breakpoints.
  //
  // If there is more than one breakpoint set at the program position,
  // then all of them will be provided.
  //
  // This is provided for the event kinds:
  //   PauseBreakpoint
  Breakpoint[] pauseBreakpoints [optional];

  // The top stack frame associated with this event, if applicable.
  //
  // This is provided for the event kinds:
  //   PauseBreakpoint
  //   PauseInterrupted
  //   PauseException
  //
  // For PauseInterrupted events, there will be no top frame if the
  // isolate is idle (waiting in the message loop).
  //
  // For the Resume event, the top frame is provided at
  // all times except for the initial resume event that is delivered
  // when an isolate begins execution.
  Frame topFrame [optional];

  // The exception associated with this event, if this is a
  // PauseException event.
  @Instance exception [optional];

  // An array of bytes, encoded as a base64 string.
  //
  // This is provided for the WriteEvent event.
  string bytes [optional];

  // The argument passed to dart:developer.inspect.
  //
  // This is provided for the Inspect event.
  @Instance inspectee [optional];

  // The RPC name of the extension that was added.
  //
  // This is provided for the ServiceExtensionAdded event.
  string extensionRPC [optional];

  // The extension event kind.
  //
  // This is provided for the Extension event.
  string extensionKind [optional];

  // The extension event data.
  //
  // This is provided for the Extension event.
  ExtensionData extensionData [optional];

  // An array of TimelineEvents
  //
  // This is provided for the TimelineEvents event.
  TimelineEvent[] timelineEvents [optional];

  // The new set of recorded timeline streams.
  //
  // This is provided for the TimelineStreamSubscriptionsUpdate event.
  string[] updatedStreams [optional];

  // Is the isolate paused at an await, yield, or yield* statement?
  //
  // This is provided for the event kinds:
  //   PauseBreakpoint
  //   PauseInterrupted
  bool atAsyncSuspension [optional];

  // The status (success or failure) related to the event.
  // This is provided for the event kinds:
  //   IsolateReloaded
  string status [optional];

  // LogRecord data.
  //
  // This is provided for the Logging event.
  LogRecord logRecord [optional];

  // The service identifier.
  //
  // This is provided for the event kinds:
  //   ServiceRegistered
  //   ServiceUnregistered
  String service [optional];

  // The RPC method that should be used to invoke the service.
  //
  // This is provided for the event kinds:
  //   ServiceRegistered
  //   ServiceUnregistered
  String method [optional];

  // The alias of the registered service.
  //
  // This is provided for the event kinds:
  //   ServiceRegistered
  String alias [optional];

  // The name of the changed flag.
  //
  // This is provided for the event kinds:
  //   VMFlagUpdate
  String flag [optional];

  // The new value of the changed flag.
  //
  // This is provided for the event kinds:
  //   VMFlagUpdate
  String newValue [optional];

  // Specifies whether this event is the last of a group of events.
  //
  // This is provided for the event kinds:
  //   HeapSnapshot
  bool last [optional];
}
```

An _Event_ is an asynchronous notification from the VM. It is delivered
only when the client has subscribed to an event stream using the
[streamListen](#streamListen) RPC.

For more information, see [events](#events).

### EventKind

```
enum EventKind {
  // Notification that VM identifying information has changed. Currently used
  // to notify of changes to the VM debugging name via setVMName.
  VMUpdate,

  // Notification that a VM flag has been changed via the service protocol.
  VMFlagUpdate,

  // Notification that a new isolate has started.
  IsolateStart,

  // Notification that an isolate is ready to run.
  IsolateRunnable,

  // Notification that an isolate has exited.
  IsolateExit,

  // Notification that isolate identifying information has changed.
  // Currently used to notify of changes to the isolate debugging name
  // via setName.
  IsolateUpdate,

  // Notification that an isolate has been reloaded.
  IsolateReload,

  // Notification that an extension RPC was registered on an isolate.
  ServiceExtensionAdded,

  // An isolate has paused at start, before executing code.
  PauseStart,

  // An isolate has paused at exit, before terminating.
  PauseExit,

  // An isolate has paused at a breakpoint or due to stepping.
  PauseBreakpoint,

  // An isolate has paused due to interruption via pause.
  PauseInterrupted,

  // An isolate has paused due to an exception.
  PauseException,

  // An isolate has paused after a service request.
  PausePostRequest,

  // An isolate has started or resumed execution.
  Resume,

  // Indicates an isolate is not yet runnable. Only appears in an Isolate's
  // pauseEvent. Never sent over a stream.
  None,

  // A breakpoint has been added for an isolate.
  BreakpointAdded,

  // An unresolved breakpoint has been resolved for an isolate.
  BreakpointResolved,

  // A breakpoint has been removed.
  BreakpointRemoved,

  // A garbage collection event.
  GC,

  // Notification of bytes written, for example, to stdout/stderr.
  WriteEvent,

  // Notification from dart:developer.inspect.
  Inspect,

  // Event from dart:developer.postEvent.
  Extension,

  // Event from dart:developer.log.
  Logging,

  // A block of timeline events has been completed.
  //
  // This service event is not sent for individual timeline events. It is
  // subject to buffering, so the most recent timeline events may never be
  // included in any TimelineEvents event if no timeline events occur later to
  // complete the block.
  TimelineEvents,

  // The set of active timeline streams was changed via `setVMTimelineFlags`.
  TimelineStreamSubscriptionsUpdate,

  // Notification that a Service has been registered into the Service Protocol
  // from another client.
  ServiceRegistered,

  // Notification that a Service has been removed from the Service Protocol
  // from another client.
  ServiceUnregistered,
}
```

Adding new values to _EventKind_ is considered a backwards compatible
change. Clients should ignore unrecognized events.

### ExtensionData

```
class ExtensionData {
}
```

An _ExtensionData_ is an arbitrary map that can have any contents.

### Field

```
class @Field extends @Object {
  // The name of this field.
  string name;

  // The owner of this field, which can be either a Library or a
  // Class.
  @Object owner;

  // The declared type of this field.
  //
  // The value will always be of one of the kinds:
  // Type, TypeRef, TypeParameter, BoundedType.
  @Instance declaredType;

  // Is this field const?
  bool const;

  // Is this field final?
  bool final;

  // Is this field static?
  bool static;
}
```

An _@Field_ is a reference to a _Field_.

```
class Field extends Object {
  // The name of this field.
  string name;

  // The owner of this field, which can be either a Library or a
  // Class.
  @Object owner;

  // The declared type of this field.
  //
  // The value will always be of one of the kinds:
  // Type, TypeRef, TypeParameter, BoundedType.
  @Instance declaredType;

  // Is this field const?
  bool const;

  // Is this field final?
  bool final;

  // Is this field static?
  bool static;

  // The value of this field, if the field is static.
  @Instance staticValue [optional];

  // The location of this field in the source code.
  SourceLocation location [optional];
}
```

A _Field_ provides information about a Dart language field or
variable.


### Flag

```
class Flag {
  // The name of the flag.
  string name;

  // A description of the flag.
  string comment;

  // Has this flag been modified from its default setting?
  bool modified;

  // The value of this flag as a string.
  //
  // If this property is absent, then the value of the flag was NULL.
  string valueAsString [optional];
}
```

A _Flag_ represents a single VM command line flag.

### FlagList

```
class FlagList extends Response {
  // A list of all flags in the VM.
  Flag[] flags;
}
```

A _FlagList_ represents the complete set of VM command line flags.

### Frame

```
class Frame extends Response {
  int index;
  @Function function [optional];
  @Code code [optional];
  SourceLocation location [optional];
  BoundVariable[] vars [optional];
  FrameKind kind [optional];
}
```

### Function

```
class @Function extends @Object {
  // The name of this function.
  string name;

  // The owner of this function, which can be a Library, Class, or a Function.
  @Library|@Class|@Function owner;

  // Is this function static?
  bool static;

  // Is this function const?
  bool const;
}
```

An _@Function_ is a reference to a _Function_.


```
class Function extends Object {
  // The name of this function.
  string name;

  // The owner of this function, which can be a Library, Class, or a Function.
  @Library|@Class|@Function owner;

  // Is this function static?
  bool static;

  // Is this function const?
  bool const;

  // The location of this function in the source code.
  SourceLocation location [optional];

  // The compiled code associated with this function.
  @Code code [optional];
}
```

A _Function_ represents a Dart language function.

### Instance

```
class @Instance extends @Object {
  // What kind of instance is this?
  InstanceKind kind;

  // Instance references always include their class.
  @Class class;

  // The value of this instance as a string.
  //
  // Provided for the instance kinds:
  //   Null (null)
  //   Bool (true or false)
  //   Double (suitable for passing to Double.parse())
  //   Int (suitable for passing to int.parse())
  //   String (value may be truncated)
  //   Float32x4
  //   Float64x2
  //   Int32x4
  //   StackTrace
  string valueAsString [optional];

  // The valueAsString for String references may be truncated. If so,
  // this property is added with the value 'true'.
  //
  // New code should use 'length' and 'count' instead.
  bool valueAsStringIsTruncated [optional];

  // The length of a List or the number of associations in a Map or the
  // number of codeunits in a String.
  //
  // Provided for instance kinds:
  //   String
  //   List
  //   Map
  //   Uint8ClampedList
  //   Uint8List
  //   Uint16List
  //   Uint32List
  //   Uint64List
  //   Int8List
  //   Int16List
  //   Int32List
  //   Int64List
  //   Float32List
  //   Float64List
  //   Int32x4List
  //   Float32x4List
  //   Float64x2List
  int length [optional];

  // The name of a Type instance.
  //
  // Provided for instance kinds:
  //   Type
  string name [optional];

  // The corresponding Class if this Type has a resolved typeClass.
  //
  // Provided for instance kinds:
  //   Type
  @Class typeClass [optional];

  // The parameterized class of a type parameter:
  //
  // Provided for instance kinds:
  //   TypeParameter
  @Class parameterizedClass [optional];


  // The pattern of a RegExp instance.
  //
  // The pattern is always an instance of kind String.
  //
  // Provided for instance kinds:
  //   RegExp
  @Instance pattern [optional];

  // The function associated with a Closure instance.
  //
  // Provided for instance kinds:
  //   Closure
  @Function closureFunction [optional];

  // The context associated with a Closure instance.
  //
  // Provided for instance kinds:
  //   Closure
  @Context closureContext [optional];

  // The port ID for a ReceivePort.
  //
  // Provided for instance kinds:
  //   ReceivePort
  int portId [optional];

  // The stack trace associated with the allocation of a ReceivePort.
  //
  // Provided for instance kinds:
  //   ReceivePort
  @Instance allocationLocation [optional];

  // A name associated with a ReceivePort used for debugging purposes.
  //
  // Provided for instance kinds:
  //   ReceivePort
  string debugName [optional];
}
```

_@Instance_ is a reference to an _Instance_.

```
class Instance extends Object {
  // What kind of instance is this?
  InstanceKind kind;

  // Instance references always include their class.
  @Class class;

  // The value of this instance as a string.
  //
  // Provided for the instance kinds:
  //   Bool (true or false)
  //   Double (suitable for passing to Double.parse())
  //   Int (suitable for passing to int.parse())
  //   String (value may be truncated)
  //   StackTrace
  string valueAsString [optional];

  // The valueAsString for String references may be truncated. If so,
  // this property is added with the value 'true'.
  //
  // New code should use 'length' and 'count' instead.
  bool valueAsStringIsTruncated [optional];

  // The length of a List or the number of associations in a Map or the
  // number of codeunits in a String.
  //
  // Provided for instance kinds:
  //   String
  //   List
  //   Map
  //   Uint8ClampedList
  //   Uint8List
  //   Uint16List
  //   Uint32List
  //   Uint64List
  //   Int8List
  //   Int16List
  //   Int32List
  //   Int64List
  //   Float32List
  //   Float64List
  //   Int32x4List
  //   Float32x4List
  //   Float64x2List
  int length [optional];

  // The index of the first element or association or codeunit returned.
  // This is only provided when it is non-zero.
  //
  // Provided for instance kinds:
  //   String
  //   List
  //   Map
  //   Uint8ClampedList
  //   Uint8List
  //   Uint16List
  //   Uint32List
  //   Uint64List
  //   Int8List
  //   Int16List
  //   Int32List
  //   Int64List
  //   Float32List
  //   Float64List
  //   Int32x4List
  //   Float32x4List
  //   Float64x2List
  int offset [optional];

  // The number of elements or associations or codeunits returned.
  // This is only provided when it is less than length.
  //
  // Provided for instance kinds:
  //   String
  //   List
  //   Map
  //   Uint8ClampedList
  //   Uint8List
  //   Uint16List
  //   Uint32List
  //   Uint64List
  //   Int8List
  //   Int16List
  //   Int32List
  //   Int64List
  //   Float32List
  //   Float64List
  //   Int32x4List
  //   Float32x4List
  //   Float64x2List
  int count [optional];

  // The name of a Type instance.
  //
  // Provided for instance kinds:
  //   Type
  string name [optional];

  // The corresponding Class if this Type is canonical.
  //
  // Provided for instance kinds:
  //   Type
  @Class typeClass [optional];

  // The parameterized class of a type parameter:
  //
  // Provided for instance kinds:
  //   TypeParameter
  @Class parameterizedClass [optional];

  // The fields of this Instance.
  BoundField[] fields [optional];

  // The elements of a List instance.
  //
  // Provided for instance kinds:
  //   List
  (@Instance|Sentinel)[] elements [optional];

  // The elements of a Map instance.
  //
  // Provided for instance kinds:
  //   Map
  MapAssociation[] associations [optional];

  // The bytes of a TypedData instance.
  //
  // The data is provided as a Base64 encoded string.
  //
  // Provided for instance kinds:
  //   Uint8ClampedList
  //   Uint8List
  //   Uint16List
  //   Uint32List
  //   Uint64List
  //   Int8List
  //   Int16List
  //   Int32List
  //   Int64List
  //   Float32List
  //   Float64List
  //   Int32x4List
  //   Float32x4List
  //   Float64x2List
  string bytes [optional];

  // The referent of a MirrorReference instance.
  //
  // Provided for instance kinds:
  //   MirrorReference
  @Instance mirrorReferent [optional];

  // The pattern of a RegExp instance.
  //
  // Provided for instance kinds:
  //   RegExp
  @Instance pattern [optional];

// The function associated with a Closure instance.
  //
  // Provided for instance kinds:
  //   Closure
  @Function closureFunction [optional];

  // The context associated with a Closure instance.
  //
  // Provided for instance kinds:
  //   Closure
  @Context closureContext [optional];

  // Whether this regular expression is case sensitive.
  //
  // Provided for instance kinds:
  //   RegExp
  bool isCaseSensitive [optional];

  // Whether this regular expression matches multiple lines.
  //
  // Provided for instance kinds:
  //   RegExp
  bool isMultiLine [optional];

  // The key for a WeakProperty instance.
  //
  // Provided for instance kinds:
  //   WeakProperty
  @Instance propertyKey [optional];

  // The key for a WeakProperty instance.
  //
  // Provided for instance kinds:
  //   WeakProperty
  @Instance propertyValue [optional];

  // The type arguments for this type.
  //
  // Provided for instance kinds:
  //   Type
  @TypeArguments typeArguments [optional];

  // The index of a TypeParameter instance.
  //
  // Provided for instance kinds:
  //   TypeParameter
  int parameterIndex [optional];

  // The type bounded by a BoundedType instance
  // - or -
  // the referent of a TypeRef instance.
  //
  // The value will always be of one of the kinds:
  // Type, TypeRef, TypeParameter, BoundedType.
  //
  // Provided for instance kinds:
  //   BoundedType
  //   TypeRef
  @Instance targetType [optional];

  // The bound of a TypeParameter or BoundedType.
  //
  // The value will always be of one of the kinds:
  // Type, TypeRef, TypeParameter, BoundedType.
  //
  // Provided for instance kinds:
  //   BoundedType
  //   TypeParameter
  @Instance bound [optional];

  // The port ID for a ReceivePort.
  //
  // Provided for instance kinds:
  //   ReceivePort
  int portId [optional];

  // The stack trace associated with the allocation of a ReceivePort.
  //
  // Provided for instance kinds:
  //   ReceivePort
  @Instance allocationLocation [optional];

  // A name associated with a ReceivePort used for debugging purposes.
  //
  // Provided for instance kinds:
  //   ReceivePort
  string debugName [optional];
}
```

An _Instance_ represents an instance of the Dart language class _Object_.

### InstanceKind

```
enum InstanceKind {
  // A general instance of the Dart class Object.
  PlainInstance,

  // null instance.
  Null,

  // true or false.
  Bool,

  // An instance of the Dart class double.
  Double,

  // An instance of the Dart class int.
  Int,

  // An instance of the Dart class String.
  String,

  // An instance of the built-in VM List implementation. User-defined
  // Lists will be PlainInstance.
  List,

  // An instance of the built-in VM Map implementation. User-defined
  // Maps will be PlainInstance.
  Map,

  // Vector instance kinds.
  Float32x4,
  Float64x2,
  Int32x4,

  // An instance of the built-in VM TypedData implementations. User-defined
  // TypedDatas will be PlainInstance.
  Uint8ClampedList,
  Uint8List,
  Uint16List,
  Uint32List,
  Uint64List,
  Int8List,
  Int16List,
  Int32List,
  Int64List,
  Float32List,
  Float64List,
  Int32x4List,
  Float32x4List,
  Float64x2List,

  // An instance of the Dart class StackTrace.
  StackTrace,

  // An instance of the built-in VM Closure implementation. User-defined
  // Closures will be PlainInstance.
  Closure,

  // An instance of the Dart class MirrorReference.
  MirrorReference,

  // An instance of the Dart class RegExp.
  RegExp,

  // An instance of the Dart class WeakProperty.
  WeakProperty,

  // An instance of the Dart class Type.
  Type,

  // An instance of the Dart class TypeParameter.
  TypeParameter,

  // An instance of the Dart class TypeRef.
  TypeRef,

  // An instance of the Dart class BoundedType.
  BoundedType,

  // An instance of the Dart class ReceivePort.
  ReceivePort,
}
```

Adding new values to _InstanceKind_ is considered a backwards
compatible change. Clients should treat unrecognized instance kinds
as _PlainInstance_.

### Isolate

```
class @Isolate extends Response {
  // The id which is passed to the getIsolate RPC to load this isolate.
  string id;

  // A numeric id for this isolate, represented as a string. Unique.
  string number;

  // A name identifying this isolate. Not guaranteed to be unique.
  string name;

  // Specifies whether the isolate was spawned by the VM or embedder for
  // internal use. If `false`, this isolate is likely running user code.
  bool isSystemIsolate;
}
```

_@Isolate_ is a reference to an _Isolate_ object.

```
class Isolate extends Response {
  // The id which is passed to the getIsolate RPC to reload this
  // isolate.
  string id;

  // A numeric id for this isolate, represented as a string. Unique.
  string number;

  // A name identifying this isolate. Not guaranteed to be unique.
  string name;

  // Specifies whether the isolate was spawned by the VM or embedder for
  // internal use. If `false`, this isolate is likely running user code.
  bool isSystemIsolate;

  // The list of isolate flags provided to this isolate. See Dart_IsolateFlags
  // in dart_api.h for the list of accepted isolate flags.
  IsolateFlag[] isolateFlags;

  // The time that the VM started in milliseconds since the epoch.
  //
  // Suitable to pass to DateTime.fromMillisecondsSinceEpoch.
  int startTime;

  // Is the isolate in a runnable state?
  bool runnable;

  // The number of live ports for this isolate.
  int livePorts;

  // Will this isolate pause when exiting?
  bool pauseOnExit;

  // The last pause event delivered to the isolate. If the isolate is
  // running, this will be a resume event.
  Event pauseEvent;

  // The root library for this isolate.
  //
  // Guaranteed to be initialized when the IsolateRunnable event fires.
  @Library rootLib [optional];

  // A list of all libraries for this isolate.
  //
  // Guaranteed to be initialized when the IsolateRunnable event fires.
  @Library[] libraries;

  // A list of all breakpoints for this isolate.
  Breakpoint[] breakpoints;

  // The error that is causing this isolate to exit, if applicable.
  Error error [optional];

  // The current pause on exception mode for this isolate.
  ExceptionPauseMode exceptionPauseMode;

  // The list of service extension RPCs that are registered for this isolate,
  // if any.
  string[] extensionRPCs [optional];
}
```

An _Isolate_ object provides information about one isolate in the VM.

### IsolateFlag

```
class IsolateFlag {
  // The name of the flag.
  string name;

  // The value of this flag as a string.
  string valueAsString;
}
```

Represents the value of a single isolate flag. See [Isolate](#isolate).

### IsolateGroup

```
class @IsolateGroup extends Response {
  // The id which is passed to the getIsolateGroup RPC to load this isolate group.
  string id;

  // A numeric id for this isolate group, represented as a string. Unique.
  string number;

  // A name identifying this isolate group. Not guaranteed to be unique.
  string name;

  // Specifies whether the isolate group was spawned by the VM or embedder for
  // internal use. If `false`, this isolate group is likely running user code.
  bool isSystemIsolateGroup;
}
```

_@IsolateGroup_ is a reference to an _IsolateGroup_ object.

```
class IsolateGroup extends Response {
  // The id which is passed to the getIsolate RPC to reload this
  // isolate.
  string id;

  // A numeric id for this isolate, represented as a string. Unique.
  string number;

  // A name identifying this isolate. Not guaranteed to be unique.
  string name;

  // Specifies whether the isolate group was spawned by the VM or embedder for
  // internal use. If `false`, this isolate group is likely running user code.
  bool isSystemIsolateGroup;

  // A list of all isolates in this isolate group.
  @Isolate[] isolates;
}
```

An _Isolate_ object provides information about one isolate in the VM.

### InboundReferences

```
class InboundReferences extends Response {
  // An array of inbound references to an object.
  InboundReference[] references;
}
```

See [getInboundReferences](#getinboundreferences).

### InboundReference

```
class InboundReference {
  // The object holding the inbound reference.
  @Object source;

  // If source is a List, parentListIndex is the index of the inbound reference.
  int parentListIndex [optional];

  // If source is a field of an object, parentField is the field containing the
  // inbound reference.
  @Field parentField [optional];
}
```

See [getInboundReferences](#getinboundreferences).

### InstanceSet

```
class InstanceSet extends Response {
  // The number of instances of the requested type currently allocated.
  int totalCount;

  // An array of instances of the requested type.
  @Object[] instances;
}
```

See [getInstances](#getinstances).

### Library

```
class @Library extends @Object {
  // The name of this library.
  string name;

  // The uri of this library.
  string uri;
}
```

_@Library_ is a reference to a _Library_.

```
class Library extends Object {
  // The name of this library.
  string name;

  // The uri of this library.
  string uri;

  // Is this library debuggable? Default true.
  bool debuggable;

  // A list of the imports for this library.
  LibraryDependency[] dependencies;

  // A list of the scripts which constitute this library.
  @Script[] scripts;

  // A list of the top-level variables in this library.
  @Field[] variables;

  // A list of the top-level functions in this library.
  @Function[] functions;

  // A list of all classes in this library.
  @Class[] classes;
}
```

A _Library_ provides information about a Dart language library.

See [setLibraryDebuggable](#setlibrarydebuggable).

### LibraryDependency

```
class LibraryDependency {
  // Is this dependency an import (rather than an export)?
  bool isImport;

  // Is this dependency deferred?
  bool isDeferred;

  // The prefix of an 'as' import, or null.
  String prefix;

  // The library being imported or exported.
  @Library target;
}
```

A _LibraryDependency_ provides information about an import or export.

### LogRecord

```
class LogRecord extends Response {
  // The log message.
  @Instance message;

  // The timestamp.
  int time;

  // The severity level (a value between 0 and 2000).
  //
  // See the package:logging `Level` class for an overview of the possible
  // values.
  int level;

  // A monotonically increasing sequence number.
  int sequenceNumber;

  // The name of the source of the log message.
  @Instance loggerName;

  // The zone where the log was emitted.
  @Instance zone;

  // An error object associated with this log event.
  @Instance error;

  // A stack trace associated with this log event.
  @Instance stackTrace;
}
```

### MapAssociation

```
class MapAssociation {
  @Instance|Sentinel key;
  @Instance|Sentinel value;
}
```

### MemoryUsage

```
class MemoryUsage extends Response {
  // The amount of non-Dart memory that is retained by Dart objects. For
  // example, memory associated with Dart objects through APIs such as
  // Dart_NewFinalizableHandle, Dart_NewWeakPersistentHandle and
  // Dart_NewExternalTypedData.  This usage is only as accurate as the values
  // supplied to these APIs from the VM embedder or native extensions. This
  // external memory applies GC pressure, but is separate from heapUsage and
  // heapCapacity.
  int externalUsage;

  // The total capacity of the heap in bytes. This is the amount of memory used
  // by the Dart heap from the perspective of the operating system.
  int heapCapacity;

  // The current heap memory usage in bytes. Heap usage is always less than or
  // equal to the heap capacity.
  int heapUsage;
}
```

A _MemoryUsage_ object provides heap usage information for a specific
isolate at a given point in time.

### Message

```
class Message extends Response {
  // The index in the isolate's message queue. The 0th message being the next
  // message to be processed.
  int index;

  // An advisory name describing this message.
  string name;

  // An instance id for the decoded message. This id can be passed to other
  // RPCs, for example, getObject or evaluate.
  string messageObjectId;

  // The size (bytes) of the encoded message.
  int size;

  // A reference to the function that will be invoked to handle this message.
  @Function handler [optional];

  // The source location of handler.
  SourceLocation location [optional];
}
```

A _Message_ provides information about a pending isolate message and the
function that will be invoked to handle it.

### NativeFunction

```
class NativeFunction {
  // The name of the native function this object represents.
  string name;
}
```

A _NativeFunction_ object is used to represent native functions in profiler
samples. See [CpuSamples](#cpusamples);

### Null

```
class @Null extends @Instance {
  // Always 'null'.
  string valueAsString;
}
```

_@Null_ is a reference to an a _Null_.

```
class Null extends Instance {
  // Always 'null'.
  string valueAsString;
}
```

A _Null_ object represents the Dart language value null.

### Object

```
class @Object extends Response {
  // A unique identifier for an Object. Passed to the
  // getObject RPC to load this Object.
  string id;

  // Provided and set to true if the id of an Object is fixed. If true, the id
  // of an Object is guaranteed not to change or expire. The object may, however,
  // still be _Collected_.
  bool fixedId [optional];
}
```

_@Object_ is a reference to a _Object_.

```
class Object extends Response {
  // A unique identifier for an Object. Passed to the
  // getObject RPC to reload this Object.
  //
  // Some objects may get a new id when they are reloaded.
  string id;

  // Provided and set to true if the id of an Object is fixed. If true, the id
  // of an Object is guaranteed not to change or expire. The object may, however,
  // still be _Collected_.
  bool fixedId [optional];

  // If an object is allocated in the Dart heap, it will have
  // a corresponding class object.
  //
  // The class of a non-instance is not a Dart class, but is instead
  // an internal vm object.
  //
  // Moving an Object into or out of the heap is considered a
  // backwards compatible change for types other than Instance.
  @Class class [optional];

  // The size of this object in the heap.
  //
  // If an object is not heap-allocated, then this field is omitted.
  //
  // Note that the size can be zero for some objects. In the current
  // VM implementation, this occurs for small integers, which are
  // stored entirely within their object pointers.
  int size [optional];
}
```

An _Object_ is a  persistent object that is owned by some isolate.

### PortList

```
class PortList extends Response {
  @Instance[] ports;
}
```

A _PortList_ contains a list of ports associated with some isolate.

See [getPort](#getPort).

### ProfileFunction

```
class ProfileFunction {
  // The kind of function this object represents.
  string kind;

  // The number of times function appeared on the stack during sampling events.
  int inclusiveTicks;

  // The number of times function appeared on the top of the stack during
  // sampling events.
  int exclusiveTicks;

  // The resolved URL for the script containing function.
  string resolvedUrl;

  // The function captured during profiling.
  (@Function|NativeFunction) function;
}
```

A _ProfileFunction_ contains profiling information about a Dart or native
function.

See [CpuSamples](#cpusamples).

### ProtocolList

```
class ProtocolList extends Response {
  // A list of supported protocols provided by this service.
  Protocol[] protocols;
}
```

A _ProtocolList_ contains a list of all protocols supported by the service
instance.

See [Protocol](#protocol) and [getSupportedProtocols](#getsupportedprotocols).

### Protocol

```
class Protocol {
  // The name of the supported protocol.
  string protocolName;

  // The major revision of the protocol.
  int major;

  // The minor revision of the protocol.
  int minor;
}
```

See [getSupportedProtocols](#getsupportedprotocols).

### ProcessMemoryUsage

```
class ProcessMemoryUsage extends Response {
  ProcessMemoryItem root;
}
```

Set [getProcessMemoryUsage](#getprocessmemoryusage).

### ProcessMemoryItem

```
class ProcessMemoryItem {
  // A short name for this bucket of memory.
  string name;

  // A longer description for this item.
  string description;

  // The amount of memory in bytes.
  // This is a retained size, not a shallow size. That is, it includes the size
  // of children.
  int size;

  // Subdivisons of this bucket of memory.
  ProcessMemoryItem[] children;
}
```

### ReloadReport

```
class ReloadReport extends Response {
  // Did the reload succeed or fail?
  bool success;
}
```

### RetainingObject

```
class RetainingObject {
  // An object that is part of a retaining path.
  @Object value;

  // The offset of the retaining object in a containing list.
  int parentListIndex [optional];

  // The key mapping to the retaining object in a containing map.
  @Object parentMapKey [optional];

  // The name of the field containing the retaining object within an object.
  string parentField [optional];
}
```

See [RetainingPath](#retainingpath).

### RetainingPath

```
class RetainingPath extends Response {
  // The length of the retaining path.
  int length;

  // The type of GC root which is holding a reference to the specified object.
  // Possible values include:
  //  * class table
  //  * local handle
  //  * persistent handle
  //  * stack
  //  * user global
  //  * weak persistent handle
  //  * unknown
  string gcRootType;

  // The chain of objects which make up the retaining path.
  RetainingObject[] elements;
}
```

See [getRetainingPath](#getretainingpath).

### Response

```
class Response {
  // Every response returned by the VM Service has the
  // type property. This allows the client distinguish
  // between different kinds of responses.
  string type;
}
```

Every non-error response returned by the Service Protocol extends _Response_.
By using the _type_ property, the client can determine which [type](#types)
of response has been provided.

### Sentinel

```
class Sentinel extends Response {
  // What kind of sentinel is this?
  SentinelKind kind;

  // A reasonable string representation of this sentinel.
  string valueAsString;
}
```

A _Sentinel_ is used to indicate that the normal response is not available.

We use a _Sentinel_ instead of an [error](#errors) for these cases because
they do not represent a problematic condition. They are normal.

### SentinelKind

```
enum SentinelKind {
  // Indicates that the object referred to has been collected by the GC.
  Collected,

  // Indicates that an object id has expired.
  Expired,

  // Indicates that a variable or field has not been initialized.
  NotInitialized,

  // Indicates that a variable or field is in the process of being initialized.
  BeingInitialized,

  // Indicates that a variable has been eliminated by the optimizing compiler.
  OptimizedOut,

  // Reserved for future use.
  Free,
}
```

A _SentinelKind_ is used to distinguish different kinds of _Sentinel_ objects.

Adding new values to _SentinelKind_ is considered a backwards
compatible change. Clients must handle this gracefully.


### FrameKind
```
enum FrameKind {
  Regular,
  AsyncCausal,
  AsyncSuspensionMarker,
  AsyncActivation
}
```

A _FrameKind_ is used to distinguish different kinds of _Frame_ objects.

### Script

```
class @Script extends @Object {
  // The uri from which this script was loaded.
  string uri;
}
```

_@Script_ is a reference to a _Script_.

```
class Script extends Object {
  // The uri from which this script was loaded.
  string uri;

  // The library which owns this script.
  @Library library;

  int lineOffset [optional];

  int columnOffset [optional];

  // The source code for this script. This can be null for certain built-in
  // scripts.
  string source [optional];

  // A table encoding a mapping from token position to line and column. This
  // field is null if sources aren't available.
  int[][] tokenPosTable [optional];
}
```

A _Script_ provides information about a Dart language script.

The _tokenPosTable_ is an array of int arrays. Each subarray
consists of a line number followed by _(tokenPos, columnNumber)_ pairs:

> [lineNumber, (tokenPos, columnNumber)*]

The _tokenPos_ is an arbitrary integer value that is used to represent
a location in the source code.  A _tokenPos_ value is not meaningful
in itself and code should not rely on the exact values returned.

For example, a _tokenPosTable_ with the value...

> [[1, 100, 5, 101, 8],[2, 102, 7]]

...encodes the mapping:

tokenPos | line | column
-------- | ---- | ------
100 | 1 | 5
101 | 1 | 8
102 | 2 | 7

### ScriptList

```
class ScriptList extends Response {
  @Script[] scripts;
}
```

### SourceLocation

```
class SourceLocation extends Response {
  // The script containing the source location.
  @Script script;

  // The first token of the location.
  int tokenPos;

  // The last token of the location if this is a range.
  int endTokenPos [optional];
}
```

The _SourceLocation_ class is used to designate a position or range in
some script.

### SourceReport

```
class SourceReport extends Response {
  // A list of ranges in the program source.  These ranges correspond
  // to ranges of executable code in the user's program (functions,
  // methods, constructors, etc.)
  //
  // Note that ranges may nest in other ranges, in the case of nested
  // functions.
  //
  // Note that ranges may be duplicated, in the case of mixins.
  SourceReportRange[] ranges;

  // A list of scripts, referenced by index in the report's ranges.
  ScriptRef[] scripts;
}
```

The _SourceReport_ class represents a set of reports tied to source
locations in an isolate.

### SourceReportCoverage

```
class SourceReportCoverage {
  // A list of token positions in a SourceReportRange which have been
  // executed.  The list is sorted.
  int[] hits;

  // A list of token positions in a SourceReportRange which have not been
  // executed.  The list is sorted.
  int[] misses;
}
```

The _SourceReportCoverage_ class represents coverage information for
one [SourceReportRange](#sourcereportrange).

Note that _SourceReportCoverage_ does not extend [Response](#response)
and therefore will not contain a _type_ property.

### SourceReportKind

```
enum SourceReportKind {
  // Used to request a code coverage information.
  Coverage,

  // Used to request a list of token positions of possible breakpoints.
  PossibleBreakpoints
}
```

### SourceReportRange

```
class SourceReportRange {
  // An index into the script table of the SourceReport, indicating
  // which script contains this range of code.
  int scriptIndex;

  // The token position at which this range begins.
  int startPos;

  // The token position at which this range ends.  Inclusive.
  int endPos;

  // Has this range been compiled by the Dart VM?
  bool compiled;

  // The error while attempting to compile this range, if this
  // report was generated with forceCompile=true.
  @Error error [optional];

  // Code coverage information for this range.  Provided only when the
  // Coverage report has been requested and the range has been
  // compiled.
  SourceReportCoverage coverage [optional];

  // Possible breakpoint information for this range, represented as a
  // sorted list of token positions.  Provided only when the when the
  // PossibleBreakpoint report has been requested and the range has been
  // compiled.
  int[] possibleBreakpoints [optional];
}
```

The _SourceReportRange_ class represents a range of executable code
(function, method, constructor, etc) in the running program.  It is
part of a [SourceReport](#sourcereport).

Note that _SourceReportRange_ does not extend [Response](#response)
and therefore will not contain a _type_ property.

### Stack

```
class Stack extends Response {
  // A list of frames that make up the synchronous stack, rooted at the message
  // loop (i.e., the frames since the last asynchronous gap or the isolate's
  // entrypoint).
  Frame[] frames;

  // A list of frames representing the asynchronous path. Comparable to
  // `awaiterFrames`, if provided, although some frames may be different.
  Frame[] asyncCausalFrames [optional];

  // A list of frames representing the asynchronous path. Comparable to
  // `asyncCausalFrames`, if provided, although some frames may be different.
  Frame[] awaiterFrames [optional];

  // A list of messages in the isolate's message queue.
  Message[] messages;

  // Specifies whether or not this stack is complete or has been artificially
  // truncated.
  bool truncated;
}
```

The _Stack_ class represents the various components of a Dart stack trace for a
given isolate.

See [getStack](#getStack).

### ExceptionPauseMode

```
enum ExceptionPauseMode {
  None,
  Unhandled,
  All,
}
```

An _ExceptionPauseMode_ indicates how the isolate pauses when an exception
is thrown.

### StepOption

```
enum StepOption {
  Into,
  Over,
  OverAsyncSuspension,
  Out,
  Rewind
}
```

A _StepOption_ indicates which form of stepping is requested in a [resume](#resume) RPC.

### Success

```
class Success extends Response {
}
```

The _Success_ type is used to indicate that an operation completed successfully.

### Timeline

```
class Timeline extends Response {
  // A list of timeline events. No order is guarenteed for these events; in particular, these events may be unordered with respect to their timestamps.
  TimelineEvent[] traceEvents;

  // The start of the period of time in which traceEvents were collected.
  int timeOriginMicros;

  // The duration of time covered by the timeline.
  int timeExtentMicros;
}
```

### TimelineEvent

```
class TimelineEvent {
}
```

An _TimelineEvent_ is an arbitrary map that contains a [Trace Event Format](https://docs.google.com/document/d/1CvAClvFfyA5R-PhYUmn5OOQtYMH4h6I0nSsKchNAySU/preview) event.

### TimelineFlags

```
class TimelineFlags extends Response {
  // The name of the recorder currently in use. Recorder types include, but are
  // not limited to: Callback, Endless, Fuchsia, Macos, Ring, Startup, and
  // Systrace.
  // Set to "null" if no recorder is currently set.
  string recorderName;

  // The list of all available timeline streams.
  string[] availableStreams;

  // The list of timeline streams that are currently enabled.
  string[] recordedStreams;
}
```

### Timestamp

```
class Timestamp extends Response {
  // A timestamp in microseconds since epoch.
  int timestamp;
}
```

### TypeArguments

```
class @TypeArguments extends @Object {
  // A name for this type argument list.
  string name;
}
```

_@TypeArguments_ is a reference to a _TypeArguments_ object.

```
class TypeArguments extends Object {
  // A name for this type argument list.
  string name;

  // A list of types.
  //
  // The value will always be one of the kinds:
  // Type, TypeRef, TypeParameter, BoundedType.
  @Instance[] types;
}
```

A _TypeArguments_ object represents the type argument vector for some
instantiated generic type.

### UnresolvedSourceLocation

```
class UnresolvedSourceLocation extends Response {
  // The script containing the source location if the script has been loaded.
  @Script script [optional];

  // The uri of the script containing the source location if the script
  // has yet to be loaded.
  string scriptUri [optional];

  // An approximate token position for the source location. This may
  // change when the location is resolved.
  int tokenPos [optional];

  // An approximate line number for the source location. This may
  // change when the location is resolved.
  int line [optional];

  // An approximate column number for the source location. This may
  // change when the location is resolved.
  int column [optional];

}
```

The _UnresolvedSourceLocation_ class is used to refer to an unresolved
breakpoint location.  As such, it is meant to approximate the final
location of the breakpoint but it is not exact.

Either the _script_ or the _scriptUri_ field will be present.

Either the _tokenPos_ or the _line_ field will be present.

The _column_ field will only be present when the breakpoint was
specified with a specific column number.

### Version

```
class Version extends Response {
  // The major version number is incremented when the protocol is changed
  // in a potentially incompatible way.
  int major;

  // The minor version number is incremented when the protocol is changed
  // in a backwards compatible way.
  int minor;
}
```

See [Versioning](#versioning).

### VM

```
class @VM extends Response {
  // A name identifying this vm. Not guaranteed to be unique.
  string name;
}
```

_@VM_ is a reference to a _VM_ object.

```
class VM extends Response {
  // A name identifying this vm. Not guaranteed to be unique.
  string name;

  // Word length on target architecture (e.g. 32, 64).
  int architectureBits;

  // The CPU we are actually running on.
  string hostCPU;

  // The operating system we are running on.
  string operatingSystem;

  // The CPU we are generating code for.
  string targetCPU;

  // The Dart VM version string.
  string version;

  // The process id for the VM.
  int pid;

  // The time that the VM started in milliseconds since the epoch.
  //
  // Suitable to pass to DateTime.fromMillisecondsSinceEpoch.
  int startTime;

  // A list of isolates running in the VM.
  @Isolate[] isolates;

  // A list of isolate groups running in the VM.
  @IsolateGroup[] isolateGroups;

  // A list of system isolates running in the VM.
  @Isolate[] systemIsolates;

  // A list of isolate groups which contain system isolates running in the VM.
  @IsolateGroup[] systemIsolateGroups;
}
```

## Revision History

version | comments
------- | --------
1.0 | Initial revision
2.0 | Describe protocol version 2.0.
3.0 | Describe protocol version 3.0.  Added `UnresolvedSourceLocation`.  Added `Sentinel` return to `getIsolate`.  Add `AddedBreakpointWithScriptUri`.  Removed `Isolate.entry`. The type of `VM.pid` was changed from `string` to `int`.  Added `VMUpdate` events.  Add offset and count parameters to `getObject` and `offset` and `count` fields to `Instance`. Added `ServiceExtensionAdded` event.
3.1 | Add the `getSourceReport` RPC.  The `getObject` RPC now accepts `offset` and `count` for string objects.  `String` objects now contain `length`, `offset`, and `count` properties.
3.2 | `Isolate` objects now include the runnable bit and many debugger related RPCs will return an error if executed on an isolate before it is runnable.
3.3 | Pause event now indicates if the isolate is paused at an `await`, `yield`, or `yield*` suspension point via the `atAsyncSuspension` field. Resume command now supports the step parameter `OverAsyncSuspension`. A Breakpoint added synthetically by an `OverAsyncSuspension` resume command identifies itself as such via the `isSyntheticAsyncContinuation` field.
3.4 | Add the `superType` and `mixin` fields to `Class`. Added new pause event `None`.
3.5 | Add the error field to `SourceReportRange.  Clarify definition of token position.  Add "Isolate must be paused" error code.
3.6 | Add `scopeStartTokenPos`, `scopeEndTokenPos`, and `declarationTokenPos` to `BoundVariable`. Add `PausePostRequest` event kind. Add `Rewind` `StepOption`. Add error code 107 (isolate cannot resume). Add `reloadSources` RPC and related error codes. Add optional parameter `scope` to `evaluate` and `evaluateInFrame`.
3.7 | Add `setFlag`.
3.8 | Add `kill`.
3.9 | Changed numbers for errors related to service extensions.
3.10 | Add `invoke`.
3.11 | Rename `invoke` parameter `receiverId` to `targetId`.
3.12 | Add `getScripts` RPC and `ScriptList` object.
3.13 | Class `mixin` field now properly set for kernel transformed mixin applications.
3.14 | Flag `profile_period` can now be set at runtime, allowing for the profiler sample rate to be changed while the program is running.
3.15 | Added `disableBreakpoints` parameter to `invoke`, `evaluate`, and `evaluateInFrame`.
3.16 | Add `getMemoryUsage` RPC and `MemoryUsage` object.
3.17 | Add `Logging` event kind and the `LogRecord` class.
3.18 | Add `getAllocationProfile` RPC and `AllocationProfile` and `ClassHeapStats` objects.
3.19 | Add `clearVMTimeline`, `getVMTimeline`, `getVMTimelineFlags`, `setVMTimelineFlags`, `Timeline`, and `TimelineFlags`.
3.20 | Add `getInstances` RPC and `InstanceSet` object.
3.21 | Add `getVMTimelineMicros` RPC and `Timestamp` object.
3.22 | Add `registerService` RPC, `Service` stream, and `ServiceRegistered` and `ServiceUnregistered` event kinds.
3.23 | Add `VMFlagUpdate` event kind to the `VM` stream.
3.24 | Add `operatingSystem` property to `VM` object.
3.25 | Add `getInboundReferences`, `getRetainingPath` RPCs, and `InboundReferences`, `InboundReference`, `RetainingPath`, and `RetainingObject` objects.
3.26 | Add `requestHeapSnapshot`.
3.27 | Add `clearCpuSamples`, `getCpuSamples` RPCs and `CpuSamples`, `CpuSample` objects.
3.28 | TODO(aam): document changes from 3.28
3.29 | Add `getClientName`, `setClientName`, `requireResumeApproval`
3.30 | Updated return types of RPCs which require an `isolateId` to allow for `Sentinel` results if the target isolate has shutdown.
3.31 | Added single client mode, which allows for the Dart Development Service (DDS) to become the sole client of the VM service.
3.32 | Added `getClassList` RPC and `ClassList` object.
3.33 | Added deprecation notice for `getClientName`, `setClientName`, `requireResumeApproval`, and `ClientName`. These RPCs are moving to the DDS protocol and will be removed in v4.0 of the VM service protocol.
3.34 | Added `TimelineStreamSubscriptionsUpdate` event which is sent when `setVMTimelineFlags` is invoked.
3.35 | Added `getSupportedProtocols` RPC and `ProtocolList`, `Protocol` objects.
3.36 | Added `getProcessMemoryUsage` RPC and `ProcessMemoryUsage` and `ProcessMemoryItem` objects.
3.37 | Added `getWebSocketTarget` RPC and `WebSocketTarget` object.
3.38 | Added `isSystemIsolate` property to `@Isolate` and `Isolate`, `isSystemIsolateGroup` property to `@IsolateGroup` and `IsolateGroup`, and properties `systemIsolates` and `systemIsolateGroups` to `VM`.
3.39 | Removed the following deprecated RPCs and objects: `getClientName`, `getWebSocketTarget`, `setClientName`, `requireResumeApproval`, `ClientName`, and `WebSocketTarget`.
3.40 | Added `IsolateFlag` object and `isolateFlags` property to `Isolate`.
3.41 | Added `PortList` object, `ReceivePort` `InstanceKind`, and `getPorts` RPC.
3.42 | Added `limit` optional parameter to `getStack` RPC.

[discuss-list]: https://groups.google.com/a/dartlang.org/forum/#!forum/observatory-discuss
