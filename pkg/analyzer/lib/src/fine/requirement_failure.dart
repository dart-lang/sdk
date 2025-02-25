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

  ExportLibraryMissing({
    required this.uri,
  });
}

sealed class InstanceMemberFailure extends RequirementFailure {}

class InstanceMemberIdMismatch extends InstanceMemberFailure {
  final Uri libraryUri;
  final LookupName interfaceName;
  final LookupName memberName;
  final ManifestItemId? expectedId;
  final ManifestItemId actualId;

  InstanceMemberIdMismatch({
    required this.libraryUri,
    required this.interfaceName,
    required this.memberName,
    required this.expectedId,
    required this.actualId,
  });
}

class InstanceMemberMissing extends InstanceMemberFailure {}

class InstanceMemberPresent extends InstanceMemberFailure {}

class LibraryMissing extends RequirementFailure {
  final Uri uri;

  LibraryMissing({
    required this.uri,
  });
}

sealed class RequirementFailure {}

sealed class TopLevelFailure extends RequirementFailure {
  final Uri libraryUri;

  TopLevelFailure({
    required this.libraryUri,
  });
}

class TopLevelIdMismatch extends TopLevelFailure {
  final LookupName name;
  final ManifestItemId? expectedId;
  final ManifestItemId actualId;

  TopLevelIdMismatch({
    required super.libraryUri,
    required this.name,
    required this.expectedId,
    required this.actualId,
  });
}

class TopLevelMissing extends TopLevelFailure {
  final LookupName name;

  TopLevelMissing({
    required super.libraryUri,
    required this.name,
  });
}

class TopLevelNotClass extends TopLevelFailure {
  TopLevelNotClass({
    required super.libraryUri,
  });
}

class TopLevelPresent extends TopLevelFailure {
  final LookupName name;

  TopLevelPresent({
    required super.libraryUri,
    required this.name,
  });
}
