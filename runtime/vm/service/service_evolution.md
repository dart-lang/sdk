# Evolving the Dart Service Protocol

This document outlines the mindset of the Dart Service Protocol designers and maintainers when it comes to extending or modifying the protocol. Any proposals or requests to update the protocol will be evaluated against the principles described below before being added to the protocol specification.

## Requirements

Any proposed additions to the Dart service protocol should adhere to the following principles.

### Perform Only Simple Operations

The API surface of the service protocol should remain as small and simple as possible. Proposed changes to the protocol will only be accepted if they meet one of the following criteria:

* There is no existing combination of RPCs that achieve the behavior proposed
* A level of atomicity is required that cannot be achieved by existing RPCs
* Significant demonstrable performance gains can be made by adding a specialized RPC (e.g., a batch version of an existing RPC)

### Avoid Introducing Side Effects

In general, interacting with the service protocol should avoid changing the state of the Dart instance. Side effects introduced as the result of a service protocol request may be difficult to debug, especially if they change state in a running Dart program. Although exceptions can be made in special circumstances, service protocol APIs should:

* **Be stateless.** Requests should be independent of one another. For example, assuming execution is paused and the Dart instance is effectively idle, invoking the same RPC twice should return the same result.
* **Be predictable.** If an API must change state, the resulting state change should be obvious and expected. For example, the `SetFlag` RPC allows for specific settings in the Dart instance to be changed but does not introduce any additional side effects.

### Keep Low-Powered Devices in Mind

As the Dart instance may be running on a remote or low-powered device, the service protocol should only provide functionality that doesn't make assumptions about the hardware configuration the Dart instance is running on. In addition, processing should be done on the client whenever possible to maintain reasonable performance in the case where the Dart instance is running on a remote or low-powered device.

Based on the principles above, any changes to the service protocol must satisfy the following:

* **The proposed change must be valid for all types of devices, regardless of their performance.** For example, a request to reduce the minimal sample rate for the profiler from 50us to 10us would be rejected as low-end ARM devices are unable to handle a 10us sample period, often leading to a crash.
* **Keep as much processing as possible on the client side to avoid slowdowns on low-end devices.** For example, dominator analysis of a heap snapshot is performed on the client side in Observatory.

### Implementation Agnostic

The Dart service protocol is designed to be usable by any implementation of Dart, not just the Dart VM in the official Dart SDK. As a result, the protocol must avoid exposing details of the underlying implementation through its interface. Any exposure of implementation details must only be done through private RPCs and their responses and should only be used within the context of that implementation (e.g., private RPCs provided by the Dart VM are fine to be used within Observatory but are not advertised to, and should not be used by, external clients).

For example, the fact that the Dart VM currently uses a generational garbage collector may not be true in the future, so a response containing information about new and old space should not be exposed through the protocol.

## FAQ

**_Q: I want to get information about system X but there's no way to query for that information over the service protocol. Can we add a new RPC for this?_**

**A:** Maybe! If it's not possible to achieve something through the current service protocol, adding support for that operation can be investigated. However, only RPCs which do not violate the principles stated above will be accepted into the protocol.

**_Q: There's a certain series of RPCs that I invoke frequently. Can we create a single RPC for this operation?_**

**A:** No, unless there is a need for the operations performed by the series of RPCs to be performed atomically or there is a significant performance benefit of performing work in a single RPC.

**_Q: I'd like to do an experiment that requires changes to the service protocol. How can I do this?_**

**A:** Assuming there's no significant performance impact anticipated by an experimental RPC, it's possible to add experimental functionality to the service protocol. Any experimental functionality should either be marked as private or be documented as being experimental and that it may be deprecated without notice. Experimental RPCs should have a short lifespan and be documented with an expected expiration date.

Any experimental changes that are intended to be permanent must adhere to the principles described in the first section of this document.

If you require assistance in adding experimental functionality to the protocol, please reach out to the maintainers at dart-service-protocol@google.com. Changes required to the Dart VM service implementation can also be handled by members of dart-service-protocol@google.com or dart-vm-team@google.com.

**_Q: There's a private RPC that performs functionality that I'm looking for. Can I use it?_**

**A: No, private RPCs and their responses should not be used outside of the Dart SDK.** The implementations of these RPCs and responses are subject to change without warning and unauthorized private RPC requests may be discarded in the future.

**_Q: Can we make a private RPC public?_**

**A:** In general, no. While some private RPCs and responses can be made public without much effort, many expose internal implementation details of the VM itself for use by VM engineers in Observatory. If there is a strong case for exposing functionality provided by a private RPC, a new public RPC will need to be defined in order to keep the protocol from exposing implementation details of the system.

**_Q: I have more questions about the service protocol. Who can I contact?_**

**A:** The Dart VM team is responsible for maintaining the service protocol. The current maintainers can be contacted at dart-service-protocol@google.com.
