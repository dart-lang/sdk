// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.common;

/**
 * Abstract view of a class that has source info.
 */
public interface HasSourceInfo {

  /**
   * @return the {@link SourceInfo} associated with this object. May be {@link SourceInfo#UNKNOWN}
   *         but not <code>null</code>.
   */
  SourceInfo getSourceInfo();
}
