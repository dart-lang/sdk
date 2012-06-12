// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.common.collect.Sets;
import com.google.common.collect.Sets.SetView;
import com.google.common.io.CharStreams;
import com.google.common.io.Closeables;
import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.LibraryDeps.Dependency;
import com.google.dart.compiler.UnitTestBatchRunner.Invocation;
import com.google.dart.compiler.ast.DartDirective;
import com.google.dart.compiler.ast.DartLibraryDirective;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartToSourceVisitor;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryNode;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.metrics.CompilerMetrics;
import com.google.dart.compiler.metrics.DartEventType;
import com.google.dart.compiler.metrics.JvmMetrics;
import com.google.dart.compiler.metrics.Tracer;
import com.google.dart.compiler.metrics.Tracer.TraceEvent;
import com.google.dart.compiler.parser.DartParser;
import com.google.dart.compiler.parser.DartScannerParserContext;
import com.google.dart.compiler.resolver.CompileTimeConstantResolver;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.resolver.CoreTypeProviderImplementation;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.Elements;
import com.google.dart.compiler.resolver.LibraryElement;
import com.google.dart.compiler.resolver.MemberBuilder;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.resolver.Resolver;
import com.google.dart.compiler.resolver.ResolverErrorCode;
import com.google.dart.compiler.resolver.SupertypeResolver;
import com.google.dart.compiler.resolver.TopLevelElementBuilder;
import com.google.dart.compiler.type.TypeAnalyzer;
import com.google.dart.compiler.util.DefaultTextOutput;

import org.kohsuke.args4j.CmdLineException;
import org.kohsuke.args4j.CmdLineParser;

import java.io.File;
import java.io.IOException;
import java.io.PrintStream;
import java.io.Reader;
import java.io.Writer;
import java.net.URI;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

/**
 * Entry point for the Dart compiler.
 */
public class DartCompiler {

  public static final String EXTENSION_DEPS = "deps";
  public static final String EXTENSION_LOG = "log";
  public static final String EXTENSION_TIMESTAMP = "timestamp";

  public static final String CORELIB_URL_SPEC = "dart:core";
  public static final String MAIN_ENTRY_POINT_NAME = "main";

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
    public String getUniqueIdentifier() {
      throw new AssertionError();
    }

    @Override
    public URI getUri() {
      throw new AssertionError();
    }

    @Override
    public LibrarySource getImportFor(String relPath) {
      return null;
    }

