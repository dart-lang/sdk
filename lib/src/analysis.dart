// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis;

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/file_system/file_system.dart' show Folder;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/options.dart';
import 'package:analyzer/source/package_map_provider.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/src/analyzer_impl.dart';
import 'package:analyzer/src/error_formatter.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_core.dart' show JavaSystem;
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:grinder/grinder.dart' as grinder;


/// A refactored fork of [AnalyzerImpl] with an eye towards easing
/// use and extension.
///
/// Still very much a WIP.
class AnalysisDriver {

  /// The maximum number of sources for which AST structures should be kept
  /// in the cache.
  // TODO: move to DriverOptions
  static const _MAX_CACHE_SIZE = 512;

  final DriverOptions _options;

  final int _startTime;
  AnalysisContext _context;

  Source _librarySource;
  SourceFactory _sourceFactory;
  /// All [Source]s referenced by the analyzed library.
  final Set<Source> _sources = new Set<Source>();

  /// All [AnalysisErrorInfo]s in the analyzed library.
  final List<AnalysisErrorInfo> errorInfos = new List<AnalysisErrorInfo>();

  /// [HashMap] between sources and analysis error infos.
  final HashMap<Source, AnalysisErrorInfo> sourceErrorsMap =
      new HashMap<Source, AnalysisErrorInfo>();

  AnalysisDriver.forFile(File file, DriverOptions options, [DartSdk dartSdk])
      : this.forPath(file.absolute.path, options, dartSdk);

  AnalysisDriver.forPath(String sourcePath, DriverOptions options,
      [DartSdk dartSdk])
      : this.forSource(
          _createSource(sourcePath, dartSdk, options),
          options,
          dartSdk);

  AnalysisDriver.forSource(this._librarySource, this._options,
      [DartSdk dartSdk])
      : _startTime = _currentTimeInMillis() {
    //TODO: is already called when redirected from forPath
    _setupSdk(dartSdk, _options);
  }

  /// Returns the maximal [ErrorSeverity] of the recorded errors.
  ErrorSeverity get maxErrorSeverity {
    var status = ErrorSeverity.NONE;
    for (AnalysisErrorInfo errorInfo in errorInfos) {
      for (AnalysisError error in errorInfo.errors) {
        if (!isDesiredError(error)) {
          continue;
        }
        var severity = _computeSeverity(error, _options.enableTypeChecks);
        status = status.max(severity);
      }
    }
    return status;
  }

  /// Default implementation contributes a package URI and package map
  /// resolvers (in addition to the predefined dart URI and file URI resolvers).
  /// Override to specialize.
  void addResolvers(List<UriResolver> resolvers) {
    if (_options.packageRootPath != null) {
      JavaFile packageDirectory = new JavaFile(_options.packageRootPath);
      resolvers.add(new PackageUriResolver([packageDirectory]));
    } else {
      PubPackageMapProvider pubPackageMapProvider =
          new PubPackageMapProvider(PhysicalResourceProvider.INSTANCE, sdk);
      PackageMapInfo packageMapInfo = pubPackageMapProvider.computePackageMap(
          PhysicalResourceProvider.INSTANCE.getResource('.'));
      Map<String, List<Folder>> packageMap = packageMapInfo.packageMap;
      if (packageMap != null) {
        resolvers.add(
            new PackageMapUriResolver(PhysicalResourceProvider.INSTANCE, packageMap));
      }
    }
  }

  /// Treats the [sourcePath] as the top level library and analyzes it using an
  /// asynchronous algorithm over the analysis engine.
  void analyzeAsync() {
    _setupForAnalysis();
    _analyzeAsync();
  }

  /// Treats the [sourcePath] as the top level library and analyzes it using a
  /// synchronous algorithm over the analysis engine. If [printMode] is `0`,

      /// then no error or performance information is printed. If [printMode] is `1`,
  /// then both will be printed. If [printMode] is `2`, then only performance
  /// information will be printed, and it will be marked as being for a cold VM.
  ErrorSeverity analyzeSync({int printMode: 1}) {
    _setupForAnalysis();
    return _analyzeSync(printMode);
  }

  /// By default creates a logger that reports to standard out and error.
  Logger createLogger() => new StdLogger(_options.log);

  bool isDesiredError(AnalysisError error) {
    if (error.errorCode.type == ErrorType.TODO) {
      return false;
    }
    if (_computeSeverity(error, _options.enableTypeChecks) ==
        ErrorSeverity.INFO &&
        _options.disableHints) {
      return false;
    }
    return true;
  }

  void _addCompilationUnitSource(CompilationUnitElement unit,
      Set<LibraryElement> libraries, Set<CompilationUnitElement> units) {
    if (unit == null || units.contains(unit)) {
      return;
    }
    units.add(unit);
    _sources.add(unit.source);
  }

