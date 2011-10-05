// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.common;

import com.google.dart.compiler.ast.DartNode;

/**
 * @author johnlenz@google.com (John Lenz)
 */
public interface Symbol {
  String getOriginalSymbolName();

  DartNode getNode();
}
