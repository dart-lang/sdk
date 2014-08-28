# Dart VM Service Protocol

NOTE: The service api is still changing rapidly.  If you use the
service api, expect to encounter non-compatible changes.

Description
How to start
JSON
Websocket

## Types

Every response returned by the VM Service has the <code>type</code>
property.  This allows the client distinguish between different kinds
of responses.  For example, global information about the VM is encoded
in an response of type [VM](#VM) and information about an isolate is
encoded in an response of type [Isolate](#Isolate).

If the type name of a response begins with an <code>@</code> character
then that response is a _reference_.  If the type name of a response
does not begin with an <code>@</code> character then that response is
an _object_ (or sometimes _full object_).  A reference is meant to be
a subset of a full object with just enough information for the client
to generate a reasonable-looking link.

For example, an isolate reference may look like this...

    {
      type: "@Isolate",
      id: "isolates/123",
      name: "worker"
    }

... and a full isolate object would have additional properties:

    {
      type: "Isolate",
      id: "isolates/123",
      name: "worker"
      entry: ...
      heaps: ...
      topFrame: ...
      ...
    }

## IDs

Most responses returned by the VM Service have an <code>id</code>
property.  An id is used to request an object from the VM.  Each id is
unique; that is to say, If two responses have the same id, they refer
to the same object.  The converse is not true: the same object may
occasionally be returned with two different ids.

An id is either _global_ or _relative_.  Global ids can be requested
from the VM directly by requesting the uri <code>/{global id}</code>.

The following is a list of known,  fixed global ids:

| id | uri | type
| --- | --- | ---
| vm | /vm | [VM](#VM)
| flags | /flags | [FlagList](#FlagList)

In addition, all isolates have global ids, but these ids are
dynamically generated.  An isolate with an id like
<code>isolates/123</code> would be available at the uri
<code>/isolates/123</code>.

Relative ids are used to refer to objects that are owned by an
isolate.  Relative ids can be requested from the VM directly by
requesting the uri <code>/{isolate&nbsp;id}/{relative&nbsp;id}</code>.

For example, we can get information about a class with id
<code>classes/Foo</code> from isolate <code>isolates/123</code> by
requesting the uri <code>/isolates/123/classes/Foo</code> from the VM.

The client must not parse ids -- they must be treated as opaque
strings.  We reserve the right to change the ids of objects.

## Names

Many responses have the <code>name</code> property.  Names are
provided so that objects can be displayed in a way that a Dart
language programmer would find sensible.

Note that names are not in any way unique.  Many objects will have the
same name.

Occasionally responses will have the <code>vmName</code> property.
This represents the internal names used to refer to an object inside
the VM itself.  The <code>vmName</code> of an object is only provided
when it differs from the <code>name</code> property; when
<code>vmName</code> is not present, the client may assume the
<code>name</code> and <code>vmName</code> are the same.

## Events

TODO

## Catalog of Types

### <a name="atAbstractType"></a>@AbstractType

### <a name="AbstractType"></a>AbstractType

### <a name="Breakpoint"></a>Breakpoint

TODO: Get rid of Location or else use it more generally.

| keys | values | comments
| --- | --- | ---
| type | "Breakpoint" |
| id | String |
| breakpointNumber | int |
| enabled | bool |
| resolved | bool |
| location | [Location](#Location) |

### <a name="atClass"></a>@Class
| keys | values | comments
| --- | --- | ---
| type | "@Class" |
| id | String |
| name | String |
| vmName? | String |

### <a name="Class"></a>Class
| keys | values | comments
| --- | --- | ---
| type | "@Class" |
| id | String |
| name | String |
| vmName? | String |
| error? | [Error](#Error) | Error encountered during class finalization
| implemented | bool |
| abstract | bool |
| patch | bool |
| finalized | bool |
| const | bool |
| super? | [@Class](#atClass) | Super class
| library | [@Library](#atLibrary) | Owning library
| script? | [@Script](#atScript) | Script containing class source
| tokenPos? | int | starting token position of class source in script
| endTokenPos? | int | end token position of class source in script
| interfaces | List of [@Class](#atClass) | interfaces this class has implemented
| fields | List of [@Field](#atField) |
| functions | List of [@Function](#atFunction) |
| subclasses | List of [@Class](#atClass) | classes which extend this class.
| canonicalTypes | [@TypeList] | kill?
| allocationStats | ClassHeapStats |

### <a name="ClassHeapStats"></a>ClassHeapStats
| keys | values | comments
| --- | --- | ---
| type | "ClassHeapStats" |
| id | String |
| class | [@Class](#atClass) |
| new | List of int | Allocation statistics for new space. See note below on allocation statistics list format.
| old | List of int | Allocation statistics for old space. See note below on allocation statistics list format.
| promotedInstances | int | number of instances promoted at last new-space GC.
| promotedBytes | int | number of bytes promoted at last new-space GC.

*Allocation statistics list format*
| index | value | description
| --- | --- | --- |
| 0 | int | Instances allocated before last GC |
| 1 | int | Bytes allocated before last GC |
| 2 | int | Instances alive after last GC |
| 3 | int | Bytes alive after last GC |
| 4 | int | Instances allocated since last GC |
| 5 | int | Bytes allocated since last GC |
| 6 | int | Instances allocated since last accumulator reset |
| 7 | int | Bytes allocated since last accumulator reset |

### <a name="atCode"></a>@Code
| keys | values | comments
| --- | --- | ---
| type | "@Code" |
| id | String |
| name | String |
| vmName? | String |
| start | String | starting address of code
| end | String | ending address of code
| isOptimized | bool |
| isAlive | bool |
| kind | String
| function | [@Function](#atFunction) |

### <a name="Code"></a>Code
| keys | values | comments
| --- | --- | ---
| type | "@Code" |
| id | String |
| name | String |
| vmName? | String |
| start | String | starting address of code
| end | String | ending address of code
| isOptimized | bool |
| isAlive | bool |
| kind | String
| function | [@Function](#atFunction) |
| object_pool | List of [@Object](Object) |
| disassembly | List of String | See note below on disassembly list format

*Disassembly list format*
| index | value | description
| --- | --- | --- |
| 0 | String | Address of instruction
| 1 | String | Hex encoding of instruction
| 2 | String | Human encoding of instruction
| 0 + (3 * K) | String | Address of Kth instruction
| 1 + (3 * K) | String | Hex encoding of instruction of Kth instruction
| 2 + (3 * K) | String | Human encoding of instruction of Kth instruction

### <a name="DebuggerEvent"></a>DebuggerEvent

| keys | values | comments
| --- | --- | ---
| type | "DebuggerEvent" |
| id | String | TODO: Remove |
| eventType | String | "BreakpointReached", "BreakpointResolved", "ExceptionThrown", "IsolateCreated", "IsolateShutdown", or "IsolateInterrupted" |
| isolate | [@Isolate](#atIsolate) |
| breakpoint? | [Breakpoint](#atBreakpoint) | for eventTypes "BreakpointResolved" and "BreakpointReached<br><br>TODO: Maybe make this @Breakpoint?
| exception? | [@Instance](#atInstance) | for eventType "ExceptionThrown"

### <a name="Error"></a>Error

TODO: Drop id from Error.

| keys | values | comments
| --- | --- | ---
| type | "Error" |
| id | String | always empty
| kind | String |
| message | String |

### <a name="atField"></a>@Field
| keys | values | comments
| --- | --- | ---
| type | "@Field" |
| id | String |
| name | String |
| vmName? | String |
| value? | Instance | value associated with static field <-- do we want to include this in a field reference?
| owner | [@Library](#atLibrary),[@Class](#atClass) | Owning library or class <-- handling of owner is inconsistent with Function
| declared_type | [@AbstractType](#atAbstractType) |
| static | bool |
| final | bool |
| const | bool |

### <a name="Field"></a>Field
| keys | values | comments
| --- | --- | ---
| type | "Field" |
| id | String |
| name | String |
| vmName? | String |
| value? | Instance | value associated with static field
| owner | [@Library](#atLibrary) | Owning library <-- handling of owner is inconsistent with Function
| owner | [@Class](#atClass) | Owning class <-- handling of owner is inconsistent with Function
| declared_type | [@AbstractType](#atAbstractType) |
| static | bool |
| final | bool |
| const | bool |
| guard_nullable | bool | can this field hold a null?
| guard_class | String OR [@Class](#atClass) | "unknown", "dynamic", or a class
| guard_length | String OR int | "unknown", "variable", or length of array
| script? | [@Script](#atScript) | Script containing field source
| tokenPos? | int | starting token position of field source in script

### <a name="Frame"></a>Frame

TODO: Add type and id?<br>

| keys | values | comments
| --- | --- | ---
| script | [@Script](#atScript) |
| tokenPos | int |
| function | [@Function](#atFunction) |
| code | [@Code](#atCode) |
| vars | List of [FrameVar](#FrameVar) |

### <a name="FrameVar"></a>FrameVar

| keys | values | comments
| --- | --- | ---
| name | String |
| value | [@Instance](#atInstance) |

### <a name="atFunction"></a>@Function
| keys | values | comments
| --- | --- | ---
| type | "@Function" |
| id | String |
| name | String |
| vmName? | String |
| owningLibrary? | [@Library](#atLibrary) | Set for non-top level functions
| owningClass? | [@Class](#atClass) | Set for non-top level functions
| parent? | [@Function](#atFunction) | Parent function
| kind | String |

### <a name="Function"></a>Function
| keys | values | comments
| --- | --- | ---
| type | "@Function" |
| id | String |
| name | String |
| vmName? | String |
| owningLibrary | [@Library](#atLibrary) | Set for non-top level functions
| owningClass | [@Class](#atClass) | Set for non-top level functions
| parent? | [@Function](#atFunction) | Parent function
| kind | String |
| static | bool |
| const | bool |
| optimizable | bool |
| inlinable | bool |
| usage_counter | int |
| optimized_call_site_count | int |
| deoptimizations | int |
| script? | [@Script](#atScript) | Script containing function source
| tokenPos? | int | starting token position of function source in script
| endTokenPos? | int | end token position of function source in script
| unoptimized_code | [@Code](#atCode) |
| code | [@Code](#atCode) | Current code

### <a name="atIsolate"></a>@Isolate

| keys | values | comments
| --- | --- | ---
| type | "@Isolate" |
| id | String |
| mainPort | String | kill? |
| name | String |

### Isolate

| keys | values | comments
| --- | --- | ---
| type | "Isolate" |
| id | String |
| mainPort | String | kill? |
| name | String |
| entry? | [@Function](#atFunction) |
| heaps | ??? |
| topFrame? | [Frame](#Frame) |
| livePorts | int |
| pauseOnExit | bool |
| pauseEvent? | [DebuggerEvent](#DebuggerEvent) |
| rootLib | [@Library](#atLibrary) |
| timers | ??? |
| tagCounters | ??? |
| error? | [Error](#Error) |
| canonicalTypeArguments | | kill? |
| libs | List of [@Library](#atLibrary) |
| features | List of String |

### <a name="atLibrary"></a>@Library

| keys | values | comments
| --- | --- | ---
| type | "@Library" |
| id | String |
| name | String |
| vmName? | String | Internal vm name.  Provided only when different from 'name'.
| url | String

### <a name="Library"></a>Library

| keys | values | comments
| --- | --- | ---
| type | "Library" |
| id | String |
| name | String |
| vmName? | String | Internal vm name.  Provided only when different from 'name'.
| classes | List of [@Class](#atClass) |
| imports | List of [@Library](#atLibrary) |
| variables | List of ... |
| functions | List of [@Function](#atFunction) |
| scripts | List of [@Script](#atScript) |

### <a name="Location"></a>Location

| keys | values | comments
| --- | --- | ---
| type | "Location" |
| script | [@Script](#atScript) |
| tokenPos | int |

### <a name="@Null"></a>@Null

TODO: Split Null from the other Sentinel types.

| keys | values | comments
| --- | --- | ---
| type | "@Null" |
| id | String | |
| valueAsString | String |

### <a name="PcDescriptor"></a>PcDescriptor

### <a name="atScript"></a>@Script
| keys | values | comments | example |
| --- | --- | ---
| type | "@Script" |
| id | String
| name | String
| vmName? | String | Internal vm name.  Provided only when different from 'name'.
| kind | String

### <a name="Script"></a>Script
| keys | values | comments
| --- | --- | ---
| type | "@Script" |
| id | String
| name | String
| vmName? | String | Internal vm name.  Provided only when different from 'name'.
| kind | String
| owningLibrary | [@Library](#atLibrary) |
| source | String
| tokenPosTable | List of list of int. See note below about token line format.

*Token line format*
| index | value | comments
| --- | --- | ---
| 0   | int | line number
| 1   | int | first token position
| 2   | int | first column number
| ... | ... | ...
| 1 + (2 * k) | int | kth token position
| 2 + (2 * k) | int | kth column number

### <a name="Sentinel"></a>Sentinel

TODO: Enumerate known Sentinels
TODO: Should this even have an id?  Maybe a *kind* instead.

| keys | values | comments
| --- | --- | ---
| type | "Sentinel" |
| id | String | |
| valueAsString | String |

### <a name="VM"></a>VM

| keys | values | comments
| --- | --- | ---
| type | "VM" |
| id | String |
| targetCPU | String |
| hostCPU | String |
| date | String | kill? |
| version | String |
| pid | int |
| assertsEnabled | bool | TODO: move to features? |
| typeChecksEnabled | bool | TODO: move to features? |
| uptime | double | seconds since vm started |
| "isolates"    | List of [@Isolate](#atIsolate)  |

