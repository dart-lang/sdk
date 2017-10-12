// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import java.io.*;
import java.util.*;
import org.antlr.runtime.*;

class ParsingResult {
  public int numberOfFileArguments;
  public int numberOfFailures;
}

/// Class for `main` which will parse files given as command line arguments.
public class SpecParser {
  private static void normalExit() {
    // Terminate with exit code indicating normal termination.
    System.exit(0);
  }

  private static void compileTimeErrorExit() {
    // Terminate with exit code indicating compile-time error.
    System.exit(254);
  }

  private static void helpAndExit() {
    System.err.println("Expected arguments: [--verbose] <file>...");
    compileTimeErrorExit();
  }

  /// Receive command lines from standard input and produce feedback about
  /// the outcome on standard output and standard error, as expected by
  /// tools/test.py when running with `--batch`.
  public static void runAsBatch() throws IOException, RecognitionException {
    ParsingResult result = new ParsingResult();
    long startTime = System.currentTimeMillis();
    InputStreamReader input = new InputStreamReader(System.in);
    BufferedReader bufferedInput = new BufferedReader(input);
    String cmdLine;

    System.out.println(">>> BATCH START");
    while ((cmdLine = bufferedInput.readLine()) != null) {
      if (cmdLine.length() == 0) {
        System.out.println(
            ">>> BATCH END (" +
            (result.numberOfFileArguments - result.numberOfFailures) +
            "/" + result.numberOfFileArguments + ") " +
            (System.currentTimeMillis() - startTime) + "ms");
        if (result.numberOfFailures > 0) compileTimeErrorExit();
        normalExit();
      }

      String[] lineArgs = cmdLine.split("\\s+");
      result = parseFiles(lineArgs);
      // Write stderr end token and flush.
      System.err.println(">>> EOF STDERR");
      String resultPassString = result.numberOfFailures == 0 ? "PASS" : "FAIL";
      System.out.println(">>> TEST " + resultPassString + " " +
          (System.currentTimeMillis() - startTime) + "ms");
      startTime = System.currentTimeMillis();
    }
  }

  /// From [arguments], obey the flags ("--<flag_name>") if known and ignore
  /// them if unknown; treat the remaining [arguments] as file paths and
  /// parse each of them. Return a [ParsingResult] specifying how many files
  /// were parsed, and how many of them failed to parse.
  private static ParsingResult parseFiles(String[] arguments)
      throws IOException, RecognitionException {
    ParsingResult result = new ParsingResult();
    boolean verbose = false;

    result.numberOfFileArguments = arguments.length;
    for (int i = 0; i < arguments.length; i++) {
      String filePath = arguments[i];
      if (filePath.substring(0, 2).equals("--")) {
        result.numberOfFileArguments--;
        if (result.numberOfFileArguments == 0) return result;
        if (filePath.equals("--verbose")) verbose = true;
        if (filePath.equals("--batch")) runAsBatch();
        // Ignore all other flags.
        continue;
      }
      if (verbose) System.err.println("Parsing file: " + filePath);
      DartParser parser = new DartParser(new CommonTokenStream(
          new DartLexer(new ANTLRFileStream(filePath))));
      if (!parser.parseLibrary(filePath)) result.numberOfFailures++;
    }
    return result;
  }

  public static void main(String[] args) throws Exception {
    if (args.length == 0) helpAndExit();
    ParsingResult result = parseFiles(args);

    if (result.numberOfFileArguments == 0) {
      helpAndExit();
    } else if (result.numberOfFileArguments == 1) {
      if (result.numberOfFailures > 0) {
        System.err.println("Parsing failed");
        compileTimeErrorExit();
      } else {
        System.out.println("Parsing succeeded.");
      }
    } else {
      if (result.numberOfFailures > 0) {
        System.err.println(
            "Parsed " + result.numberOfFileArguments + " files, " +
            result.numberOfFailures + " failed.");
        compileTimeErrorExit();
      } else {
        System.out.println("Parsed " + result.numberOfFileArguments +
            " files successfully.");
      }
    }
  }
}
