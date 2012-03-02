// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.common.collect.Lists;
import com.google.dart.compiler.CompilerConfiguration.ErrorFormat;

import org.kohsuke.args4j.Argument;
import org.kohsuke.args4j.CmdLineException;
import org.kohsuke.args4j.CmdLineParser;
import org.kohsuke.args4j.Option;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

/**
 * Options that can be specified on the command line.
 */
public class CommandLineOptions {

  /**
   * Command line options accepted by the {@link DartCompiler} entry point.
   */
  public static class CompilerOptions {

    @Option(name = "--batch", aliases = { "-batch" },
        usage = "Batch mode (for unit testing)")
    private boolean batch = false;

    @Option(name = "--expose_core_impl", usage = "Automatic import of dart:coreimpl library")
    private boolean exposeCoreImpl = false;

    @Option(name = "--error_format",
        usage = "Format errors as normal or machine")
    private String errorFormat = "";

    @Option(name = "--enable_type_checks",
        usage = "Generate runtime type checks")
    private boolean developerModeChecks = false;

    @Option(name = "--disable-type-optimizations",
        usage = "Turn off type optimizations\n (for debugging)")
    private boolean disableTypeOptimizations = false;

    @Option(name = "--dump_ast_format",
        usage = "Dump parse tree. Supported formats include console, text or dot")
    private String dumpAST = "";

    @Option(name = "--ignore-unrecognized-flags",
        usage = "Ignore unrecognized command line flags")
    private boolean ignoreUnrecognizedFlags = false;

    @Option(name = "--jvm-metrics-detail",
        usage = "Display summary (default) or\n verbose metrics")
    private String jvmMetricDetail = "summary";

    @Option(name = "--jvm-metrics-format",
        usage = "Output metrics in tabular (default)\n or pretty format")
    private String jvmMetricFormat = "tabular";

    @Option(name = "--jvm-metrics-type",
        usage = "Comma-separated list to display:\n "
        + "  all:  (default) all stat types\n "
        + "  gc:   show garbage collection stats\n "
        + "  mem:  show memory stats\n "
        + "  jit:  show jit stats")
    private String jvmMetricType = "all";

    // leave the command line flag for legacy purposes.
    @SuppressWarnings("unused")
    @Option(name = "--noincremental",
        usage = "Disable incremental compilation (default)")
    private boolean noincremental = true; // not used, just a placeholder for arg parsing

    @Option(name = "--incremental",
    usage = "Enable incremental compilation")
    private boolean incremental = false;

    // TODO(zundel): -out is for backward compatibility until scripts are updated
    @Option(name = "--work", aliases = { "-out" },
        usage = "Directory to receive compiler output\n for future incremental builds")
    private File workDirectory = new File("out");

    @Option(name = "--help", aliases = { "-?", "-help" },
        usage = "Prints this help message")
    private boolean showHelp = false;

    @Option(name = "--jvm-metrics",
        usage = "Print jvm metrics at end of compile")
    private boolean showJvmMetrics = false;

    @Option(name = "--metrics",
        usage = "Print compilation metrics")
    private boolean showMetrics = false;

    @Option(name = "--fatal-type-errors", aliases = { "-fatal-type-errors" },
        usage = "Treat type errors as fatal")
    private boolean typeErrorsAreFatal = false;

    @Option(name = "--fatal-warnings", aliases = { "-Werror" },
        usage = "Treat non-type warnings as fatal")
    private boolean warningsAreFatal = false;

    @Argument
    private final List<String> sourceFiles = new ArrayList<String>();

    /**
     * @return <code>true</code> to automatically import dart:coreimpl
     */
    public boolean shouldExposeCoreImpl() {
      return exposeCoreImpl;
    }

    public String getJvmMetricOptions() {
      if (!showJvmMetrics) {
        return null;
      }
      return jvmMetricDetail + ":" + jvmMetricFormat + ":" + jvmMetricType;
    }

    /**
     * Returns the list of files passed to the compiler.
     */
    public List<String> getSourceFiles() {
      return sourceFiles;
    }

    /**
     * Returns the path to receive compiler intermediate output.
     */
    public File getWorkDirectory() {
      return workDirectory;
    }

    public boolean ignoreUnrecognizedFlags() {
      return ignoreUnrecognizedFlags;
    }

    /**
     * Returns whether the compiler should attempt to incrementally recompile.
     */
    public boolean buildIncrementally() {
      return incremental;
    }

    public boolean shouldBatch() {
      return batch;
    }

    public boolean disableTypeOptimizations() {
      return disableTypeOptimizations;
    }

    public String dumpAST(){
      return dumpAST;
    }

    /**
     * Returns <code>true</code> if the compiler should print it's help message.
     */
    public boolean showHelp() {
      return showHelp;
    }

    public boolean showJvmMetrics() {
      return showJvmMetrics;
    }

    public boolean showMetrics() {
      return showMetrics;
    }

    /**
     * Returns whether type errors are fatal.
     */
    public boolean typeErrorsAreFatal() {
      return typeErrorsAreFatal;
    }

    /**
     * Returns whether warnings (excluding type warnings) are fatal.
     */
    public boolean warningsAreFatal() {
      return warningsAreFatal;
    }

    public boolean developerModeChecks() {
      return developerModeChecks;
    }

    /**
     * @return the format to use for printing errors
     */
    public ErrorFormat printErrorFormat() {
      String lowerError = errorFormat.toLowerCase();
      if ("machine".equals(lowerError)) {
        return ErrorFormat.MACHINE;
      }
      return ErrorFormat.NORMAL;
    }
  }

  /**
   * Parses command line options, handling the feature to ignore unrecognized
   * flags.
   *
   * If one of the options is 'ignore-unrecognized-flags', then any exceptions
   * for 'not a valid option' are suppressed.
   *
   * @param args Arguments passed from main()
   * @param parsedOptions [out parameter] parsed options
   * @throws CmdLineException Thrown if there is a problem parsing the options.
   */
  public static CmdLineParser parse(String[] args, CompilerOptions parsedOptions)
      throws CmdLineException {
    boolean ignoreUnrecognized = false;
    for (String arg : args) {
      if (arg.equals("--ignore-unrecognized-flags")) {
        ignoreUnrecognized = true;
        break;
      }
    }

    if (!ignoreUnrecognized) {
      CmdLineParser cmdLineParser = new CmdLineParser(parsedOptions);
      cmdLineParser.parseArgument(args);
      return cmdLineParser;
    }
    CmdLineParser cmdLineParser = new CmdLineParser(parsedOptions);
    for (int i = 0, len = args.length; i < len; i++) {
      try {
        cmdLineParser.parseArgument(args);
      } catch (CmdLineException e) {
        String msg = e.getMessage();

        if (e.getMessage().endsWith(" is not a valid option")) {
          String option = msg.substring(1);
          int closeQuote = option.indexOf('\"');
          option = option.substring(0, closeQuote);
          List<String> newArgs = Lists.newArrayList();
          for (String arg : args) {
            if (arg.equals(option)) {
              System.out.println("(Ignoring unrecognized flag: " + arg + ")");
              continue;
            }
            newArgs.add(arg);
          }
          args = newArgs.toArray(new String[newArgs.size()]);
          cmdLineParser = new CmdLineParser(parsedOptions);
          continue;
        }
      }
      break;
    }
    return cmdLineParser;
  }
}
