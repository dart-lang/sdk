// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/sdk/build_sdk_summary.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/manifest/manifest_validator.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/source/path_filter.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer/src/utilities/legacy.dart';
import 'package:analyzer_cli/src/analyzer_impl.dart';
import 'package:analyzer_cli/src/batch_mode.dart';
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:analyzer_cli/src/error_severity.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:analyzer_cli/src/perf_report.dart';
import 'package:analyzer_cli/starter.dart' show CommandLineStarter;
import 'package:linter/src/rules.dart' as linter;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Shared IO sink for standard error reporting.
StringSink errorSink = io.stderr;

/// Shared IO sink for standard out reporting.
StringSink outSink = io.stdout;

/// Test this option map to see if it specifies lint rules.
bool containsLintRuleEntry(YamlMap options) {
  var linterNode = options.valueAt('linter');
  return linterNode is YamlMap && linterNode.valueAt('rules') != null;
}

class Driver implements CommandLineStarter {
  static final ByteStore analysisDriverMemoryByteStore = MemoryByteStore();

  bool _isStarted = false;

  late _AnalysisContextProvider _analysisContextProvider;
  DriverBasedAnalysisContext? analysisContext;

  /// The driver that was most recently created by a call to [_analyzeAll].
  @visibleForTesting
  AnalysisDriver? analysisDriver;

  /// The total number of source files loaded by an AnalysisContext.
  int _analyzedFileCount = 0;

  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;

  /// Collected analysis statistics.
  final AnalysisStats stats = AnalysisStats();

