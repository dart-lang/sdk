// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/src/correction/change_workspace.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/instrumentation/service.dart';

/// An object used to provide context information for Dart assist contributors.
final class DartAssistContext {
  /// The instrumentation service used to report errors that prevent a fix from
  /// being composed.
  final InstrumentationService instrumentationService;

  /// The workspace in which an assist operates.
  final ChangeWorkspace workspace;

  /// The resolved library result in which an assist operates.
  final ResolvedLibraryResult libraryResult;

  /// The unit result in which an assist operates.
  final ResolvedUnitResult unitResult;

  /// The starting offset of the selection.
  final int selectionOffset;

  /// The length of the selection.
  final int selectionLength;

  DartAssistContext(
    this.instrumentationService,
    this.workspace,
    this.libraryResult,
    this.unitResult,
    this.selectionOffset,
    this.selectionLength,
  );
}
