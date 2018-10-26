// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';

/**
 * An object used to provide context information for Dart assist contributors.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartAssistContext {
  /**
   * The resolution result in which assist operates.
   */
  ResolveResult get resolveResult;

  /**
   * The length of the selection.
   */
  int get selectionLength;

  /**
   * The start of the selection.
   */
  int get selectionOffset;
}
