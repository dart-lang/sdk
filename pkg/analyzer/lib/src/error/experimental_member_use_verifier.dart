// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/element_usage_detector.dart';

/// Instance of [ElementUsageReporter] for reporting uses of experimental
/// elements.
class ExperimentalElementUsageReporter implements ElementUsageReporter<()> {
  final DiagnosticReporter _diagnosticReporter;

  ExperimentalElementUsageReporter({
    required DiagnosticReporter diagnosticReporter,
  }) : _diagnosticReporter = diagnosticReporter;

  @override
  void report(
    SyntacticEntity errorEntity,
    String displayName,
    () tagInfo, {
    required bool isInSamePackage,
  }) {
    // Use of an experimental API from within the same package is OK
    if (isInSamePackage) return;

    _diagnosticReporter.atEntity(
      errorEntity,
      WarningCode.experimentalMemberUse,
      arguments: [displayName],
    );
  }
}

/// Instance of [ElementUsageSet] for experimental elements.
class ExperimentalElementUsageSet implements ElementUsageSet<()> {
  const ExperimentalElementUsageSet();

  @override
  ()? getTagInfo(Element element) =>
      element.metadata.annotations.any((e) => e.isExperimental) ? () : null;
}