  void _addLibrarySources(LibraryElement library, Set<LibraryElement> libraries,
      Set<CompilationUnitElement> units) {
    if (library == null || !libraries.add(library)) {
      return;
    }
    // may be skip library
    {
      UriKind uriKind = library.source.uriKind;
      // Optionally skip package: libraries.
      if (!_options.showPackageWarnings && uriKind == UriKind.PACKAGE_URI) {
        return;
      }
      // Optionally skip SDK libraries.
      if (!_options.showSdkWarnings && uriKind == UriKind.DART_URI) {
        return;
      }
    }
    // add compilation units
    _addCompilationUnitSource(
        library.definingCompilationUnit,
        libraries,
        units);
    for (CompilationUnitElement child in library.parts) {
      _addCompilationUnitSource(child, libraries, units);
    }
    // add referenced libraries
    for (LibraryElement child in library.importedLibraries) {
      _addLibrarySources(child, libraries, units);
    }
    for (LibraryElement child in library.exportedLibraries) {
      _addLibrarySources(child, libraries, units);
    }
  }

  /// The async version of the analysis
  void _analyzeAsync() {
    new Future(_context.performAnalysisTask).then((AnalysisResult result) {
      List<ChangeNotice> notices = result.changeNotices;
      if (result.hasMoreWork) {
        // There is more work, record the set of sources, and then call self
        // again to perform next task
        for (ChangeNotice notice in notices) {
          _sources.add(notice.source);
          sourceErrorsMap[notice.source] = notice;
        }
        return _analyzeAsync();
      }

      // There are not any more tasks, set error code and print performance
      // numbers.
      //
      // prepare errors
      sourceErrorsMap.forEach((k, v) {
        errorInfos.add(sourceErrorsMap[k]);
      });

      // print errors and performance numbers
      _printErrorsAndPerf();

      // compute max severity and set exitCode
      ErrorSeverity status = maxErrorSeverity;
      if (status == ErrorSeverity.WARNING && _options.warningsAreFatal) {
        status = ErrorSeverity.ERROR;
      }
      exitCode = status.ordinal;
    }).catchError((ex, st) {
      AnalysisEngine.instance.logger.logError("$ex\n$st");
    });
  }

  /// The sync version of analysis.
  ErrorSeverity _analyzeSync(int printMode) {
    // don't try to analyze parts
    if (_context.computeKindOf(_librarySource) == SourceKind.PART) {
      print("Only libraries can be analyzed.");
      print("${_librarySource.shortName} is a part and can not be analyzed.");
      return ErrorSeverity.ERROR;
    }
    // resolve library
    var libraryElement = _context.computeLibraryElement(_librarySource);
    // prepare source and errors
    _prepareSources(libraryElement);
    _prepareErrors();

    // print errors and performance numbers
    if (printMode == 1) {
      _printErrorsAndPerf();
    } else if (printMode == 2) {
      _printColdPerf();
    }

    // compute max severity and set exitCode
    ErrorSeverity status = maxErrorSeverity;
    if (status == ErrorSeverity.WARNING && _options.warningsAreFatal) {
      status = ErrorSeverity.ERROR;
    }
    return status;
  }

  List<UriResolver> _getResolvers() {
    List<UriResolver> resolvers = [
        new DartUriResolver(sdk),
        new FileUriResolver()];
    addResolvers(resolvers);
    return resolvers;
  }

  void _prepareAnalysisContext(Source source) {
    var resolvers = _getResolvers();
    _sourceFactory = new SourceFactory(resolvers);
    _context = AnalysisEngine.instance.createAnalysisContext();
    _context.sourceFactory = _sourceFactory;
    Map<String, String> definedVariables = _options.definedVariables;
    if (!definedVariables.isEmpty) {
      DeclaredVariables declaredVariables = _context.declaredVariables;
      definedVariables.forEach((String variableName, String value) {
        declaredVariables.define(variableName, value);
      });
    }

    AnalysisEngine.instance.logger = createLogger();

    // set options for context
    AnalysisOptionsImpl contextOptions = new AnalysisOptionsImpl();
    _setOptions(contextOptions);
    _context.analysisOptions = contextOptions;

    // Create and add a ChangeSet
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    _context.applyChanges(changeSet);
  }

  /// Fills [errorInfos] using [_sources].
  void _prepareErrors() {
    for (Source source in _sources) {
      _context.computeErrors(source);
      var sourceErrors = _context.getErrors(source);
      errorInfos.add(sourceErrors);
    }
  }

  /// Fills [_sources].
  void _prepareSources(LibraryElement library) {
    var units = new Set<CompilationUnitElement>();
    var libraries = new Set<LibraryElement>();
    _addLibrarySources(library, libraries, units);
  }

