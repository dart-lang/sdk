// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Some metadata information attached to the {@link DartDeclaration}.
 */
public class DartMetadata {
  public static final DartMetadata EMPTY = new DartMetadata(false, false);
  private boolean deprecated;
  private boolean override;

  private DartMetadata(boolean deprecated, boolean override) {
    this.deprecated = deprecated;
    this.override = override;
  }

  public DartMetadata makeDeprecated() {
    return new DartMetadata(true, override);
  }

  public DartMetadata makeOverride() {
    return new DartMetadata(deprecated, true);
  }

  public boolean isDeprecated() {
    return deprecated;
  }

  public boolean isOverride() {
    return override;
  }
}
