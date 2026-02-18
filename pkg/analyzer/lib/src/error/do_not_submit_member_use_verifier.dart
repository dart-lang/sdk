// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/element_usage_detector.dart';
import 'package:analyzer/src/error/listener.dart';

/// Instance of [ElementUsageReporter] for reporting uses of elements annotated
/// with `@doNotSubmit`.
class DoNotSubmitElementUsageReporter implements ElementUsageReporter<()> {
  final DiagnosticReporter _diagnosticReporter;

  DoNotSubmitElementUsageReporter({
    required DiagnosticReporter diagnosticReporter,
  }) : _diagnosticReporter = diagnosticReporter;

  @override
  void report(
    SyntacticEntity errorEntity,
    String displayName,
    () tagInfo, {
    required bool isInSamePackage,
    required bool isInTestDirectory,
  }) {
    _diagnosticReporter.report(
      diag.invalidUseOfDoNotSubmitMember
          .withArguments(name: displayName)
          .at(errorEntity),
    );
  }
}

/// Instance of [ElementUsageSet] for elements annotated with `@doNotSubmit`.
class DoNotSubmitElementUsageSet implements ElementUsageSet<()> {
  const DoNotSubmitElementUsageSet();

  @override
  ()? getTagInfo(Element element) =>
      element.metadata.hasDoNotSubmit ? () : null;
}
