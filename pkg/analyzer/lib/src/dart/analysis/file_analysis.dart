// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';

/// Information about a file being analyzed.
class FileAnalysis {
  final FileState file;
  final RecordingDiagnosticListener diagnosticListener;
  final DiagnosticReporter diagnosticReporter;
  final CompilationUnitImpl unit;
  final LibraryFragmentImpl element;
  final IgnoreInfo ignoreInfo;
  final ImportsTracking importsTracking;

  FileAnalysis({
    required this.file,
    required this.diagnosticListener,
    required this.unit,
    required this.element,
  }) : diagnosticReporter = DiagnosticReporter(diagnosticListener, file.source),
       ignoreInfo = IgnoreInfo.forDart(unit, file.content),
       importsTracking = element.scope.importsTrackingInit();
}
