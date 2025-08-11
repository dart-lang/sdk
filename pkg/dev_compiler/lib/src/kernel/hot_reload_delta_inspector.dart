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

  /// A set of packages that should not be hot reloaded.
  ///
  /// The delta inspector will reject any component that modifies any such
  /// packages (while allowing them to be introduced).
  final Set<String> nonHotReloadablePackages;

  HotReloadDeltaInspector({this.nonHotReloadablePackages = const {}});

  /// Returns all hot reload rejection errors discovered while comparing [delta]
  /// against the [lastAccepted] version.
  ///
  /// Attaches metadata to the [delta] component to be consumed by DDC when
  /// compiling.
  List<String> compareGenerations(Component lastAccepted, Component delta) {
    final deltaLibraryImportUris = [
      for (var library in delta.libraries) '${library.importUri}',
    ];
    _partialLastAcceptedLibraryIndex = LibraryIndex(
      lastAccepted,
      deltaLibraryImportUris,
    );
    final deltaLibraryIndex = LibraryIndex(delta, deltaLibraryImportUris);
    final metadataRepo =
        lastAccepted.metadata[hotReloadLibraryMetadataTag]
            as HotReloadLibraryMetadataRepository? ??
        HotReloadLibraryMetadataRepository();
    metadataRepo.generation++;
    _rejectionMessages.clear();
    for (var deltaLibrary in delta.libraries) {
      final acceptedLibrary = _partialLastAcceptedLibraryIndex.tryGetLibrary(
        '${deltaLibrary.importUri}',
      );
      if (acceptedLibrary == null) {
        // No previous version of the library to compare with.
        continue;
      }
      if (_shouldNotCompileWithHotReload(deltaLibrary.importUri)) {
        _rejectionMessages.add(
          'Attempting to hot reload a modified library from a package '
          'marked as non-hot-reloadable: '
          "Library: '${deltaLibrary.importUri}'",
        );
      }
      var libraryMetadata = metadataRepo.mapping.putIfAbsent(
        deltaLibrary,
        HotReloadLibraryMetadata.new,
      );
      // TODO(60281): Handle members when an entire library has been deleted
      // from the delta.
      libraryMetadata.deletedStaticProcedureNames.clear();
      libraryMetadata.deletedStaticProcedureNames.addAll(
        _findDeletedLibraryProcedures(acceptedLibrary, deltaLibraryIndex),
      );
      for (var deltaClass in deltaLibrary.classes) {
        final acceptedClass = _partialLastAcceptedLibraryIndex.tryGetClass(
          '${deltaLibrary.importUri}',
          deltaClass.name,
        );
        if (acceptedClass == null) {
          // No previous version of the class to compare with.
          continue;
        }
        _checkClassTypeParametersCountChange(acceptedClass, deltaClass);
        if (acceptedClass.isEnum || deltaClass.isEnum) {
          _checkEnumIllegalConversion(acceptedClass, deltaClass);
        }
        if (acceptedClass.hasConstConstructor) {
          _checkConstClassConsistency(acceptedClass, deltaClass);
          _checkConstClassDeletedFields(acceptedClass, deltaClass);
        }
      }
    }
    // Finalize the metadata written in this comparison.
    metadataRepo.encodeMapping();
    // Attaching the metadata to the delta node simplifies the stateless server
    // approach used by dartpad. Ideally in the future the frontend server can
    // rely on this being attached to the delta component as well.
    delta.addMetadataRepository(metadataRepo);
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
      _rejectionMessages.add(
        'Const class cannot become non-const: '
        "Library:'${deltaClass.enclosingLibrary.importUri}' "
        'Class: ${deltaClass.name}',
      );
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
      for (var field in acceptedClass.fields) field.name.text,
    };
    final deltaFields = {for (var field in deltaClass.fields) field.name.text};
    if (acceptedFields.difference(deltaFields).isNotEmpty) {
      _rejectionMessages.add(
        'Const class cannot remove fields: '
        "Library:'${deltaClass.enclosingLibrary.importUri}' "
        'Class: ${deltaClass.name}',
      );
    }
  }

  /// Records a rejection error when the number of [TypeParameter]s on a class
  /// changes between [acceptedClass] and [deltaClass].
  ///
  /// [acceptedClass] and [deltaClass] must represent the same class in the
  /// last known accepted and delta components respectively.
  void _checkClassTypeParametersCountChange(
    Class acceptedClass,
    Class deltaClass,
  ) {
    if (acceptedClass.typeParameters.length !=
        deltaClass.typeParameters.length) {
      _rejectionMessages.add(
        'Limitation: changing type parameters does not work with hot reload.'
        "Library:'${deltaClass.enclosingLibrary.importUri}' "
        'Class: ${deltaClass.name}',
      );
    }
  }

  /// Records a rejection error when a class is redefined as or from an [Enum].
  ///
  /// [acceptedClass] and [deltaClass] must represent the same class in the
  /// last known accepted and delta components respectively.
  void _checkEnumIllegalConversion(Class acceptedClass, Class deltaClass) {
    if (acceptedClass.isEnum && !deltaClass.isEnum) {
      _rejectionMessages.add(
        'Enum class cannot be redefined to be a non-enum class.'
        'Class: ${deltaClass.name}',
      );
    } else if (!acceptedClass.isEnum && deltaClass.isEnum) {
      _rejectionMessages.add(
        'Class cannot be redefined to be a enum class.'
        'Class: ${deltaClass.name}',
      );
    }
  }

  /// Returns the names of library methods, getters, and setters that were
  /// present in [acceptedLibrary] but do not appear in [deltaLibraryIndex].
  List<String> _findDeletedLibraryProcedures(
    Library acceptedLibrary,
    LibraryIndex deltaLibraryIndex,
  ) {
    final acceptedLibraryImportUri = '${acceptedLibrary.importUri}';
    return [
      for (var acceptedProcedure in acceptedLibrary.procedures)
        if (deltaLibraryIndex.tryGetProcedure(
              acceptedLibraryImportUri,
              LibraryIndex.topLevel,
              acceptedProcedure.indexName,
            ) ==
            null)
          acceptedProcedure.name.text,
    ];
  }

  /// Returns `true` if the resource at [uri] should not be compiled with hot
  /// reload.
  ///
  /// No 'dart:' libraries will be compiled with hot reload support.
  bool _shouldNotCompileWithHotReload(Uri uri) {
    return (uri.isScheme('dart')) ||
        (uri.isScheme('package') &&
            nonHotReloadablePackages.contains(uri.pathSegments[0]));
  }
}

