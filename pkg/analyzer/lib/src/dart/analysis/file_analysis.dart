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
  final RecordingErrorListener errorListener;
  final ErrorReporter errorReporter;
  final CompilationUnitImpl unit;
  final CompilationUnitElementImpl element;
  final IgnoreInfo ignoreInfo;
  late ImportsTracking importsTracking;

  FileAnalysis({
    required this.file,
    required this.errorListener,
    required this.unit,
    required this.element,
  })  : errorReporter = ErrorReporter(errorListener, file.source),
        ignoreInfo = IgnoreInfo.forDart(unit, file.content);
}
