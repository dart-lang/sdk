## 2.0.1-wip

- Include support for `package:protobuf` 5.0.

## 2.0.0

- Bump dependency constraint on `package:protobuf` to `>= 4.0.0`.
- Introduce `EventCategory`, `EventName`, and `DebugAnnotationName` classes.
- Add `eventCategories`, `eventNames`, `debugAnnotationNames` and
  `debugAnnotationStringValues` getters to `InternedData`.
- Add `nameIid` and `stringValueIid` getters to `DebugAnnotation`.
- Add `hasNameIid`, `clearNameIid`, `hasStringValueIid`, and
  `clearStringValueIid` methods to `DebugAnnotation`.
- Add `categoryIids` and `nameIid` getters to `TrackEvent`.
- Add `hasNameIid` and `clearNameIid` methods to `TrackEvent`.

## 1.0.0

- Initial version
- Add code for working with Perfetto protos, which can be imported from
  `'package:vm_service_protos/vm_service_protos.dart'`.
