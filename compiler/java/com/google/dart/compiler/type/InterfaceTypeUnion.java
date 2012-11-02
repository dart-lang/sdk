// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import java.util.List;

/**
 * Artificial {@link InterfaceType} which is union of several {@link InterfaceType}s.
 */
public interface InterfaceTypeUnion extends InterfaceType {
  /**
   * @return the {@link InterfaceType} making this union.
   */
  List<InterfaceType> getTypes();
}
