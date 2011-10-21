// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart;

import java.io.File;
import java.io.IOException;
import java.io.Reader;
import java.io.StringReader;
import java.io.StringWriter;
import java.io.Writer;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.List;
import java.util.Map;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.dart.compiler.CompilerConfiguration;
import com.google.dart.compiler.DartArtifactProvider;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompiler;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.DefaultCompilerConfiguration;
import com.google.dart.compiler.LibrarySource;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.UrlLibrarySource;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.backend.js.JavascriptBackend;

/**
 * Your one stop service for invoking the {@link DartCompiler} on an in-memory request.
 */
public class CompileService {
  /**
   * An in-memory {@link DartArtifactProvider}. This can be returned as a
   * {@link ThreadSafeArtifacts} to provide an immutable cache of artifacts.
   */
  private static class Artifacts extends DartArtifactProvider implements
      ThreadSafeArtifacts {

    private static String keyFor(Source source, String extension) {
      return source.getName() + "|" + extension;
    }
    private final ThreadSafeArtifacts snapshot;

    private final Map<String, Map<String, String>> artifacts = Maps.newHashMap();

    public Artifacts(ThreadSafeArtifacts snapshot) {
      this.snapshot = snapshot;
    }

    @Override
    public String getArtifact(Source source, String part, String extension) {
      // First check the snapshot for the artifact.
      final String fromSnapshot = (snapshot != null)
          ? snapshot.getArtifact(source, part, extension)
          : null;
      if (fromSnapshot != null) {
        return fromSnapshot;
      }

      // Next check the local artifacts.
      final Map<String, String> parts = artifacts.get(keyFor(source, extension));
      return parts == null ? null : parts.get(part);
    }

    @Override
    public Reader getArtifactReader(Source source, String part, String extension)
        throws IOException {
      final String artifact = getArtifact(source, part, extension);
      return artifact == null ? null : new StringReader(artifact);
    }

    @Override
    public URI getArtifactUri(Source source, String part, String extension) {
      return uriFor(part.isEmpty()
          ? source.getName() + "." + extension
          : source.getName() + "$" + part + "." + extension);
    }

    @Override
    public Writer getArtifactWriter(final Source source, final String part,
        final String extension) throws IOException {
      return new StringWriter() {
        @Override
        public void close() throws IOException {
          super.close();
          putArtifact(source, part, extension, toString());
        }
      };
    }

    public String getJavaScriptFor(Source source) {
      return getArtifact(source, "", JavascriptBackend.EXTENSION_APP_JS);
    }

    @Override
    public boolean hasArtifactsFor(Source source, String extension) {
      return (snapshot != null && snapshot.hasArtifactsFor(source, extension))
          || artifacts.containsKey(keyFor(source, extension));
    }

    @Override
    public boolean isOutOfDate(Source source, Source base, String extension) {
      return !hasArtifactsFor(base, extension);
    }

    private void putArtifact(Source source, String part, String extension,
        String data) {
      final String key = keyFor(source, extension);
      Map<String, String> parts = artifacts.get(key);
      if (parts == null) {
        parts = Maps.newHashMap();
        artifacts.put(key, parts);
      }
      parts.put(part, data);
    }
  }

  /**
   * Captures the errors and warnings during a compiler run.
   */
  private static class Listener  extends DartCompilerListener {

    private final List<CompileError> fatalErrors = Lists.newArrayList();

    private final List<CompileError> typeErrors = Lists.newArrayList();

    private final List<CompileError> warnings = Lists.newArrayList();

    @Override
    public void compilationError(DartCompilationError error) {
      fatalErrors.add(CompileError.from(error));
    }

    @Override
    public void compilationWarning(DartCompilationError error) {
      warnings.add(CompileError.from(error));
    }

    @Override
    public void typeError(DartCompilationError error) {
      typeErrors.add(CompileError.from(error));
    }

    @Override
    public void unitCompiled(DartUnit unit) {
    }
  }
  
  /**
   * Provides an immutable view of an Artifact provider. This allows
   * {@link Artifacts} to be built and then referenced as an immutable
   * (thread-safe) cache of compilation artifacts. The only reason this
   * interface exists is to help prevent concurrency bugs because if you mutate
   * it during a compile ... oof.
   */
  private interface ThreadSafeArtifacts {
    String getArtifact(Source source, String part, String extension);

