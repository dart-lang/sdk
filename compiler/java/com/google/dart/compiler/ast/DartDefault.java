// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import java.util.List;

/**
 * Represents a Dart 'default' switch member.
 */
public class DartDefault extends DartSwitchMember {

  public DartDefault(List<DartLabel> labels, List<DartStatement> statements) {
    super(labels, statements);
  }

  @Override
  public <R> R accept(ASTVisitor<R> visitor) {
    return visitor.visitDefault(this);
  }
}
