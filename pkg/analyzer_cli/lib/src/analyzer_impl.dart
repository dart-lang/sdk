// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.src.analyzer_impl;

import 'dart:collection';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:path/path.dart' as pathos;

/// The maximum number of sources for which AST structures should be kept in the cache.
const int _maxCacheSize = 512;

int currentTimeMillis() => new DateTime.now().millisecondsSinceEpoch;

/// Analyzes single library [File].
class AnalyzerImpl {
  static final PerformanceTag _prepareErrorsTag =
      new PerformanceTag("AnalyzerImpl.prepareErrors");
  static final PerformanceTag _resolveLibraryTag =
      new PerformanceTag("AnalyzerImpl._resolveLibrary");

  final CommandLineOptions options;
  final int startTime;

  final AnalysisContext context;

  /// Accumulated analysis statistics.
  final AnalysisStats stats;

  final Source librarySource;

  /// All [Source]s references by the analyzed library.
  final Set<Source> sources = new Set<Source>();

  /// All [AnalysisErrorInfo]s in the analyzed library.
  final List<AnalysisErrorInfo> errorInfos = new List<AnalysisErrorInfo>();

  /// [HashMap] between sources and analysis error infos.
  final HashMap<Source, AnalysisErrorInfo> sourceErrorsMap =
      new HashMap<Source, AnalysisErrorInfo>();

  /// If the file specified on the command line is part of a package, the name
  /// of that package.  Otherwise `null`.  This allows us to analyze the file
  /// specified on the command line as though it is reached via a "package:"
  /// URI, but avoid suppressing its output in the event that the user has not
  /// specified the "--package-warnings" option.
  String _selfPackageName;

  AnalyzerImpl(this.context, this.librarySource, this.options, this.stats,
      this.startTime);

  /// Returns the maximal [ErrorSeverity] of the recorded errors.
  ErrorSeverity get maxErrorSeverity {
    var status = ErrorSeverity.NONE;
    for (AnalysisErrorInfo errorInfo in errorInfos) {
      for (AnalysisError error in errorInfo.errors) {
        if (_processError(error) == null) {
          continue;
        }
        var severity = computeSeverity(error, options);
        status = status.max(severity);
      }
    }
    return status;
  }

  void addCompilationUnitSource(
      CompilationUnitElement unit, Set<CompilationUnitElement> units) {
    if (unit == null || units.contains(unit)) {
      return;
    }
    units.add(unit);
    sources.add(unit.source);
  }

  void addLibrarySources(LibraryElement library, Set<LibraryElement> libraries,
      Set<CompilationUnitElement> units) {
    if (library == null || !libraries.add(library)) {
      return;
    }
    // Maybe skip library.
    if (!_isAnalyzedLibrary(library)) {
      return;
    }
    // Add compilation units.
    addCompilationUnitSource(library.definingCompilationUnit, units);
    for (CompilationUnitElement child in library.parts) {
      addCompilationUnitSource(child, units);
    }
    // Add referenced libraries.
    for (LibraryElement child in library.importedLibraries) {
      addLibrarySources(child, libraries, units);
    }
    for (LibraryElement child in library.exportedLibraries) {
      addLibrarySources(child, libraries, units);
    }
  }

  /// Treats the [sourcePath] as the top level library and analyzes it using a
  /// synchronous algorithm over the analysis engine. If [printMode] is `0`,
  /// then no error or performance information is printed. If [printMode] is `1`,
  /// then both will be printed. If [printMode] is `2`, then only performance
  /// information will be printed, and it will be marked as being for a cold VM.
  ErrorSeverity analyzeSync({int printMode: 1}) {
    setupForAnalysis();
    return _analyzeSync(printMode);
  }

  /// Fills [errorInfos] using [sources].
  void prepareErrors() {
    return _prepareErrorsTag.makeCurrentWhile(() {
      for (Source source in sources) {
        context.computeErrors(source);
        errorInfos.add(context.getErrors(source));
      }
    });
  }

  /// Fills [sources].
  void prepareSources(LibraryElement library) {
    var units = new Set<CompilationUnitElement>();
    var libraries = new Set<LibraryElement>();
    addLibrarySources(library, libraries, units);
  }

  /// Setup local fields such as the analysis context for analysis.
  void setupForAnalysis() {
    sources.clear();
    errorInfos.clear();
    Uri libraryUri = librarySource.uri;
    if (libraryUri.scheme == 'package' && libraryUri.pathSegments.length > 0) {
      _selfPackageName = libraryUri.pathSegments[0];
    }
  }

  /// The sync version of analysis.
  ErrorSeverity _analyzeSync(int printMode) {
    // Don't try to analyze parts.
    if (context.computeKindOf(librarySource) == SourceKind.PART) {
      stderr.writeln("Only libraries can be analyzed.");
      stderr.writeln(
          "${librarySource.fullName} is a part and can not be analyzed.");
      return ErrorSeverity.ERROR;
    }
    var libraryElement = _resolveLibrary();
    prepareSources(libraryElement);
    prepareErrors();

    // Print errors and performance numbers.
    if (printMode == 1) {
      _printErrors();
    } else if (printMode == 2) {
      _printColdPerf();
    }

    // Compute max severity and set exitCode.
    ErrorSeverity status = maxErrorSeverity;
    if (status == ErrorSeverity.WARNING && options.warningsAreFatal) {
      status = ErrorSeverity.ERROR;
    }
    return status;
  }

  /// Returns true if we want to report diagnostics for this library.
  bool _isAnalyzedLibrary(LibraryElement library) {
    Source source = library.source;
    switch (source.uriKind) {
      case UriKind.DART_URI:
        return options.showSdkWarnings;
      case UriKind.PACKAGE_URI:
        if (_isPathInPubCache(source.fullName)) {
          return false;
        }
        return _isAnalyzedPackage(source.uri);
      default:
        return true;
    }
  }

