// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

/**
 * Some metadata information attached to the {@link DartDeclaration}. This has been superseded by
 * the metadata defined in the specification and will be removed in the near future.
 */
public class DartObsoleteMetadata {
  public static final DartObsoleteMetadata EMPTY = new DartObsoleteMetadata(false, false);
  private boolean deprecated;
  private boolean override;

  private DartObsoleteMetadata(boolean deprecated, boolean override) {
    this.deprecated = deprecated;
    this.override = override;
  }

  public DartObsoleteMetadata makeDeprecated() {
    return new DartObsoleteMetadata(true, override);
  }

  public DartObsoleteMetadata makeOverride() {
    return new DartObsoleteMetadata(deprecated, true);
  }

  public boolean isDeprecated() {
    return deprecated;
  }

  public boolean isOverride() {
    return override;
  }
}
