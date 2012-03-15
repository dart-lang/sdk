// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.common;

/**
 * Abstract base class for nodes that carry source information.
 */
public class AbstractNode implements HasSourceInfo, HasSourceInfoSetter {

  private SourceInfo sourceInfo = SourceInfo.UNKNOWN;

  @Override
  public final SourceInfo getSourceInfo() {
    return sourceInfo;
  }

  @Override
  public final void setSourceInfo(SourceInfo sourceInfo) {
    this.sourceInfo = sourceInfo;
  }
}
