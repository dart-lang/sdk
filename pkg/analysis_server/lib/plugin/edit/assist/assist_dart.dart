// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * An object used to provide context information for Dart assist contributors.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartAssistContext {
  /**
   * The analysis driver used to access analysis results.
   */
  AnalysisDriver get analysisDriver;

  /**
   * The length of the selection.
   */
  int get selectionLength;

  /**
   * The start of the selection.
   */
  int get selectionOffset;

  /**
   * The source to get assists in.
   */
  Source get source;

  /**
   * The [CompilationUnit] to compute assists in.
   */
  CompilationUnit get unit;
}
