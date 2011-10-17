// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.common.io.CharStreams;
import com.google.common.io.Closeables;
import com.google.common.io.Files;
import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.LibraryDeps.Dependency;
import com.google.dart.compiler.UnitTestBatchRunner.Invocation;
import com.google.dart.compiler.ast.DartDirective;
import com.google.dart.compiler.ast.DartLibraryDirective;
import com.google.dart.compiler.ast.DartNode;
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
import com.google.dart.compiler.parser.CommentPreservingParser;
import com.google.dart.compiler.parser.DartParser;
import com.google.dart.compiler.parser.DartScanner.Location;
import com.google.dart.compiler.parser.DartScannerParserContext;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.resolver.CoreTypeProviderImplementation;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.LibraryElement;
import com.google.dart.compiler.resolver.MemberBuilder;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.resolver.Resolver;
import com.google.dart.compiler.resolver.SupertypeResolver;
import com.google.dart.compiler.resolver.TopLevelElementBuilder;
import com.google.dart.compiler.type.TypeAnalyzer;

import org.kohsuke.args4j.CmdLineException;
import org.kohsuke.args4j.CmdLineParser;

import java.io.File;
import java.io.IOException;
import java.io.PrintStream;
import java.io.Reader;
import java.io.Writer;
import java.net.URI;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Entry point for the Dart compiler.
 */
public class DartCompiler {

  public static final String EXTENSION_API = "api";
  public static final String EXTENSION_DEPS = "deps";
  public static final String EXTENSION_LOG = "log";

  public static final String CORELIB_URL_SPEC = "dart:core";
  public static final String MAIN_ENTRY_POINT_NAME = "main";

  private static class Compiler {
    private final LibrarySource app;
    private final List<LibrarySource> embeddedLibraries = new ArrayList<LibrarySource>();
    private final DartCompilerMainContext context;
    private final CompilerConfiguration config;
    private final Map<URI, LibraryUnit> libraries = new LinkedHashMap<URI, LibraryUnit>();
    private boolean packageApp = false;
    private final boolean checkOnly;
    private final boolean collectComments;
    private CoreTypeProvider typeProvider;
    private final boolean incremental;
    private final boolean usePrecompiledDartLibs;
    private final List<DartCompilationPhase> phases;
    private final List<Backend> backends;
    private final LibrarySource coreLibrarySource;

    private Compiler(LibrarySource app, List<LibrarySource> embedded, CompilerConfiguration config,
        DartCompilerMainContext context) {
      this.app = app;
      this.config = config;
      this.phases = config.getPhases();
      this.backends = config.getBackends();
      this.context = context;
      checkOnly = config.checkOnly();
      collectComments = config.collectComments();
      for (LibrarySource library : embedded) {
        if (SystemLibraryManager.isDartSpec(library.getName())) {
          embeddedLibraries.add(context.getSystemLibraryFor(library.getName()));
        } else {
          embeddedLibraries.add(library);
        }
      }
      coreLibrarySource = context.getSystemLibraryFor(CORELIB_URL_SPEC);
      embeddedLibraries.add(coreLibrarySource);

      if (config.shouldOptimize()) {
        // Optimizing turns off incremental compilation.
        incremental = false;
        usePrecompiledDartLibs = false;
      } else {
        incremental = config.incremental();
        usePrecompiledDartLibs = true;
      }
    }

    private void compile() {
      TraceEvent logEvent = Tracer.canTrace() ? Tracer.start(DartEventType.COMPILE) : null;
      try {
        updateAndResolve();
        if (context.getErrorCount() > 0) {
          return;
        }
        if (!context.getFilesHaveChanged()) {
          return;
        }

        compileLibraries();
        packageApp();
      } catch (IOException e) {
        context.compilationError(new DartCompilationError(app, e));
      } finally {
        Tracer.end(logEvent);
      }
    }

