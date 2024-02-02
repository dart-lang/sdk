// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';

/// Information about a file being analyzed.
class UnitAnalysis {
  final FileState file;
  final CompilationUnit unit;
  final CompilationUnitElement element;
  final ErrorReporter errorReporter;

  UnitAnalysis({
    required this.file,
    required this.unit,
    required this.element,
    required this.errorReporter,
  });
}
