// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.type.InterfaceType;

/**
 * Exception thrown if a duplicated interface is detected in the supertype graph of a class or
 * interface.
 */
public class DuplicatedInterfaceException extends Exception {
  private final InterfaceType first;
  private final InterfaceType second;

  public DuplicatedInterfaceException(InterfaceType first, InterfaceType second) {
    super(first + " & " + second);
    this.first = first;
    this.second = second;
  }

  public InterfaceType getFirst() {
    return first;
  }

  public InterfaceType getSecond() {
    return second;
  }
}
