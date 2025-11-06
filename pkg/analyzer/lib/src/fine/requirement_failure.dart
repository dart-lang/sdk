// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_id.dart';
import 'package:analyzer/src/fine/manifest_item.dart';
import 'package:analyzer/src/fine/requirements.dart';

final class ExportCountMismatch extends ExportFailure {
  final Uri fragmentUri;
  final Uri exportedUri;
  final int expectedCount;
  final int actualCount;

  ExportCountMismatch({
    required this.fragmentUri,
    required this.exportedUri,
    required this.expectedCount,
    required this.actualCount,
  });

  @override
  String toString() {
    return 'ExportCountMismatch(fragmentUri: $fragmentUri, '
        'exportedUri: $exportedUri, '
        'expectedCount: $expectedCount, '
        'actualCount: $actualCount)';
  }
}

class ExportedExtensionsMismatch extends RequirementFailure {
  final Uri libraryUri;
  final ManifestItemIdList expectedIds;
  final ManifestItemIdList actualIds;

  ExportedExtensionsMismatch({
    required this.libraryUri,
    required this.expectedIds,
    required this.actualIds,
  });

  @override
  String toString() {
    return 'ExportedExtensionsMismatch(libraryUri: $libraryUri, '
        'expectedIds: $expectedIds, actualIds: $actualIds)';
  }
}

sealed class ExportFailure extends RequirementFailure {}

final class ExportIdMismatch extends ExportFailure {
  final Uri fragmentUri;
  final Uri exportedUri;
  final LookupName name;
  final ManifestItemId? expectedId;
  final ManifestItemId actualId;

  ExportIdMismatch({
    required this.fragmentUri,
    required this.exportedUri,
    required this.name,
    required this.expectedId,
    required this.actualId,
  });

  @override
  String toString() {
    return 'ExportIdMismatch(fragmentUri: $fragmentUri, '
        'exportedUri: $exportedUri, '
        'name: ${name.asString}, '
        'expectedId: $expectedId, '
        'actualId: $actualId)';
  }
}

final class ExportLibraryMissing extends ExportFailure {
  final Uri uri;

  ExportLibraryMissing({required this.uri});

  @override
  String toString() {
    return 'ExportLibraryMissing(uri: $uri)';
  }
}

class ImplementedMethodIdMismatch extends RequirementFailure {
  final Uri libraryUri;
  final LookupName interfaceName;
  final LookupName methodName;
  final ManifestItemId? expectedId;
  final ManifestItemId? actualId;

  ImplementedMethodIdMismatch({
    required this.libraryUri,
    required this.interfaceName,
    required this.methodName,
    required this.expectedId,
    required this.actualId,
  });

  @override
  String toString() {
    return 'ImplementedMethodIdMismatch(libraryUri: $libraryUri, '
        'interfaceName: ${interfaceName.asString}, '
        'methodName: ${methodName.asString}, '
        'expectedId: $expectedId, actualId: $actualId)';
  }
}

class InstanceChildrenIdsMismatch extends RequirementFailure {
  final Uri libraryUri;
  final LookupName instanceName;
  final String childrenPropertyName;
  final ManifestItemIdList expectedIds;
  final ManifestItemIdList actualIds;

  InstanceChildrenIdsMismatch({
    required this.libraryUri,
    required this.instanceName,
    required this.childrenPropertyName,
    required this.expectedIds,
    required this.actualIds,
  });

  @override
  String toString() {
    return 'InstanceChildrenIdsMismatch(libraryUri: $libraryUri, '
        'instanceName: ${instanceName.asString}, '
        'childrenPropertyName: $childrenPropertyName, '
        'expectedIds: $expectedIds, actualIds: $actualIds)';
  }
}

class InstanceFieldIdMismatch extends RequirementFailure {
  final Uri libraryUri;
  final LookupName interfaceName;
  final LookupName fieldName;
  final ManifestItemId? expectedId;
  final ManifestItemId? actualId;

  InstanceFieldIdMismatch({
    required this.libraryUri,
    required this.interfaceName,
    required this.fieldName,
    required this.expectedId,
    required this.actualId,
  });

  @override
  String toString() {
    return 'InstanceFieldIdMismatch(libraryUri: $libraryUri, '
        'interfaceName: ${interfaceName.asString}, '
        'fieldName: ${fieldName.asString}, '
        'expectedId: $expectedId, '
        'actualId: $actualId)';
  }
}

class InstanceMethodIdMismatch extends RequirementFailure {
  final Uri libraryUri;
  final LookupName interfaceName;
  final LookupName methodName;
  final ManifestItemId? expectedId;
  final ManifestItemId? actualId;

