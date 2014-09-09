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

## Type Hierarchy

The types returned by the VM Service fit into a type hierarchy, with a
subtyping relationship as indicated by the following indented list:

<pre>
Object
    ClassHeapStats
    Class
    Code
    Context
    Counter
    Error
    Field
    FrameVar
    Frame
    Function
    Gauge
    Instance
        AbstractType
	    BoundedType
	    TypeParameter
	    TypeRef
	    Type
        List
        Sentinel  // TODO - subtype of Instance or not?
        String
        bool
        double
        int
        null
    Isolate
    Library
    Location
    Script
    ServiceError
    ServiceEvent
    Socket
    TypeArguments  // TODO - expose?
    VM
</pre>

TODO: How to put links in a pre in markdown?

A subtype is guaranteed to provide all of the properties of its
parent type.  For example, an [int](#int) can be used as an
[Instance](#Instance).

The subtyping relationship also holds for reference types.  For
example, [@int](#int) can be used as an [@Instance](#Instance).

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

## Private Properties

Some properties returned by the VM Service begin with an underscore
(<code>_</code>) character.  These properties are called _private
properties_.  Private properties provide private information about the
VM's implementation.  Private properties may be added, removed, or
changed at any time with any release of the VM.  They are provided for
those tools that need this level of internal access, such as the
Observatory.

For example, some responses will have the <code>_vmType</code>
nnnproperty.  This provides the VM-internal type name of an object, and
is provided only when this type name differs from the
<code>type</code> property.

## Events

TODO

## Catalog of Types

### <a name="AbstractType"></a>AbstractType

### <a name="Breakpoint"></a>Breakpoint

TODO: Get rid of Location or else use it more generally.

Object properties:

| keys | values | comments
| --- | --- | ---
| type | "Breakpoint" |
| id | String |
| breakpointNumber | int |
| enabled | bool |
| resolved | bool |
| location | [Location](#Location) |

### <a name="Class"></a>Class

Reference properties:

| keys | values | comments
| --- | --- | ---
| type | "@Class", "Class" |
| id | String |
| name | String |
| _vmName? | String |

Object properties:

| keys | values | comments
| --- | --- | ---
| error? | [Error](#Error) | Error encountered during class finalization
| implemented | bool |
| abstract | bool |
| patch | bool |
| finalized | bool |
| const | bool |
| super? | [@Class](#Class) | Super class
| library | [@Library](#Library) | Owning library
| script? | [@Script](#Script) | Script containing class source
| tokenPos? | int | starting token position of class source in script
| endTokenPos? | int | end token position of class source in script
| interfaces | List of [@Class](#Class) | interfaces this class has implemented
| fields | List of [@Field](#Field) |
| functions | List of [@Function](#Function) |
| subclasses | List of [@Class](#Class) | classes which extend this class.
| canonicalTypes | [@TypeList] | kill?
| allocationStats | ClassHeapStats |

### <a name="ClassHeapStats"></a>ClassHeapStats

Object properties:

| keys | values | comments
| --- | --- | ---
| type | "ClassHeapStats" |
| id | String |
| class | [@Class](#Class) |
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

### <a name="Code"></a>Code

Reference properties:

| keys | values | comments
| --- | --- | ---
| type | "@Code", "Code"|
| id | String |
| name | String |
| _vmName? | String |
| start | String | starting address of code
| end | String | ending address of code
| isOptimized | bool |
| isAlive | bool |
| kind | String
| function | [@Function](#Function) |

Object properties:

| keys | values | comments
| --- | --- | ---
| start | String | starting address of code
| end | String | ending address of code
| isOptimized | bool |
| isAlive | bool |
| kind | String
| function | [@Function](#Function) |
| object_pool | List of [@Object](#Object) |
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

### <a name="Error"></a>Error

TODO: Drop id from Error.<br>

Object properties:

| keys | values | comments
| --- | --- | ---
| type | "Error" |
| _vmType? | String | VM internal name for this type.  Provided only when different from 'type'
| id | String | always empty
| kind | String |
| message | String |

### <a name="Field"></a>Field

Reference properties:

| keys | values | comments
| --- | --- | ---
| type | "@Field", "Field" |
| id | String |
| name | String |
| _vmName? | String |
| value? | Instance | value associated with static field <-- do we want to include this in a field reference?
| owner | [@Library](#Library),[@Class](#Class) | Owning library or class <-- handling of owner is inconsistent with Function
| declared_type | [@AbstractType](#AbstractType) |
| static | bool |
| final | bool |
| const | bool |

Object properties:

| keys | values | comments
| --- | --- | ---
| guard_nullable | bool | can this field hold a null?
| guard_class | String OR [@Class](#Class) | "unknown", "dynamic", or a class
| guard_length | String OR int | "unknown", "variable", or length of array
| script? | [@Script](#Script) | Script containing field source
| tokenPos? | int | starting token position of field source in script

### <a name="Frame"></a>Frame

TODO: Add type and id?<br>

Object properties:

| keys | values | comments
| --- | --- | ---
| script | [@Script](#Script) |
| tokenPos | int |
| function | [@Function](#Function) |
| code | [@Code](#Code) |
| vars | List of [FrameVar](#FrameVar) |

### <a name="FrameVar"></a>FrameVar

Object properties:

| keys | values | comments
| --- | --- | ---
| name | String |
| value | [@Instance](#Instance) |

### <a name="Function"></a>Function

Reference properties:

| keys | values | comments
| --- | --- | ---
| type | "@Function", "Function" |
| id | String |
| name | String |
| _vmName? | String |
| owningLibrary? | [@Library](#Library) | Set for non-top level functions
| owningClass? | [@Class](#Class) | Set for non-top level functions
| parent? | [@Function](#Function) | Parent function
| kind | String |

Object properties:

| keys | values | comments
| --- | --- | ---
| static | bool | TODO: not consistent with Field 
| const | bool |
| optimizable | bool |
| inlinable | bool |
| usage_counter | int |
| optimized_call_site_count | int |
| deoptimizations | int |
| script? | [@Script](#Script) | Script containing function source
| tokenPos? | int | starting token position of function source in script
| endTokenPos? | int | end token position of function source in script
| unoptimized_code | [@Code](#Code) |
| code | [@Code](#Code) | Current code

### <a name="Isolate"></a>Isolate

Reference properties:

| keys | values | comments
| --- | --- | ---
| type | "@Isolate", "Isolate" |
| id | String |
| mainPort | String | kill? |
| name | String |

Object properties:

| keys | values | comments
| --- | --- | ---
| entry? | [@Function](#Function) |
| heaps | ??? |
| topFrame? | [Frame](#Frame) |
| livePorts | int |
| pauseOnExit | bool |
| pauseEvent? | [DebuggerEvent](#DebuggerEvent) |
| rootLib | [@Library](#Library) |
| timers | ??? |
| tagCounters | ??? |
| error? | [Error](#Error) |
| canonicalTypeArguments | | kill? |
| libs | List of [@Library](#Library) |
| features | List of String |

### <a name="Library"></a>Library

Reference properties:

| keys | values | comments
| --- | --- | ---
| type | "@Library", "Library" |
| id | String |
| name | String |
| _vmName? | String | VM-internal name.  Provided only when different from 'name'.
| url | String

Object properties:

| keys | values | comments
| --- | --- | ---
| classes | List of [@Class](#Class) |
| imports | List of [@Library](#Library) |
| variables | List of ... |
| functions | List of [@Function](#Function) |
| scripts | List of [@Script](#Script) |

### <a name="Location"></a>Location

Object properties:

| keys | values | comments
| --- | --- | ---
| type | "Location" |
| script | [@Script](#Script) |
| tokenPos | int |

### <a name="null"></a>null

Reference properties:

| keys | values | comments
| --- | --- | ---
| type | "@null", "null" |
| id | String | |
| valueAsString | String |

Object properties:<br>

TODO.

### <a name="Object"></a>Object

[Object](#Object) is the supertype of all responses returned by the VM
Service.  It does not necessarily refer to an Object at the Dart
language level (see [Instance](#Instance)).

Reference properties:

| keys | values | comments
| --- | --- | ---
| type | "@Object", "Object" or subtype |
| _vmType? | String | VM internal name for this type.  Provided only when different from 'type'
| id | String |

Object properties: none<br>

### <a name="PcDescriptor"></a>PcDescriptor

### <a name="Script"></a>Script

Reference properties:

| keys | values | comments | example |
| --- | --- | ---
| type | "@Script", "Script" |
| id | String
| name | String
| _vmName? | String | VM-internal name.  Provided only when different from 'name'.
| kind | String

Object properties:

| keys | values | comments
| --- | --- | ---
| owningLibrary | [@Library](#Library)
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

TODO: Enumerate known Sentinels<br>
TODO: Should this even have an id?  Maybe a *kind* instead.<br><br>

Object properties:

| keys | values | comments
| --- | --- | ---
| type | "Sentinel" |
| id | String | |
| valueAsString | String |

### <a name="ServiceEvent"></a>ServiceEvent

Object properties:

| keys | values | comments
| --- | --- | ---
| type | "ServiceEvent" |
| id | String | TODO: Remove |
| eventType | String | "BreakpointReached", "BreakpointResolved", "ExceptionThrown", "IsolateCreated", "IsolateShutdown", "IsolateInterrupted" |
| isolate | [@Isolate](#Isolate) |
| breakpoint? | [Breakpoint](#Breakpoint) | for eventTypes "BreakpointResolved" and "BreakpointReached<br><br>TODO: Maybe make this @Breakpoint?
| exception? | [@Instance](#Instance) | for eventType "ExceptionThrown"

### <a name="VM"></a>VM

Object properties:

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
| "isolates"    | List of [@Isolate](#Isolate)  |

