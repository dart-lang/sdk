// Copyright (c) 2011, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast.viz;

import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartUnit;

/**
 * Write the AST in Dot format. Output file is placed next to the JS file in the output directory
 */
public class NullWriter extends BaseASTWriter {

  public NullWriter(String outputDir) {
    super(outputDir);
  }

  @Override
  protected void startHook(DartUnit unit) {
  }

  @Override
  protected void endHook(DartUnit unit) {
  }

  @Override
  public void process(DartUnit unit) {
    return;
  }

  @Override
  protected void write(String nodeType, DartNode node, String data) {
  }
}