  _printColdPerf() {
    // print cold VM performance numbers
    int totalTime = JavaSystem.currentTimeMillis() - _startTime;
    int ioTime = PerformanceStatistics.io.result;
    int scanTime = PerformanceStatistics.scan.result;
    int parseTime = PerformanceStatistics.parse.result;
    int resolveTime = PerformanceStatistics.resolve.result;
    int errorsTime = PerformanceStatistics.errors.result;
    int hintsTime = PerformanceStatistics.hints.result;
    stdout.writeln("io-cold:$ioTime");
    stdout.writeln("scan-cold:$scanTime");
    stdout.writeln("parse-cold:$parseTime");
    stdout.writeln("resolve-cold:$resolveTime");
    stdout.writeln("errors-cold:$errorsTime");
    stdout.writeln("hints-cold:$hintsTime");
    stdout.writeln("other-cold:${totalTime
        - (ioTime + scanTime + parseTime + resolveTime + errorsTime + hintsTime)}");
    stdout.writeln("total-cold:$totalTime");
  }

  _printErrorsAndPerf() {
    // The following is a hack. We currently print out to stderr to ensure that
    // when in batch mode we print to stderr, this is because the prints from
    // batch are made to stderr. The reason that options.shouldBatch isn't used
    // is because when the argument flags are constructed in BatchRunner and
    // passed in from batch mode which removes the batch flag to prevent the
    // "cannot have the batch flag and source file" error message.
    IOSink sink = _options.machineFormat ? stderr : stdout;

    // print errors
    ErrorFormatter formatter =
        new ErrorFormatter(sink, new _OptionsWrapper(_options), isDesiredError);
    formatter.formatErrors(errorInfos);

    // print performance numbers
    if (_options.perf || _options.warmPerf) {
      int totalTime = JavaSystem.currentTimeMillis() - _startTime;
      int ioTime = PerformanceStatistics.io.result;
      int scanTime = PerformanceStatistics.scan.result;
      int parseTime = PerformanceStatistics.parse.result;
      int resolveTime = PerformanceStatistics.resolve.result;
      int errorsTime = PerformanceStatistics.errors.result;
      int hintsTime = PerformanceStatistics.hints.result;
      stdout.writeln("io:$ioTime");
      stdout.writeln("scan:$scanTime");
      stdout.writeln("parse:$parseTime");
      stdout.writeln("resolve:$resolveTime");
      stdout.writeln("errors:$errorsTime");
      stdout.writeln("hints:$hintsTime");
      stdout.writeln("other:${totalTime
      - (ioTime + scanTime + parseTime + resolveTime + errorsTime + hintsTime)}");
      stdout.writeln("total:$totalTime");
    }
  }

  void _setOptions(AnalysisOptionsImpl analysisOptions) {
    analysisOptions.cacheSize = _MAX_CACHE_SIZE;
    analysisOptions.hint = !_options.disableHints;
    analysisOptions.lint = _options.enableLints;
  }

  /// Setup local fields such as the analysis context for analysis.
  void _setupForAnalysis() {
    _sources.clear();
    errorInfos.clear();
    _prepareAnalysisContext(_librarySource);
  }

  /// Compute the severity of the error; however, if
  /// enableTypeChecks] is false, then de-escalate checked-mode compile time
  /// errors to a severity of [ErrorSeverity.INFO].
  static ErrorSeverity _computeSeverity(AnalysisError error,
      bool enableTypeChecks) {
    if (!enableTypeChecks &&
        error.errorCode.type == ErrorType.CHECKED_MODE_COMPILE_TIME_ERROR) {
      return ErrorSeverity.INFO;
    }
    return error.errorCode.errorSeverity;
  }

  static Source _createSource(String sourcePath, DartSdk dartSdk,
      DriverOptions options) {
    _setupSdk(dartSdk, options);
    JavaFile sourceFile = new JavaFile(_normalizeSourcePath(sourcePath));
    Uri uri = _getUri(sourceFile);
    return new FileBasedSource.con2(uri, sourceFile);
  }

  static int _currentTimeInMillis() =>
      new DateTime.now().millisecondsSinceEpoch;