  /// Determine whether the given URI refers to a package being analyzed.
  bool _isAnalyzedPackage(Uri uri) {
    if (uri.scheme != 'package' || uri.pathSegments.isEmpty) {
      return false;
    }
    String packageName = uri.pathSegments.first;
    if (packageName == _selfPackageName) {
      return true;
    } else if (!options.showPackageWarnings) {
      return false;
    } else if (options.showPackageWarningsPrefix == null) {
      return true;
    } else {
      return packageName.startsWith(options.showPackageWarningsPrefix);
    }
  }

  _printColdPerf() {
    // Print cold VM performance numbers.
    int totalTime = currentTimeMillis() - startTime;
    int otherTime = totalTime;
    for (PerformanceTag tag in PerformanceTag.all) {
      if (tag != PerformanceTag.UNKNOWN) {
        int tagTime = tag.elapsedMs;
        outSink.writeln('${tag.label}-cold:$tagTime');
        otherTime -= tagTime;
      }
    }
    outSink.writeln('other-cold:$otherTime');
    outSink.writeln("total-cold:$totalTime");
  }

  _printErrors() {
    // The following is a hack. We currently print out to stderr to ensure that
    // when in batch mode we print to stderr, this is because the prints from
    // batch are made to stderr. The reason that options.shouldBatch isn't used
    // is because when the argument flags are constructed in BatchRunner and
    // passed in from batch mode which removes the batch flag to prevent the
    // "cannot have the batch flag and source file" error message.
    StringSink sink = options.machineFormat ? errorSink : outSink;

    // Print errors.
    ErrorFormatter formatter =
        new ErrorFormatter(sink, options, stats, _processError);
    formatter.formatErrors(errorInfos);
  }

  ProcessedSeverity _processError(AnalysisError error) =>
      processError(error, options, context);

  LibraryElement _resolveLibrary() {
    return _resolveLibraryTag.makeCurrentWhile(() {
      return context.computeLibraryElement(librarySource);
    });
  }

  /// Compute the severity of the error; however:
  ///   * if [options.enableTypeChecks] is false, then de-escalate checked-mode
  ///   compile time errors to a severity of [ErrorSeverity.INFO].
  ///   * if [options.hintsAreFatal] is true, escalate hints to errors.
  ///   * if [options.lintsAreFatal] is true, escalate lints to errors.
  static ErrorSeverity computeSeverity(
      AnalysisError error, CommandLineOptions options,
      [AnalysisContext context]) {
    if (context != null) {
      ErrorProcessor processor =
          ErrorProcessor.getProcessor(context.analysisOptions, error);
      // If there is a processor for this error, defer to it.
      if (processor != null) {
        return processor.severity;
      }
    }

    if (!options.enableTypeChecks &&
        error.errorCode.type == ErrorType.CHECKED_MODE_COMPILE_TIME_ERROR) {
      return ErrorSeverity.INFO;
    } else if (options.hintsAreFatal && error.errorCode is HintCode) {
      return ErrorSeverity.ERROR;
    } else if (options.lintsAreFatal && error.errorCode is LintCode) {
      return ErrorSeverity.ERROR;
    }
    return error.errorCode.errorSeverity;
  }

  /// Return the corresponding package directory or `null` if none is found.
  static JavaFile getPackageDirectoryFor(JavaFile sourceFile) {
    // We are going to ask parent file, so get absolute path.
    sourceFile = sourceFile.getAbsoluteFile();
    // Look in the containing directories.
    JavaFile dir = sourceFile.getParentFile();
    while (dir != null) {
      JavaFile packagesDir = new JavaFile.relative(dir, "packages");
      if (packagesDir.exists()) {
        return packagesDir;
      }
      dir = dir.getParentFile();
    }
    // Not found.
    return null;
  }

  /// Check various configuration options to get a desired severity for this
  /// [error] (or `null` if it's to be suppressed).
  static ProcessedSeverity processError(AnalysisError error,
      CommandLineOptions options, AnalysisContext context) {
    ErrorSeverity severity = computeSeverity(error, options, context);
    bool isOverridden = false;

    // Skip TODOs categorically (unless escalated to ERROR or HINT.)
    // https://github.com/dart-lang/sdk/issues/26215
    if (error.errorCode.type == ErrorType.TODO &&
        severity == ErrorSeverity.INFO) {
      return null;
    }

    // First check for a filter.
    if (severity == null) {
      // Null severity means the error has been explicitly ignored.
      return null;
    } else {
      isOverridden = true;
    }

    // If not overridden, some "natural" severities get globally filtered.
    if (!isOverridden) {
      // Check for global hint filtering.
      if (severity == ErrorSeverity.INFO && options.disableHints) {
        return null;
      }
    }

    return new ProcessedSeverity(severity, isOverridden);
  }

  /// Return `true` if the given [path] is in the Pub cache.
  static bool _isPathInPubCache(String path) {
    List<String> parts = pathos.split(path);
    if (parts.contains('.pub-cache')) {
      return true;
    }
    for (int i = 0; i < parts.length - 2; i++) {
      if (parts[i] == 'Pub' && parts[i + 1] == 'Cache') {
        return true;
      }
    }
    return false;
  }
}

/// This [Logger] prints out information comments to [outSink] and error messages
/// to [errorSink].
class StdLogger extends Logger {
  StdLogger();

  @override
  void logError(String message, [CaughtException exception]) {
    errorSink.writeln(message);
    if (exception != null) {
      errorSink.writeln(exception);
    }
  }

  @override
  void logInformation(String message, [CaughtException exception]) {
    outSink.writeln(message);
    if (exception != null) {
      outSink.writeln(exception);
    }
  }
}
