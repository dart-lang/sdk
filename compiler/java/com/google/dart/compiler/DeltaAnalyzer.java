// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.common.io.CharStreams;
import com.google.common.io.Closeables;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryNode;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.metrics.CompilerMetrics;
import com.google.dart.compiler.parser.DartParser;
import com.google.dart.compiler.parser.DartScannerParserContext;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.resolver.CoreTypeProviderImplementation;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.LibraryElement;
import com.google.dart.compiler.resolver.MemberBuilder;
import com.google.dart.compiler.resolver.Resolver;
import com.google.dart.compiler.resolver.Scope;
import com.google.dart.compiler.resolver.SupertypeResolver;
import com.google.dart.compiler.resolver.TopLevelElementBuilder;
import com.google.dart.compiler.type.TypeAnalyzer;

import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.net.URI;

class DeltaAnalyzer {
  private final SourceDelta delta;
  private final LibraryElement enclosingLibrary;
  private final CompilerConfiguration config;
  private final DartCompilerListener listener;
  private final CoreTypeProvider typeProvider;
  private final DartCompilerContext context;

  public DeltaAnalyzer(SourceDelta delta,
                       LibraryElement enclosingLibrary,
                       LibraryElement coreLibrary,
                       DartNode interestNode,
                       int interestStart,
                       int interestLength,
                       CompilerConfiguration config,
                       DartCompilerListener listener) {
    this.delta = delta;
    this.enclosingLibrary = enclosingLibrary;
    this.config = config;
    this.listener = listener;
    typeProvider = new CoreTypeProviderImplementation(coreLibrary.getScope(), listener);
    this.context = new Context();
  }

  public DartNode analyze() throws IOException {
    Source originalSource = delta.getSourceBefore();
    DartUnit unit = delta.getUnitAfter();
    if (unit == null) {
      DartSource source = delta.getSourceAfter();
      unit = getParser(source).parseUnit(source);
    }
    Scope scope = deltaLibraryScope(originalSource, unit);
    // We have to create supertypes and member elements for the entire unit. For example, if you're
    // doing code-completion, you are only interested in the current expression, but you may be
    // code-completing on a type that is defined outside the current class.
    new SupertypeResolver().exec(unit, context, typeProvider);
    new MemberBuilder().exec(unit, context, typeProvider);

    // The following two phases can be narrowed down to the interest area. We currently ignore the
    // interest area, but long term, we will need to narrow down to the interest area to handle
    // very large files.
    new Resolver(context, scope, typeProvider).exec(unit);
    new TypeAnalyzer().exec(unit, context, typeProvider);
    return unit;
  }

  private Scope deltaLibraryScope(Source originalSource, DartUnit unit) {
    // Create a library unit which holds the new unit.
    LibraryUnit libraryUnit = new LibraryUnit(makeLibrarySource("delta"));
    // Copy all the imports
    for (LibraryNode path : enclosingLibrary.getLibraryUnit().getImportPaths()) {
      libraryUnit.addImportPath(path);
    }
    for (LibraryUnit importUnit : enclosingLibrary.getLibraryUnit().getImportedLibraries()) {
      libraryUnit.addImport(importUnit, importUnit.getEntryNode());
    }
    libraryUnit.putUnit(unit);

    // Create top-level elements for the new unit.
    new TopLevelElementBuilder().exec(libraryUnit, context);
    new TopLevelElementBuilder().fillInLibraryScope(libraryUnit, listener);

    // Copy all the elements from the old library, except the ones declared in the original source.
    Scope scope = libraryUnit.getElement().getScope();
    for (Element member : enclosingLibrary.getMembers()) {
      if (member.getSourceInfo().getSource() != originalSource) {
        scope.declareElement(member.getName(), member);
      }
    }
    return scope;
  }

  private LibrarySource makeLibrarySource(final String name) {
    final URI uri = URI.create(name);
    return new LibrarySource() {
      @Override
      public String getUniqueIdentifier() {
        return uri.toString();
      }

      @Override
      public URI getUri() {
        return uri;
      }

      @Override
      public Reader getSourceReader() {
        throw new AssertionError();
      }

      @Override
      public String getName() {
        return name;
      }

      @Override
      public long getLastModified() {
        throw new AssertionError();
      }

      @Override
      public boolean exists() {
        throw new AssertionError();
      }

      @Override
      public DartSource getSourceFor(String relPath) {
        return null;
      }

      @Override
      public LibrarySource getImportFor(String relPath) {
        return null;
      }
    };
  }

  private DartParser getParser(Source source) throws IOException {
    Reader r = source.getSourceReader();
    String sourceString = CharStreams.toString(r);
    Closeables.close(r, false);
    return new DartParser(new DartScannerParserContext(source, sourceString, listener), false);
  }

  private class Context implements DartCompilerListener, DartCompilerContext {
    @Override
    public LibraryUnit getApplicationUnit() {
      throw new AssertionError();
    }

    @Override
    public LibraryUnit getAppLibraryUnit() {
      throw new AssertionError();
    }

    @Override
    public LibraryUnit getLibraryUnit(LibrarySource lib) {
      throw new AssertionError();
    }

    @Override
    public Reader getArtifactReader(Source source, String part, String extension) {
      throw new AssertionError();
    }

    @Override
    public URI getArtifactUri(DartSource source, String part, String extension) {
      throw new AssertionError();
    }

    @Override
    public Writer getArtifactWriter(Source source, String part, String extension) {
      throw new AssertionError();
    }

    @Override
    public boolean isOutOfDate(Source source, Source base, String extension) {
      throw new AssertionError();
    }

    @Override
    public CompilerMetrics getCompilerMetrics() {
      return null;
    }

    @Override
    public CompilerConfiguration getCompilerConfiguration() {
      return config;
    }

    @Override
    public LibrarySource getSystemLibraryFor(String importSpec) {
      throw new AssertionError();
    }

    @Override
    public void onError(DartCompilationError event) {
      listener.onError(event);
    }

    @Override
    public void unitAboutToCompile(DartSource source, boolean diet) {
    }

    @Override
    public void unitCompiled(DartUnit unit) {
    }
  }
}
