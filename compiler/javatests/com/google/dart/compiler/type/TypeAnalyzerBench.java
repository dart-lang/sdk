// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.CompilerConfiguration;
import com.google.dart.compiler.DartArtifactProvider;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilationPhase;
import com.google.dart.compiler.DartCompiler;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DefaultCompilerConfiguration;
import com.google.dart.compiler.DefaultDartArtifactProvider;
import com.google.dart.compiler.DefaultLibrarySource;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.UrlLibrarySource;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.resolver.CoreTypeProvider;

import org.kohsuke.args4j.CmdLineException;
import org.kohsuke.args4j.CmdLineParser;

import java.io.CharArrayReader;
import java.io.CharArrayWriter;
import java.io.File;
import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.net.URI;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Benchmark for the type analyzer. The benchmark will loop forever to ease profiling.
 */
public class TypeAnalyzerBench {
  private static final double SCORE_SCALE = 1000d;
  private static final long ROUND_DURATION_MS = 5000L;

  public static void main(String... arguments) throws CmdLineException, IOException {
    CompilerOptions compilerOptions = new CompilerOptions();
    CmdLineParser cmdLineParser = new CmdLineParser(compilerOptions);
    cmdLineParser.parseArgument(arguments);
    final CollectingPhase phase = new CollectingPhase();
    CompilerConfiguration config = new DefaultCompilerConfiguration(compilerOptions) {
      @Override
      public List<DartCompilationPhase> getPhases() {
        ArrayList<DartCompilationPhase> phases = new ArrayList<DartCompilationPhase>();
        phases.addAll(super.getPhases());
        phases.add(phase);
        return phases;
      }
    };
    DartArtifactProvider provider = getArtifactProvider(config.getOutputDirectory());
    DartCompilerListener listener = getListener();
    List<String> sourceFiles = compilerOptions.getSourceFiles();
    if (sourceFiles.size() != 1) {
      throw new IllegalArgumentException("incorrect number of source files " + sourceFiles);
    }
    File sourceFile = new File(sourceFiles.get(0));
    LibrarySource lib;
    if (sourceFile.getName().endsWith(".dart")) {
      lib = new DefaultLibrarySource(sourceFile, null);
    } else {
      lib = new UrlLibrarySource(sourceFile);
    }
    DartCompiler.compileLib(lib, config, provider, listener);
    Deque<Double> scores = new ArrayDeque<Double>(10);
    for (int i = 0; i < 10; i++) {
      scores.addLast(0d);
    }
    long start = System.currentTimeMillis();
    int i = 0;
    while (true) {
      i++;
      TypeAnalyzer typeAnalyzer = new TypeAnalyzer();
      for (DartUnit unit : phase.units) {
        typeAnalyzer.exec(unit, phase.context, phase.typeProvider);
      }
      long elapsed = System.currentTimeMillis() - start;
      if (elapsed > ROUND_DURATION_MS) {
        double score = i * SCORE_SCALE / elapsed;
        scores.removeFirst();
        scores.addLast(score);
        printScores(scores);
        start = System.currentTimeMillis();
        i = 0;
      }
    }
  }

  private static void printScores(Deque<Double> scores) {
    double xn = 1d;
    for (double x : scores) {
      xn *= x;
    }
    double geomean = Math.pow(xn, 1d / scores.size());
    xn = 0d;
    for (double x : scores) {
      double deviation = x - geomean;
      xn += deviation * deviation;
    }
    double stddev = Math.sqrt(xn / (scores.size() - 1));
    System.out.println(String.format("geomean %.03f std. dev. %.03f", geomean, stddev));
  }

  private static DartArtifactProvider getArtifactProvider(File outputDirectory) {
    final DartArtifactProvider provider = new DefaultDartArtifactProvider(outputDirectory);
    return new DartArtifactProvider() {
      ConcurrentHashMap<URI, CharArrayWriter> artifacts =
          new ConcurrentHashMap<URI, CharArrayWriter>();

      @Override
      public boolean isOutOfDate(Source source, Source base, String extension) {
        return true;
      }

      @Override
      public Writer getArtifactWriter(Source source, String part, String extension) {
        URI uri = getArtifactUri(source, part, extension);
        CharArrayWriter writer = new CharArrayWriter();
        CharArrayWriter existing = artifacts.putIfAbsent(uri, writer);
        return (existing == null) ? writer : existing;
      }


      @Override
      public URI getArtifactUri(Source source, String part, String extension) {
        return provider.getArtifactUri(source, part, extension);
      }

      @Override
      public Reader getArtifactReader(Source source, String part, String extension)
          throws IOException {
        URI uri = getArtifactUri(source, part, extension);
        CharArrayWriter writer = artifacts.get(uri);
        if (writer != null) {
          return new CharArrayReader(writer.toCharArray());
        }
        return provider.getArtifactReader(source, part, extension);
      }
    };
  }

  private static DartCompilerListener getListener() {
    return new DartCompilerListener() {
      @Override
      public void compilationError(DartCompilationError event) {
      }

      @Override
      public void compilationWarning(DartCompilationError event) {
      }

      @Override
      public void typeError(DartCompilationError event) {
      }
    };
  }

  static class CollectingPhase implements DartCompilationPhase {
    List<DartUnit> units = new ArrayList<DartUnit>();
    DartCompilerContext context;
    CoreTypeProvider typeProvider;

    @Override
    public synchronized DartUnit exec(DartUnit unit, DartCompilerContext context,
                                      CoreTypeProvider typeProvider) {
      units.add(unit);
      this.context = context;
      this.typeProvider = typeProvider;
      return unit;
    }
  }
}
