A package used to spawn the Dart Developer Service (DDS), which is used to communicate with a Dart VM Service instance and provide extended functionality to the core VM Service Protocol.

# Functionality

Existing VM Service clients can issue both HTTP and websocket requests to a running DDS instance as if it were an instance of the VM Service itself. If a request corresponds to an RPC defined in the [VM Service Protocol][service-protocol], DDS will forward the request and return the response from the VM Service. Requests corresponding to an RPC defined in the [DDS Protocol][dds-protocol] will be handled directly by the DDS instance.

[dds-protocol]: dds_protocol.md
[service-protocol]: https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md
