// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.ast.DartUnit;

/**
 * Representation of changes to source.
 */
public abstract class SourceDelta {
  public abstract Source getSourceBefore();

  public abstract DartSource getSourceAfter();

  public abstract DartUnit getUnitAfter();

  public final SourceDelta after(DartSource sourceAfter) {
    return new BeforeAfter(getSourceBefore(), sourceAfter, null);
  }

  public final SourceDelta after(DartUnit nodeAfter) {
    return new BeforeAfter(getSourceBefore(), null, nodeAfter);
  }

  public static SourceDelta before(final DartSource sourceBefore) {
    return new BeforeAfter(sourceBefore, sourceBefore, null);
  }

  private static class BeforeAfter extends SourceDelta {
    private final Source sourceBefore;
    private final DartSource sourceAfter;
    private final DartUnit nodeAfter;

    BeforeAfter(Source sourceBefore, DartSource sourceAfter, DartUnit nodeAfter) {
      this.sourceBefore = sourceBefore;
      this.sourceAfter = sourceAfter;
      this.nodeAfter = nodeAfter;
    }

    @Override
    public Source getSourceBefore() {
      return sourceBefore;
    }

    @Override
    public DartSource getSourceAfter() {
      return sourceAfter;
    }

    @Override
    public DartUnit getUnitAfter() {
      return nodeAfter;
    }
  }
}
