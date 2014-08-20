# Dart VM Service Protocol

Description

## Response Format

### VM

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
| topFrame? | [@Frame](#atFrame) |
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
