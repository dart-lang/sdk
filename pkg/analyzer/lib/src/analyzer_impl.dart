// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_impl;

import 'dart:async';

import 'dart:io';

import 'package:path/path.dart' as pathos;

import 'generated/java_io.dart';
import 'generated/engine.dart';
import 'generated/error.dart';
import 'generated/source_io.dart';
import 'generated/sdk.dart';
import 'generated/sdk_io.dart';
import 'generated/element.dart';
import '../options.dart';

import 'package:analyzer/src/generated/java_core.dart' show JavaSystem;
import 'package:analyzer/src/error_formatter.dart';

/**
 * The maximum number of sources for which AST structures should be kept in the cache.
 */
const int _MAX_CACHE_SIZE = 512;

DartSdk sdk;

/// Analyzes single library [File].
class AnalyzerImpl {
  final String sourcePath;
  final CommandLineOptions options;
  final int startTime;

  ContentCache contentCache = new ContentCache();
  SourceFactory sourceFactory;
  AnalysisContext context;

  /// All [Source]s references by the analyzed library.
  final Set<Source> sources = new Set<Source>();

  /// All [AnalysisErrorInfo]s in the analyzed library.
  final List<AnalysisErrorInfo> errorInfos = new List<AnalysisErrorInfo>();

  AnalyzerImpl(this.sourcePath, this.options, this.startTime) {
    if (sdk == null) {
      sdk = new DirectoryBasedDartSdk(new JavaFile(options.dartSdkPath));
    }
  }

  /**
   * Treats the [sourcePath] as the top level library and analyzes it.
   */
  void analyze() {
    sources.clear();
    errorInfos.clear();
    if (sourcePath == null) {
      throw new ArgumentError("sourcePath cannot be null");
    }
    JavaFile sourceFile = new JavaFile(sourcePath);
    UriKind uriKind = getUriKind(sourceFile);
    Source librarySource = new FileBasedSource.con2(sourceFile, uriKind);

    // prepare context
    prepareAnalysisContext(sourceFile, librarySource);

    // async perform all tasks in context
   _analyze();
  }

  void _analyze() {
    new Future(context.performAnalysisTask).then((AnalysisResult result) {
      List<ChangeNotice> notices = result.changeNotices;
      // TODO(jwren) change 'notices != null' to 'result.hasMoreWork()' after
      // next dart translation is landed for the analyzer
      if (notices != null) {
        // There is more work, record the set of sources, and then call self
        // again to perform next task
        for (ChangeNotice notice in notices) {
          sources.add(notice.source);
        }
        return _analyze();
      }
      //
      // There are not any more tasks, set error code and print performance
      // numbers.
      //
      // prepare errors
      prepareErrors();

      // compute max severity and set exitCode
      ErrorSeverity status = maxErrorSeverity;
      if (status == ErrorSeverity.WARNING && options.warningsAreFatal) {
        status = ErrorSeverity.ERROR;
      }
      exitCode = status.ordinal;

      // print errors
      ErrorFormatter formatter = new ErrorFormatter(stdout, options);
      formatter.formatErrors(errorInfos);

      // print performance numbers
      if (options.perf) {
        int totalTime = JavaSystem.currentTimeMillis() - startTime;
        int ioTime = PerformanceStatistics.io.result;
        int scanTime = PerformanceStatistics.scan.result;
        int parseTime = PerformanceStatistics.parse.result;
        int resolveTime = PerformanceStatistics.resolve.result;
        int errorsTime = PerformanceStatistics.errors.result;
        int hintsTime = PerformanceStatistics.hints.result;
        int angularTime = PerformanceStatistics.angular.result;
        stdout.writeln("io:$ioTime");
        stdout.writeln("scan:$scanTime");
        stdout.writeln("parse:$parseTime");
        stdout.writeln("resolve:$resolveTime");
        stdout.writeln("errors:$errorsTime");
        stdout.writeln("hints:$hintsTime");
        stdout.writeln("angular:$angularTime");
        stdout.writeln("other:${totalTime
             - (ioTime + scanTime + parseTime + resolveTime + errorsTime + hintsTime
             + angularTime)}");
        stdout.writeln("total:$totalTime");
      }
    }).catchError((ex, st) {
      AnalysisEngine.instance.logger.logError("${ex}\n${st}");
    });
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

  void prepareAnalysisContext(JavaFile sourceFile, Source source) {
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
    sourceFactory = new SourceFactory(resolvers);
    context = AnalysisEngine.instance.createAnalysisContext();
    context.sourceFactory = sourceFactory;
    // Uncomment the following to have errors reported on stdout and stderr
    AnalysisEngine.instance.logger = new StdLogger(options.log);

    // set options for context
    AnalysisOptionsImpl contextOptions = new AnalysisOptionsImpl();
    contextOptions.cacheSize = _MAX_CACHE_SIZE;
    contextOptions.hint = !options.disableHints;
    context.analysisOptions = contextOptions;

    // Create and add a ChangeSet
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    context.applyChanges(changeSet);
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
    if (library == null || !libraries.add(library) ) {
      return;
    }
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

  /// Fills [errorInfos] using [sources].
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
      var libraryDirectory = directoryBasedSdk.libraryDirectory.getAbsolutePath();
      var sdkLibPath = libraryDirectory + pathos.separator;
      var filePath = file.getPath();
      if (filePath.startsWith(sdkLibPath)) {
        var internalPath = pathos.join(libraryDirectory, '_internal') + pathos.separator;
        if (!filePath.startsWith(internalPath)) {
          return UriKind.DART_URI;
        }
      }
    }
    // some generic file
    return UriKind.FILE_URI;
  }
}

/**
 * This [Logger] prints out information comments to [stdout] and error messages
 * to [stderr].
 */
class StdLogger extends Logger {
  final bool log;

  StdLogger(this.log);

  @override
  void logError(String message) {
    stderr.writeln(message);
  }

  @override
  void logError2(String message, Exception exception) {
    stderr.writeln(message);
  }

  @override
  void logInformation(String message) {
    if (log) {
      stdout.writeln(message);
    }
  }

  @override
  void logInformation2(String message, Exception exception) {
    if (log) {
      stdout.writeln(message);
    }
  }
}
