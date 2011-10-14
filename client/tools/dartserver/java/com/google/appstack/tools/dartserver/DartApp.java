// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.appstack.tools.dartserver;

import java.io.File;
import java.io.IOException;
import java.io.Reader;
import java.io.StringReader;
import java.io.StringWriter;
import java.io.Writer;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.Backend;
import com.google.dart.compiler.CompilerConfiguration;
import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.DartArtifactProvider;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilationPhase;
import com.google.dart.compiler.DartCompiler;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DartSource;
import com.google.dart.compiler.DefaultCompilerConfiguration;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.UrlLibrarySource;
import com.google.dart.compiler.backend.js.JavascriptBackend;
import com.google.dart.compiler.metrics.CompilerMetrics;

public class DartApp {
  public static class Result {
    private final DartApp app;
    private final List<DartCompilationError> errors;
    private final Throwable compilationException;

    Result(DartApp app, List<DartCompilationError> errors, Throwable compilationException) {
      this.app = app;
      this.errors = errors;
      this.compilationException = compilationException;
    }

    public boolean didBuild() {
      return errors.isEmpty() && compilationException == null;
    }

    public DartApp getApp() {
      return app;
    }

    public List<DartCompilationError> getErrors() {
      return errors;
    }

    public Throwable getCompilationException() {
      return compilationException;
    }
  }

  private final String sources;

  public DartApp(String sources) {
    this.sources = sources;
  }

  public String getSources() {
    return sources;
  }

  private static class CompilationState {
    private StringWriter appCode;
    private List<DartCompilationError> errors = new ArrayList<DartCompilationError>();

    private class Listener extends DartCompilerListener {
      @Override
      public void compilationError(DartCompilationError error) {
        errors.add(error);
      }

      @Override
      public void compilationWarning(DartCompilationError error) {
        errors.add(error);
      }

      @Override
      public void typeError(DartCompilationError error) {
        errors.add(error);
      }

      @Override
      public void unitCompiled(DartUnit unit) {
      }
    }

    private static String keyFor(Source source, String part, String extension) {
      return source.getName() + "/" + part + "/" + extension;
    }

    private class Artifacts extends DartArtifactProvider {

      private final Map<String, StringWriter> artifacts = new HashMap<String, StringWriter>();

      @Override
      public Reader getArtifactReader(Source source, String part, String extension)
          throws IOException {
        final StringWriter data = artifacts.get(keyFor(source, part, extension));
        return data == null ? null : new StringReader(data.toString());
      }

      @Override
      public Writer getArtifactWriter(Source source, String part, String extension)
          throws IOException {
        final StringWriter data = new StringWriter();
        if (source instanceof LibrarySource
            && JavascriptBackend.EXTENSION_JS.equals(extension)) {
          appCode = data;
        }

        artifacts.put(keyFor(source, part, extension), data);
        return data;
      }

      @Override
      public boolean isOutOfDate(Source source, Source base, String extension) {
        return true;
      }

      @Override
      public URI getArtifactUri(Source source, String part, String extension) {
        try {
          // TODO(knorton): This is all sorts of wrong but I need to find out
          // what these URI's are actually used for.
          return new URI("bogus://" + source.getName());
        } catch (URISyntaxException e) {
          throw new RuntimeException(e);
        }
      }

    }

    private final Listener listener = new Listener();
    private final Artifacts artifacts = new Artifacts();

    String getJavaScript() {
      return appCode.toString();
    }

    List<DartCompilationError> getErrors() {
      return errors;
    }

    boolean hasErrors() {
      return !errors.isEmpty();
    }
  }

  public String getJavaScript() {
    return sources;
  }

  static class StrictOptions extends CompilerOptions {
    public boolean typeErrorsAreFatal() {
      return true;
    }

    /**
     * Returns whether warnings (excluding type warnings) are fatal.
     */
    public boolean warningsAreFatal() {
      return true;
    }
  }

  public static Result build(File appFile) {
    final CompilationState state = new CompilationState();
    try {
      CompilerConfiguration config = new DefaultCompilerConfiguration(
          new JavascriptBackend(), new StrictOptions());
      DartCompiler.compileLib(new UrlLibrarySource(appFile),
          config, state.artifacts, state.listener);
      return state.hasErrors() ? new Result(null, state.getErrors(), null)
          : new Result(new DartApp(state.getJavaScript()), state.getErrors(), null);
    } catch (Throwable e) {
      return new Result(new DartApp(""), new ArrayList<DartCompilationError>(), e);
    }
  }
}
