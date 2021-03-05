// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;
import 'dart:isolate';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/sdk/build_sdk_summary.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/command_line/arguments.dart'
    show applyAnalysisOptionFlags;
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/interner.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/pub.dart';
import 'package:analyzer/src/manifest/manifest_validator.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/source/path_filter.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer_cli/src/analyzer_impl.dart';
import 'package:analyzer_cli/src/batch_mode.dart';
import 'package:analyzer_cli/src/build_mode.dart';
import 'package:analyzer_cli/src/context_cache.dart';
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:analyzer_cli/src/error_severity.dart';
import 'package:analyzer_cli/src/has_context_mixin.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:analyzer_cli/src/perf_report.dart';
import 'package:analyzer_cli/starter.dart' show CommandLineStarter;
import 'package:linter/src/rules.dart' as linter;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// Shared IO sink for standard error reporting.
StringSink errorSink = io.stderr;

/// Shared IO sink for standard out reporting.
StringSink outSink = io.stdout;

/// Test this option map to see if it specifies lint rules.
bool containsLintRuleEntry(YamlMap options) {
  var linterNode = getValue(options, 'linter');
  return linterNode is YamlMap && getValue(linterNode, 'rules') != null;
}

class Driver with HasContextMixin implements CommandLineStarter {
  static final ByteStore analysisDriverMemoryByteStore = MemoryByteStore();

  @override
  ContextCache contextCache;

  _AnalysisContextProvider _analysisContextProvider;
  DriverBasedAnalysisContext analysisContext;

  /// The driver that was most recently created by a call to [_analyzeAll], or
  /// `null` if [_analyzeAll] hasn't been called yet.
  @visibleForTesting
  AnalysisDriver analysisDriver;

  /// The total number of source files loaded by an AnalysisContext.
  int _analyzedFileCount = 0;

  /// The resource provider used to access the file system.
  @override
  final ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;

  /// Collected analysis statistics.
  final AnalysisStats stats = AnalysisStats();

  /// The [PathFilter] for excluded files with wildcards, etc.
  PathFilter pathFilter;

  /// Create a new Driver instance.
  Driver({@Deprecated('This parameter has no effect') bool isTesting = false});

  /// Converts the given [filePath] into absolute and normalized.
  String normalizePath(String filePath) {
    filePath = filePath.trim();
    filePath = resourceProvider.pathContext.absolute(filePath);
    filePath = resourceProvider.pathContext.normalize(filePath);
    return filePath;
  }

  @override
  Future<void> start(List<String> args, {SendPort sendPort}) async {
    if (analysisDriver != null) {
      throw StateError('start() can only be called once');
    }
    var startTime = DateTime.now().millisecondsSinceEpoch;

    StringUtilities.INTERNER = MappedInterner();

    linter.registerLintRules();

    // Parse commandline options.
    var options = CommandLineOptions.parse(resourceProvider, args);

    _analysisContextProvider = _AnalysisContextProvider(resourceProvider);

    // Do analysis.
    if (options.buildMode) {
      var severity = await _buildModeAnalyze(options, sendPort);
      // Propagate issues to the exit code.
      if (_shouldBeFatal(severity, options)) {
        io.exitCode = severity.ordinal;
      }
    } else if (options.batchMode) {
      var batchRunner = BatchRunner(outSink, errorSink);
      batchRunner.runAsBatch(args, (List<String> args) async {
        var options = CommandLineOptions.parse(resourceProvider, args);
        return await _analyzeAll(options);
      });
    } else {
      var severity = await _analyzeAll(options);
      // Propagate issues to the exit code.
      if (_shouldBeFatal(severity, options)) {
        io.exitCode = severity.ordinal;
      }
    }

    // When training a snapshot, in addition to training regular analysis
    // (above), we train build mode as well.
    if (options.trainSnapshot) {
      // TODO(devoncarew): Iterate on this training to make it more
      // representative of what we see internally; call into _buildModeAnalyze()
      // with some appropriate options.
      print('\nGenerating strong mode summary...');
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 3; i++) {
        buildSdkSummary(
          resourceProvider: PhysicalResourceProvider.INSTANCE,
          sdkPath: options.dartSdkPath,
        );
      }

      print('Done in ${stopwatch.elapsedMilliseconds} ms.');
    }