  InstanceMethodIdMismatch({
    required this.libraryUri,
    required this.interfaceName,
    required this.methodName,
    required this.expectedId,
    required this.actualId,
  });

  @override
  String toString() {
    return 'InstanceMethodIdMismatch(libraryUri: $libraryUri, '
        'interfaceName: ${interfaceName.asString}, '
        'methodName: ${methodName.asString}, '
        'expectedId: $expectedId, actualId: $actualId)';
  }
}

class InterfaceChildrenIdsMismatch extends RequirementFailure {
  final Uri libraryUri;
  final LookupName interfaceName;
  final String childrenPropertyName;
  final ManifestItemIdList expectedIds;
  final ManifestItemIdList actualIds;

  InterfaceChildrenIdsMismatch({
    required this.libraryUri,
    required this.interfaceName,
    required this.childrenPropertyName,
    required this.expectedIds,
    required this.actualIds,
  });

  @override
  String toString() {
    return 'InterfaceChildrenIdsMismatch(libraryUri: $libraryUri, '
        'interfaceName: ${interfaceName.asString}, '
        'childrenPropertyName: $childrenPropertyName, '
        'expectedIds: $expectedIds, actualIds: $actualIds)';
  }
}

class InterfaceConstructorIdMismatch extends RequirementFailure {
  final Uri libraryUri;
  final LookupName interfaceName;
  final LookupName constructorName;
  final ManifestItemId? expectedId;
  final ManifestItemId? actualId;

  InterfaceConstructorIdMismatch({
    required this.libraryUri,
    required this.interfaceName,
    required this.constructorName,
    required this.expectedId,
    required this.actualId,
  });

  @override
  String toString() {
    return 'InterfaceConstructorIdMismatch(libraryUri: $libraryUri, '
        'interfaceName: ${interfaceName.asString}, '
        'constructorName: ${constructorName.asString}, '
        'expectedId: $expectedId, '
        'actualId: $actualId)';
  }
}

class InterfaceHasNonFinalFieldMismatch extends RequirementFailure {
  final Uri libraryUri;
  final LookupName interfaceName;
  final bool expected;
  final bool actual;

  InterfaceHasNonFinalFieldMismatch({
    required this.libraryUri,
    required this.interfaceName,
    required this.expected,
    required this.actual,
  });

  @override
  String toString() {
    return 'InterfaceHasNonFinalFieldMismatch(libraryUri: $libraryUri, '
        'interfaceName: ${interfaceName.asString}, '
        'expected: $expected, '
        'actual: $actual)';
  }
}

class InterfaceIdMismatch extends RequirementFailure {
  final Uri libraryUri;
  final LookupName interfaceName;
  final ManifestItemId expectedId;
  final ManifestItemId actualId;

  InterfaceIdMismatch({
    required this.libraryUri,
    required this.interfaceName,
    required this.expectedId,
    required this.actualId,
  });

  @override
  String toString() {
    return 'InterfaceIdMismatch(libraryUri: $libraryUri, '
        'interfaceName: ${interfaceName.asString}, '
        'expectedId: $expectedId, '
        'actualId: $actualId)';
  }
}

class LibraryChildrenIdsMismatch extends RequirementFailure {
  final Uri libraryUri;
  final String childrenPropertyName;
  final ManifestItemIdList expectedIds;
  final ManifestItemIdList actualIds;

  LibraryChildrenIdsMismatch({
    required this.libraryUri,
    required this.childrenPropertyName,
    required this.expectedIds,
    required this.actualIds,
  });

  @override
  String toString() {
    return 'LibraryChildrenIdsMismatch(libraryUri: $libraryUri, '
        'childrenPropertyName: $childrenPropertyName, '
        'expectedIds: $expectedIds, actualIds: $actualIds)';
  }
}

class LibraryExportedUrisMismatch extends RequirementFailure {
  final Uri libraryUri;
  final List<Uri> expected;
  final List<Uri> actual;

  LibraryExportedUrisMismatch({
    required this.libraryUri,
    required this.expected,
    required this.actual,
  });

  @override
  String toString() {
    return 'LibraryExportedUrisMismatch(libraryUri: $libraryUri, '
        'expected: $expected, actual: $actual)';
  }
}

class LibraryFeatureSetMismatch extends RequirementFailure {
  final Uri libraryUri;
  final Uint8List? expected;
  final Uint8List? actual;

  LibraryFeatureSetMismatch({
    required this.libraryUri,
    required this.expected,
    required this.actual,
  });

  @override
  String toString() {
    return 'LibraryFeatureSetMismatch(libraryUri: $libraryUri, '
        'expected: $expected, actual: $actual)';
  }
}

