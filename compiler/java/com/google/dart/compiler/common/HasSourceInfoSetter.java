// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.common;

/**
 * Object for which you can set new {@link SourceInfo}.
 */
public interface HasSourceInfoSetter {

  /**
   * Set the {@link SourceInfo} associated with this object. May only be called only once.
   */
  void setSourceInfo(SourceInfo sourceInfo);
}
