// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.common.collect.Lists;
import com.google.dart.compiler.CompilerConfiguration.ErrorFormat;
import com.google.dart.runner.DartRunner;
import com.google.dart.runner.RunnerOptions;

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

    @Option(name = "--deprecated-generate-code",
        usage = "Use deprecated code generation.\n Will be removed 1 March 2012.")
    private boolean deprecatedGenerateCode = false;

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

    @Option(name = "--generate_source_maps",
        usage = "Generate source maps")
    private boolean generateSourceMaps = false;

    @Option(name = "--dump_ast_format",
        usage = "Dump parse tree. Supported formats include console, text or dot")
    private String dumpAST = "";

    @Option(name = "--coverage_type",
        usage = "Add instrumentation probes for collecting coverage. " +
            "Supported types include function, statement, branch and all")
    private String coverage = "";

    @Option(name = "--human-readable-output",
        usage = "Write human readable javascript")
    private boolean generateHumanReadableOutput = false;

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

    @Option(name = "--noincremental", aliases = { "-noincremental" },
        usage = "Disable incremental compilation")
    private boolean noincremental = false;

    @Option(name = "--out",
        usage = "Write generated JavaScript to a file")
    private File outputFilename = null;

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
     * Returns whether the option -check-only is provided.
     */
    public boolean checkOnly() {
      return !deprecatedGenerateCode;
    }

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
      return !noincremental;
    }

    public boolean shouldBatch() {
      return batch;
    }

    public boolean disableTypeOptimizations() {
      return disableTypeOptimizations;
    }

    public boolean generateSourceMaps() {
      return generateSourceMaps;
    }

    public boolean generateHumanReadableOutput() {
      return generateHumanReadableOutput;
    }

    public String dumpAST(){
      return dumpAST;
    }

    public String getCoverageType(){
      return coverage;
    }

    /**
     * @return the path to receive compiler output.
     */
    public File getOutputFilename() {
      return outputFilename;
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
   * Command line options accepted by the {@link DartRunner} entry point.
   */
  public static class DartRunnerOptions extends CompilerOptions implements RunnerOptions {

    @Option(name = "--compile-only", usage = "Compile but do not execute")
    private boolean compileOnly = false;

    @Option(name = "--verbose", usage = "Extra diagnostic output")
    private boolean verbose = false;

    @Option(name="--prof", usage = "Enable profiling")
    private boolean prof;

    /**
     * @return <code>true</code> if the program should compile but not execute.
     */
    @Override
    public boolean shouldCompileOnly() {
      return compileOnly;
    }

    /**
     * Returns <code>true</code> if profiling is enabled.
     */
    @Override
    public boolean shouldProfile() {
      return prof;
    }

    /**
     * @return <code>true</code> to enable diagnostic output
     */
    @Override
    public boolean verbose() {
      return verbose;
    }

    public void setVerbose(boolean value) {
      this.verbose = value;
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
