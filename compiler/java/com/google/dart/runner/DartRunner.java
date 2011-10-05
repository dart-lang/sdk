// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.runner;

import com.google.common.base.Joiner;
import com.google.common.io.CharStreams;
import com.google.common.io.Files;
import com.google.dart.compiler.Backend;
import com.google.dart.compiler.CommandLineOptions;
import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.CommandLineOptions.DartRunnerOptions;
import com.google.dart.compiler.CompilerConfiguration;
import com.google.dart.compiler.DartArtifactProvider;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompiler;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.DefaultCompilerConfiguration;
import com.google.dart.compiler.DefaultDartCompilerListener;
import com.google.dart.compiler.DefaultErrorFormatter;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.UrlLibrarySource;
import com.google.dart.compiler.backend.js.ClosureJsBackend;
import com.google.dart.compiler.backend.js.JavascriptBackend;
import com.google.debugging.sourcemap.SourceMapConsumerFactory;
import com.google.debugging.sourcemap.SourceMapParseException;
import com.google.debugging.sourcemap.SourceMapSupplier;
import com.google.debugging.sourcemap.SourceMapping;

import org.kohsuke.args4j.CmdLineException;
import org.kohsuke.args4j.CmdLineParser;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintStream;
import java.io.Reader;
import java.io.StringReader;
import java.io.StringWriter;
import java.io.Writer;
import java.net.URI;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Collections;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

public class DartRunner {

