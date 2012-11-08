// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

/**
 * Common superclass for all types.
 */
abstract class AbstractType implements Type {
  @Override
  public TypeQuality getQuality() {
    return TypeQuality.EXACT;
  }
}
