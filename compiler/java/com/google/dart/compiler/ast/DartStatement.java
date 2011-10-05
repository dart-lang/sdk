// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Abstract base class for Dart statement objects.
 */
public abstract class DartStatement extends DartNode {
  public boolean isAbruptCompletingStatement() {
    return false;
  }
}