    @Override
    public DartSource getSourceFor(String relPath) {
      return null;
    }
  }

  private static class Compiler {
    private final LibrarySource app;
    private final List<LibrarySource> embeddedLibraries = new ArrayList<LibrarySource>();
    private final DartCompilerMainContext context;
    private final CompilerConfiguration config;
    private final Map<URI, LibraryUnit> libraries = new LinkedHashMap<URI, LibraryUnit>();
    private CoreTypeProvider typeProvider;
    private final boolean incremental;
    private final List<DartCompilationPhase> phases;
    private final LibrarySource coreLibrarySource;

    private Compiler(LibrarySource app, List<LibrarySource> embedded, CompilerConfiguration config,
        DartCompilerMainContext context) {
      this.app = app;
      this.config = config;
      this.phases = config.getPhases();
      this.context = context;
      for (LibrarySource library : embedded) {
        if (SystemLibraryManager.isDartSpec(library.getName())) {
          LibrarySource foundLibrary = context.getSystemLibraryFor(library.getName());
          assert(foundLibrary != null);
          embeddedLibraries.add(foundLibrary);
        } else {
          embeddedLibraries.add(library);
        }
      }
      coreLibrarySource = context.getSystemLibraryFor(CORELIB_URL_SPEC);
      assert(coreLibrarySource != null);
      embeddedLibraries.add(coreLibrarySource);

      incremental = config.incremental();
    }

    void addResolvedLibraries(Map<URI, LibraryUnit> resolvedLibraries) {
      libraries.putAll(resolvedLibraries);
    }

    Map<URI, LibraryUnit> getLibraries() {
      return libraries;
    }

    private void compile() {
      TraceEvent logEvent = Tracer.canTrace() ? Tracer.start(DartEventType.COMPILE) : null;
      try {
        updateAndResolve();
        if (!config.resolveDespiteParseErrors() && context.getErrorCount() > 0) {
          return;
        }
        compileLibraries();
      } catch (IOException e) {
        context.onError(new DartCompilationError(app, DartCompilerErrorCode.IO, e.getMessage()));
      } finally {
        Tracer.end(logEvent);
      }
    }

    /**
     * Update the current application and any referenced libraries and resolve
     * them.
     *
     * @return a {@link LibraryUnit}, maybe <code>null</code>
     * @throws IOException on IO errors - the caller must log this if it cares
     */
    private LibraryUnit updateAndResolve() throws IOException {
      TraceEvent logEvent = Tracer.canTrace() ? Tracer.start(DartEventType.UPDATE_RESOLVE) : null;

      CompilerMetrics compilerMetrics = context.getCompilerMetrics();
      if (compilerMetrics != null) {
        compilerMetrics.startUpdateAndResolveTime();
      }

      try {
        LibraryUnit library = updateLibraries(app);
        importEmbeddedLibraries();
        parseOutOfDateFiles();
        if (incremental) {
          addOutOfDateDeps();
        }
        if (!config.resolveDespiteParseErrors() && (context.getErrorCount() > 0)) {
          return library;
        }
        buildLibraryScopes();
        LibraryUnit corelibUnit = updateLibraries(coreLibrarySource);
        typeProvider = new CoreTypeProviderImplementation(corelibUnit.getElement().getScope(),
                                                          context);
        resolveLibraries();
        validateLibraryDirectives();
        return library;
      } finally {
        if(compilerMetrics != null) {
          compilerMetrics.endUpdateAndResolveTime();
        }

        Tracer.end(logEvent);
      }
    }

    /**
     * This method reads all libraries. They will be populated from some combination of fully-parsed
     * and diet-parser compilation units.
     */
    private void parseOutOfDateFiles() throws IOException {
      TraceEvent logEvent =
          Tracer.canTrace() ? Tracer.start(DartEventType.PARSE_OUTOFDATE) : null;
      CompilerMetrics compilerMetrics = context.getCompilerMetrics();
      long parseStart = compilerMetrics != null ? CompilerMetrics.getCPUTime() : 0;

      try {
        final Set<String> topLevelSymbolsDiff = Sets.newHashSet();
        for (LibraryUnit lib : getLibrariesToProcess()) {
          LibrarySource libSrc = lib.getSource();
          LibraryNode selfSourcePath = lib.getSelfSourcePath();

          // Load the existing DEPS, or create an empty one.
          LibraryDeps deps = lib.getDeps(context);
          Set<String> newUnitPaths = Sets.newHashSet();

          // Parse each compilation unit.
          for (LibraryNode sourcePathNode : lib.getSourcePaths()) {
            String relPath = sourcePathNode.getText();
            newUnitPaths.add(relPath);

            // Prepare DartSource for "#source" unit.
            final DartSource dartSrc = libSrc.getSourceFor(relPath);
            if (dartSrc == null || !dartSrc.exists()) {
              continue;
            }

            if (!incremental
                || SystemLibraryManager.isDartUri(libSrc.getUri())
                || isSourceOutOfDate(dartSrc)) {
              DartUnit unit = parse(dartSrc, lib.getPrefixes(),  false);
              // If we just parsed unit of library, report problems.
              if (sourcePathNode == selfSourcePath) {
                // report "#import" problems
                for (LibraryNode importPathNode : lib.getImportPaths()) {
                  LibrarySource dep = getImportSource(libSrc, importPathNode);
                  if (dep == null) {
                    reportMissingSource(context, libSrc, importPathNode);
                  }
                }
                // report "#source" problems
                for (LibraryNode checkSourcePathNode : lib.getSourcePaths()) {
                  String checkRelPath = checkSourcePathNode.getText();
                  final DartSource checkSource = libSrc.getSourceFor(checkRelPath);
                  if (checkSource == null || !checkSource.exists()) {
                    reportMissingSource(context, libSrc, checkSourcePathNode);
                  }
                }
              }

              // Process unit, if exists.
              if (unit != null) {
                if (sourcePathNode == selfSourcePath) {
                  lib.setSelfDartUnit(unit);
                }
                // Replace unit within the library.
                lib.putUnit(unit);
                context.setFilesHaveChanged();
                // Include into top-level symbols diff from current units, already existed or new.
                {
                  LibraryDeps.Source source = deps.getSource(relPath);
                  Set<String> newTopSymbols = unit.getTopDeclarationNames();
                  if (source != null) {
                    Set<String> oldTopSymbols = source.getTopSymbols();
                    SetView<String> diff0 = Sets.symmetricDifference(oldTopSymbols, newTopSymbols);
                    topLevelSymbolsDiff.addAll(diff0);
                  } else {
                    topLevelSymbolsDiff.addAll(newTopSymbols);
                  }
                }
              }
            } else {
              DartUnit dietUnit = parse(dartSrc, lib.getPrefixes(), true);
              if (dietUnit != null) {
                if (sourcePathNode == selfSourcePath) {
                  lib.setSelfDartUnit(dietUnit);
                }
                lib.putUnit(dietUnit);
              }
            }
          }

          // Include into top-level symbols diff from units which disappeared since last compiling.
          {
            Set<String> oldUnitPaths = deps.getUnitPaths();
            Set<String> disappearedUnitPaths = Sets.difference(oldUnitPaths, newUnitPaths);
            for (String relPath : disappearedUnitPaths) {
              LibraryDeps.Source source = deps.getSource(relPath);
              if (source != null) {
                Set<String> oldTopSymbols = source.getTopSymbols();
                topLevelSymbolsDiff.addAll(oldTopSymbols);
              }
            }
          }
        }

        // Parse units, which potentially depend on the difference in top-level symbols.
        if (!topLevelSymbolsDiff.isEmpty()) {
          context.setFilesHaveChanged();
          for (LibraryUnit lib : getLibrariesToProcess()) {
            LibrarySource libSrc = lib.getSource();
            LibraryNode selfSourcePath = lib.getSelfSourcePath();
            LibraryDeps deps = lib.getDeps(context);
            for (LibraryNode libNode : lib.getSourcePaths()) {
              String relPath = libNode.getText();
              // Prepare source dependency.
              LibraryDeps.Source source = deps.getSource(relPath);
              if (source == null) {
                continue;
              }
              // Check re-compilation conditions.
              if (source.shouldRecompileOnAnyTopLevelChange()
                  || !Sets.intersection(source.getAllSymbols(), topLevelSymbolsDiff).isEmpty()
                  || !Sets.intersection(source.getHoles(), topLevelSymbolsDiff).isEmpty()) {
                DartSource dartSrc = libSrc.getSourceFor(relPath);
                if (dartSrc == null || !dartSrc.exists()) {
                  continue;
                }
                DartUnit unit = parse(dartSrc, lib.getPrefixes(), false);
                if (unit != null) {
                  if (libNode == selfSourcePath) {
                    lib.setSelfDartUnit(unit);
                  } else {
                    lib.putUnit(unit);
                  }
                }
              }
            }
          }
        }
      } finally {
        if (compilerMetrics != null) {
          compilerMetrics.addParseWallTimeNano(CompilerMetrics.getCPUTime() - parseStart);
        }
        Tracer.end(logEvent);
      }
    }

    Collection<LibraryUnit> getLibrariesToProcess() {
      return libraries.values();
    }

    /**
     * This method reads the embedded library sources, making sure they are added
     * to the list of libraries to compile. It then adds the libraries as imports
     * of all libraries. The import is without prefix.
     */
    private void importEmbeddedLibraries() throws IOException {
      TraceEvent importEvent =
          Tracer.canTrace() ? Tracer.start(DartEventType.IMPORT_EMBEDDED_LIBRARIES) : null;
      try {
        for (LibrarySource embedded : embeddedLibraries) {
          updateLibraries(embedded);
        }

        for (LibraryUnit lib : getLibrariesToProcess()) {
          for (LibrarySource embedded : embeddedLibraries) {
            LibraryUnit imp = libraries.get(embedded.getUri());
            // Check that the current library is not the embedded library, and
            // that the current library does not already import the embedded
            // library.
            if (lib != imp && !lib.hasImport(imp)) {
              lib.addImport(imp, null);
            }
          }
        }
      } finally {
        Tracer.end(importEvent);
      }
    }

    /**
     * This method reads a library source and sets it up with its imports. When it
     * completes, it is guaranteed that {@link Compiler#libraries} will be completely populated.
     */
    private LibraryUnit updateLibraries(LibrarySource libSrc) throws IOException {
      TraceEvent updateEvent =
          Tracer.canTrace() ? Tracer.start(DartEventType.UPDATE_LIBRARIES, "name",
              libSrc.getName()) : null;
      try {
        // Avoid cycles.
        LibraryUnit lib = libraries.get(libSrc.getUri());
        if (lib != null) {
          return lib;
        }

        lib = context.getLibraryUnit(libSrc);
        // If we could not find the library, continue. The context will report
        // the error at the end.
        if (lib == null) {
          return null;
        }

        libraries.put(libSrc.getUri(), lib);

        // Update dependencies.
        for (LibraryNode libNode : lib.getImportPaths()) {
          LibrarySource dep = getImportSource(libSrc, libNode);
          if (dep != null) {
            lib.addImport(updateLibraries(dep), libNode);
          }
        }
        return lib;
      } finally {
        Tracer.end(updateEvent);
      }
    }

    /**
     * @return the {@link LibrarySource} referenced in the "#import" from "libSrc". May be
     *         <code>null</code> if invalid URI or not existing library.
     */
    private LibrarySource getImportSource(LibrarySource libSrc, LibraryNode libNode)
        throws IOException {
      String libSpec = libNode.getText();
      LibrarySource dep;
      if (SystemLibraryManager.isDartSpec(libSpec)) {
        dep = context.getSystemLibraryFor(libSpec);
      } else {
        dep = libSrc.getImportFor(libSpec);
      }
      if (dep == null || !dep.exists()) {
        return null;
      }
      return dep;
    }

    /**
     * Determines whether the given source is out-of-date with respect to its artifacts.
     */
    private boolean isSourceOutOfDate(DartSource dartSrc) {
      TraceEvent logEvent =
          Tracer.canTrace() ? Tracer.start(DartEventType.IS_SOURCE_OUTOFDATE, "src",
              dartSrc.getName()) : null;

      try {
        // If incremental compilation is disabled, just return true to force all
        // units to be recompiled.
        if (!incremental) {
          return true;
        }

        TraceEvent timestampEvent =
            Tracer.canTrace() ? Tracer.start(
                DartEventType.TIMESTAMP_OUTOFDATE,
                "src",
                dartSrc.getName()) : null;
        try {
          return context.isOutOfDate(dartSrc, dartSrc, EXTENSION_TIMESTAMP);
        } finally {
          Tracer.end(timestampEvent);
        }
      } finally {
        Tracer.end(logEvent);
      }
    }

    /**
     * Build scopes for the given libraries.
     */
    private void buildLibraryScopes() {
      TraceEvent logEvent =
          Tracer.canTrace() ? Tracer.start(DartEventType.BUILD_LIB_SCOPES) : null;
      try {
        Collection<LibraryUnit> libs = getLibrariesToProcess();

        // Build the class elements declared in the sources of a library.
        // Loop can be parallelized.
        for (LibraryUnit lib : libs) {
          new TopLevelElementBuilder().exec(lib, context);
        }

        // The library scope can then be constructed, containing types declared
        // in the library, and types declared in the imports. Loop can be parallelized.
        for (LibraryUnit lib : libs) {
          new TopLevelElementBuilder().fillInLibraryScope(lib, context);
        }
      } finally {
        Tracer.end(logEvent);
      }
    }

    /**
     * Parses compilation units that are out-of-date with respect to their dependencies.
     */
    private void addOutOfDateDeps() throws IOException {
      TraceEvent logEvent = Tracer.canTrace() ? Tracer.start(DartEventType.ADD_OUTOFDATE) : null;
      try {
        boolean filesHaveChanged = false;
        for (LibraryUnit lib : getLibrariesToProcess()) {

          // Load the existing DEPS, or create an empty one.
          LibraryDeps deps = lib.getDeps(context);

          // Prepare all top-level symbols.
          Set<String> oldTopLevelSymbols = Sets.newHashSet();
          for (LibraryDeps.Source source : deps.getSources()) {
            oldTopLevelSymbols.addAll(source.getTopSymbols());
          }

          // Parse units that are out-of-date with respect to their dependencies.
          for (DartUnit unit : lib.getUnits()) {
            if (unit.isDiet()) {
              String relPath = ((DartSource) unit.getSourceInfo().getSource()).getRelativePath();
              LibraryDeps.Source source = deps.getSource(relPath);
              if (isUnitOutOfDate(lib, source)) {
                filesHaveChanged = true;
                DartSource dartSrc = lib.getSource().getSourceFor(relPath);
                if (dartSrc != null && dartSrc.exists()) {
                  unit = parse(dartSrc, lib.getPrefixes(), false);
                  if (unit != null) {
                    lib.putUnit(unit);
                  }
                }
              }
            }
          }
        }

        if (filesHaveChanged) {
          context.setFilesHaveChanged();
        }
      } finally {
        Tracer.end(logEvent);
      }
    }

    /**
     * Determines whether the given dependencies are out-of-date.
     */
    private boolean isUnitOutOfDate(LibraryUnit lib, LibraryDeps.Source source) {
      // If we don't have dependency information, then we can not be sure that nothing changed.
      if (source == null) {
        return true;
      }
      // Check all dependencies.
      for (Dependency dep : source.getDeps()) {
        LibraryUnit depLib = libraries.get(dep.getLibUri());
        if (depLib == null) {
          return true;
        }
        // Prepare unit.
        DartUnit depUnit = depLib.getUnit(dep.getUnitName());
        if (depUnit == null) {
          return true;
        }
        // May be unit modified.
        if (depUnit.getSourceInfo().getSource().getLastModified() != dep.getLastModified()) {
          return true;
        }
      }
      // No changed dependencies.
      return false;
    }

    /**
     * Resolve all libraries. Assume that all library scopes are already built.
     */
    private void resolveLibraries() {
      TraceEvent logEvent =
          Tracer.canTrace() ? Tracer.start(DartEventType.RESOLVE_LIBRARIES) : null;
      try {
        // TODO(jgw): Optimization: Skip work for libraries that have nothing to
        // compile.

        // Resolve super class chain, and build the member elements. Both passes
        // need the library scope to be setup. Each for loop can be
        // parallelized.
        for (LibraryUnit lib : getLibrariesToProcess()) {
          for (DartUnit unit : lib.getUnits()) {
            // These two method calls can be parallelized.
            new SupertypeResolver().exec(unit, context, getTypeProvider());
            new MemberBuilder().exec(unit, context, getTypeProvider());
          }
        }

        // Perform resolution on compile-time constant expressions.
        for (LibraryUnit lib : getLibrariesToProcess()) {
          for (DartUnit unit : lib.getUnits()) {
            new CompileTimeConstantResolver().exec(unit, context, getTypeProvider());
          }
        }
      } finally {
        Tracer.end(logEvent);
      }
    }

    private void validateLibraryDirectives() {
      for (LibraryUnit lib : getLibrariesToProcess()) {
        // don't need to validate system libraries
        if (SystemLibraryManager.isDartUri(lib.getSource().getUri())) {
          continue;
        }
        
        // check for #source uniqueness
        {
          Set<URI> includedSourceUris = Sets.newHashSet();
          for (LibraryNode sourceNode : lib.getSourcePaths()) {
            String path = sourceNode.getText();
            URI uri = lib.getSource().getSourceFor(path).getUri();
            if (includedSourceUris.contains(uri)) {
              context.onError(new DartCompilationError(sourceNode.getSourceInfo(),
                  DartCompilerErrorCode.UNIT_WAS_ALREADY_INCLUDED, uri));
            }
            includedSourceUris.add(uri);
          }
        }

        // Validate import prefixes.
        for (LibraryNode importNode : lib.getImportPaths()) {
          String prefix = importNode.getPrefix();
          if (DartParser.PSEUDO_KEYWORDS_SET.contains(prefix)) {
            context.onError(new DartCompilationError(importNode.getSourceInfo(),
                ResolverErrorCode.BUILT_IN_IDENTIFIER_AS_IMPORT_PREFIX, prefix));
          }
        }

        // check that each imported library has a library directive
        for (LibraryUnit importedLib : lib.getImports()) {

          if (SystemLibraryManager.isDartUri(importedLib.getSource().getUri())) {
            // system libraries are always valid
            continue;
          }

          // get the dart unit corresponding to this library
          DartUnit unit = importedLib.getSelfDartUnit();
          if (unit.isDiet()) {
            // don't need to check a unit that hasn't changed
            continue;
          }

          boolean foundLibraryDirective = false;
          for (DartDirective directive : unit.getDirectives()) {
            if (directive instanceof DartLibraryDirective) {
              foundLibraryDirective = true;
              break;
            }
          }
          if (!foundLibraryDirective) {
            // find the imported path node (which corresponds to the import directive node)
            SourceInfo info = null;
            for (LibraryNode importPath : lib.getImportPaths()) {
              if (importPath.getText().equals(importedLib.getSelfSourcePath().getText())) {
                info = importPath.getSourceInfo();
                break;
              }
            }
            if (info != null) {
              context.onError(new DartCompilationError(info,
                  DartCompilerErrorCode.MISSING_LIBRARY_DIRECTIVE,
                  ((DartSource) unit.getSourceInfo().getSource()).getRelativePath()));
            }
          }
        }

        // check that all sourced units have no directives
        for (DartUnit unit : lib.getUnits()) {
          if (unit.isDiet()) {
            // don't need to check a unit that hasn't changed
            continue;
          }
          if (unit.getDirectives().size() > 0) {
            // find corresponding source node for this unit
            for (LibraryNode sourceNode : lib.getSourcePaths()) {
              if (sourceNode == lib.getSelfSourcePath()) {
                // skip the special synthetic selfSourcePath node
                continue;
              }
              DartSource dartSource = (DartSource) unit.getSourceInfo().getSource();
              // check for directives
              if (dartSource.getRelativePath().equals(sourceNode.getText())) {
                context.onError(new DartCompilationError(unit.getDirectives().get(0),
                    DartCompilerErrorCode.ILLEGAL_DIRECTIVES_IN_SOURCED_UNIT,
                    Elements.getRelativeSourcePath(dartSource, lib.getSource())));
              }
            }
          }
        }
      }
    }

    private void setEntryPoint() {
      LibraryUnit lib = context.getAppLibraryUnit();
      lib.setEntryNode(new LibraryNode(MAIN_ENTRY_POINT_NAME));
      // this ensures that if we find it, it's a top-level static element
      Element element = lib.getElement().lookupLocalElement(MAIN_ENTRY_POINT_NAME);
      switch (ElementKind.of(element)) {
        case NONE:
          // this is ok, it might just be a library
          break;

        case METHOD:
          MethodElement methodElement = (MethodElement) element;
          Modifiers modifiers = methodElement.getModifiers();
          if (modifiers.isGetter()) {
            context.onError(new DartCompilationError(element,
                DartCompilerErrorCode.ENTRY_POINT_METHOD_MAY_NOT_BE_GETTER, MAIN_ENTRY_POINT_NAME));
          } else if (modifiers.isSetter()) {
            context.onError(new DartCompilationError(element,
                DartCompilerErrorCode.ENTRY_POINT_METHOD_MAY_NOT_BE_SETTER, MAIN_ENTRY_POINT_NAME));
          } else if (methodElement.getParameters().size() > 0) {
            context.onError(new DartCompilationError(element,
                DartCompilerErrorCode.ENTRY_POINT_METHOD_CANNOT_HAVE_PARAMETERS,
                MAIN_ENTRY_POINT_NAME));
          } else {
            lib.getElement().setEntryPoint(methodElement);
          }
          break;

        default:
          context.onError(new DartCompilationError(element,
              ResolverErrorCode.NOT_A_STATIC_METHOD, MAIN_ENTRY_POINT_NAME));
          break;
      }
    }

    private void compileLibraries() throws IOException {
      TraceEvent logEvent =
          Tracer.canTrace() ? Tracer.start(DartEventType.COMPILE_LIBRARIES) : null;

      CompilerMetrics compilerMetrics = context.getCompilerMetrics();
      if (compilerMetrics != null) {
        compilerMetrics.startCompileLibrariesTime();
      }

      try {
        // Set entry point
        setEntryPoint();

        // The two following for loops can be parallelized.
        for (LibraryUnit lib : getLibrariesToProcess()) {
          boolean persist = false;

          // Compile all the units in this library.
          for (DartUnit unit : lib.getUnits()) {

            // Don't compile diet units.
            if (unit.isDiet()) {
              continue;
            }

            updateAnalysisTimestamp(unit);

            // Run all compiler phases including AST simplification and symbol
            // resolution. This must run in serial.
            for (DartCompilationPhase phase : phases) {
              TraceEvent phaseEvent =
                  Tracer.canTrace() ? Tracer.start(DartEventType.EXEC_PHASE, "phase", phase
                      .getClass().getCanonicalName(), "lib", lib.getName(), "unit", unit
                      .getSourceName()) : null;
              try {
                unit = phase.exec(unit, context, getTypeProvider());
              } finally {
                Tracer.end(phaseEvent);
              }
              if (!config.resolveDespiteParseErrors() && context.getErrorCount() > 0) {
                return;
              }
            }

            // To help support the IDE, notify the listener that this unit is compiled.
            context.unitCompiled(unit);

            // Update deps.
            lib.getDeps(context).update(context, unit);

            // We analyzed something, so we need to persist the deps.
            persist = true;
          }

          // Persist the DEPS file.
          if (persist) {
            lib.writeDeps(context);
          }
        }
      } finally {
        if (compilerMetrics != null) {
          compilerMetrics.endCompileLibrariesTime();
        }
        Tracer.end(logEvent);
      }
    }

    private void updateAnalysisTimestamp(DartUnit unit) throws IOException {
      // Update timestamp.
      Writer writer =
          context.getArtifactWriter(unit.getSourceInfo().getSource(), "", EXTENSION_TIMESTAMP);
      String timestampData = String.format("%d\n", System.currentTimeMillis());
      writer.write(timestampData);
      writer.close();
    }

    DartUnit parse(DartSource dartSrc, Set<String> libraryPrefixes, boolean diet) throws IOException {
      TraceEvent parseEvent =
          Tracer.canTrace() ? Tracer.start(DartEventType.PARSE, "src", dartSrc.getName()) : null;
      CompilerMetrics compilerMetrics = context.getCompilerMetrics();
      long parseStart = compilerMetrics != null ? CompilerMetrics.getThreadTime() : 0;
      Reader r = dartSrc.getSourceReader();
      String srcCode;
      boolean failed = true;
      try {
        try {
          srcCode = CharStreams.toString(r);
          failed = false;
        } finally {
          Closeables.close(r, failed);
        }
        
        // auto-magically define "assert" function
        if (dartSrc.getUri().toString().equals("dart://core/runtime/object.dart")) {
          srcCode += "\nvoid assert(x) {}";
        }

        DartScannerParserContext parserContext =
            new DartScannerParserContext(dartSrc, srcCode, context, context.getCompilerMetrics());
        DartParser parser = new DartParser(parserContext, libraryPrefixes, diet);
        DartUnit unit = parser.parseUnit(dartSrc);
        if (compilerMetrics != null) {
          compilerMetrics.addParseTimeNano(CompilerMetrics.getThreadTime() - parseStart);
        }

        if (!config.resolveDespiteParseErrors() && context.getErrorCount() > 0) {
          // We don't return this unit, so no more processing expected for it.
          context.unitCompiled(unit);
          return null;
        }
        return unit;
      } finally {
        Tracer.end(parseEvent);
      }
    }

    private void reportMissingSource(DartCompilerContext context,
                                     LibrarySource libSrc,
                                     LibraryNode libNode) {
      DartCompilationError event = new DartCompilationError(libNode,
                                                            DartCompilerErrorCode.MISSING_SOURCE,
                                                            libNode.getText());
      event.setSource(libSrc);
      context.onError(event);
    }
    CoreTypeProvider getTypeProvider() {
      typeProvider.getClass(); // Quick null check.
      return typeProvider;
    }
  }

  /**
   * Selectively compile a library. Use supplied libraries and ASTs when available.
   * This allows programming tools to provide customized ASTs for code that is currently being
   * edited, and may not compile correctly.
   */
  private static class SelectiveCompiler extends Compiler {
    /** Map from source URI to AST representing the source */
    private final Map<URI, LibraryUnit> resolvedLibraries;
    private final Map<URI,DartUnit> parsedUnits;
    private Collection<LibraryUnit> librariesToProcess;
    private final SystemLibraryManager libraryManager;

    private SelectiveCompiler(LibrarySource app, Map<URI, LibraryUnit> resolvedLibraries,
        Map<URI,DartUnit> parsedUnits, CompilerConfiguration config,
        DartCompilerMainContext context, SystemLibraryManager libraryManager) {
      super(app, Collections.<LibrarySource>emptyList(), config, context);
      this.resolvedLibraries = resolvedLibraries;
      this.parsedUnits = parsedUnits;
      this.libraryManager = libraryManager;
      addResolvedLibraries(resolvedLibraries);
    }

    @Override
    Collection<LibraryUnit> getLibrariesToProcess() {
      if (librariesToProcess == null) {
        librariesToProcess = new ArrayList<LibraryUnit>();
        librariesToProcess.addAll(super.getLibrariesToProcess());
        librariesToProcess.removeAll(resolvedLibraries.values());
      }
      return librariesToProcess;
    }

    @Override
    DartUnit parse(DartSource dartSrc, Set<String> prefixes, boolean diet) throws IOException {
      if (parsedUnits == null) {
        return super.parse(dartSrc, prefixes, diet);
      }
      URI srcUri = dartSrc.getUri();
      // Remove the parsed unit from the map if present
      // so that it will not be consumed a 2nd time if it is sourced by multiple libraries
      DartUnit parsedUnit = parsedUnits.remove(srcUri);
      if (parsedUnit != null) {
        return parsedUnit;
      }
      if (libraryManager != null) {
        URI fileUri = libraryManager.resolveDartUri(srcUri);
        parsedUnit = parsedUnits.remove(fileUri);
        if (parsedUnit != null) {
          return parsedUnit;
        }
      }
      return super.parse(dartSrc, prefixes, diet);
    }
  }

  private static CompilerOptions processCommandLineOptions(String[] args) {
    CmdLineParser cmdLineParser = null;
    CompilerOptions compilerOptions = null;
    try {
      compilerOptions = new CompilerOptions();
      cmdLineParser = CommandLineOptions.parse(args, compilerOptions);
      if (args.length == 0 || compilerOptions.showHelp()) {
        showUsage(cmdLineParser, System.err);
        System.exit(1);
      }
    } catch (CmdLineException e) {
      System.err.println(e.getLocalizedMessage());
      showUsage(cmdLineParser, System.err);
      System.exit(1);
    }

    assert compilerOptions != null;
    return compilerOptions;
  }

  public static void main(final String[] topArgs) {
    Tracer.init();

    CompilerOptions topCompilerOptions = processCommandLineOptions(topArgs);
    boolean result = false;
    try {
      if (topCompilerOptions.shouldBatch()) {
        if (topArgs.length > 1) {
          System.err.println("(Extra arguments specified with -batch ignored.)");
        }
        UnitTestBatchRunner.runAsBatch(topArgs, new Invocation() {
          @Override
          public boolean invoke(String[] lineArgs) throws Throwable {
            List<String> allArgs = new ArrayList<String>();
            for (String arg: topArgs) {
              if (!arg.equals("-batch")) {
                allArgs.add(arg);
              }
            }
            for (String arg: lineArgs) {
              allArgs.add(arg);
            }

            CompilerOptions compilerOptions = processCommandLineOptions(
                allArgs.toArray(new String[allArgs.size()]));
            if (compilerOptions.shouldBatch()) {
              System.err.println("-batch ignored: Already in batch mode.");
            }
            return compilerMain(compilerOptions);
          }
        });
      } else {
        result = compilerMain(topCompilerOptions);
      }
    } catch (Throwable t) {
      t.printStackTrace();
      crash();
    }
    if (!result) {
      System.exit(1);
    }
  }

  /**
   * Invoke the compiler to build single application.
   *
   * @param compilerOptions parsed command line arguments
   *
   * @return <code> true</code> on success, <code>false</code> on failure.
   */
  public static boolean compilerMain(CompilerOptions compilerOptions) throws IOException {
    List<String> sourceFiles = compilerOptions.getSourceFiles();
    if (sourceFiles.size() == 0) {
      System.err.println("dartc: no source files were specified.");
      showUsage(null, System.err);
      return false;
    }

    File sourceFile = new File(sourceFiles.get(0));
    if (!sourceFile.exists()) {
      System.err.println("dartc: file not found: " + sourceFile);
      showUsage(null, System.err);
      return false;
    }

    CompilerConfiguration config = new DefaultCompilerConfiguration(compilerOptions);
    return compilerMain(sourceFile, config);
  }

  /**
   * Invoke the compiler to build single application.
   *
   * @param sourceFile file passed on the command line to build
   * @param config compiler configuration built from parsed command line options
   *
   * @return <code> true</code> on success, <code>false</code> on failure.
   */
  public static boolean compilerMain(File sourceFile, CompilerConfiguration config)
      throws IOException {
    String errorMessage = compileApp(sourceFile, config);
    if (errorMessage != null) {
      System.err.println(errorMessage);
      return false;
    }

    TraceEvent logEvent = Tracer.canTrace() ? Tracer.start(DartEventType.WRITE_METRICS) : null;
    try {
      maybeShowMetrics(config);
    } finally {
      Tracer.end(logEvent);
    }
    return true;
  }

  public static void crash() {
    // Our test scripts look for 253 to signal a "crash".
    System.exit(253);
  }

  private static void showUsage(CmdLineParser cmdLineParser, PrintStream out) {
    out.println("Usage: dartc [<options>] <dart-script> [script-arguments]");
    out.println("Available options:");
    if (cmdLineParser == null) {
      cmdLineParser = new CmdLineParser(new CompilerOptions());
    }
    cmdLineParser.printUsage(out);
  }

  private static void maybeShowMetrics(CompilerConfiguration config) {
    CompilerMetrics compilerMetrics = config.getCompilerMetrics();
    if (compilerMetrics != null) {
      compilerMetrics.write(System.out);
    }

    JvmMetrics.maybeWriteJvmMetrics(System.out, config.getJvmMetricOptions());
  }

  /**
   * Treats the <code>sourceFile</code> as the top level library and generates compiled output by
   * linking the dart source in this file with all libraries referenced with <code>#import</code>
   * statements.
   */
  public static String compileApp(File sourceFile, CompilerConfiguration config) throws IOException {
    TraceEvent logEvent =
        Tracer.canTrace() ? Tracer.start(DartEventType.COMPILE_APP, "src", sourceFile.toString())
            : null;
    try {
      File outputDirectory = config.getOutputDirectory();
      DefaultDartArtifactProvider provider = new DefaultDartArtifactProvider(outputDirectory);
      // Compile the Dart application and its dependencies.
      final LibrarySource lib = new UrlLibrarySource(sourceFile);
      DefaultDartCompilerListener listener;
      if (config.getCompilerOptions().showSourceFromAst()) {
        listener = new DefaultDartCompilerListener(config.printErrorFormat()) {
          @Override
          public void unitCompiled(DartUnit unit) {
            if (unit.getLibrary() != null) {
              if (unit.getLibrary().getSource() == lib) {
                DefaultTextOutput output = new DefaultTextOutput(false);
                unit.accept(new DartToSourceVisitor(output));
                System.out.println(output.toString());
              }
            }
          }
        };
      } else {
        listener = new DefaultDartCompilerListener(config.printErrorFormat());
      }
      String errorString = compileLib(lib, config, provider, listener);
      return errorString;
    } finally {
      Tracer.end(logEvent);
    }
  }

  /**
   * Compiles the given library, translating all its source files, and those
   * of its imported libraries, transitively.
   *
   * @param lib The library to be compiled (not <code>null</code>)
   * @param config The compiler configuration specifying the compilation phases
   * @param provider A mechanism for specifying where code should be generated
   * @param listener An object notified when compilation errors occur
   */
  public static String compileLib(LibrarySource lib, CompilerConfiguration config,
      DartArtifactProvider provider, DartCompilerListener listener) throws IOException {
    return compileLib(lib, Collections.<LibrarySource>emptyList(), config, provider, listener);
  }

  /**
   * Same method as above, but also takes a list of libraries that should be
   * implicitly imported by all libraries. These libraries are provided by the embedder.
   */
  public static String compileLib(LibrarySource lib,
                                  List<LibrarySource> embeddedLibraries,
                                  CompilerConfiguration config,
                                  DartArtifactProvider provider,
                                  DartCompilerListener listener) throws IOException {
    DartCompilerMainContext context = new DartCompilerMainContext(lib, provider, listener,
                                                                  config);
    if (config.getCompilerOptions().shouldExposeCoreImpl()) {
      if (embeddedLibraries == null) {
        embeddedLibraries = Lists.newArrayList();
      }
      // use a place-holder LibrarySource instance, to be replaced when embedded
      // in the compiler, where the dart uri can be resolved.
      embeddedLibraries.add(new NamedPlaceHolderLibrarySource("dart:coreimpl"));
    }

    new Compiler(lib, embeddedLibraries, config, context).compile();
    int errorCount = context.getErrorCount();
    if (config.typeErrorsAreFatal()) {
      errorCount += context.getTypeErrorCount();
    }
    if (config.warningsAreFatal()) {
      errorCount += context.getWarningCount();
    }
    if (errorCount > 0) {
      return "Compilation failed with " + errorCount
          + (errorCount == 1 ? " problem." : " problems.");
    }
    if (!context.getFilesHaveChanged()) {
      return null;
    }
    // Write checking log.
    {
      Writer writer = provider.getArtifactWriter(lib, "", EXTENSION_LOG);
      boolean threw = true;
      try {
        writer.write(String.format("Checked %s and found:%n", lib.getName()));
        writer.write(String.format("  no load/resolution errors%n"));
        writer.write(String.format("  %s type errors%n", context.getTypeErrorCount()));
        threw = false;
      } finally {
        Closeables.close(writer, threw);
      }
    }
    return null;
  }

  /**
   * Analyzes the given library and all its transitive dependencies.
   *
   * @param lib The library to be analyzed
   * @param parsedUnits A collection of unresolved ASTs that should be used
   * instead of parsing the associated source from storage. Intended for
   * IDE use when modified buffers must be analyzed. AST nodes in the map may be
   * ignored if not referenced by {@code lib}. (May be null.)
   * @param config The compiler configuration (phases will not be used), but resolution and
   * type-analysis will be invoked
   * @param provider A mechanism for specifying where code should be generated
   * @param listener An object notified when compilation errors occur
   * @throws NullPointerException if any of the arguments except {@code parsedUnits}
   * are {@code null}
   * @throws IOException on IO errors, which are not logged
   */
  public static LibraryUnit analyzeLibrary(LibrarySource lib, Map<URI, DartUnit> parsedUnits,
      CompilerConfiguration config, DartArtifactProvider provider, DartCompilerListener listener)
      throws IOException {
    HashMap<URI, LibraryUnit> resolvedLibs = new HashMap<URI, LibraryUnit>();
    return analyzeLibraries(lib, resolvedLibs, parsedUnits, config, provider, null, listener, false).get(lib.getUri());
  }

  /**
   * Analyzes the given library and all its transitive dependencies.
   *
   * @param lib The library to be analyzed
   * @param resolvedLibs A collection of library units that should be used
   * instead of parsing and resolving the associated source from storage.
   * @param parsedUnits A collection of unresolved ASTs that should be used
   * instead of parsing the associated source from storage. Intended for
   * IDE use when modified buffers must be analyzed. 
   * Units are removed from this map as they are used. AST nodes in the map may be
   * ignored if not referenced by {@code lib}. (May be null.)
   * @param config The compiler configuration (phases and backends
   * will not be used), but resolution and type-analysis will be
   * invoked
   * @param provider A mechanism for specifying where code should be generated
   * @param libraryManager 
   * @param listener An object notified when compilation errors occur
   * @param resolveAllNewLibs <code>true</code> if all new libraries should be resolved
   * or false if only the library specified by the "lib" parameter should be resolved
   * @throws NullPointerException if any of the arguments except {@code parsedUnits}
   * are {@code null}
   * @throws IOException on IO errors, which are not logged
   */
  public static Map<URI, LibraryUnit> analyzeLibraries(LibrarySource lib,
      Map<URI, LibraryUnit> resolvedLibs, Map<URI, DartUnit> parsedUnits,
      CompilerConfiguration config, DartArtifactProvider provider, SystemLibraryManager libraryManager, 
      DartCompilerListener listener, boolean resolveAllNewLibs) throws IOException {
    lib.getClass(); // Quick null check.
    provider.getClass(); // Quick null check.
    listener.getClass(); // Quick null check.
    resolvedLibs.getClass(); // Quick null check.
    DartCompilerMainContext context = new DartCompilerMainContext(lib, provider, listener, config);
    Compiler compiler = new SelectiveCompiler(lib, resolvedLibs, parsedUnits, config, context, libraryManager);

    LibraryUnit topLibUnit = compiler.updateAndResolve();
    if (topLibUnit == null) {
      return null;
    }

    Map<URI, LibraryUnit> librariesToResolve;
    librariesToResolve = new HashMap<URI, LibraryUnit>();
    if (resolveAllNewLibs) {
      librariesToResolve.putAll(compiler.getLibraries());
    }
    librariesToResolve.put(topLibUnit.getSource().getUri(), topLibUnit);
    
    DartCompilationPhase[] phases = {new Resolver.Phase(), new TypeAnalyzer()};
    Map<URI, LibraryUnit> newLibraries = Maps.newHashMap();
    for (Entry<URI, LibraryUnit> entry : librariesToResolve.entrySet()) {
      URI libUri = entry.getKey();
      LibraryUnit libUnit = entry.getValue();
      if (!resolvedLibs.containsKey(libUri) && libUnit != null) {
        newLibraries.put(libUri, libUnit);
        for (DartUnit unit : libUnit.getUnits()) {
          // Don't analyze diet units.
          if (unit.isDiet()) {
            continue;
          }
          for (DartCompilationPhase phase : phases) {
            unit = phase.exec(unit, context, compiler.getTypeProvider());
            // Ignore errors. Resolver and TypeAnalyzer should be able to cope with
            // resolution errors.
          }
          // To help support the IDE, notify the listener that this unit is compiled.
          context.unitCompiled(unit);
        }
      }
    }

    return newLibraries;
  }

  /**
   * Re-analyzes source code after a modification. The modification is described by a SourceDelta.
   *
   * @param delta what has changed
   * @param enclosingLibrary the library in which the change occurred
   * @param interestStart beginning of interest area (as character offset from the beginning of the
   *          source file after the change.
   * @param interestLength length of interest area
   * @return a node which covers the entire interest area.
   */
  public static DartNode analyzeDelta(SourceDelta delta,
                                      LibraryElement enclosingLibrary,
                                      LibraryElement coreLibrary,
                                      DartNode interestNode,
                                      int interestStart,
                                      int interestLength,
                                      CompilerConfiguration config,
                                      DartCompilerListener listener) throws IOException {
    DeltaAnalyzer analyzer = new DeltaAnalyzer(delta, enclosingLibrary, coreLibrary,
                                               interestNode, interestStart, interestLength,
                                               config, listener);
    return analyzer.analyze();
  }

  public static LibraryUnit findLibrary(LibraryUnit libraryUnit, String uri,
      Set<LibraryElement> seen) {
    if (seen.contains(libraryUnit.getElement())) {
      return null;
    }
    seen.add(libraryUnit.getElement());
    if (uri.equals(libraryUnit.getName())) {
      return libraryUnit;
    }
    for (LibraryNode src : libraryUnit.getSourcePaths()) {
      if (src.getText().equals(uri)) {
        return libraryUnit;
      }
    }
    for (LibraryUnit importedLibrary : libraryUnit.getImports()) {
      LibraryUnit unit = findLibrary(importedLibrary, uri, seen);
      if (unit != null) {
        return unit;
      }
    }
    return null;
  }

  public static LibraryUnit getCoreLib(LibraryUnit libraryUnit) {
    return findLibrary(libraryUnit, "dart:core", new HashSet<LibraryElement>());
  }
}
