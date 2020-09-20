// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:analyzer_cli/src/error_severity.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:path/path.dart' as path;

int get currentTimeMillis => DateTime.now().millisecondsSinceEpoch;

/// Analyzes single library [File].
class AnalyzerImpl {
  final CommandLineOptions options;
  final int startTime;

  final AnalysisOptions analysisOptions;
  final AnalysisDriver analysisDriver;

  /// Accumulated analysis statistics.
  final AnalysisStats stats;

  /// The library file to analyze.
  final FileState libraryFile;

  /// All files references by the analyzed library.
  final Set<String> files = <String>{};

  /// All [AnalysisErrorInfo]s in the analyzed library.
  final List<ErrorsResult> errorsResults = [];

  /// If the file specified on the command line is part of a package, the name
  /// of that package. Otherwise `null`. This allows us to analyze the file
  /// specified on the command line as though it is reached via a "package:"
  /// URI, but avoid suppressing its output in the event that the user has not
  /// specified the "--package-warnings" option.
  String _selfPackageName;

  AnalyzerImpl(this.analysisOptions, this.analysisDriver, this.libraryFile,
      this.options, this.stats, this.startTime);

  void addCompilationUnitSource(
      CompilationUnitElement unit, Set<CompilationUnitElement> units) {
    if (unit == null || !units.add(unit)) {
      return;
    }
    var source = unit.source;
    if (source != null) {
      files.add(source.fullName);
    }
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
    for (var child in library.parts) {
      addCompilationUnitSource(child, units);
    }
    // Add referenced libraries.
    for (var child in library.importedLibraries) {
      addLibrarySources(child, libraries, units);
    }
    for (var child in library.exportedLibraries) {
      addLibrarySources(child, libraries, units);
    }
  }

  /// Treats the [sourcePath] as the top level library and analyzes it using
  /// the analysis engine. If [printMode] is `0`, then no error or performance
  /// information is printed. If [printMode] is `1`, then errors will be printed.
  /// If [printMode] is `2`, then performance information will be printed, and
  /// it will be marked as being for a cold VM.
  Future<ErrorSeverity> analyze(ErrorFormatter formatter,
      {int printMode = 1}) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    setupForAnalysis();
    return await _analyze(printMode, formatter);
  }

  /// Returns the maximal [ErrorSeverity] of the recorded errors.
  ErrorSeverity computeMaxErrorSeverity() {
    var status = ErrorSeverity.NONE;
    for (var result in errorsResults) {
      for (var error in result.errors) {
        if (_defaultSeverityProcessor(error) == null) {
          continue;
        }
        status = status.max(computeSeverity(error, options, analysisOptions));
      }
    }
    return status;
  }

  /// Fills [errorsResults] using [files].
  Future<void> prepareErrors() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    for (var path in files) {
      var errorsResult = await analysisDriver.getErrors(path);
      errorsResults.add(errorsResult);
    }
  }

  /// Fills [files].
  void prepareSources(LibraryElement library) {
    var units = <CompilationUnitElement>{};
    var libraries = <LibraryElement>{};
    addLibrarySources(library, libraries, units);
  }

  /// Setup local fields such as the analysis context for analysis.
  void setupForAnalysis() {
    files.clear();
    errorsResults.clear();
    var libraryUri = libraryFile.uri;
    if (libraryUri.scheme == 'package' && libraryUri.pathSegments.isNotEmpty) {
      _selfPackageName = libraryUri.pathSegments[0];
    }
  }

  Future<ErrorSeverity> _analyze(
      int printMode, ErrorFormatter formatter) async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    // Don't try to analyze parts.
    if (libraryFile.isPart) {
      var libraryPath = libraryFile.path;
      stderr.writeln('Only libraries can be analyzed.');
      stderr.writeln('$libraryPath is a part and cannot be analyzed.');
      return ErrorSeverity.ERROR;
    }

    var libraryElement = await _resolveLibrary();
    prepareSources(libraryElement);
    await prepareErrors();

    // Print errors and performance numbers.
    if (printMode == 1) {
      formatter.formatErrors(errorsResults);
    } else if (printMode == 2) {
      _printColdPerf();
    }

    // Compute and return max severity.
    return computeMaxErrorSeverity();
  }

  ErrorSeverity _defaultSeverityProcessor(AnalysisError error) =>
      determineProcessedSeverity(error, options, analysisOptions);

  /// Returns true if we want to report diagnostics for this library.
  bool _isAnalyzedLibrary(LibraryElement library) {
    var source = library.source;
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
    var packageName = uri.pathSegments.first;
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

  // TODO(devoncarew): This is never called.
  void _printColdPerf() {
    // Print cold VM performance numbers.
    var totalTime = currentTimeMillis - startTime;
    outSink.writeln('total-cold:$totalTime');
  }

  Future<LibraryElement> _resolveLibrary() async {
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;

    var libraryPath = libraryFile.path;
    analysisDriver.priorityFiles = [libraryPath];
    var elementResult = await analysisDriver.getUnitElement(libraryPath);
    return elementResult.element.library;
  }

  /// Return `true` if the given [pathName] is in the Pub cache.
  static bool _isPathInPubCache(String pathName) {
    var parts = path.split(pathName);
    if (parts.contains('.pub-cache')) {
      return true;
    }
    for (var i = 0; i < parts.length - 2; i++) {
      if (parts[i] == 'Pub' && parts[i + 1] == 'Cache') {
        return true;
      }
    }
    return false;
  }
}

/// This [InstrumentationService] prints out information comments to [outSink]
/// and error messages to [errorSink].
class StdInstrumentation extends NoopInstrumentationService {
  @override
  void logError(String message) {
    errorSink.writeln(message);
  }

  @override
  void logException(dynamic exception,
      [StackTrace stackTrace,
      List<InstrumentationServiceAttachment> attachments]) {
    errorSink.writeln(exception);
    errorSink.writeln(stackTrace);
  }

  @override
  void logInfo(String message, [Object exception]) {
    outSink.writeln(message);
    if (exception != null) {
      outSink.writeln(exception);
    }
  }
}
