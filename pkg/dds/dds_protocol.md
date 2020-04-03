# Dart Development Service Protocol 0.x

This document describes _version 0.x_ of the Dart Development Service Protocol.
This protocol is an extension of the Dart VM Service Protocol and implements it
in it's entirety. For details on the VM Service Protocol, see the [Dart VM Service Protocol Specification][service-protocol].

The Service Protocol uses [JSON-RPC 2.0][].

[JSON-RPC 2.0]: http://www.jsonrpc.org/specification


**Table of Contents**

- [RPCs, Requests, and Responses](#rpcs-requests-and-responses)
- [Events](#events)
- [Types](#types)
- [IDs and Names](#ids-and-names)
- [Revision History](#revision-history)

## RPCs, Requests, and Responses

See the corresponding section in the VM Service protocol [here][service-protocol-rpcs-requests-and-responses].

## Events

See the corresponding section in the VM Service protocol [here][service-protocol-events].

## Binary Events

See the corresponding section in the VM Service protocol [here][service-protocol-binary-events].

## Types

See the corresponding section in the VM Service protocol [here][service-protocol-types].

## IDs and Names

See the corresponding section in the VM Service protocol [here][service-protocol-ids-and-names].

## Public RPCs

The DDS Protocol supports all [public RPCs defined in the VM Service protocol][service-protocol-public-rpcs].

## Revision History

version | comments
------- | --------
0.x | Initial revision

[service-protocol]: https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md
[service-protocol-rpcs-requests-and-responses]: https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md#rpcs-requests-and-responses
[service-protocol-events]: https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md#events
[service-protocol-binary-events]: https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md#binary-events
[service-protocol-types]: https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md#types
[service-protocol-ids-and-names]: https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md#ids-and-names
[service-protocol-public-rpcs]: https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md#public-rpcs