  static JavaFile _getPackageDirectoryFor(JavaFile sourceFile) {
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

  /// Returns the [Uri] for the given input file.
  /// Usually it is a `file:` [Uri], but if [file] is located in the `lib`
  /// directory of the [sdk], then returns a `dart:` [Uri].
  static Uri _getUri(JavaFile file) {
    // may be file in SDK
    {
      Source source = sdk.fromFileUri(file.toURI());
      if (source != null) {
        return source.uri;
      }
    }
    // some generic file
    return file.toURI();
  }

  /// Convert [sourcePath] into an absolute path.
  static String _normalizeSourcePath(String sourcePath) =>
      new File(sourcePath).absolute.path;

  static void _setupSdk(DartSdk dartSdk, DriverOptions options) {
    if (dartSdk != null) {
      if (dartSdk is DirectoryBasedDartSdk) {
        sdk = dartSdk;
      } else {
        sdk = new SdkWrapper(dartSdk);
      }
    } else if (options.dartSdkPath != null) {
      sdk = new DirectoryBasedDartSdk(new JavaFile(options.dartSdkPath));
    } else if (sdk == null) {
      // In case no SDK has been specified, fall back to inferring it
      // TODO: pass args to grinder
      Directory sdkDir = grinder.getSdkDir();
      sdk = new DirectoryBasedDartSdk(new JavaFile(sdkDir.path));
    }
  }

}


class DriverOptions {

  /// The path to the dart SDK.
  String dartSdkPath;

  /// A table mapping the names of defined variables to their values.
  Map<String, String> definedVariables = {};

  /// Whether to display version information.
  bool displayVersion;

  /// Whether to report hints.
  bool disableHints = false;

  /// Whether to enable lints.
  bool enableLints = false;

  /// Whether to treat type mismatches found during constant evaluation as
  /// errors.
  bool enableTypeChecks = false;

  /// Whether to ignore unrecognized flags.
  bool ignoreUnrecognizedFlags;

  /// Whether to log additional analysis messages and exceptions.
  bool log = false;

  /// Whether to use machine format for error display.
  bool machineFormat = false;

  /// The path to the package root.
  String packageRootPath;

  /// Whether to show performance statistics.
  bool perf = false;

  /// Whether to show package: warnings.
  bool showPackageWarnings = false;

  /// Whether to show SDK warnings.
  bool showSdkWarnings = false;

  /// Whether to show both cold and hot performance statistics.
  bool warmPerf = false;

  /// Whether to treat warnings as fatal.
  bool warningsAreFatal = false;
}


class SdkWrapper implements DirectoryBasedDartSdk {

  DartSdk dartSdk;

  SdkWrapper(this.dartSdk);

  @override
  AnalysisContext get context => dartSdk.context;

  @override
  JavaFile get dart2JsExecutable => null;

  @override
  JavaFile get dartFmtExecutable => null;

  @override
  String get dartiumBinaryName => null;

  @override
  JavaFile get dartiumExecutable => null;

  @override
  JavaFile get dartiumWorkingDirectory => null;

  @override
  JavaFile get directory => null;

  @override
  JavaFile get docDirectory => null;

  @override
  bool get hasDocumentation => false;

  @override
  bool get isDartiumInstalled => null;

  @override
  JavaFile get libraryDirectory => null;

  @override
  JavaFile get pubExecutable => null;

  @override
  List<SdkLibrary> get sdkLibraries => dartSdk.sdkLibraries;

  @override
  String get sdkVersion => dartSdk.sdkVersion;

  @override
  List<String> get uris => dartSdk.uris;

  @override
  String get vmBinaryName => null;

  @override
  JavaFile get vmExecutable => null;

  @override
  Source fromFileUri(Uri uri) => dartSdk.fromFileUri(uri);

  @override
  JavaFile getDartiumWorkingDirectory(JavaFile installDir) => null;

  @override
  JavaFile getDocFileFor(String libraryName) => null;

  @override
  SdkLibrary getSdkLibrary(String dartUri) => null;

  @override
  LibraryMap initialLibraryMap(bool useDart2jsPaths) => null;

  @override
  Source mapDartUri(String dartUri) => dartSdk.mapDartUri(dartUri);
}

class _OptionsWrapper implements CommandLineOptions {

  final DriverOptions driverOptions;

  _OptionsWrapper(this.driverOptions);

  @override
  String get dartSdkPath => null;

  @override
  Map<String, String> get definedVariables => null;

  @override
  bool get disableHints => false;

  @override
  bool get displayVersion => driverOptions.displayVersion;

  @override
  bool get enableTypeChecks => false;

  @override
  bool get ignoreUnrecognizedFlags => driverOptions.ignoreUnrecognizedFlags;

  @override
  bool get log => driverOptions.log;

  @override
  bool get machineFormat => driverOptions.machineFormat;

  @override
  String get packageRootPath => driverOptions.packageRootPath;

  @override
  bool get perf => false; // driverOptions.perf;

  @override
  bool get shouldBatch => false;

  @override
  bool get showPackageWarnings => driverOptions.showPackageWarnings;

  @override
  bool get showSdkWarnings => driverOptions.showSdkWarnings;

  @override
  List<String> get sourceFiles => [];

  @override
  bool get warmPerf => false; // driverOptions.warmPerf;

  @override
  bool get warningsAreFatal => false;
}
