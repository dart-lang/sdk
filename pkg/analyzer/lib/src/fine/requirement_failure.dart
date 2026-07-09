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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.exportCountMismatch;
  }

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.exportedExtensionsMismatch;
  }

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.exportIdMismatch;
  }

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.exportLibraryMissing;
  }

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.implementedMethodIdMismatch;
  }

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.instanceChildrenIdsMismatch;
  }

  @override
  String get statisticKey => '$runtimeType.$childrenPropertyName';

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.instanceFieldIdMismatch;
  }

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.instanceMethodIdMismatch;
  }

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
  final ManifestItemIdList? expectedIds;
  final ManifestItemIdList? actualIds;

  InterfaceChildrenIdsMismatch({
    required this.libraryUri,
    required this.interfaceName,
    required this.childrenPropertyName,
    required this.expectedIds,
    required this.actualIds,
  });

  @override
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.interfaceChildrenIdsMismatch;
  }

  @override
  String get statisticKey => '$runtimeType.$childrenPropertyName';

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.interfaceConstructorIdMismatch;
  }

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.interfaceHasNonFinalFieldMismatch;
  }

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.interfaceIdMismatch;
  }

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.libraryChildrenIdsMismatch;
  }

  @override
  String get statisticKey => '$runtimeType.$childrenPropertyName';

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.libraryExportedUrisMismatch;
  }

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.libraryFeatureSetMismatch;
  }

  @override
  String toString() {
    return 'LibraryFeatureSetMismatch(libraryUri: $libraryUri, '
        'expected: $expected, actual: $actual)';
  }
}

class LibraryIsOriginNotExistingFileMismatch extends RequirementFailure {
  final Uri libraryUri;
  final bool expected;
  final bool actual;

  LibraryIsOriginNotExistingFileMismatch({
    required this.libraryUri,
    required this.expected,
    required this.actual,
  });

  @override
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.libraryIsOriginNotExistingFileMismatch;
  }

  @override
  String toString() {
    return 'LibraryIsOriginNotExistingFileMismatch(libraryUri: $libraryUri, '
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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.libraryIsSyntheticMismatch;
  }

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.libraryLanguageVersionMismatch;
  }

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.libraryMetadataMismatch;
  }

  @override
  String toString() => 'LibraryMetadataMismatch(libraryUri: $libraryUri)';
}

class LibraryMissing extends RequirementFailure {
  final Uri uri;

  LibraryMissing({required this.uri});

  @override
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.libraryMissing;
  }

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.libraryNameMismatch;
  }

  @override
  String toString() {
    return 'LibraryNameMismatch(libraryUri: $libraryUri, '
        'expected: $expected, actual: $actual)';
  }
}

final class OpaqueApiUseFailure extends RequirementFailure {
  @override
  final RequirementFailureKindId kindId;

  final List<OpaqueApiUse> uses;

  OpaqueApiUseFailure({required this.kindId, required this.uses});

  @override
  String get statisticKey {
    var use = uses.first;
    return '$runtimeType.${use.targetRuntimeType}.${use.methodName}';
  }

  @override
  String toString() {
    return 'OpaqueApiUseFailure(kindId: $kindId, uses: $uses)';
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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.reExportDeprecatedOnlyMismatch;
  }

  @override
  String toString() {
    return 'ReExportDeprecatedOnlyMismatch(libraryUri: $libraryUri, '
        'name: ${name.asString}, expected: $expected, actual: $actual)';
  }
}

sealed class RequirementFailure {
  RequirementFailureKindId get kindId;

  String get statisticKey => '$runtimeType';
}

enum RequirementFailureKindId {
  exportCountMismatch(0),
  exportIdMismatch(1),
  exportLibraryMissing(2),
  exportedExtensionsMismatch(3),
  implementedMethodIdMismatch(4),
  instanceChildrenIdsMismatch(5),
  instanceFieldIdMismatch(6),
  instanceGetterIdMismatch(7),
  instanceMethodIdMismatch(8),
  interfaceChildrenIdsMismatch(9),
  interfaceConstructorIdMismatch(10),
  interfaceHasNonFinalFieldMismatch(11),
  interfaceIdMismatch(12),
  libraryChildrenIdsMismatch(13),
  libraryExportedUrisMismatch(14),
  libraryFeatureSetMismatch(15),
  libraryIsSyntheticMismatch(16),
  libraryLanguageVersionMismatch(17),
  libraryMetadataMismatch(18),
  libraryMissing(19),
  libraryNameMismatch(20),
  opaqueAccept(21),
  opaqueContext(22),
  opaqueDocumentationComment(23),
  opaqueFieldNameNonPromotabilityInfo(24),
  opaqueFirstFragment(25),
  opaqueFragments(26),
  opaqueGetInheritedMember(27),
  opaqueGetOverridden(28),
  opaqueInheritedConcreteMembers(29),
  opaqueInheritedMembers(30),
  opaqueInterfaceMembers(31),
  opaqueLastFragment(32),
  opaqueLookUpGetter(33),
  opaqueLookUpInheritedMethod(34),
  opaqueLookUpMethod(35),
  opaqueLookUpSetter(36),
  opaqueNameLength(37),
  opaqueNameOffset(38),
  opaquePublicNamespace(39),
  opaqueSession(40),
  opaqueVisitChildren(41),
  reExportDeprecatedOnlyMismatch(42),
  superImplementedMethodIdMismatch(43),
  topLevelIdMismatch(44),
  topLevelNotInstance(45),
  topLevelNotInterface(46),
  libraryIsOriginNotExistingFileMismatch(47);

  final int id;

  const RequirementFailureKindId(this.id);
}

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.superImplementedMethodIdMismatch;
  }

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.topLevelIdMismatch;
  }

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
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.topLevelNotInstance;
  }

  @override
  String toString() {
    return 'TopLevelNotInstance(libraryUri: $libraryUri, '
        'name: ${name.asString})';
  }
}

class TopLevelNotInterface extends TopLevelFailure {
  TopLevelNotInterface({required super.libraryUri, required super.name});

  @override
  RequirementFailureKindId get kindId {
    return RequirementFailureKindId.topLevelNotInterface;
  }

  @override
  String toString() {
    return 'TopLevelNotInterface(libraryUri: $libraryUri, '
        'name: ${name.asString})';
  }
}