    /**
     * Update the current application and any referenced libraries and resolve
     * them.
     *
     * @return a {@link LibraryUnit}, never null
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
        if (!context.getFilesHaveChanged()) {
          return library;
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
     * This method reads all libraries, updating their apis as necessary. They
     * will be populated from some combination of fully-parsed compilation units
     * and api files.
     */
    private void parseOutOfDateFiles() throws IOException {
      TraceEvent logEvent =
          Tracer.canTrace() ? Tracer.start(DartEventType.PARSE_OUTOFDATE) : null;
      CompilerMetrics compilerMetrics = context.getCompilerMetrics();
      long parseStart = compilerMetrics != null ? CompilerMetrics.getCPUTime() : 0;

      try {
        for (LibraryUnit lib : libraries.values()) {
          LibrarySource libSrc = lib.getSource();
          boolean libIsDartUri = SystemLibraryManager.isDartUri(libSrc.getUri());
          LibraryUnit apiLib = new LibraryUnit(libSrc);
          LibraryNode selfSourcePath = lib.getSelfSourcePath();
          boolean shouldLoadApi = incremental || (libIsDartUri && usePrecompiledDartLibs);
          boolean apiOutOfDate = !(shouldLoadApi && apiLib.loadApi(context, context));

          // Parse each compilation unit and update the API to reflect its contents.
          for (LibraryNode libNode : lib.getSourcePaths()) {
            final DartSource dartSrc = libSrc.getSourceFor(libNode.getText());
            if (dartSrc == null || !dartSrc.exists()) {
              // Dart Editor needs to have all missing files reported as compilation errors.
              // In addition, continue allows lib.populateTopLevelNodes() to be called so that the
              // top level elements are populated preventing an NPE later on.
              reportMissingSource(context, libSrc, libNode);
              continue;
            }

            DartUnit apiUnit = apiLib.getUnit(dartSrc.getName());
            if (apiUnit == null || (!libIsDartUri && isSourceOutOfDate(dartSrc, libSrc))) {
              DartUnit unit = parse(dartSrc, lib.getPrefixes());
              if (unit != null) {
                if (libNode == selfSourcePath) {
                  lib.setSelfDartUnit(unit);
                }
                lib.putUnit(unit);
                apiOutOfDate = true;
              }
            } else {
              if (libNode == selfSourcePath) {
                lib.setSelfDartUnit(apiUnit);
              }
              lib.putUnit(apiUnit);
            }
          }

          // Persist the api file.
          if (apiOutOfDate) {
            context.setFilesHaveChanged();
            if (!checkOnly) {
              lib.saveApi(context);
            }
          }

          // Populate the library's class map. This is used later for
          // dependency checking.
          lib.populateTopLevelNodes();
        }
      } finally {
        if (compilerMetrics != null) {
          compilerMetrics.addParseWallTimeNano(CompilerMetrics.getCPUTime() - parseStart);
        }
        Tracer.end(logEvent);
      }
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

        for (LibraryUnit lib : libraries.values()) {
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
          String libSpec = libNode.getText();
          LibrarySource dep;
          if (SystemLibraryManager.isDartSpec(libSpec)) {
            dep = context.getSystemLibraryFor(libSpec);
          } else {
            dep = libSrc.getImportFor(libSpec);
          }
          if (dep == null) {
            reportMissingSource(context, libSrc, libNode);
            continue;
          }

          lib.addImport(updateLibraries(dep), libNode);
        }
        return lib;
      } finally {
        Tracer.end(updateEvent);
      }
    }

    /**
     * Determines whether the given source is out-of-date with respect to its artifacts or
     * its library's associated api.
     */
    private boolean isSourceOutOfDate(DartSource dartSrc, LibrarySource libSrc) {
      TraceEvent logEvent =
          Tracer.canTrace() ? Tracer.start(DartEventType.IS_SOURCE_OUTOFDATE, "src",
              dartSrc.getName()) : null;
      try {
        // If incremental compilation is disabled, just return true to force all
        // units to be recompiled.
        if (!incremental) {
          return true;
        }

        for (Backend backend : backends) {
          TraceEvent backendEvent =
              Tracer.canTrace() ? Tracer.start(DartEventType.BACKEND_OUTOFDATE, "be", backend
                  .getClass().getCanonicalName(), "src", dartSrc.getName()) : null;
          try {
            if (backend.isOutOfDate(dartSrc, context)) {
              return true;
            }
          } finally {
            Tracer.end(backendEvent);
          }
        }
        return (context.isOutOfDate(dartSrc, libSrc, EXTENSION_API));
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
        Collection<LibraryUnit> libs = libraries.values();

        // Build the class elements declared in the sources of a library.
        // Loop can be parallelized.
        for (LibraryUnit lib : libs) {
          new TopLevelElementBuilder().exec(lib, context);
        }

        // The library scope can then be constructed, containing types declared
        // in the library, and // types declared in the imports. Loop can be
        // parallelized.
        for (LibraryUnit lib : libs) {
          new TopLevelElementBuilder().fillInLibraryScope(lib, context);
        }
      } finally {
        Tracer.end(logEvent);
      }
    }

