# Changelog

## 4.1.0
- Update to version `3.35.0` of the spec.
- Expose more `@required` parameters on the named constructors of VM service objects.

## 4.0.4
- Update to version `3.34.0` of the spec.
- Fixed issue where `TimelineEvents` was not a valid service event kind.
- Fixed issue where invoking a service extension with no arguments would result
  in a TypeError during request routing.
- Added `TimelineStreamSubscriptionsUpdate` event, which is broadcast when
  `setVMTimelineFlags` is used to change the set of currently recording timeline
  streams.

## 4.0.3
- Update to version `3.33.0` of the spec.
- Add static error code constants to `RPCError`.
- Update the toString() method or `RPCError` and add a toMap() method.

## 4.0.2
- Fixed issue where RPC format did not conform to the JSON-RPC 2.0
  specification.
- Added `getClassList` RPC.

## 4.0.1
- Improved documentation.
- Fixed analysis issues.

## 4.0.0
- **breaking**: RPCs which can return a `Sentinel` will now throw a `SentinelException`
  if a `Sential` is received as a response.
- **breaking**: RPCs which can return multiple values now return
  `Future<Response>` rather than `Future<dynamic>`.
- `RPCError` now implements `Exception`.

## 3.0.0
- **breaking**: RPCs which have an isolateId parameter now return
  `Future<dynamic>` as a `Sentinel` can be returned if the target isolate no
  longer exists.

## 2.3.3
- Classes now implement their corresponding reference types to handle cases
  where the service returns a more specific type than promised.

## 2.3.2
- Added `getClientName`, `setClientName`, and `requireResumePermission` methods.
- Added `ClientName` class.

## 2.3.1
- Fixed issue where `dart:io` extensions were not being exported.

## 2.3.0
- Added `getHttpEnableTimelineLogging` and `setHttpEnableTimelineLogging` methods.
- Added `HttpTimelineLoggingState` class.

## 2.2.1
- Fixed issue where `TimelineEvent.toJson` always returned an empty map.

## 2.2.0
- Added support for interacting with dart:io service extensions.
- Bumped minimum SDK requirement to 2.6.0.

## 2.1.4
- Fixed issue where `TimelineEvent` always had no content.

## 2.1.3
- Fixed issue where exception would be thrown when attempting to parse a
  List entry in a response which is not present. This occurs when connected to
  a service which does not yet support the latest service protocol supported by
  this package.

## 2.1.2
- Requests which have not yet completed when `VmService.dispose` is invoked will
  now complete with an `RPCError` exception rather than a `String` exception.

## 2.1.1
- Added `getLineNumberFromTokenPos` and `getColumnNumberFromTokenPos` methods
  to `Script`.

## 2.1.0
- Added `HeapSnapshotGraph` class which parses the binary events posted to the
  `HeapSnapshot` stream after a `requestHeapSnapshot` invocation.
- Fixed issue where listening to `EventStream.kHeapSnapshot` and calling
  `requestHeapSnapshot` would throw an exception.

## 2.0.0
- **breaking**: VM service objects which have fields now have constructors with
  named parameters for each field. Required fields are annotated with `@required`.

## 1.2.0
- Support service protocol version 3.27:
  - Added `getCpuSamples` and `clearCpuSamples` methods
  - Added `CpuSamples`, `CpuSample`, and `ProfileFunction` classes.

## 1.1.2
- Fixed issue where `closureFunction` and `closureContext` were only expected in
  `Instance` objects rather than `InstanceRef`.

## 1.1.1
- Fixed issue serializing list arguments for certain VM service methods.
  - Issue #37872

## 1.1.0
- Support service protocol version 3.25:
  - Added `getInboundReferences`, `getRetainingPath` methods
  - Added `InboundReferences`, `InboundReference`, `RetainingPath`, and
    `RetainingObject` objects

## 1.0.1
- Support service protocol version 3.24:
  - Added `operatingSystem` property to `VM` object

## 1.0.0+1
- Updated description and homepage.

## 1.0.0
- Migrated `vm_service_lib` into the Dart SDK.
- Renamed from `package:vm_service_lib` to `package:vm_service`.
- Switched versioning system to follow semantic versioning standards instead of
  pinning versions to match the service protocol version.

## 3.22.2
- Fix `registerService` RPC and `Service` stream not being handled correctly.
- Fixed failing tests.

## 3.22.1
- **breaking**: Changed type of `library` property in `Class` objects from
  `ObjectRef` to `LibraryRef`.

## 3.22.0
- The `registerService` RPC and `Service` stream are now public.
- `Event` has been updated to include the optional `service`, `method`, and
  `alias` properties.

## 3.21.1
- **breaking**: Fixed issue where an `InstanceRef` of type `null` could be returned
  instead of null for non-`InstanceRef` properties and return values. As a
  result, some property and return types have been changed from Obj to their
  correct types.

## 3.21.0
- support service protocol version 3.21

## 3.20.0+2
- allow optional params in `getVMTimeline`

## 3.20.0+1
- handle null isolate ids in `callServiceExtension`
- add backwards compatibility for `InstanceSet` and `AllocationProfile`

## 3.20.0
- rev to 3.20.0; expose public methods added in 3.17 - 3.20 VM Service Protocol versions

## 3.17.0+1
- generate a list of available event streams

## 3.17.0
- rev to 3.17.0; expose the Logging event and the getMemoryUsage call

