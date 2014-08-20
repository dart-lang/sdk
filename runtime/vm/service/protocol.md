# Dart VM Service Protocol

Description
How to start
JSON
Websocket

## Types

Every response returned by the VM Service has the <code>type</code> property.  This allows the client distinguish between different kinds of responses.  For example, global information about the VM is encoded in an response of type [VM](#VM) and information about an isolate is encoded in an response of type [Isolate](#Isolate).

If the type name of a response begins with an <code>@</code> character then that response is a _reference_.  If the type name of a response does not begin with an <code>@</code> character then that response is an _object_ (or sometimes _full object_).  A reference is meant to be a subset of a full object with just enough information for the client to generate a reasonable-looking link.

For example, an isolate reference may look like this...

    {
      type: "@Isolate",
      id: "isolates/123",
      name: "worker"
    }

... and a full isolate object would have additional properties:

    {
      type: "@Isolate",
      id: "isolates/123",
      name: "worker"
      entry: ...
      heaps: ...
      topFrame: ...
      ...
    }
 
## IDs

Most responses returned by the VM Service have an <code>id</code> property.  An id is used to request an object from the VM.

An id is either _global_ or _relative_.  Global ids can be requested from the VM directly by requesting the uri <code>/{global id}</code>.

The following is a list of known,  fixed global ids:

| id | uri | type
| --- | --- | ---
| vm | /vm | [VM](#VM)
| flags | /flags | [FlagList](#FlagList)

In addition, all isolates have global ids, but these ids are dynamically generated.  An isolate with an id like <code>isolates/123</code> would be available at the uri <code>/isolates/123</code>.

Relative ids are used to refer to objects that are owned by an isolate.  Relative ids can be requested from the VM directly by requesting the uri <code>/{isolate&nbsp;id}/{relative&nbsp;id}</code>.

For example, we can get information about a class with id <code>classes/Foo</code> from isolate <code>isolates/123</code> by requesting the uri <code>/isolates/123/classes/Foo</code> from the VM.

The client must not parse ids -- they must be treated as opaque strings.  We reserve the right to change the ids of objects.

## Events

TODO

## Catalog of Types
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
| user_name | String |
| name | String
| url | String

### <a name="Library"></a>Library

| keys | values | comments
| --- | --- | ---
| type | "Library" |
| id | String |
| user_name | String |
| name | String
| classes | List of [@Class](#atClass) |
| imports | List of [@Library](#atLibrary) |
| variables | List of ... |
| functions | List of [@Function](#atFunction) |
| scripts | List of [@Script](#atScript) |

### <a name="atScript"></a>@Script
| keys | values | comments | example |
| --- | --- | ---
| type | "@Script" |
| id | String
| user_name | String
| name | String
| kind | String

### <a name="Script"></a>Script
| keys | values | comments
| --- | --- | ---
| type | "@Script" |
| id | String
| user_name | String
| name | String
| kind | String
| owningLibrary | [@Library](#atLibrary) |
| source | String
| tokenPosTable | List of TokenLine

### <a name="TokenLine"></a>TokenLine
| index | value | comments
| --- | --- | ---
| 0   | integer | line number
| 1   | integer | first token position
| 2   | integer | first column number
| ... | ... | ...
| 1 + (2 * k) | integer | kth token position
| 2 + (2 * k) | integer | kth column number
