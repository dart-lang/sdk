# Dart VM Service Protocol 2.0

> Please post feedback to the [observatory-discuss group][discuss-list]

This document describes of _version 2.0_ of the Dart VM Service Protocol. This
protocol is used to communicate with a running Dart Virtual Machine.

To use the Service Protocol, start the VM with the *--observe* flag.
The VM will start a webserver which services protocol requests via WebSocket.
It is possible to make HTTP (non-WebSocket) requests,
but this does not allow access to VM _events_ and is not documented
here.

The Service Protocol uses [JSON-RPC 2.0][].

[JSON-RPC 2.0]: http://www.jsonrpc.org/specification

**Table of Contents**

- [RPCs, Requests, and Responses](#rpcs-requests-and-responses)
- [Events](#events)
- [Types](#types)
- [IDs and Names](#ids-and-names)
- [Versioning](#versioning)
- [Private RPCs, Types, and Properties](#private-rpcs-types-and-properties)
- [Public RPCs](#public-rpcs)
	- [addBreakpoint](#addbreakpoint)
	- [addBreakpointAtEntry](#addbreakpointatentry)
	- [evaluate](#evaluate)
	- [evaluateInFrame](#evaluateinframe)
	- [getFlagList](#getflaglist)
	- [getIsolate](#getisolate)
	- [getObject](#getobject)
	- [getStack](#getstack)
	- [getVersion](#getversion)
	- [getVM](#getvm)
	- [pause](#pause)
	- [removeBreakpoint](#removebreakpoint)
	- [resume](#resume)
	- [setName](#setname)
	- [setLibraryDebuggable](#setlibrarydebuggable)
	- [streamCancel](#streamcancel)
	- [streamListen](#streamlisten)
- [Public Types](#public-types)
	- [BoundField](#boundfield)
	- [BoundVariable](#boundvariable)
	- [Breakpoint](#breakpoint)
	- [Class](#class)
	- [ClassList](#classlist)
	- [Code](#code)
	- [CodeKind](#codekind)
	- [Context](#context)
	- [ContextElement](#contextelement)
	- [Error](#error)
	- [ErrorKind](#errorkind)
	- [Event](#event)
	- [EventKind](#eventkind)
	- [Field](#field)
	- [Flag](#flag)
	- [FlagList](#flaglist)
	- [Frame](#frame)
	- [Function](#function)
	- [Instance](#instance)
	- [Isolate](#isolate)
	- [Library](#library)
	- [LibraryDependency](#librarydependency)
	- [MapAssociation](#mapassociation)
	- [Message](#message)
	- [Null](#null)
	- [Object](#object)
	- [Sentinel](#sentinel)
	- [SentinelKind](#sentinelkind)
	- [Script](#script)
	- [SourceLocation](#sourcelocation)
	- [Stack](#stack)
	- [StepOption](#stepoption)
	- [Success](#success)
	- [TypeArguments](#typearguments)
	- [Response](#response)
	- [Version](#version)
	- [VM](#vm)
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
    "major": 2,
    "minor": 0
  }
  "id": "1"
}
```

Parameters for RPC requests are always provided as _named_ parameters.
The JSON-RPC spec provides for _positional_ parameters as well, but they
are not supported by the Dart VM.

By convention, every response returned by the Service Protocol is a subtype
of [Response](#response) and provides a _type_ paramters which can be used
to distinguish the exact return type. In the example above, the
[Version](#version) type is returned.

Here is an example [streamListen](#streamlisten) request which provides
a parameter:

```
{
  "jsonrpc": "2.0",
  "method": "streamListen",
  "params": {
    "streamId": "GC",
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

In addition the the [error codes](http://www.jsonrpc.org/specification#error_object)
specified in the JSON-RPC spec, we use the following application specific error codes:

code | message | meaning
---- | ------- | -------
100 | Feature is disabled | The operation is unable to complete because a feature is disabled
101 | VM must be paused | This operation is only valid when the VM is paused
102 | Cannot add breakpoint | The VM is unable to add a breakpoint at the specified line or function
103 | Stream already subscribed | The client is already subscribed to the specified _streamId_
104 | Stream not subscribed | The client is not subscribed to the specified _streamId_




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



## Types

By convention, every result and event provided by the Service Protocol
is a subtype of [Response](#response) and has the _type_ property.
This allows the client to distinguish different kinds of responses. For example,
information about a Dart function is returned using the [Function](#function) type.

If the type of a response begins with the _@_ character, then that
response is a _reference_. If the type name of a response does not
begin with the _@_ character, it is the an _object_. A reference is
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
    "major": 2,
    "minor": 0
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

## Public RPCs

The following is a list of all public RPCs supported by the Service Protocol.

An RPC is described using the following format:

```
ReturnType methodName(parameterType1 parameterName1,
                      parameterType2, parameterName2,
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

Any RPC may return an _error_ response as [described above](#rpc-error).

Some parameters are optional. This is indicated by the text
_[optional]_ following the parameter name:

```
ReturnType methodName(parameterType parameterName [optional)
```

A description of the return types and parameter types is provided
in the section on [public types](#public-types).

### addBreakpoint

```
Breakpoint addBreakpoint(string isolateId,
                         string scriptId,
                         int line)
```

The _addBreakpoint_ RPC is used to add a breakpoint at a specific line
of some script.

If no breakpoint is possible at that line, the _102_ (Cannot add
breakpoint) error code is returned.

Note that breakpoints are added and removed on a per-isolate basis.

See [Breakpoint](#breakpoint).

### addBreakpointAtEntry

```
Breakpoint addBreakpointAtEntry(string isolateId,
                                string functionId)
```
The _addBreakpointAtEntry_ RPC is used to add a breakpoint at the
entrypoint of some function.

If no breakpoint is possible at the function entry, the _102_ (Cannot add
breakpoint) error code is returned.

See [Breakpoint](#breakpoint).

Note that breakpoints are added and removed on a per-isolate basis.

### evaluate

```
@Instance|@Error|Sentinel evaluate(string isolateId,
                                   string targetId,
                                   string expression)
```

The _evaluate_ RPC is used to evaluate an expression in the context of
some target.

_targetId_ may refer to a [Library](#library), [Class](#class), or
[Instance](#instance).

If _targetId_ is a temporary id which has expired, then then _Expired_
[Sentinel](#sentinel) is returned.

If _targetId_ refers to an object which has been collected by the VM's
garbage collector, then the _Collected_ [Sentinel](#sentinel) is
returned.

If an error occurs while evaluating the expression, an [@Error](#error)
reference will be returned.

If the expression is evaluated successfully, an [@Instance](#instance)
reference will be returned.

### evaluateInFrame

```
@Instance|@Error evaluateInFrame(string isolateId,
                                 int frameIndex,
                                 string expression)
```

The _evaluateInFrame_ RPC is used to evaluate an expression in the
context of a particular stack frame. _frameIndex_ is the index of the
desired [Frame](#frame), with an index of _0_ indicating the top (most
recent) frame.

If an error occurs while evaluating the expression, an [@Error](#error)
reference will be returned.

If the expression is evaluated successfully, an [@Instance](#instance)
reference will be returned.

### getFlagList

```
FlagList getFlagList()
```

The _getFlagList RPC returns a list of all command line flags in the
VM along with their current values.

See [FlagList](#flaglist).

### getIsolate

```
Isolate getIsolate(string isolateId)
```

The _getIsolate_ RPC is used to lookup an _Isolate_ object by its _id_.

See [Isolate](#isolate).

### getObject

```
Object|Sentinel  getObject(string isolateId,
                           string objectId)
```

The _getObject_ RPC is used to lookup an _object_ from some isolate by
its _id_.

If _objectId_ is a temporary id which has expired, then then _Expired_
[Sentinel](#sentinel) is returned.

If _objectId_ refers to an object which has been collected by the VM's
garbage collector, then the _Collected_ [Sentinel](#sentinel) is
returned.

If the object handle has not expired and the object has not been
collected, then an [Object](#object) will be returned.

### getStack

```
Stack getStack(string isolateId)
```

The _getStack_ RPC is used to retrieve the current execution stack and
message queue for an isolate. The isolate does not need to be paused.

See [Stack](#stack).

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

### pause

```
Success pause(string isolateId)
```

The _pause_ RPC is used to interrupt a running isolate. The RPC enqueues the interrupt request and potentially returns before the isolate is paused.

When the isolate is paused an event will be sent on the _Debug_ stream.

See [Success](#success).

### removeBreakpoint

```
Success removeBreakpoint(string isolateId,
                         string breakpointId)
```

The _removeBreakpoint_ RPC is used to remove a breakpoint by its _id_.

Note that breakpoints are added and removed on a per-isolate basis.

See [Success](#success).

### resume

```
Success resume(string isolateId,
               StepOption step [optional])
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

See [Success](#success), [StepOption](#StepOption).

### setName

```
Success setName(string isolateId,
                string name)
```

The _setName_ RPC is used to change the debugging name for an isolate.

See [Success](#success).

### setLibraryDebuggable

```
Success setLibraryDebuggable(string isolateId,
                             string libraryId,
                             bool isDebuggable)
```

The _setLibraryDebuggable_ RPC is used to enable or disable whether
breakpoints and stepping work for a given library.

See [Success](#success).

### streamCancel

```
Success streamCancel(string streamId)
```

The _streamCancel_ RPC cancels a stream subscription in the VM.

If the client is not subscribed to the stream, the _104_ (Stream not
subscribed) error code is returned.

See [Success](#success).

### streamListen

```
Success streamListen(string streamId)
```

The _streamListen_ RPC subscribes to a stream in the VM. Once
subscribed, the client will begin receiving events from the stream.

If the client is not subscribed to the stream, the _103_ (Stream already
subscribed) error code is returned.

The _streamId_ parameter may have the following published values:

streamId | event types provided
-------- | -----------
Isolate | IsolateStart, IsolateExit, IsolateUpdate
Debug | PauseStart, PauseExit, PauseBreakpoint, PauseInterrupted, PauseException, Resume, BreakpointAdded, BreakpointResolved, BreakpointRemoved, Inspect
GC | GC

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
class BoundVariable {
  string name;
  @Instance|Sentinel value;
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
class Breakpoint extends Response {
  int breakpointNumber;
  bool resolved;
  SourceLocation location;
}
```

A _Breakpoint_ describes a debugger breakpoint.

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
  @Instance error [optional];

  // Is this an abstract class?
  bool abstract;

  // Is this a const class?
  bool const;

  // Has this class been finalized?
  bool finalized;

  // Is this class implemented?
  bool implemented;

  // Is this a vm patch class?
  bool patch;

  // The library which contains this class.
  @Library library;

  // The location of this class in the source code.
  SourceLocation location [optional];

  // The superclass of this class, if any.
  @Class super [optional];

  // A list of interface types for this class.
  //
  // The value will be of the kind: Type.
  @Instance[] interfaces;

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
class @Context {
  // The number of variables in this context.
  int length;
}
```

```
class Context {
  // The number of variables in this context.
  int length;

  // The enclosing context for this context.
  Context parent [optional];

  // The variables in this context object.
  ContextElement[] variables;
}
```

### ContextElement

```
class ContextElement {
  @Instance|Sentinel value;
}
```

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
[rpc error](#rpc-error).

### ErrorKind

```
enum ErrorKind {
  // The isolate has encountered an unhandled Dart exception.
  UnhandledException,

  // The isolate has encountered a Dart language error in the program.
  LanguageError,

  // The isolate has encounted an internal error. These errors should be
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
  @Isolate isolate;

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
}
```

An _Event_ is an asynchronous notification from the VM. It is delivered
only when the client has subscribed to an event stream using the
[streamListen](#streamListen) RPC.

For more information, see [events](#events).

### EventKind

```
enum EventKind {
  // Notification that a new isolate has started.
  IsolateStart,

  // Notification that an isolate has exited.
  IsolateExit,

  // Notification that isolate identifying information has changed.
  // Currently used to notify of changes to the isolate debugging name
  // via setName.
  IsolateUpdate,

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

  // An isolate has started or resumed execution.
  Resume,

  // A breakpoint has been added for an isolate.
  BreakpointAdded,

  // An unresolved breakpoint has been resolved for an isolate.
  BreakpointResolved,

  // A breakpoint has been removed.
  BreakpointRemoved,

  // A garbage collection event.
  GC,

  // Notification of bytes written, for example, to stdout/stderr.
  WriteEvent
}
```

Adding new values to _EventKind_ is considered a backwards compatible
change. Clients should ignore unrecognized events.

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
  // A list of all flags which are set to default values.
  Flag[] unmodifiedFlags;

  // A list of all flags which have been modified by the user.
  Flag[] modifiedFlags;
}
```

A _FlagList_ represents the complete set of VM command line flags.

### Frame

```
class Frame extends Response {
  int index;
  @Function function;
  @Code code;
  @Script script;
  int tokenPos;
  BoundVariable[] vars;
}
```

### Function

```
class @Function extends @Object {
  // The name of this function.
  string name;

  // The owner of this field, which can be a Library, Class, or a
  // Function.
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

  // The owner of this field, which can be a Library, Class, or a
  // Function.
  @Library|@Class|@Function owner;

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
  string valueAsString [optional];

  // The valueAsString for String references may be truncated. If so,
  // this property is added with the value 'true'.
  bool valueAsStringIsTruncated [optional];

  // The length of a List instance.
  //
  // Provided for instance kinds:
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


  // The pattern of a RegExp instance.
  //
  // Provided for instance kinds:
  //   RegExp
  String pattern [optional];
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
  string valueAsString [optional];

  // The valueAsString for String references may be truncated. If so,
  // this property is added with the value 'true'.
  bool valueAsStringIsTruncated [optional];

  // The length of a List instance.
  //
  // Provided for instance kinds:
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
  BoundField fields [optional];

  // The elements of a List instance.
  //
  // Provided for instance kinds:
  //   List
  @Instance|Sentinel[] elements [optional];

  // The elements of a List instance.
  //
  // Provided for instance kinds:
  //   Map
  MapAssociation[] associations [optional];

  // The bytes of a TypedData instance.
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
  int[] bytes [optional];

  // The function associated with a Closure instance.
  //
  // Provided for instance kinds:
  //   Closure
  @Function closureFunction [optional];

  // The context associated with a Closure instance.
  //
  // Provided for instance kinds:
  //   Closure
  @Function closureContext [optional];

  // The referent of a MirrorReference instance.
  //
  // Provided for instance kinds:
  //   MirrorReference
  @Instance mirrorReferent [optional];

  // The pattern of a RegExp instance.
  //
  // Provided for instance kinds:
  //   RegExp
  String pattern [optional];

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

  // An instance of the built-in VM TypedData implementations.  User-defined
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

  // An instance of the built-in VM Closure implementation. User-defined
  // Closures will be PlainInstance.
  Closure,

  // An instance of the Dart class MirrorReference.
  MirrorReference,

  // An instance of the Dart class RegExp.
  RegExp,

  // An instance of the Dart class WeakProperty.
  WeakProperty,

  // An instance of the Dart class Type
  Type,

  // An instance of the Dart class TypeParamer
  TypeParameter,

  // An instance of the Dart class TypeRef
  TypeRef,

  // An instance of the Dart class BoundedType
  BoundedType,
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

  // The time that the VM started in milliseconds since the epoch.
  //
  // Suitable to pass to DateTime.fromMillisecondsSinceEpoch.
  int startTime;

  // The entry function for this isolate.
  @Function entry [optional];

  // The number of live ports for this isolate.
  int livePorts;

  // Will this isolate pause when exiting?
  bool pauseOnExit;

  // The last pause event delivered to the isolate. If the isolate is
  // running, this will be a resume event.
  Event pauseEvent;

  // The error that is causing this isolate to exit, if applicable.
  Error error [optional];

  // The root library for this isolate.
  @Library rootLib;

  // A list of all libraries for this isolate.
  @Library[] libraries;

  // A list of all breakpoints for this isolate.
  Breakpoint[] breakpoints;
}
```

An _Isolate_ object provides information about one isolate in the VM.

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

  // Is this library debuggable?  Default true.
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

### MapAssociation

```
class MapAssociation {
  @Instance|Sentinel key;
  @Instance|Sentinel value;
}
```

### Message

```
class Message extends Response {
  int index;
  string name;
  string messageObjectId;
  int size;
  @Function handler [optional];
  SourceLocation location [optional];
}
```

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

  // The source code for this script. For certain built-in scripts,
  // this may be reconstructed without source comments.
  string source;

  // A table encoding a mapping from token position to line and column.
  int[][] tokenPosTable;
}
```

A _Script_ provides information about a Dart language script.

The _tokenPosTable_ is an array of int arrays. Each subarray
consists of a line number followed by _(tokenPos, columnNumber)_ pairs:

> [lineNumber, (tokenPos, columnNumber)*]

For example, a _tokenPosTable_ with the value...

> [[1, 100, 5, 101, 8],[2, 102, 7]]

...encodes the mapping:

tokenPos | line | column
-------- | ---- | ------
100 | 1 | 5
101 | 1 | 8
102 | 2 | 7

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

### Stack

```
class Stack extends Response {
  Frame[] frames;
  Message[] messages;
}
```

### StepOption

```
enum StepOption {
  Into,
  Over,
  Out
}
```

A _StepOption_ indicates which form of stepping is requested in a [resume](#resume) RPC.

### Success

```
class Success extends Response {
}
```

The _Success_ type is used to indicate that an operation completed successfully.

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
class VM extends Response {
  // Word length on target architecture (e.g. 32, 64).
  int architectureBits;

  // The CPU we are generating code for.
  string targetCPU;

  // The CPU we are actually running on.
  string hostCPU;

  // The Dart VM version string.
  string version;

  // The process id for the VM.
  string pid;

  // The time that the VM started in milliseconds since the epoch.
  //
  // Suitable to pass to DateTime.fromMillisecondsSinceEpoch.
  int startTime;

  // A list of isolates running in the VM.
  @Isolate[] isolates;
}
```

## Revision History

version | comments
------- | --------
1.0 draft 1 | initial revision


[discuss-list]: https://groups.google.com/a/dartlang.org/forum/#!forum/observatory-discuss
