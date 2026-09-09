// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/element_usage_detector.dart';
import 'package:analyzer/src/error/listener.dart';

/// Instance of [ElementUsageReporter] for reporting uses of experimental
/// elements.
class ExperimentalElementUsageReporter implements ElementUsageReporter<()> {
  final DiagnosticReporter _diagnosticReporter;

  ExperimentalElementUsageReporter({
    required DiagnosticReporter diagnosticReporter,
  }) : _diagnosticReporter = diagnosticReporter;

  @override
  void report(
    SourceRange usageRange,
    String displayName,
    () tagInfo, {
    required bool isInSamePackage,
    bool isImplicitTypeReference = false,
  }) {
    // Use of an experimental API from within the same package is OK
    if (isInSamePackage) return;

    _diagnosticReporter.report(
      diag.experimentalMemberUse
          .withArguments(member: displayName)
          .atSourceRange(usageRange),
    );
  }
}

/// Instance of [ElementUsageSet] for experimental elements.
class ExperimentalElementUsageSet implements ElementUsageSet<()> {
  const ExperimentalElementUsageSet();

  @override
  bool get reliesOnlyOnElementMetadata => true;

  @override
  ()? getTagInfo(Element _, Metadata elementMetadata) =>
      elementMetadata.annotations.any((e) => e.isExperimental) ? () : null;
}
