library metadata;

import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors.dart';

/// Returns the metadata for the given string or null if not found.
InstanceMirror findMetadata(List<InstanceMirror> metadataList, String find) {
  return metadataList.firstMatching(
      (metadata) {
        if (metadata is TypeInstanceMirror) {
          return metadata.representedType.simpleName == find;
        }
        return metadata.type.simpleName == find;
      }, orElse: () => null);
}
