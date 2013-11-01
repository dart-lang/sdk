// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_impl;

import 'dart:io';

import 'generated/java_io.dart';
import 'generated/engine.dart';
import 'generated/error.dart';
import 'generated/source_io.dart';
import 'generated/sdk.dart';
import 'generated/sdk_io.dart';
import 'generated/ast.dart';
import 'generated/element.dart';
import '../options.dart';


DartSdk sdk;

/// Analyzes single library [File].
class AnalyzerImpl {
  final CommandLineOptions options;

  ContentCache contentCache = new ContentCache();
  SourceFactory sourceFactory;
  AnalysisContext context;

  /// All [Source]s references by the analyzed library.
  final Set<Source> sources = new Set<Source>();

  /// All [AnalysisErrorInfo]s in the analyzed library.
  final List<AnalysisErrorInfo> errorInfos = new List<AnalysisErrorInfo>();

  AnalyzerImpl(CommandLineOptions this.options) {
    if (sdk == null) {
      sdk = new DirectoryBasedDartSdk(new JavaFile(options.dartSdkPath));
    }
  }

  /**
   * Treats the [sourcePath] as the top level library and analyzes it.
   */
  void analyze(String sourcePath) {
    sources.clear();
    errorInfos.clear();
    if (sourcePath == null) {
      throw new ArgumentError("sourcePath cannot be null");
    }
    var sourceFile = new JavaFile(sourcePath);
    var uriKind = getUriKind(sourceFile);
    var librarySource = new FileBasedSource.con2(contentCache, sourceFile, uriKind);
    // prepare context
    prepareAnalysisContext(sourceFile);
    // don't try to analyzer parts
    var unit = context.parseCompilationUnit(librarySource);
    var hasLibraryDirective = false;
    var hasPartOfDirective = false;
    for (var directive in unit.directives) {
      if (directive is LibraryDirective) hasLibraryDirective = true;
      if (directive is PartOfDirective) hasPartOfDirective = true;
    }
    if (hasPartOfDirective && !hasLibraryDirective) {
      print("Only libraries can be analyzed.");
      print("$sourceFile is a part and can not be analyzed.");
      return;
    }
    // resolve library
    var libraryElement = context.computeLibraryElement(librarySource);
    // prepare source and errors
    prepareSources(libraryElement);
    prepareErrors();
  }

  /// Returns the maximal [ErrorSeverity] of the recorded errors.
  ErrorSeverity get maxErrorSeverity {
    var status = ErrorSeverity.NONE;
    for (AnalysisErrorInfo errorInfo in errorInfos) {
      for (AnalysisError error in errorInfo.errors) {
        var severity = error.errorCode.errorSeverity;
        status = status.max(severity);
      }
    }
    return status;
  }

  void prepareAnalysisContext(JavaFile sourceFile) {
    List<UriResolver> resolvers = [new DartUriResolver(sdk), new FileUriResolver()];
    // may be add package resolver
    {
      JavaFile packageDirectory;
      if (options.packageRootPath != null) {
        packageDirectory = new JavaFile(options.packageRootPath);
      } else {
        packageDirectory = getPackageDirectoryFor(sourceFile);
      }
      if (packageDirectory != null) {
        resolvers.add(new PackageUriResolver([packageDirectory]));
      }
    }
    sourceFactory = new SourceFactory.con1(contentCache, resolvers);
    context = AnalysisEngine.instance.createAnalysisContext();
    context.sourceFactory = sourceFactory;

    // set options for context
    AnalysisOptionsImpl contextOptions = new AnalysisOptionsImpl();
    contextOptions.cacheSize = 256;
    contextOptions.hint = !options.disableHints;
    context.analysisOptions = contextOptions;
  }

  /// Fills [sources].
  void prepareSources(LibraryElement library) {
    var units = new Set<CompilationUnitElement>();
    var libraries = new Set<LibraryElement>();
    addLibrarySources(library, libraries, units);
  }

  void addCompilationUnitSource(CompilationUnitElement unit, Set<LibraryElement> libraries,
      Set<CompilationUnitElement> units) {
    if (unit == null || units.contains(unit)) {
      return;
    }
    units.add(unit);
    sources.add(unit.source);
  }

  void addLibrarySources(LibraryElement library, Set<LibraryElement> libraries,
      Set<CompilationUnitElement> units) {
    if (library == null || libraries.contains(library)) {
      return;
    }
    libraries.add(library);
    // may be skip library
    {
      UriKind uriKind = library.source.uriKind;
      // Optionally skip package: libraries.
      if (!options.showPackageWarnings && uriKind == UriKind.PACKAGE_URI) {
        return;
      }
      // Optionally skip SDK libraries.
      if (!options.showSdkWarnings && uriKind == UriKind.DART_URI) {
        return;
      }
    }
    // add compilation units
    addCompilationUnitSource(library.definingCompilationUnit, libraries, units);
    for (CompilationUnitElement child in library.parts) {
      addCompilationUnitSource(child, libraries, units);
    }
    // add referenced libraries
    for (LibraryElement child in library.importedLibraries) {
      addLibrarySources(child, libraries, units);
    }
    for (LibraryElement child in library.exportedLibraries) {
      addLibrarySources(child, libraries, units);
    }
  }

  /// Fills [errorInfos].
  void prepareErrors() {
    for (Source source in sources) {
      context.computeErrors(source);
      var sourceErrors = context.getErrors(source);
      errorInfos.add(sourceErrors);
    }
  }

  static JavaFile getPackageDirectoryFor(JavaFile sourceFile) {
    // we are going to ask parent file, so get absolute path
    sourceFile = sourceFile.getAbsoluteFile();
    // look in the containing directories
    JavaFile dir = sourceFile.getParentFile();
    while (dir != null) {
      JavaFile packagesDir = new JavaFile.relative(dir, "packages");
      if (packagesDir.exists()) {
        return packagesDir;
      }
      dir = dir.getParentFile();
    }
    // not found
    return null;
  }

  /**
   * Returns the [UriKind] for the given input file. Usually {@link UriKind#FILE_URI}, but if
   * the given file is located in the "lib" directory of the [sdk], then returns
   * {@link UriKind#DART_URI}.
   */
  static UriKind getUriKind(JavaFile file) {
    // may be file in SDK
    if (sdk is DirectoryBasedDartSdk) {
      DirectoryBasedDartSdk directoryBasedSdk = sdk;
      String sdkLibPath = directoryBasedSdk.libraryDirectory.getPath() + JavaFile.separator;
      if (file.getPath().startsWith(sdkLibPath)) {
        return UriKind.DART_URI;
      }
    }
    // some generic file
    return UriKind.FILE_URI;
  }
}