const hotReloadLibraryMetadataTag = 'ddc.hot-reload-library.metadata';

/// Metadata repository implementation that tracks hot reload information
/// associated to [Library] nodes.
class HotReloadLibraryMetadataRepository
    extends MetadataRepository<HotReloadLibraryMetadata> {
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
  final Map<Library, HotReloadLibraryMetadata> mapping = {};

  @override
  void writeToBinary(
    HotReloadLibraryMetadata metadata,
    Node node,
    BinarySink sink,
  ) {
    // TODO(nshahan): How to write all metadata even when there are no
    // associated nodes.
  }

  @override
  HotReloadLibraryMetadata readFromBinary(Node node, BinarySource source) {
    // TODO(nshahan): Read metadata when it is available.
    return HotReloadLibraryMetadata();
  }

  /// The current hot reload generation.
  int generation = 0;

  final _encodedMetadata = <String, HotReloadLibraryMetadata>{};

  /// Modifies [mapping] to contain metadata associated with the [Node]s present
  /// in [index].
  ///
  /// This method should always be called before reading values from [mapping].
  ///
  /// Clears [mapping] before adding the [Node] to metadata mappings.
  void mapToIndexedNodes(LibraryIndex index) {
    mapping.clear();
    for (var identifier in _encodedMetadata.keys) {
      final library = index.tryGetLibrary(identifier);
      if (library == null) continue;
      final metadata = _encodedMetadata[identifier];
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
    _encodedMetadata.addAll({
      for (var library in mapping.keys)
        '${library.importUri}': mapping[library]!,
    });
    mapping.clear();
  }
}

class HotReloadLibraryMetadata {
  /// Names of library methods, getters, and setters that have been deleted
  /// from the library in the latest delta.
  ///
  /// These members should be deleted from the library in the next compile.
  final Set<String> deletedStaticProcedureNames = {};
}

extension ProcedureExtension on Procedure {
  /// Returns the name used to lookup this [Procedure] in a [LibraryIndex].
  String get indexName {
    if (isGetter) return '${LibraryIndex.getterPrefix}${name.text}';
    if (isSetter) return '${LibraryIndex.setterPrefix}${name.text}';
    return name.text;
  }
}