  /// The [PathFilter] for excluded files with wildcards, etc.
  late PathFilter pathFilter;

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
  Future<void> start(List<String> arguments) async {
    if (_isStarted) {
      throw StateError('start() can only be called once');
    }
    _isStarted = true;
    var startTime = DateTime.now().millisecondsSinceEpoch;
    noSoundNullSafety = false;

    linter.registerLintRules();

    // Parse commandline options.
    var options = CommandLineOptions.parse(resourceProvider, arguments)!;

    _analysisContextProvider = _AnalysisContextProvider(resourceProvider);

    // Do analysis.
    if (options.batchMode) {
      var batchRunner = BatchRunner(outSink, errorSink);
      batchRunner.runAsBatch(arguments, (List<String> args) async {
        var options = CommandLineOptions.parse(resourceProvider, args)!;
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
        await buildSdkSummary(
          resourceProvider: PhysicalResourceProvider.INSTANCE,
          sdkPath: options.dartSdkPath!,
        );
      }

      print('Done in ${stopwatch.elapsedMilliseconds} ms.');
    }

    if (analysisDriver != null) {
      _analyzedFileCount += analysisDriver!.knownFiles.length;
    }

    if (options.perfReport != null) {
      var json = makePerfReport(
          startTime, currentTimeMillis, options, _analyzedFileCount, stats);
      io.File(options.perfReport!).writeAsStringSync(json);
    }
  }

  /// Perform analysis according to the given [options].
  Future<ErrorSeverity> _analyzeAll(CommandLineOptions options) async {
    if (!options.jsonFormat && !options.machineFormat) {
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
    final analyzedFiles = <FileState>{};
    final partFiles = <FileState>{};

    // Note: This references analysisDriver via closure, so it will change over
    // time during the following analysis.
    SeverityProcessor defaultSeverityProcessor;
    defaultSeverityProcessor = (AnalysisError error) {
      return determineProcessedSeverity(
          error, options, analysisDriver!.analysisOptions);
    };

    // We currently print out to stderr to ensure that when in batch mode we
    // print to stderr, this is because the prints from batch are made to
    // stderr. The reason that options.shouldBatch isn't used is because when
    // the argument flags are constructed in BatchRunner and passed in from
    // batch mode which removes the batch flag to prevent the "cannot have the
    // batch flag and source file" error message.
    ErrorFormatter formatter;
    if (options.jsonFormat) {
      formatter = JsonErrorFormatter(outSink, options, stats,
          severityProcessor: defaultSeverityProcessor);
    } else if (options.machineFormat) {
      // The older machine format emits to stderr (instead of stdout) for legacy
      // reasons.
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
      final analysisDriver =
          this.analysisDriver = _analysisContextProvider.analysisDriver;
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
            file.createSource(),
            content,
            analysisDriver.sourceFactory,
            analysisDriver.currentSession.analysisContext.contextRoot.root.path,
            analysisDriver.analysisOptions.sdkVersionConstraint,
          );
          await formatter.formatErrors([
            ErrorsResultImpl(
              session: analysisDriver.currentSession,
              file: file,
              uri: pathContext.toUri(path),
              lineInfo: lineInfo,
              isAugmentation: false,
              isLibrary: true,
              isPart: false,
              errors: errors,
            )
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
            var node = loadYamlNode(content, sourceUrl: file.toUri());

            if (node is YamlMap) {
              errors.addAll(validatePubspec(
                contents: node,
                source: file.createSource(),
                provider: resourceProvider,
                analysisOptions: analysisDriver
                    .currentSession.analysisContext.analysisOptions,
              ));
            }
            if (errors.isNotEmpty) {
              for (var error in errors) {
                var severity = determineProcessedSeverity(
                    error, options, analysisDriver.analysisOptions)!;
                allResult = allResult.max(severity);
              }
              var lineInfo = LineInfo.fromContent(content);
              await formatter.formatErrors([
                ErrorsResultImpl(
                  session: analysisDriver.currentSession,
                  file: file,
                  uri: pathContext.toUri(path),
                  lineInfo: lineInfo,
                  isAugmentation: false,
                  isLibrary: true,
                  isPart: false,
                  errors: errors,
                ),
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
            await formatter.formatErrors([
              ErrorsResultImpl(
                session: analysisDriver.currentSession,
                file: file,
                uri: pathContext.toUri(path),
                lineInfo: lineInfo,
                isAugmentation: false,
                isLibrary: true,
                isPart: false,
                errors: errors,
              ),
            ]);
            for (var error in errors) {
              var severity = determineProcessedSeverity(
                  error, options, analysisDriver.analysisOptions)!;
              allResult = allResult.max(severity);
            }
          } catch (exception) {
            // If the file cannot be analyzed, ignore it.
          }
        } else {
          dartFiles.add(path);
          var file = analysisDriver.fsState.getFileForPath(path);

          final kind = file.kind;
          if (kind is LibraryFileKind) {
            var status = await _runAnalyzer(file, options, formatter);
            allResult = allResult.max(status);
            analyzedFiles.addAll(kind.files);
          } else if (kind is PartFileKind) {
            partFiles.add(file);
          }
        }
      }
    }

    // We are done analyzing this batch of files.
    // The next batch should not be affected by a previous batch.
    // E.g. the same parts in both batches, but with different libraries.
    for (var path in dartFiles) {
      analysisDriver!.removeFile(path);
    }

    // Any dangling parts still in this list were definitely dangling.
    for (var partFile in partFiles) {
      if (!analyzedFiles.contains(partFile)) {
        reportPartError(partFile.path);
      }
    }

    formatter.flush();

    if (!options.machineFormat && !options.jsonFormat) {
      stats.print(outSink);
    }

    return allResult;
  }

  /// Collect all analyzable files at [filePath], recursively if it's a
  /// directory, ignoring links.
  Iterable<io.File> _collectFiles(String filePath, AnalysisOptions options) {
    var files = <io.File>[];
    var file = io.File(filePath);
    if (file.existsSync()) {
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
    final analysisDriver = this.analysisDriver!;
    var analyzer = AnalyzerImpl(analysisDriver.analysisOptions, analysisDriver,
        file, options, stats, startTime);
    return analyzer.analyze(formatter);
  }

  bool _shouldBeFatal(ErrorSeverity severity, CommandLineOptions options) {
    if (severity == ErrorSeverity.ERROR) {
      return true;
    } else {
      return false;
    }
  }

  void _verifyAnalysisOptionsFileExists(CommandLineOptions options) {
    var path = options.defaultAnalysisOptionsPath;
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
      CommandLineOptions? previous, CommandLineOptions newOptions) {
    return previous != null &&
        newOptions.defaultPackagesPath == previous.defaultPackagesPath &&
        _equalMaps(newOptions.declaredVariables, previous.declaredVariables) &&
        newOptions.log == previous.log &&
        newOptions.defaultLanguageVersion == previous.defaultLanguageVersion &&
        newOptions.disableCacheFlushing == previous.disableCacheFlushing &&
        _equalLists(
            newOptions.enabledExperiments!, previous.enabledExperiments!);
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
  final FileContentCache _fileContentCache;

  CommandLineOptions? _commandLineOptions;
  late List<String> _pathList;

  final Map<Folder, DriverBasedAnalysisContext?> _folderContexts = {};
  AnalysisContextCollectionImpl? _collection;
  DriverBasedAnalysisContext? _analysisContext;

  _AnalysisContextProvider(this._resourceProvider)
      : _fileContentCache = FileContentCache(_resourceProvider);

  DriverBasedAnalysisContext? get analysisContext {
    return _analysisContext;
  }

  AnalysisDriver get analysisDriver {
    return _analysisContext!.driver;
  }

  /// TODO(scheglov) Use analyzedFiles()
  PathFilter get pathFilter {
    var contextRoot = analysisContext!.contextRoot;
    var optionsFile = contextRoot.optionsFile;

    // If there is no options file, there can be no excludes.
    if (optionsFile == null) {
      return PathFilter(contextRoot.root.path, contextRoot.root.path, []);
    }

    // Exclude patterns are relative to the directory with the options file.
    return PathFilter(contextRoot.root.path, optionsFile.parent.path,
        analysisContext!.analysisOptions.excludePatterns);
  }

  void configureForPath(String path) {
    var folder = _resourceProvider.getFolder(path);
    if (!folder.exists) {
      folder = _resourceProvider.getFile(path).parent;
    }

    // In batch mode we are given separate file paths to analyze.
    // All files of a folder have the same configuration.
    // So, reuse the corresponding analysis context.
    _analysisContext = _folderContexts[folder];
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
      optionsFile: _commandLineOptions!.defaultAnalysisOptionsPath,
      packagesFile: _commandLineOptions!.defaultPackagesPath,
      resourceProvider: _resourceProvider,
      sdkPath: _commandLineOptions!.dartSdkPath,
      updateAnalysisOptions2: _updateAnalysisOptions,
      fileContentCache: _fileContentCache,
    );

    _setContextForPath(path);
    _folderContexts[folder] = _analysisContext;
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
    _analysisContext = _collection!.contextFor(path);
  }

  void _updateAnalysisOptions({
    required AnalysisOptionsImpl analysisOptions,
    required ContextRoot contextRoot,
    required DartSdk sdk,
  }) {
    _commandLineOptions!.updateAnalysisOptions(analysisOptions);
  }
}
