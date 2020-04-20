# VM Service Feature Availability

This table describe which features of the [VM service protocol](service.md) are available in different modes of the Dart VM. In general, the JIT supports the full set of features, and AOT supports features that do not require code generation or modification. When attempting to use a feature in a mode where it is not supported, the service RPC will return error code 100 ("Feature is disabled").

| Feature                         | Supported Modes                         |
| ---                             | ---                                     |
| CPU Profiler                    | All Modes                               |
| Dart Allocation Site Profiler   | JIT only                                |
| Malloc Allocation Site Profiler | Debug VM builds only                    |
| Allocation Table                | All Modes                               |
| Heap Snapshot                   | All Modes                               |
| Metrics                         | All Modes                               |
| Timeline/Tracing                | All Modes                               |
| Object Inspection               | All Modes                               |
| Stack Inspection                | JIT only                                |
| Breakpoints/Pause-on-Exception  | JIT only                                |
| Stepping                        | JIT only                                |
| Pausing/Resuming                | JIT only [1]                            |
| Reload                          | JIT with a compilation server available |
| Evaluate                        | JIT with a compilation server available |
| Invoke                          | JIT + AOT [2]                           |

[1] This could be added to AOT without affecting AOT code generation, but has not yet been implemented.

[2] The target function must be annotated as an entry point to work under AOT.
