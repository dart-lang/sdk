// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import org.antlr.runtime.*;

/// Class for `main` which will parse files given as command line arguments.
public class SpecParser {
  private static void helpAndExit() {
    System.err.println("Expected arguments: [--verbose] <file>...");
    System.exit(1);
  }

  public static void main(String[] args) throws Exception {
    boolean verbose = false;
    int numberOfFileArguments = 0;
    int numberOfFailures = 0;

    if (args.length == 0) helpAndExit();
    numberOfFileArguments = args.length;
    for (int i = 0; i < args.length; i++) {
      String filePath = args[i];
      if (filePath.equals("--verbose")) {
        verbose = true;
        numberOfFileArguments--;
        if (numberOfFileArguments == 0) helpAndExit();
        continue;
      }
      if (verbose) System.err.println("Parsing file: " + filePath);
      DartParser parser = new DartParser(new CommonTokenStream(
          new DartLexer(new ANTLRFileStream(filePath))));
      if (!parser.parseLibrary(filePath)) numberOfFailures++;
    }
    if (numberOfFailures > 0) {
      System.err.println("Parsed " + numberOfFileArguments + " files, " +
          numberOfFailures + " failing.");
      System.exit(1);
    } else {
      if (numberOfFileArguments == 1) {
        System.out.println("Parsed successfully.");
      } else {
        System.out.println("Parsed " + numberOfFileArguments +
            " files successfully.");
      }
    }
  }
}
