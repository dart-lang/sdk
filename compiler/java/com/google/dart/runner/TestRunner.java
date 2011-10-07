// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.runner;

import com.google.dart.compiler.CommandLineOptions;
import com.google.dart.compiler.CommandLineOptions.TestRunnerOptions;
import com.google.dart.compiler.DartCompiler;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.UnitTestBatchRunner;
import com.google.dart.compiler.UnitTestBatchRunner.Invocation;

import org.kohsuke.args4j.CmdLineException;
import org.kohsuke.args4j.CmdLineParser;

import java.io.ByteArrayOutputStream;
import java.io.OutputStream;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.List;

/**
 * Runs dart programs.<br/>
 * The command-line interface is similar to the VM's command line interface.
 * </br>
 */
public class TestRunner {

  public static void main(String[] args) {

    try {
      boolean runBatch = false;
      TestRunnerOptions options = processCommandLineOptions(args);
      if (options.shouldBatch()) {
        runBatch = true;
        if (args.length > 1) {
          System.err.println("(Extra arguments specified with -batch ignored.)");
        }
      }
      if (runBatch) {
        UnitTestBatchRunner.runAsBatch(args, new Invocation() {
          @Override
          public boolean invoke(String[] args) throws Throwable {
            try {
              throwingMain(args, System.out, System.err);
            } catch (RunnerError e) {
              System.out.println(e.getLocalizedMessage());
              return false;
            }
            return true;
          }
        });
      } else {
        throwingMain(args, System.out, System.err);
      }
    } catch (RunnerError e) {
      System.err.println(e.getLocalizedMessage());
      System.exit(1);
    } catch (Throwable e) {
      e.printStackTrace();
      DartCompiler.crash();
    }
  }

  private static void printUsageAndThrow(CmdLineParser cmdLineParser, String reason) throws RunnerError {
    StringBuilder usage = new StringBuilder();
    usage.append(reason);
    usage.append("\n");
    usage.append("Usage: ");
    usage.append(System.getProperty("com.google.dart.runner.progname",
                                      TestRunner.class.getSimpleName()));
    usage.append(" [<options>] <dart-script-file> [<script-arguments>]\n");
    usage.append("\n");

    OutputStream s = new ByteArrayOutputStream();
    if (cmdLineParser == null) {
      cmdLineParser = new CmdLineParser(new TestRunnerOptions());
    }
    cmdLineParser.printUsage(s);
    usage.append(s);
    throw new RunnerError(usage.toString());
  }

  private static TestRunnerOptions processCommandLineOptions(String[] args) throws RunnerError {
    CmdLineParser cmdLineParser = null;
    TestRunnerOptions parsedOptions = null;
    try {
      parsedOptions = new TestRunnerOptions();
      cmdLineParser = CommandLineOptions.parse(args, parsedOptions);
      if (args.length == 0 || parsedOptions.showHelp()) {
        printUsageAndThrow(cmdLineParser, "");
        System.exit(1);
      }
    } catch (CmdLineException e) {
      printUsageAndThrow(cmdLineParser, e.getLocalizedMessage());
      System.exit(1);
    }

    assert parsedOptions != null;
    return parsedOptions;
  }
  public static void throwingMain(String[] args, PrintStream stdout, PrintStream stderr)
      throws RunnerError {
    TestRunnerOptions options = processCommandLineOptions(args);
    List<LibrarySource> imports = new ArrayList<LibrarySource>();
    DartRunner.throwingMain(options, args, imports, stdout, stderr);
  }
}