class LibraryIsSyntheticMismatch extends RequirementFailure {
  final Uri libraryUri;
  final bool expected;
  final bool actual;

  LibraryIsSyntheticMismatch({
    required this.libraryUri,
    required this.expected,
    required this.actual,
  });

  @override
  String toString() {
    return 'LibraryIsSyntheticMismatch(libraryUri: $libraryUri, '
        'expected: $expected, actual: $actual)';
  }
}

class LibraryLanguageVersionMismatch extends RequirementFailure {
  final Uri libraryUri;
  final ManifestLibraryLanguageVersion expected;
  final ManifestLibraryLanguageVersion actual;

  LibraryLanguageVersionMismatch({
    required this.libraryUri,
    required this.expected,
    required this.actual,
  });

  @override
  String toString() {
    return 'LibraryLanguageVersionMismatch(libraryUri: $libraryUri, '
        'expected: $expected, actual: $actual)';
  }
}

class LibraryMetadataMismatch extends RequirementFailure {
  final Uri libraryUri;

  LibraryMetadataMismatch({required this.libraryUri});

  @override
  String toString() => 'LibraryMetadataMismatch(libraryUri: $libraryUri)';
}

class LibraryMissing extends RequirementFailure {
  final Uri uri;

  LibraryMissing({required this.uri});

  @override
  String toString() {
    return 'LibraryMissing(uri: $uri)';
  }
}

class LibraryNameMismatch extends RequirementFailure {
  final Uri libraryUri;
  final String? expected;
  final String? actual;

  LibraryNameMismatch({
    required this.libraryUri,
    required this.expected,
    required this.actual,
  });

  @override
  String toString() {
    return 'LibraryNameMismatch(libraryUri: $libraryUri, '
        'expected: $expected, actual: $actual)';
  }
}

final class OpaqueApiUseFailure extends RequirementFailure {
  final List<OpaqueApiUse> uses;

  OpaqueApiUseFailure({required this.uses});

  @override
  String toString() {
    return 'OpaqueApiUseFailure(uses: $uses)';
  }
}

class ReExportDeprecatedOnlyMismatch extends RequirementFailure {
  final Uri libraryUri;
  final LookupName name;
  final bool expected;
  final bool actual;

  ReExportDeprecatedOnlyMismatch({
    required this.libraryUri,
    required this.name,
    required this.expected,
    required this.actual,
  });

  @override
  String toString() {
    return 'ReExportDeprecatedOnlyMismatch(libraryUri: $libraryUri, '
        'name: ${name.asString}, expected: $expected, actual: $actual)';
  }
}

sealed class RequirementFailure {}

class SuperImplementedMethodIdMismatch extends RequirementFailure {
  final Uri libraryUri;
  final LookupName interfaceName;
  final int superIndex;
  final LookupName methodName;
  final ManifestItemId? expectedId;
  final ManifestItemId? actualId;

  SuperImplementedMethodIdMismatch({
    required this.libraryUri,
    required this.interfaceName,
    required this.superIndex,
    required this.methodName,
    required this.expectedId,
    required this.actualId,
  });

  @override
  String toString() {
    return 'SuperImplementedMethodIdMismatch(libraryUri: $libraryUri, '
        'interfaceName: ${interfaceName.asString}, '
        'superIndex: $superIndex, '
        'methodName: ${methodName.asString}, '
        'expectedId: $expectedId, actualId: $actualId)';
  }
}

sealed class TopLevelFailure extends RequirementFailure {
  final Uri libraryUri;
  final LookupName name;

  TopLevelFailure({required this.libraryUri, required this.name});
}

class TopLevelIdMismatch extends TopLevelFailure {
  final ManifestItemId? expectedId;
  final ManifestItemId? actualId;

  TopLevelIdMismatch({
    required super.libraryUri,
    required super.name,
    required this.expectedId,
    required this.actualId,
  });

  @override
  String toString() {
    return 'TopLevelIdMismatch(libraryUri: $libraryUri, '
        'name: ${name.asString}, '
        'expectedId: $expectedId, '
        'actualId: $actualId)';
  }
}

class TopLevelNotInstance extends TopLevelFailure {
  final Object? actualItem;

  TopLevelNotInstance({
    required super.libraryUri,
    required super.name,
    required this.actualItem,
  });

  @override
  String toString() {
    return 'TopLevelNotInstance(libraryUri: $libraryUri, '
        'name: ${name.asString})';
  }
}

class TopLevelNotInterface extends TopLevelFailure {
  TopLevelNotInterface({required super.libraryUri, required super.name});

  @override
  String toString() {
    return 'TopLevelNotInterface(libraryUri: $libraryUri, '
        'name: ${name.asString})';
  }
}
