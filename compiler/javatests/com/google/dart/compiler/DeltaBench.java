// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.resolver.LibraryElement;
import com.google.dart.compiler.testing.TestCompilerConfiguration;
import com.google.dart.compiler.testing.TestCompilerContext;

import java.io.File;
import java.io.IOException;
import java.util.HashSet;

public class DeltaBench {
  public static void main(String[] args) throws IOException {
    File trunkDir = new File(args[0]);
    File libraryFile = new File(trunkDir, args[1]);
    File outputDirectory = new File(trunkDir, args[2]);
    for (int i = 0; i < 100; i++) {
      analyze(libraryFile, outputDirectory, null);
      for (int j = 3; j < args.length; j++) {
        analyze(libraryFile, outputDirectory, args[j]);
      }
    }
  }

  private static void analyze(File libraryFile, File outputDirectory, String interestingFile)
      throws IOException {
    final boolean incremental = interestingFile == null;
    long start = System.currentTimeMillis();
    LibrarySource librarySource = new UrlLibrarySource(libraryFile);
    CompilerConfiguration config = new TestCompilerConfiguration() {
      @Override
      public boolean incremental() {
        return incremental;
      }

      @Override
      public boolean shouldOptimize() {
        return false;
      }

      @Override
      public boolean checkOnly() {
        return false;
      }
    };
    DartCompilerListener listener = new TestCompilerContext();
    DartArtifactProvider provider = new DefaultDartArtifactProvider(outputDirectory);
    LibraryUnit libraryUnit = DartCompiler.analyzeLibrary(librarySource, null, config, provider,
                                                          listener);
    System.err.println("analyzeLibrary" + (incremental ? "+incremental" : "") +
                       "(" + libraryUnit.getName() + ") took " +
                       (System.currentTimeMillis() - start) + "ms");
    if (incremental) {
      return;
    }
    LibraryUnit enclosingLibraryUnit = DartCompiler.findLibrary(libraryUnit, interestingFile,
                                                   new HashSet<LibraryElement>());
    LibraryUnit coreLibraryUnit = DartCompiler.findLibrary(libraryUnit, "object.dart",
                                              new HashSet<LibraryElement>());
    DartUnit unit = null;
    for (DartUnit current : enclosingLibraryUnit.getUnits()) {
      if (current.getSource().getName().endsWith(interestingFile)) {
        unit = current;
        break;
      }
    }
    start = System.currentTimeMillis();
    DartCompiler.analyzeDelta(SourceDelta.before(unit.getSource()),
                              enclosingLibraryUnit.getElement(),
                              coreLibraryUnit.getElement(),
                              null, -1, -1, config, listener);
    System.err.println("analyzeDelta(" + unit.getSource().getName() + ") took " +
        (System.currentTimeMillis() - start) + "ms");
  }
}