    boolean hasArtifactsFor(Source source, String extension);
  }

  private final static String FAKE_NAME = "tator";

  public static CompileService create() {
    return create(false);
  }
  
  public static CompileService create(LibrarySource lib) {
    return create(lib, false);
  }

  public static CompileService create(boolean useCheckedMode) {
    final CompilerConfiguration config = config(true, useCheckedMode);
    final LibrarySource lib = config.getSystemLibraryFor("dart:core");
    return new CompileService(buildArtifactsFor(config, lib), lib, useCheckedMode);
  }

  public static CompileService create(LibrarySource lib, boolean useCheckedMode) {
    final CompilerConfiguration config = config(true, useCheckedMode);
    return new CompileService(buildArtifactsFor(config, lib), lib, useCheckedMode);
  }

  private static ThreadSafeArtifacts buildArtifactsFor(CompilerConfiguration config, LibrarySource lib) {
    // TODO(knorton): This needs a better way to communicate build errors.
    try {
      final Artifacts snapshot = new Artifacts(null);
      DartCompiler.compileLib(lib,
          config,
          snapshot,
          new DartCompilerListener() {
            @Override
            public void compilationError(DartCompilationError error) {
              throw new RuntimeException("Unable to build runtime lib: " + error);
            }

            @Override
            public void compilationWarning(DartCompilationError warning) {
            }

            @Override
            public void typeError(DartCompilationError error) {
              throw new RuntimeException("Unable to build runtime lib: " + error);
            }

            @Override
            public void unitCompiled(DartUnit unit) { 
            }
          });
      return snapshot;
    } catch (IOException e) {
      throw new RuntimeException(e);
    }

  }

  private static CompilerConfiguration config(final boolean incremental, final boolean checked) {
    return new DefaultCompilerConfiguration() {
      @Override
      public boolean incremental() {
        return incremental;
      }
      
      @Override
      public boolean shouldWarnOnNoSuchType() {
        return true;
      }
      
      @Override
      public boolean developerModeChecks() {
        return checked;
      }
    };
  }

  private final ThreadSafeArtifacts artifactCache;
  
  private final LibrarySource runtimeLibrary;
  
  private final boolean useCheckedMode;
  
  private CompileService(ThreadSafeArtifacts artifactCache, LibrarySource runtimeLibrary,
      boolean useCheckedMode) {
    this.artifactCache = artifactCache;
    this.runtimeLibrary = runtimeLibrary;
    this.useCheckedMode = useCheckedMode;
  }

  public CompileResult build(File appFile) {
    return build(new UrlLibrarySource(appFile));
  }

  /**
   * Compiles a Dart app comprised of source code and a declared entryPoint.
   * 
   * NOTE: This method is intended to be thread-safe. All mutable state will
   * be thread local. Only the artifactCache is shared and it is intentionally
   * immutable. 
   */
  public CompileResult build(String source) {
    // Create the libary for the app.
    final LibraryFromSources app = new LibraryFromSources(FAKE_NAME, runtimeLibrary);
    app.addSource(new SourceFromString(app, FAKE_NAME + ".dart", source));
    return build(app);
  }

  static URI uriFor(String relPath) {
    try {
      return new URI(null, relPath, null);
    } catch (URISyntaxException e) {
      throw new RuntimeException(e);
    }
  }
  
  private CompileResult build(LibrarySource source) {
    final Listener listener = new Listener();
    final Artifacts artifacts = new Artifacts(artifactCache);
    
    final long startedAt = System.currentTimeMillis();
    try {
      DartCompiler.compileLib(source,
          config(true, useCheckedMode),
          artifacts,
          listener);
      return new CompileResult(artifacts.getJavaScriptFor(source),
          listener.fatalErrors,
          listener.typeErrors,
          listener.warnings,
          System.currentTimeMillis() - startedAt);
    } catch (Throwable e) {
      return new CompileResult(listener.fatalErrors,
          listener.typeErrors,
          listener.warnings,
          e,
          System.currentTimeMillis() - startedAt);
    }
  }
}
