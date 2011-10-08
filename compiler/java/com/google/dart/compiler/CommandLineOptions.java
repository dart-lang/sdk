// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.common.collect.Lists;
import com.google.dart.runner.DartRunner;
import com.google.dart.runner.RunnerOptions;

import org.kohsuke.args4j.Argument;
import org.kohsuke.args4j.CmdLineException;
import org.kohsuke.args4j.CmdLineParser;
import org.kohsuke.args4j.Option;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

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

    @Option(name = "--check-only", aliases = { "-check-only" },
        usage = "Do not generate output, only analyze")
    private boolean checkOnly = false;

<<<<<<< HEAD
    @Option(name = "--warn_no_such_type",
        usage = "Treat some type checks as warnints\n instead of fatal errors")
    private boolean shouldWarnOnNoSuchType = false;
=======
    @Option(name = "--enable_type_checks", usage = "generate runtime type checks")
    private boolean developerModeChecks = false;
>>>>>>> master

    @Option(name = "--disable-type-optimizations",
        usage = "Turn off type optimizations\n (for debugging)")
    private boolean disableTypeOptimizations = false;

    @Option(name = "--documentation-lib", aliases = { "-documentation-lib" },
        usage = "Only generate docs for the\n given library")
    private String documentationLibrary = null;

    @Option(name = "--documentation-out", aliases = { "-documentation-out" },
        usage = "Directory to write documentation")
    private String documentationOutputDirectory = null;

    @Option(name = "--generate-documentation", aliases = { "-generate-documentation" },
        usage = "Generate docs from source")
    private boolean generateDocumentation = false;

    @Option(name = "--generate-isolate-stubs", aliases = { "-generate-isolate-stubs" },
        usage = "Classes to generate stubs\n (comma-separated list)")
    private String generateIsolateStubs = null;

    @Option(name = "--human-readable-output",
        usage = "Write human readable javascript")
    private boolean generateHumanReadableOutput = false;

    @Option(name = "--ignore-unrecognized-flags",
        usage = "Ignore unrecognized command line flags")
    private boolean ignoreUnrecognizedFlags = false;

    @Option(name = "--isolate-stub-out", aliases = { "-isolate-stub-out" },
        usage = "File to receive generated stub output")
    private String isolateStubOutputFile = null;

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

    private boolean optimize = false;

    /**
     * Enables optimization of the generated javascript.
     */
    @Option(name = "--optimize", aliases = { "-optimize" },
        usage = "Produce optimized code")
    public void setOptimize(boolean optimize) {
      this.optimize = optimize;
    }

    @Option(name = "--out",
        usage = "Write generated JavaSccript  to a file")
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
      return checkOnly;
    }

    /**
     * Returns whether the option -generate-documentation is provided.
     */
    public boolean generateDocumentation() {
      return generateDocumentation;
    }

    /**
     * Returns the library to document. If null is returned generate
     * documentation for all libraries.
     */
    public String getDocumentationLibrary() {
      return documentationLibrary;
    }

    /**
     * Returns the documentation output directory.
     */
    public String getDocumentationOutputDirectory() {
      return documentationOutputDirectory;
    }

    /**
     * Returns the names of classes to generate stubs for.
     */
    public Set<String> getIsolateStubClasses() {
      Set<String> set = new HashSet<String>();
      if (generateIsolateStubs != null) {
        set.addAll(Arrays.asList(generateIsolateStubs.split(",")));
      }
      return set;
    }

    public String getIsolateStubOutputFile() {
      return isolateStubOutputFile;
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

    public boolean generateHumanReadableOutput() {
      return generateHumanReadableOutput;
    }

    /**
     * @return the path to receive compiler output.
     */
    public File getOutputFilename() {
      return outputFilename;
    }

    /**
     * Returns <code>true</code> if optimization is enabled.
     */
    public boolean shouldOptimize() {
      return optimize;
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
     * Returns returns true if some resolver static errors should be reported as type
     * warnings instead of fatal errors.
     */
    public boolean shouldWarnOnNoSuchType() {
      return shouldWarnOnNoSuchType;
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
  }

  /**
   * Command line options accepted by the {@link DartRunner} entry point.
   */
  public static class DartRunnerOptions extends CompilerOptions implements RunnerOptions {

    @Option(name = "--compile-only", usage = "Compile but do not execute")
    private boolean compileOnly = false;

    @Option(name = "--expose_core_impl", usage = "Automatic import of dart:coreimpl library")
    private boolean exposeCoreImpl = false;

    @Option(name = "--verbose", usage = "Extra diagnostic output")
    private boolean verbose = false;

    @Option(name="--prof", usage = "Enable profiling")
    private boolean prof;

    @Option(name = "--rhino", usage = "Use rhino as the javascript interpreter")
    private boolean rhino = false;

    /**
     * @return <code>true</code> if the program should compile but not execute.
     */
    @Override
    public boolean shouldCompileOnly() {
      return compileOnly;
    }

    /**
     * @return <code>true</code> to automatically import dart:coreimpl
     */
    public boolean shouldExposeCoreImpl() {
      return exposeCoreImpl;
    }

    /**
     * Returns <code>true</code> if profiling is enabled.
     */
    @Override
    public boolean shouldProfile() {
      return prof;
    }

    /**
     * @return <code>true</code> if rhino should be used as the runtime (default is to invoke d8)
     */
    @Override
    public boolean useRhino() {
      return rhino;
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
   * Command line options accepted by the {@link com.google.dart.runner.TestRunner} entry point.
   */
  public static class TestRunnerOptions extends DartRunnerOptions  {
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