    if (analysisDriver != null) {
      _analyzedFileCount += analysisDriver.knownFiles.length;
    }

    if (options.perfReport != null) {
      var json = makePerfReport(
          startTime, currentTimeMillis, options, _analyzedFileCount, stats);
      io.File(options.perfReport).writeAsStringSync(json);
    }
  }

  /// Perform analysis according to the given [options].
  Future<ErrorSeverity> _analyzeAll(CommandLineOptions options) async {
    if (!options.machineFormat) {
      var fileNames = options.sourceFiles.map((String file) {
        file = path.normalize(file);
        if (file == '.') {
          file = path.basename(path.current);
        } else if (file == '..') {
          file = path.basename(path.normalize(path.absolute(file)));
        }
        return file;
      }).toList();

      outSink.writeln("Analyzing ${fileNames.join(', ')}...");
    }

    _verifyAnalysisOptionsFileExists(options);

    // These are used to do part file analysis across sources.
    var dartFiles = <String>{};
    var libraryFiles = <FileState>{};
    var danglingParts = <FileState>{};

    // Note: This references analysisDriver via closure, so it will change over
    // time during the following analysis.
    var defaultSeverityProcessor = (AnalysisError error) {
      return determineProcessedSeverity(
          error, options, analysisDriver.analysisOptions);
    };

    // We currently print out to stderr to ensure that when in batch mode we
    // print to stderr, this is because the prints from batch are made to
    // stderr. The reason that options.shouldBatch isn't used is because when
    // the argument flags are constructed in BatchRunner and passed in from
    // batch mode which removes the batch flag to prevent the "cannot have the
    // batch flag and source file" error message.
    ErrorFormatter formatter;
    if (options.machineFormat) {
      formatter = MachineErrorFormatter(errorSink, options, stats,
          severityProcessor: defaultSeverityProcessor);
    } else {
      formatter = HumanErrorFormatter(outSink, options, stats,
          severityProcessor: defaultSeverityProcessor);
    }

    var allResult = ErrorSeverity.NONE;

    void reportPartError(String partPath) {
      errorSink.writeln('$partPath is a part and cannot be analyzed.');
      errorSink.writeln('Please pass in a library that contains this part.');
      io.exitCode = ErrorSeverity.ERROR.ordinal;
      allResult = allResult.max(ErrorSeverity.ERROR);
    }

    var pathList = options.sourceFiles.map(normalizePath).toList();
    _analysisContextProvider.setCommandLineOptions(options, pathList);

    for (var sourcePath in pathList) {
      _analysisContextProvider.configureForPath(sourcePath);
      analysisContext = _analysisContextProvider.analysisContext;
      analysisDriver = _analysisContextProvider.analysisDriver;
      pathFilter = _analysisContextProvider.pathFilter;

      // Add all the files to be analyzed en masse to the context. Skip any
      // files that were added earlier (whether explicitly or implicitly) to
      // avoid causing those files to be unnecessarily re-read.
      var filesToAnalyze = <String>{};

      // Collect files for analysis.
      // Note that these files will all be analyzed in the same context.
      // This should be updated when the ContextManager re-work is complete
      // (See: https://github.com/dart-lang/sdk/issues/24133)
      var files = _collectFiles(sourcePath, analysisDriver.analysisOptions);
      if (files.isEmpty) {
        errorSink.writeln('No dart files found at: $sourcePath');
        io.exitCode = ErrorSeverity.ERROR.ordinal;
        return ErrorSeverity.ERROR;
      }

      for (var file in files) {
        filesToAnalyze.add(file.absolute.path);
      }

      // Analyze the libraries.
      var pathContext = resourceProvider.pathContext;
      for (var path in filesToAnalyze) {
        if (file_paths.isAnalysisOptionsYaml(pathContext, path)) {
          var file = resourceProvider.getFile(path);
          var content = file.readAsStringSync();
          var lineInfo = LineInfo.fromContent(content);
          var errors = analyzeAnalysisOptions(
              file.createSource(), content, analysisDriver.sourceFactory);
          formatter.formatErrors([
            ErrorsResultImpl(analysisDriver.currentSession, path, null,
                lineInfo, false, errors)
          ]);
          for (var error in errors) {
            var severity = determineProcessedSeverity(
                error, options, analysisDriver.analysisOptions);
            if (severity != null) {
              allResult = allResult.max(severity);
            }
          }
        } else if (file_paths.isPubspecYaml(pathContext, path)) {
          var errors = <AnalysisError>[];
          try {
            var file = resourceProvider.getFile(path);
            var content = file.readAsStringSync();
            var node = loadYamlNode(content);
            if (node is YamlMap) {
              var validator =
                  PubspecValidator(resourceProvider, file.createSource());
              errors.addAll(validator.validate(node.nodes));
            }

            if (analysisDriver != null && analysisDriver.analysisOptions.lint) {
              var visitors = <LintRule, PubspecVisitor>{};
              for (var linter in analysisDriver.analysisOptions.lintRules) {
                if (linter is LintRule) {
                  var visitor = linter.getPubspecVisitor();
                  if (visitor != null) {
                    visitors[linter] = visitor;
                  }
                }
              }
              if (visitors.isNotEmpty) {
                var sourceUri = pathContext.toUri(path);
                var pubspecAst = Pubspec.parse(content,
                    sourceUrl: sourceUri, resourceProvider: resourceProvider);
                var listener = RecordingErrorListener();
                var reporter = ErrorReporter(listener,
                    resourceProvider.getFile(path).createSource(sourceUri),
                    isNonNullableByDefault: false);
                for (var entry in visitors.entries) {
                  entry.key.reporter = reporter;
                  pubspecAst.accept(entry.value);
                }
                errors.addAll(listener.errors);
              }
            }

            if (errors.isNotEmpty) {
              for (var error in errors) {
                var severity = determineProcessedSeverity(
                    error, options, analysisDriver.analysisOptions);
                allResult = allResult.max(severity);
              }
              var lineInfo = LineInfo.fromContent(content);
              formatter.formatErrors([
                ErrorsResultImpl(analysisDriver.currentSession, path, null,
                    lineInfo, false, errors)
              ]);
            }
          } catch (exception) {
            // If the file cannot be analyzed, ignore it.
          }
        } else if (file_paths.isAndroidManifestXml(pathContext, path)) {
          try {
            var file = resourceProvider.getFile(path);
            var content = file.readAsStringSync();
            var validator = ManifestValidator(file.createSource());
            var lineInfo = LineInfo.fromContent(content);
            var errors = validator.validate(
                content, analysisDriver.analysisOptions.chromeOsManifestChecks);
            formatter.formatErrors([
              ErrorsResultImpl(analysisDriver.currentSession, path, null,
                  lineInfo, false, errors)
            ]);
            for (var error in errors) {
              var severity = determineProcessedSeverity(
                  error, options, analysisDriver.analysisOptions);
              allResult = allResult.max(severity);
            }
          } catch (exception) {
            // If the file cannot be analyzed, ignore it.
          }
        } else {
          dartFiles.add(path);
          var file = analysisDriver.fsState.getFileForPath(path);

          if (file.isPart) {
            if (!libraryFiles.contains(file.library)) {
              danglingParts.add(file);
            }
            continue;
          }
          libraryFiles.add(file);

          var status = await _runAnalyzer(file, options, formatter);
          allResult = allResult.max(status);

          // Mark previously dangling parts as no longer dangling.
          for (var part in file.partedFiles) {
            danglingParts.remove(part);
          }
        }
      }
    }

    // We are done analyzing this batch of files.
    // The next batch should not be affected by a previous batch.
    // E.g. the same parts in both batches, but with different libraries.
    for (var path in dartFiles) {
      analysisDriver.removeFile(path);
    }

    // Any dangling parts still in this list were definitely dangling.
    for (var partFile in danglingParts) {
      reportPartError(partFile.path);
    }

    formatter.flush();

    if (!options.machineFormat) {
      stats.print(outSink);
    }

    return allResult;
  }

  /// Perform analysis in build mode according to the given [options].
  ///
  /// If [sendPort] is provided it is used for bazel worker communication
  /// instead of stdin/stdout.
  Future<ErrorSeverity> _buildModeAnalyze(
      CommandLineOptions options, SendPort sendPort) async {
    if (options.buildModePersistentWorker) {
      var workerLoop = sendPort == null
          ? AnalyzerWorkerLoop.std(resourceProvider,
              dartSdkPath: options.dartSdkPath)
          : AnalyzerWorkerLoop.sendPort(resourceProvider, sendPort,
              dartSdkPath: options.dartSdkPath);
      await workerLoop.run();
      return ErrorSeverity.NONE;
    } else {
      return await BuildMode(resourceProvider, options, stats,
              ContextCache(resourceProvider, options, verbosePrint))
          .analyze();
    }
  }

  /// Collect all analyzable files at [filePath], recursively if it's a
  /// directory, ignoring links.
  Iterable<io.File> _collectFiles(String filePath, AnalysisOptions options) {
    var files = <io.File>[];
    var file = io.File(filePath);
    if (file.existsSync() && !pathFilter.ignored(filePath)) {
      files.add(file);
    } else {
      var directory = io.Directory(filePath);
      if (directory.existsSync()) {
        var pathContext = resourceProvider.pathContext;
        for (var entry
            in directory.listSync(recursive: true, followLinks: false)) {
          var relative = path.relative(entry.path, from: directory.path);
          if ((file_paths.isDart(pathContext, entry.path) ||
                  file_paths.isAndroidManifestXml(pathContext, entry.path)) &&
              entry is io.File &&
              !pathFilter.ignored(entry.path) &&
              !_isInHiddenDir(relative)) {
            files.add(entry);
          }
        }
      }
    }
    return files;
  }

  /// Returns `true` if this relative path is a hidden directory.
  bool _isInHiddenDir(String relative) =>
      path.split(relative).any((part) => part.startsWith('.'));

  /// Analyze a single source.
  Future<ErrorSeverity> _runAnalyzer(
      FileState file, CommandLineOptions options, ErrorFormatter formatter) {
    var startTime = currentTimeMillis;
    var analyzer = AnalyzerImpl(analysisDriver.analysisOptions, analysisDriver,
        file, options, stats, startTime);
    return analyzer.analyze(formatter);
  }

  bool _shouldBeFatal(ErrorSeverity severity, CommandLineOptions options) {
    if (severity == ErrorSeverity.ERROR) {
      return true;
    } else if (severity == ErrorSeverity.WARNING &&
        (options.warningsAreFatal || options.infosAreFatal)) {
      return true;
    } else if (severity == ErrorSeverity.INFO && options.infosAreFatal) {
      return true;
    } else {
      return false;
    }
  }

  void _verifyAnalysisOptionsFileExists(CommandLineOptions options) {
    var path = options.analysisOptionsFile;
    if (path != null) {
      if (!resourceProvider.getFile(path).exists) {
        printAndFail('Options file not found: $path',
            exitCode: ErrorSeverity.ERROR.ordinal);
      }
    }
  }

  static void verbosePrint(String text) {
    outSink.writeln(text);
  }

  /// Return whether the [newOptions] are equal to the [previous].
  static bool _equalCommandLineOptions(
      CommandLineOptions previous, CommandLineOptions newOptions) {
    return previous != null &&
        newOptions != null &&
        newOptions.packageConfigPath == previous.packageConfigPath &&
        _equalMaps(newOptions.definedVariables, previous.definedVariables) &&
        newOptions.log == previous.log &&
        newOptions.disableHints == previous.disableHints &&
        newOptions.showPackageWarnings == previous.showPackageWarnings &&
        newOptions.showPackageWarningsPrefix ==
            previous.showPackageWarningsPrefix &&
        newOptions.showSdkWarnings == previous.showSdkWarnings &&
        newOptions.lints == previous.lints &&
        _equalLists(
            newOptions.buildSummaryInputs, previous.buildSummaryInputs) &&
        newOptions.defaultLanguageVersion == previous.defaultLanguageVersion &&
        newOptions.disableCacheFlushing == previous.disableCacheFlushing &&
        _equalLists(newOptions.enabledExperiments, previous.enabledExperiments);
  }

  /// Perform a deep comparison of two string lists.
  static bool _equalLists(List<String> l1, List<String> l2) {
    if (l1.length != l2.length) {
      return false;
    }
    for (var i = 0; i < l1.length; i++) {
      if (l1[i] != l2[i]) {
        return false;
      }
    }
    return true;
  }

  /// Perform a deep comparison of two string maps.
  static bool _equalMaps(Map<String, String> m1, Map<String, String> m2) {
    if (m1.length != m2.length) {
      return false;
    }
    for (var key in m1.keys) {
      if (!m2.containsKey(key) || m1[key] != m2[key]) {
        return false;
      }
    }
    return true;
  }
}