## 3.15.1+2
- fix handling of errors in registered service callbacks to return valid
  JSON-RPC errors and avoid the client getting "Service Disappeared" responses

## 3.15.1+1
- rename `getVmWsUriFromObservatoryUri` to `convertToWebSocketUrl`
- fix an assignment issue in `evaluate`

## 3.15.1
- Add `getVmWsUriFromObservatoryUri`, a helper function to convert observatory URIs
  into the required WebSocket URI for connecting to the VM service.

## 3.15.0
- support service protocol version 3.15
- fix an issue decoding null `Script.tokenPosTable` values

## 3.14.3-dev.4
- Add support for the `_Service` stream in the `VmServerConnection` directly.

## 3.14.3-dev.3
- Add support for automatically delegating service extension requests to the
  client which registered them.
  - This is only for services that are registered via the vm service protocol,
    services registered through `dart:developer` should be handled by the
    `VmServiceInterface` implementation (which should invoke the registered
    callback directly).
- Added a `ServiceExtensionRegistry` class, which tracks which clients have
  registered which service extensions.
- **breaking**: Renamed `VmServer` to `VmServerConnection`.
  - One `VmServerConnection` should be created _per client_ connection to the
    server. These should typically all share the same underlying
    `VmServiceInterface` instance, as well as the same
    `ServiceExtensionRegistry` instance.

## 3.14.3-dev.2
- Add `callServiceExtension` method to the `VmServiceInterface` class.
  - The `VmServer` will delegate all requests whose methods start with `ext.` to
    that implementation.

## 3.14.3-dev.1
- Add `VmServiceInterface` and `VmServer` classes, which can handle routing
  jsonrpc2 requests to a `VmServiceInterface` instance, and serializing the
  responses back.

## 3.14.3-dev.0
- Add `toJson` methods to all classes.

## 3.14.2
- fix code generation for the `getSourceReport` call

## 3.14.1
- address an encoding issue with stdout / stderr text

## 3.14.0
- regenerate for `v3.14`
- bump to a major version numbering scheme

## 0.3.10+2
- work around an issue de-serializing Instance.closureContext

## 0.3.10+1
- fix an issue de-serializing some object types

## 0.3.10
- regenerate for `v3.12`
- expose `isolate.getScripts()`
- expose `isolate.getInstances()`

## 0.3.9+2
- handle nulls for `Script.source`
- fix a decoding issue for `Script.tokenPosTable`

## 0.3.9+1
- rev to version `3.9` of the spec
- expose `invoke`

## 0.3.9
- Rename the `Null` type to `NullVal`

## 0.3.8
- upgrades for Dart 2 dependencies

## 0.3.7
- ensure the library works with Dart 2
- regenerate the library based on the 3.8-dev spec
- now require a minimum of a 2.0.0-dev Dart SDK
- update to not use deprecated dart:convert constants

## 0.3.6
- workaround for an issue with the type of @Library refs for VM objects

## 0.3.5+1
- bug fix for deserializing `Instance` objects

## 0.3.5
- improve access to the profiling APIs

## 0.3.4
- more strong mode runtime fixes
- expose some undocumented (and unsupported) service protocol methods

## 0.3.3
- fix strong mode issues at runtime (with JSLists and Lists)
- expose the ability to evaluate in the scope of another object
- expose the async causal frame info
- expose the `awaiterFrames` field
- expose the `frameIndex` param for the step call

## 0.3.2+1
- fix a strong mode issue in the generated Dart library

## 0.3.2
- expose the `PausePostRequest` event

## 0.3.1
- fix a parsing issue with ExtensionData

## 0.2.4
- expose the service protocol timeline API
- add the new `None` event type

## 0.2.3
- include the name of the calling method in RPC errors

## 0.2.2
- fixed several strong mode analysis issues

## 0.2.1
- upgrade to service protocol version `3.3`

## 0.2.0
- upgrade to service protocol version `3.2`

## 0.1.2
- fixed a bug with the `ServiceExtensionAdded` event

## 0.1.1
- expose the new 'Extension' event information

## 0.1.0
- rev to 0.1.0; declare first stable API version

## 0.0.13
- improve the toString() message for RPCError

## 0.0.12
- bug fix for parsing MapAssociations

## 0.0.11
- bug fix to the service extension API

## 0.0.10
- expose a service extension API

## 0.0.9
- update to the latest spec to capture the `Event.inspectee` field

## 0.0.8
- allow listening to arbitrary event types
- use Strings for the enum types (to allow for unknown enum values)

## 0.0.7
- make the diagnostic logging synchronous
- remove a workaround for a VM bug (fixed in 1.13.0-dev.7.3)
- several strong mode fixes

## 0.0.6
- added `exceptionPauseMode` to the Isolate class
- added `hashCode` and `operator==` methods to classes supporting object identity
- work around a VM bug with the `type` field of `BoundVariable` and `BoundField`

## 0.0.5
- added more dartdocs
- moved back to using Dart enums
- changed from optional positional params to optional named params

## 0.0.4
- enum redux

## 0.0.3
- update to use a custom enum class
- upgrade to the latest service protocol spec

## 0.0.2
- added the `setExceptionPauseMode` method
- fixed an issue with enum parsing

## 0.0.1
- first publish
- upgraded the library to the 3.0 version of the service protocol
- upgraded the library to the 2.0 version of the service protocol
- copied basic Dart API generator from Atom Dart Plugin
  https://github.com/dart-atom/dartlang/tree/master/tool
- refactored Dart code to generate Java client as well as Dart client
