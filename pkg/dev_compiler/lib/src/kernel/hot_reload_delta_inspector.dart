// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/library_index.dart';

/// Inspects a delta [Component] and compares against the last known accepted
/// version.
class HotReloadDeltaInspector {
  /// A partial index for the last accepted generation [Component].
  ///
  /// In practice this is likely a partial index of the last known accepted
  /// generation that only contains the libraries present in the delta.
  late LibraryIndex _partialLastAcceptedLibraryIndex;

  /// Rejection errors discovered while comparing a delta with the previous
  /// generation.
  final _rejectionMessages = <String>[];

  /// Returns all hot reload rejection errors discovered while comparing [delta]
  /// against the [lastAccepted] version.
  ///
  /// Attaches metadata to the [delta] component to be consumed by DDC when
  /// compiling.
  List<String> compareGenerations(Component lastAccepted, Component delta) {
    final hotReloadLibraryMetadata =
        lastAccepted.metadata[hotReloadLibraryMetadataTag]
                as HotReloadLibraryMetadataRepository? ??
            HotReloadLibraryMetadataRepository();
    _partialLastAcceptedLibraryIndex = LibraryIndex(lastAccepted,
        [for (var library in delta.libraries) '${library.importUri}']);
    _rejectionMessages.clear();
    for (var deltaLibrary in delta.libraries) {
      for (var deltaClass in deltaLibrary.classes) {
        final acceptedClass = _partialLastAcceptedLibraryIndex.tryGetClass(
            '${deltaLibrary.importUri}', deltaClass.name);
        if (acceptedClass == null) {
          // No previous version of the class to compare with.
          continue;
        }
        _checkClassTypeParametersCountChange(acceptedClass, deltaClass);
        if (acceptedClass.hasConstConstructor) {
          _checkConstClassConsistency(acceptedClass, deltaClass);
          _checkConstClassDeletedFields(acceptedClass, deltaClass);
        }
      }
      hotReloadLibraryMetadata.mapping[deltaLibrary] = true;
    }
    // Finalize the metadata written in this comparison.
    hotReloadLibraryMetadata.encodeMapping();
    // Attaching the metadata to the delta node simplifies the stateless server
    // approach used by dartpad. Ideally in the future the frontend server can
    // rely on this being attached to the delta component as well.
    delta.addMetadataRepository(hotReloadLibraryMetadata);
    return _rejectionMessages;
  }

  /// Records a rejection error when [acceptedClass] is const but [deltaClass]
  /// is non-const.
  ///
  /// [acceptedClass] and [deltaClass] must represent the same class in the
  /// last known accepted and delta components respectively.
  void _checkConstClassConsistency(Class acceptedClass, Class deltaClass) {
    assert(acceptedClass.hasConstConstructor);
    if (!deltaClass.hasConstConstructor) {
      _rejectionMessages.add('Const class cannot become non-const: '
          "Library:'${deltaClass.enclosingLibrary.importUri}' "
          'Class: ${deltaClass.name}');
    }
  }

  /// Records a rejection error when [acceptedClass] and [deltaClass] are both
  /// const but fields have been removed from [deltaClass].
  ///
  /// [acceptedClass] and [deltaClass] must represent the same class in the
  /// last known accepted and delta components respectively.
  void _checkConstClassDeletedFields(Class acceptedClass, Class deltaClass) {
    assert(acceptedClass.hasConstConstructor);
    if (!deltaClass.hasConstConstructor) {
      // Avoid reporting errors when fields are removed but the delta class is
      // also no longer const. That is already reported by
      // [_checkConstClassConsistency].
      return;
    }
    // Verify all fields are still present.
    final acceptedFields = {
      for (var field in acceptedClass.fields) field.name.text
    };
    final deltaFields = {for (var field in deltaClass.fields) field.name.text};
    if (acceptedFields.difference(deltaFields).isNotEmpty) {
      _rejectionMessages.add('Const class cannot remove fields: '
          "Library:'${deltaClass.enclosingLibrary.importUri}' "
          'Class: ${deltaClass.name}');
    }
  }

  /// Records a rejection error when the number of [TypeParameter]s on a class
  /// changes between [acceptedClass] and [deltaClass].
  ///
  /// [acceptedClass] and [deltaClass] must represent the same class in the
  /// last known accepted and delta components respectively.
  void _checkClassTypeParametersCountChange(
      Class acceptedClass, Class deltaClass) {
    if (acceptedClass.typeParameters.length !=
        deltaClass.typeParameters.length) {
      _rejectionMessages.add(
          'Limitation: changing type parameters does not work with hot reload.'
          "Library:'${deltaClass.enclosingLibrary.importUri}' "
          'Class: ${deltaClass.name}');
    }
  }
}

const hotReloadLibraryMetadataTag = 'ddc.hot-reload-library.metadata';

/// Metadata repository implementation that tracks hot reload information
/// associated to [Library] nodes.
///
/// Currently only tracks if the library should be compiled with the intention
/// to be hot reloaded.
// TODO(nshahan): Expand to track more useful information.
class HotReloadLibraryMetadataRepository extends MetadataRepository<bool> {
  @override
  String get tag => hotReloadLibraryMetadataTag;

  /// [mapping] in this repository should not be considered consistently live.
  ///
  /// Each hot reload compile request should move through these steps:
  ///
  /// * Write: Add entries using `mapping[lib] = data` but they should be
  ///   considered pending.
  /// * Finalize Write: After collecting all the entries, [encodeMapping] will
  ///   persist the pending entries to storage that is consistent across future
  ///   compiles.
  /// * Prepare Read: Before reading any values from [mapping] the metadata must
  ///   be linked to nodes by calling [mapToIndexedNodes].
  /// * Read: After mapping to nodes in a [LibraryIndex] access metadata using
  ///  `var data = mapping[lib]` but know that this only contains data that was
  ///   available to be linked in the previous step.
  @override
  Map<Library, bool> mapping = <Library, bool>{};

  @override
  void writeToBinary(bool metadata, Node node, BinarySink sink) {
    // TODO(nshahan): How to write all metadata even when there are no
    // associated nodes.
  }

  @override
  bool readFromBinary(Node node, BinarySource source) {
    // TODO(nshahan): Read metadata when it is available.
    return false;
  }

  final _reloadedLibraries = <String, bool>{};

  /// Modifies [mapping] to contain metadata associated with the [Node]s present
  /// in [index].
  ///
  /// This method should always be called before reading values from [mapping].
  ///
  /// Clears [mapping] before adding the [Node] to metadata mappings.
  void mapToIndexedNodes(LibraryIndex index) {
    mapping.clear();
    for (var identifier in _reloadedLibraries.keys) {
      final library = index.tryGetLibrary(identifier);
      if (library == null) continue;
      final metadata = _reloadedLibraries[identifier];
      if (metadata == null) continue;

      mapping[library] = metadata;
    }
  }

  /// Encodes the current [mapping] to enable lookup in a future compile
  /// generation when the `Node` keys are no longer valid.
  ///
  /// This method should always be called after writing values to [mapping].
  ///
  /// Clears [mapping] after encoding.
  void encodeMapping() {
    _reloadedLibraries.addAll({
      for (var library in mapping.keys)
        '${library.importUri}': mapping[library]!
    });
    mapping.clear();
  }
}