  private static DartRunnerOptions processCommandLineOptions(String[] args) throws RunnerError {
    CmdLineParser cmdLineParser = null;
    DartRunnerOptions parsedOptions = null;
    try {
      parsedOptions = new DartRunnerOptions();
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

  public static void main(String[] args) {
    try {
      DartRunnerOptions options = processCommandLineOptions(args);
      throwingMain(options, args, Collections.<LibrarySource>emptyList(), System.out, System.err);
    } catch (RunnerError error) {
      System.err.println(error.getLocalizedMessage());
      System.exit(1);
    } catch (Throwable e) {
      e.printStackTrace();
      DartCompiler.crash();
    }
  }

  public static void throwingMain(DartRunnerOptions options,
                                  String[] args,
                                  List<LibrarySource> imports,
                                  PrintStream stdout,
                                  final PrintStream stderr)
      throws RunnerError {

    if (options.getSourceFiles().isEmpty()) {
      throw new RunnerError("No script files specified on the command line: " + Joiner.on(" ").join(args));
    }

    String script = options.getSourceFiles().get(0);
    ArrayList<String> scriptArguments = new ArrayList<String>();

    LibrarySource app = new UrlLibrarySource(new File(script));

    // TODO(zundel): Replace RunnerFlag enum with DartRunnerOptions
    final Set<RunnerFlag> flags = EnumSet.noneOf(RunnerFlag.class);
    if (options.shouldOptimize()) {
      flags.add(RunnerFlag.OPTIMIZE);
    }
    if (options.verbose()) {
      flags.add(RunnerFlag.VERBOSE);
    }
    if (options.shouldProfile()) {
      flags.add(RunnerFlag.PROFILE);
    }
    if (options.shouldCompileOnly()) {
      flags.add(RunnerFlag.COMPILE_ONLY);
    }
    if (options.typeErrorsAreFatal()) {
      flags.add(RunnerFlag.FATAL_TYPE_ERRORS);
    }
    if (options.useRhino()) {
      flags.add(RunnerFlag.USE_RHINO);
    }
    if (options.shouldExposeCoreImpl()) {
      imports = new ArrayList<LibrarySource>(imports);
      // use a place-holder LibrarySource instance, to be replaced when embedded
      // in the compiler, where the dart uri can be resolved.
      imports.add(new NamedPlaceHolderLibrarySource("dart:coreimpl"));
    }

    File outFile =  options.getOutputFilename();

    DefaultDartCompilerListener listener = new DefaultDartCompilerListener() {
        {
          ((DefaultErrorFormatter) formatter).setOutputStream(stderr);
        }
        @Override
        public void compilationWarning(DartCompilationError event) {
          compilationError(event);
        }
      };

    CompilationResult compiled;
    compiled = compileApp(app, imports, flags, listener);

    if (listener.getProblemCount() != 0) {
      throw new RunnerError("Compilation failed.");
    }

    if (outFile != null) {
      File dir = outFile.getParentFile();
      if (dir != null) {
        if (!dir.exists()) {
          throw new RunnerError("Cannot create: " + outFile.getName()
                                + ".  " + dir + " does not exist");
        }
        if (!dir.canWrite()) {
          throw new RunnerError("Cannot write " + outFile.getName() + " to "
              + dir + ":  Permission denied.");
        }
      } else {
        dir = new File (".");
        if (!dir.canWrite()) {
          throw new RunnerError("Cannot write " + outFile.getName() + " to "
              + dir + ":  Permission denied.");
        }
      }
      try {
        Files.write(compiled.js, outFile, Charset.defaultCharset());
      } catch (IOException e) {
        throw new RunnerError(e);
      }
    }

    if (!flags.contains(RunnerFlag.COMPILE_ONLY)) {
      runApp(compiled, app.getName(), flags, scriptArguments.toArray(new String[0]), stdout, stderr);
    }
  }

  private static void printUsageAndThrow(CmdLineParser cmdLineParser, String reason)
      throws RunnerError {

    StringBuilder usage = new StringBuilder();
    usage.append(reason);
    usage.append("\n");
    usage.append("Usage: ");
    usage.append(System.getProperty("com.google.dart.runner.progname",
                                      DartRunner.class.getSimpleName()));
    usage.append(" [<options>] <dart-script-file> [<script-arguments>]\n");
    usage.append("\n");

    OutputStream s = new ByteArrayOutputStream();
    if (cmdLineParser == null) {
      cmdLineParser = new CmdLineParser(new DartRunnerOptions());
    }
    usage.append(s);
    throw new RunnerError(usage.toString());
  }

  private static class NamedPlaceHolderLibrarySource implements LibrarySource {
    private final String name;

    public NamedPlaceHolderLibrarySource(String name) {
      this.name = name;
    }

    @Override
    public boolean exists() {
      throw new AssertionError();
    }

    @Override
    public long getLastModified() {
      throw new AssertionError();
    }

    @Override
    public String getName() {
      return name;
    }

    @Override
    public Reader getSourceReader() {
      throw new AssertionError();
    }

    @Override
    public URI getUri() {
      throw new AssertionError();
    }

    @Override
    public LibrarySource getImportFor(String relPath) {
      throw new AssertionError();
    }

    @Override
    public DartSource getSourceFor(String relPath) {
      throw new AssertionError();
    }
  }

  private static class RunnerDartArtifactProvider extends DartArtifactProvider {
    private final Map<String, StringWriter> artifacts = new ConcurrentHashMap<String, StringWriter>();

    @Override
    public Reader getArtifactReader(Source source, String part, String ext) {
      String key = getKey(source, part, ext);
      StringWriter w = artifacts.get(key);
      if (w == null) {
        return null;
      }
      return new StringReader(w.toString());
    }

    @Override
    public URI getArtifactUri(Source source, String part, String ext) {
      String key = getKey(source, part, ext);
      return URI.create(key);
    }

    @Override
    public Writer getArtifactWriter(Source source, String part, String ext) {
      StringWriter w = new StringWriter();
      String key = getKey(source, part, ext);
      StringWriter oldValue = artifacts.put(key, w);
      if (oldValue != null) {
        throw new RuntimeException("Can only write artifact once for " + key);
      }
      return w;
    }

    private String getKey(Source source, String part, String ext) {
      String keyPart = (part.isEmpty()) ? "" : "$" + part;
      return source.getName() + keyPart + "." + ext;
    }

    public String getGeneratedFileContents(String name) {
      StringWriter w = artifacts.get(name);
      if (w == null) {
        return null;
      }
      return w.toString();
    }

    @Override
    public boolean isOutOfDate(Source source, Source base, String ext) {
      return true;
    }
  }

  public static void compileAndRunApp(LibrarySource app,
                                      Set<RunnerFlag> flags,
                                      CompilerConfiguration config,
                                      DartCompilerListener listener,
                                      String[] dartArguments,
                                      PrintStream stdout,
                                      PrintStream stderr)
      throws RunnerError {
    CompilationResult compiled = compileApp(
        app, Collections.<LibrarySource>emptyList(), config, listener);
    runApp(compiled, app.getName(), flags, dartArguments, stdout, stderr);
  }

  private static void runApp(CompilationResult compiled,
                             String sourceName,
                             Set<RunnerFlag> flags,
                             String[] scriptArguments,
                             PrintStream stdout,
                             PrintStream stderr)
      throws RunnerError {
    if (flags.contains(RunnerFlag.USE_RHINO)) {
      new RhinoLauncher().execute(compiled.js, sourceName, scriptArguments, flags, stdout, stderr);
    } else {
      new V8Launcher(compiled.mapping).execute(compiled.js, sourceName, scriptArguments, flags,
                                               stdout, stderr);
    }
  }

  private static class CompilationResult {
    final SourceMapping mapping;
    final String js;

    public CompilationResult(String js, SourceMapping mapping) {
      this.mapping = mapping;
      this.js = js;
    }
  }

  private static CompilationResult compileApp(LibrarySource app,
                                              List<LibrarySource> imports,
                                              final Set<RunnerFlag> flags,
                                              DartCompilerListener listener)
      throws RunnerError {
    // TODO(johnlenz): create a "OptimizingCompilerConfiguration"

    Backend backend;
    CompilerOptions defaultOptions = new CompilerOptions();
    if (flags.contains(RunnerFlag.OPTIMIZE)) {
      backend = new ClosureJsBackend();
      defaultOptions.optimize(true);
    } else {
      backend = new JavascriptBackend();
    }
    CompilerConfiguration config = new DefaultCompilerConfiguration(backend, defaultOptions) {
      @Override
      public boolean expectEntryPoint() {
        return true;
      }

      @Override
      public boolean typeErrorsAreFatal() {
        return flags.contains(RunnerFlag.FATAL_TYPE_ERRORS);
      }
    };
    return compileApp(app, imports, config, listener);
  }

  /**
   * Parses and compiles an application to Javascript.
   */
  private static CompilationResult compileApp(LibrarySource app,
                                              List<LibrarySource> imports,
                                              CompilerConfiguration config,
                                              DartCompilerListener listener) throws RunnerError {
    try {
      final RunnerDartArtifactProvider provider = new RunnerDartArtifactProvider();
      String errmsg = DartCompiler.compileLib(app, imports, config, provider, listener);
      if (errmsg != null) {
         throw new RunnerError(errmsg);
      }
      Backend backend = config.getBackends().get(0);

      SourceMapping mapping = null;
      Reader mr = provider.getArtifactReader(app, "", backend.getSourceMapExtension());
      if (mr != null) {
        String mapContents = CharStreams.toString(mr);
        try {
          mapping = SourceMapConsumerFactory.parse(mapContents, new SourceMapSupplier() {

            @Override
            public String getSourceMap(String url) {
              String contents = provider.getGeneratedFileContents(url);
              if (contents == null || contents.isEmpty()) {
                return null;
              }
              return contents;
            }

          });
        } catch (SourceMapParseException e) {
          throw new AssertionError(e);
        }
        mr.close();
      }

      Reader r = provider.getArtifactReader(app, "", backend.getAppExtension());
      String js = CharStreams.toString(r);
      r.close();
      return new CompilationResult(js, mapping);
    } catch (IOException e) {
      // This can't happen; it's just a StringWriter.
      throw new AssertionError(e);
    }
  }
}
