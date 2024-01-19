// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix_processor.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';

/// An object used to provide context information for Dart assist contributors.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DartAssistContext {
  /// Return the instrumentation service used to report errors that prevent a
  /// fix from being composed.
  InstrumentationService get instrumentationService;

  /// A mapping of [ProducerGenerator]s to the set of lint names with which they
  /// are associated (can fix).
  Map<ProducerGenerator, Set<String>> get producerGeneratorsForLintRules;

  /// The resolution result in which assist operates.
  ResolvedUnitResult get resolveResult;

  /// The length of the selection.
  int get selectionLength;

  /// The start of the selection.
  int get selectionOffset;

  /// The workspace in which the fix contributor operates.
  ChangeWorkspace get workspace;
}