    /**
     * Parses compilation units that are out-of-date with respect to their dependencies. The
     * parsed units will replace api units already in the library.
     */
    private void addOutOfDateDeps() throws IOException {
      TraceEvent logEvent = Tracer.canTrace() ? Tracer.start(DartEventType.ADD_OUTOFDATE) : null;
      try {
        boolean filesHaveChanged = false;
        for (LibraryUnit lib : libraries.values()) {

          if (SystemLibraryManager.isDartUri(lib.getSource().getUri())) {
            // embedded dart libs are always up to date
            continue;
          }

          // Load the existing DEPS, or create an empty one.
          LibraryDeps deps = lib.getDeps(context);

          // Parse units that are out-of-date with respect to their
          // dependencies.
          for (String sourceName : deps.getSourceNames()) {
            LibraryDeps.Source depSource = deps.getSource(sourceName);
            if (isSourceOutOfDate(lib, depSource)) {
              filesHaveChanged = true;
              DartSource dartSrc = lib.getSource().getSourceFor(sourceName);
              if ((dartSrc != null) && (dartSrc.exists())) {
                DartUnit unit = parse(dartSrc, lib.getPrefixes());
                if (unit != null) {
                  // Replace the newly-parsed unit within the library.
                  lib.putUnit(unit);
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
     * Determines whether the given source (as referenced by {@link LibraryDeps.Source}) is
     * out-of-date with respect to any of its dependencies.
     */
    private boolean isSourceOutOfDate(LibraryUnit lib, LibraryDeps.Source depSource) {
      for (String nodeName : depSource.getNodeNames()) {
        TraceEvent logEvent =
            Tracer.canTrace() ? Tracer.start(DartEventType.IS_CLASS_OUT_OF_DATE, "class",
                nodeName) : null;
        try {
          if (depSource.isHole(nodeName)) {
            // The dependency's a "hole", meaning that any new identifier in the
            // library scope that shadows it should force a recompile.
            if (lib.getTopLevelNode(nodeName) != null) {
              // The library defines a top-level node with the same name as the hole, so
              // we need to recompile.
              return true;
            }
          } else {
            // Normal dependency.
            Dependency dep = depSource.getDependency(nodeName);

            // Find the cached API and get its hash.
            LibraryUnit depLib = libraries.get(dep.getLibUri());
            if (depLib == null) {
              // The library no longer exists, so presume that we need to
              // recompile.
              return true;
            }

            // If there's a hash mismatch, deps are out of date
            DartNode depNode = depLib.getTopLevelNode(nodeName);
            if (depNode == null) {
              // Node was removed. That's about as mismatched as you can get.
              return true;
            }
            String hash = Integer.toString(depNode.computeHash());
            if (!hash.equals(dep.getHash())) {
              return true;
            }
          }
        } finally {
          Tracer.end(logEvent);
        }
      }

      // No holes or hash mismatches; in date.
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
        for (LibraryUnit lib : libraries.values()) {
          for (DartUnit unit : lib.getUnits()) {
            // These two method calls can be parallelized.
            new SupertypeResolver().exec(unit, context, getTypeProvider());
            new MemberBuilder().exec(unit, context, getTypeProvider());
          }
        }
      } finally {
        Tracer.end(logEvent);
      }
    }
    
    private void validateLibraryDirectives() {
      LibraryUnit appLibUnit = context.getAppLibraryUnit();
      for (LibraryUnit lib : libraries.values()) {
        // don't need to validate system libraries
        if (SystemLibraryManager.isDartUri(lib.getSource().getUri())) {
          continue;
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
            // find the imported path node (which corresponds to the import
            // directive node)
            SourceInfo info = null;
            for (LibraryNode importPath : lib.getImportPaths()) {
              if (importPath.getText().equals(importedLib.getSelfSourcePath().getText())) {
                info = importPath;
                break;
              }
            }
            if (info != null) {
              context.compilationError(new DartCompilationError(info,
                  DartCompilerErrorCode.MISSING_LIBRARY_DIRECTIVE, unit.getSource()
                      .getRelativePath()));
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
              if (unit.getSource().getRelativePath().equals(sourceNode.getText())) {
                context.compilationError(new DartCompilationError(unit.getDirectives().get(0),
                    DartCompilerErrorCode.ILLEGAL_DIRECTIVES_IN_SOURCED_UNIT, unit.getSource()
                        .getRelativePath()));
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
            context.compilationError(new DartCompilationError(Location.NONE,
                DartCompilerErrorCode.ENTRY_POINT_METHOD_MAY_NOT_BE_GETTER, MAIN_ENTRY_POINT_NAME));
          } else if (modifiers.isSetter()) {
            context.compilationError(new DartCompilationError(Location.NONE,
                DartCompilerErrorCode.ENTRY_POINT_METHOD_MAY_NOT_BE_SETTER, MAIN_ENTRY_POINT_NAME));
          } else if (methodElement.getParameters().size() > 0) {
            context.compilationError(new DartCompilationError(Location.NONE,
                DartCompilerErrorCode.ENTRY_POINT_METHOD_CANNOT_HAVE_PARAMETERS,
                MAIN_ENTRY_POINT_NAME));
          } else {
            lib.getElement().setEntryPoint(methodElement);
          }
          break;

        default:
          context.compilationError(new DartCompilationError(Location.NONE,
              DartCompilerErrorCode.NOT_A_STATIC_METHOD, MAIN_ENTRY_POINT_NAME));
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
        for (LibraryUnit lib : libraries.values()) {
          boolean persist = false;

          // Compile all the units in this library.
          for (DartUnit unit : lib.getUnits()) {
            // Don't compile api-only units.
            if (unit.isDiet()) {
              continue;
            }

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
              if (context.getErrorCount() > 0) {
                packageApp = false;
                return;
              }
            }

            // To help support the IDE, notify the listener that this unit is compiled.
            context.unitCompiled(unit);

            if (checkOnly) {
              continue;
            }

            // Run the unit through all the backends. This loop can also be
            // parallelized.
            for (Backend be : config.getBackends()) {
              TraceEvent backendEvent =
                  Tracer.canTrace() ? Tracer.start(DartEventType.BACKEND_COMPILE, "be", be
                      .getClass().getSimpleName(), "lib", lib.getName(), "unit", unit
                      .getSourceName()) : null;
              try {
                be.compileUnit(unit, unit.getSource(), context, typeProvider);
              } finally {
                Tracer.end(backendEvent);
              }
            }

            // Update deps.
            lib.getDeps(context).update(unit, context);

            // We compiled something, so remember that this means we need to
            // persist the deps and package the app.
            persist = true;
            packageApp = true;
          }

          // Persist the DEPS file.
          if (persist && !checkOnly) {
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

    private void packageApp() throws IOException {
      TraceEvent logEvent = Tracer.canTrace() ? Tracer.start(DartEventType.PACKAGE_APP) : null;

      CompilerMetrics compilerMetrics = context.getCompilerMetrics();
      if (compilerMetrics != null) {
        compilerMetrics.startPackageAppTime();
      }

      try {
        // Package output for each backend.
        if (packageApp) {
          // When there's no entry-point in the application unit,
          // don't attempt to package it. This can happen when
          // compileUnit() is called on a library. Always package app
          // when generating documentation.
          if (context.getApplicationUnit().getEntryNode() == null && !collectComments) {
            if (config.expectEntryPoint()) {
              context.compilationError(new DartCompilationError(Location.NONE,
                  DartCompilerErrorCode.NO_ENTRY_POINT));
            }
            return;
          }

          for (Backend be : backends) {
            TraceEvent backendEvent =
                Tracer.canTrace() ? Tracer.start(DartEventType.BACKEND_PACKAGE_APP, "be", be
                    .getClass().getSimpleName()) : null;
            try {
              be.packageApp(app, libraries.values(), context, typeProvider);
            } finally {
              Tracer.end(backendEvent);
            }
          }
        }
      } finally {
        if (compilerMetrics != null) {
          compilerMetrics.endPackageAppTime();
        }
        Tracer.end(logEvent);
      }
    }

    DartUnit parse(DartSource dartSrc, Set<String> libraryPrefixes) throws IOException {
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

        DartParser parser;
        if (collectComments) {
          DartScannerParserContext parserContext =
              CommentPreservingParser.createContext(dartSrc, srcCode, context,
                  context.getCompilerMetrics());
          parser = new CommentPreservingParser(parserContext, false);
        } else {
          DartScannerParserContext parserContext =
              new DartScannerParserContext(dartSrc, srcCode, context, context.getCompilerMetrics());
          parser = new DartParser(parserContext, libraryPrefixes);
        }
        DartUnit unit = parser.parseUnit(dartSrc);
        if (compilerMetrics != null) {
          compilerMetrics.addParseTimeNano(CompilerMetrics.getThreadTime() - parseStart);
        }

        if (!config.resolveDespiteParseErrors() && context.getErrorCount() > 0) {
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
      context.compilationError(event);
    }

    CoreTypeProvider getTypeProvider() {
      typeProvider.getClass(); // Quick null check.
      return typeProvider;
    }
  }

  /**
   * Selectively compile a library. Use supplied ASTs when available. This allows programming
   * tools to provide customized ASTs for code that is currently being edited, and may not
   * compile correctly.
   */
  private static class SelectiveCompiler extends Compiler {
    /** Map from source URI to AST representing the source */
    private final Map<URI,DartUnit> parsedUnits;

    private SelectiveCompiler(LibrarySource app, Map<URI,DartUnit> suppliedUnits,
        CompilerConfiguration config, DartCompilerMainContext context) {
      super(app, Collections.<LibrarySource>emptyList(), config, context);
      parsedUnits = suppliedUnits;
    }

    @Override
    DartUnit parse(DartSource dartSrc, Set<String> prefixes) throws IOException {
      if (parsedUnits == null) {
        return super.parse(dartSrc, prefixes);
      }
      URI srcUri = dartSrc.getUri();
      DartUnit parsedUnit = parsedUnits.get(srcUri);
      return parsedUnit == null ? super.parse(dartSrc, prefixes) : parsedUnit;
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

  public static void main(String[] args) {
    Tracer.init();

    CompilerOptions topCompilerOptions = processCommandLineOptions(args);
    boolean result = false;
    try {
      if (topCompilerOptions.shouldBatch()) {
        if (args.length > 1) {
          System.err.println("(Extra arguments specified with -batch ignored.)");
        }
        UnitTestBatchRunner.runAsBatch(args, new Invocation() {
          @Override
          public boolean invoke(String[] args) throws Throwable {
            CompilerOptions compilerOptions = processCommandLineOptions(args);
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

    CompilerConfiguration config;
    if (compilerOptions.getIsolateStubClasses().isEmpty()) {
      config = new DefaultCompilerConfiguration(compilerOptions);
    } else {
      config = new DartIsolateStubGeneratorCompilerConfiguration(
          compilerOptions);
    }
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
   * Compiles the source file which could be a single *.dart source file or a *.app file.  If it
   * is the former an *.app file is conceptually synthesized.
   */
  public static String compileApp(File sourceFile, CompilerConfiguration config) throws IOException {
    TraceEvent logEvent =
        Tracer.canTrace() ? Tracer.start(DartEventType.COMPILE_APP, "src", sourceFile.toString())
            : null;
    File outFile = config.getOutputFilename();
    if (outFile != null && config.getBackends().size() > 1) {
      // More than one backend is ambiguous.
      throw new IllegalArgumentException("Output filename "
          + outFile + " specified.  Only valid with a single backend.");
    }
    try {
      File outputDirectory = config.getOutputDirectory();
      DefaultDartArtifactProvider provider = new DefaultDartArtifactProvider(outputDirectory);
      DefaultDartCompilerListener listener = new DefaultDartCompilerListener();

      // Compile the Dart application and its dependencies.
      LibrarySource lib = new UrlLibrarySource(sourceFile);
      config = new DelegatingCompilerConfiguration(config) {
        @Override
        public boolean expectEntryPoint() {
          return true;
        }
      };

      String errorString = compileLib(lib, config, provider, listener);

      // Write out a copy of the generated JS if specified by the user
      if (errorString == null && outFile != null && !config.getBackends().isEmpty()) {
        File dir = outFile.getParentFile();
        if (dir != null) {
          if (dir != null && !dir.exists()) {
            throw new IOException("Cannot create: " + outFile.getName()
                                  + ".  " + dir + " does not exist");
          }
          if (!dir.canWrite()) {
            throw new IOException("Cannot write " + outFile.getName() + " to "
                + dir + ":  Permission denied.");
          }
        } else {
          dir = new File (".");
          if (!dir.canWrite()) {
            throw new IOException("Cannot write " + outFile.getName() + " to "
                + dir + ":  Permission denied.");
          }
        }

        Reader r = null;
        try {
        // HACK: there can be more than one backend.  Since there isn't
        // an obvious way to tell which one the user meant, for now
        // just restrict the option to save the output if more than
        // one is active.
         r = provider.getArtifactReader(lib, "",
             config.getBackends().get(0).getAppExtension());
         String js = CharStreams.toString(r);
         if (r != null) {
           Files.write(js, outFile, Charset.defaultCharset());
         }
        } finally {
          Closeables.close(r, true);
        }
      }
      return errorString;
    } finally {
      Tracer.end(logEvent);
    }
  }

  /**
   * Compiles the given library, translating all its source files, and those
   * of its imported libraries, transitively.
   *
   * If the specified library contains an entry-point method, then the application will be packaged
   * by each backend. Otherwise, only library artifacts will be generated.
   *
   * @param lib The library to be compiled (not <code>null</code>)
   * @param config The compiler configuration specifying the compilation phases
   *     and backends
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
    if (config.checkOnly()) {
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
   * @param parsedUnits A collection of ASTs that should be used
   * instead of parsing the associated source from storage. Intended for
   * IDE use when modified buffers must be analyzed. AST nodes in the map may be
   * ignored if not referenced by {@code lib}. (May be null.)
   * @param config The compiler configuration (phases and backends
   * will not be used), but resolution and type-analysis will be
   * invoked
   * @param provider A mechanism for specifying where code should be generated
   * @param listener An object notified when compilation errors occur
   * @throws NullPointerException if any of the arguments except {@code parsedUnits}
   * are {@code null}
   * @throws IOException on IO errors, which are not logged
   */
  public static LibraryUnit analyzeLibrary(LibrarySource lib, Map<URI, DartUnit> parsedUnits,
      CompilerConfiguration config, DartArtifactProvider provider, DartCompilerListener listener)
      throws IOException {
    lib.getClass(); // Quick null check.
    provider.getClass(); // Quick null check.
    listener.getClass(); // Quick null check.
    DartCompilerMainContext context = new DartCompilerMainContext(lib, provider, listener, config);
    Compiler compiler = new SelectiveCompiler(lib, parsedUnits, config, context);
    LibraryUnit libraryUnit = compiler.updateAndResolve();
    // Ignore errors. Resolver should be able to cope with
    // errors. Otherwise, we should fix it.
    DartCompilationPhase[] phases = {
      new Resolver.Phase(),
      new TypeAnalyzer()
    };
    for (DartUnit unit : libraryUnit.getUnits()) {
      // Don't analyze api-only units.
      if (unit.isDiet()) {
        continue;
      }

      for (DartCompilationPhase phase : phases) {
        unit = phase.exec(unit, context, compiler.getTypeProvider());
        // Ignore errors. TypeAnalyzer should be able to cope with
        // resolution errors.
      }
    }
    return libraryUnit;
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
    return findLibrary(libraryUnit, "corelib.dart", new HashSet<LibraryElement>());
  }
}
