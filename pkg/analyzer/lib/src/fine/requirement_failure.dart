// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/fine/lookup_name.dart';
import 'package:analyzer/src/fine/manifest_id.dart';

final class ExportCountMismatch extends ExportFailure {
  final Uri fragmentUri;
  final Uri exportedUri;
  final int actualCount;
  final int requiredCount;

  ExportCountMismatch({
    required this.fragmentUri,
    required this.exportedUri,
    required this.actualCount,
    required this.requiredCount,
  });
}

// TODO(scheglov): break down
sealed class ExportFailure extends RequirementFailure {}

final class ExportIdMismatch extends ExportFailure {
  final Uri fragmentUri;
  final Uri exportedUri;
  final LookupName name;
  final ManifestItemId actualId;
  final ManifestItemId? expectedId;

  ExportIdMismatch({
    required this.fragmentUri,
    required this.exportedUri,
    required this.name,
    required this.actualId,
    required this.expectedId,
  });
}

final class ExportLibraryMissing extends ExportFailure {
  final Uri uri;

  ExportLibraryMissing({required this.uri});
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
}

class LibraryMissing extends RequirementFailure {
  final Uri uri;

  LibraryMissing({required this.uri});
}

sealed class RequirementFailure {}

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
}

class TopLevelNotInterface extends TopLevelFailure {
  TopLevelNotInterface({required super.libraryUri, required super.name});
}
