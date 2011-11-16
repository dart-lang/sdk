// Copyright (c) 2011, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast.viz;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

import com.google.common.io.Closeables;
import com.google.dart.compiler.ast.DartUnit;

/**
 * Write the AST in Text format. Output file is placed next to the JS file in the output directory
 */
public class TextWriter extends ConsoleWriter {

  public TextWriter(String outputDir) {
    super(outputDir);
  }

  @Override
  protected void startHook(DartUnit unit) {
    if (!isIgnored(unit)) {
      String txtFilePath = outputDir + File.separator + unit.getSource().getUri()
          + ".ast.txt";
      makeParentDirs(txtFilePath);
      try {
        //Set output to text file
        out = new FileWriter(new File(txtFilePath));
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
  }

  @Override
  protected void endHook(DartUnit unit) {
    if (!isIgnored(unit)) {
      try {
        Closeables.close(out, true);
      } catch (IOException e) {
        System.err.println("Error closing AST output file");
        e.printStackTrace();
      }
    }
  }
}