class _AnalysisContextProvider {
  final ResourceProvider _resourceProvider;

  CommandLineOptions _commandLineOptions;
  List<String> _pathList;

  final Map<Folder, DriverBasedAnalysisContext> _folderContexts = {};
  AnalysisContextCollectionImpl _collection;
  DriverBasedAnalysisContext _analysisContext;

  _AnalysisContextProvider(this._resourceProvider);

  DriverBasedAnalysisContext get analysisContext {
    return _analysisContext;
  }

  AnalysisDriver get analysisDriver {
    return _analysisContext.driver;
  }

  /// TODO(scheglov) Use analyzedFiles()
  PathFilter get pathFilter {
    return PathFilter(analysisContext.contextRoot.root.path,
        analysisContext.analysisOptions.excludePatterns);
  }

  void configureForPath(String path) {
    var parentFolder = _resourceProvider.getFile(path).parent2;

    // In batch mode we are given separate file paths to analyze.
    // All files of a folder have the same configuration.
    // So, reuse the corresponding analysis context.
    _analysisContext = _folderContexts[parentFolder];
    if (_analysisContext != null) {
      return;
    }

    if (_collection != null) {
      try {
        _setContextForPath(path);
        return;
      } on StateError {
        // The previous collection cannot analyze the path.
        _collection = null;
      }
    }

    _collection = AnalysisContextCollectionImpl(
      byteStore: Driver.analysisDriverMemoryByteStore,
      includedPaths: _pathList,
      optionsFile: _commandLineOptions.analysisOptionsFile,
      packagesFile: _commandLineOptions.packageConfigPath,
      resourceProvider: _resourceProvider,
      sdkPath: _commandLineOptions.dartSdkPath,
      updateAnalysisOptions: _updateAnalysisOptions,
    );

    _setContextForPath(path);
    _folderContexts[parentFolder] = _analysisContext;
  }

  void setCommandLineOptions(
    CommandLineOptions options,
    List<String> pathList,
  ) {
    if (!Driver._equalCommandLineOptions(_commandLineOptions, options)) {
      _folderContexts.clear();
      _collection = null;
      _analysisContext = null;
    }
    _commandLineOptions = options;
    _pathList = pathList;
  }

  void _setContextForPath(String path) {
    var analysisContext = _collection.contextFor(path);
    _analysisContext = analysisContext as DriverBasedAnalysisContext;
  }

  void _updateAnalysisOptions(AnalysisOptionsImpl analysisOptions) {
    var args = _commandLineOptions.contextBuilderOptions.argResults;
    applyAnalysisOptionFlags(analysisOptions, args);

    var defaultLanguageVersion = _commandLineOptions.defaultLanguageVersion;
    if (defaultLanguageVersion != null) {
      var nonPackageLanguageVersion =
          Version.parse('$defaultLanguageVersion.0');
      analysisOptions.nonPackageLanguageVersion = nonPackageLanguageVersion;
      analysisOptions.nonPackageFeatureSet = FeatureSet.latestLanguageVersion()
          .restrictToVersion(nonPackageLanguageVersion);
    }
  }
}
