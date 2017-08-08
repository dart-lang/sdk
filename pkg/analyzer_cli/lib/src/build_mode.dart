// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.src.build_mode;

import 'dart:async';
import 'dart:io' as io;

import 'package:analyzer/dart/ast/ast.dart' show CompilationUnit;
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:analyzer/src/summary/summary_sdk.dart' show SummaryBasedDartSdk;
import 'package:analyzer/task/dart.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:analyzer_cli/src/error_severity.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:bazel_worker/bazel_worker.dart';

/**
 * Persistent Bazel worker.
 */
class AnalyzerWorkerLoop extends AsyncWorkerLoop {
  final StringBuffer errorBuffer = new StringBuffer();
  final StringBuffer outBuffer = new StringBuffer();

  final ResourceProvider resourceProvider;
  final String dartSdkPath;

  AnalyzerWorkerLoop(this.resourceProvider, AsyncWorkerConnection connection,
      {this.dartSdkPath})
      : super(connection: connection);

  factory AnalyzerWorkerLoop.std(ResourceProvider resourceProvider,
      {io.Stdin stdinStream, io.Stdout stdoutStream, String dartSdkPath}) {
    AsyncWorkerConnection connection = new StdAsyncWorkerConnection(
        inputStream: stdinStream, outputStream: stdoutStream);
    return new AnalyzerWorkerLoop(resourceProvider, connection,
        dartSdkPath: dartSdkPath);
  }

  /**
   * Performs analysis with given [options].
   */
  void analyze(CommandLineOptions options) {
    new BuildMode(resourceProvider, options, new AnalysisStats()).analyze();
    AnalysisEngine.instance.clearCaches();
  }

  /**
   * Perform a single loop step.
   */
  @override
  Future<WorkResponse> performRequest(WorkRequest request) async {
    errorBuffer.clear();
    outBuffer.clear();
    try {
      // Add in the dart-sdk argument if `dartSdkPath` is not null, otherwise it
      // will try to find the currently installed sdk.
      var arguments = new List<String>.from(request.arguments);
      if (dartSdkPath != null &&
          !arguments.any((arg) => arg.startsWith('--dart-sdk'))) {
        arguments.add('--dart-sdk=$dartSdkPath');
      }
      // Prepare options.
      CommandLineOptions options =
          CommandLineOptions.parse(arguments, printAndFail: (String msg) {
        throw new ArgumentError(msg);
      });
      // Analyze and respond.
      analyze(options);
      String msg = _getErrorOutputBuffersText();
      return new WorkResponse()
        ..exitCode = EXIT_CODE_OK
        ..output = msg;
    } catch (e, st) {
      String msg = _getErrorOutputBuffersText();
      msg += '$e\n$st';
      return new WorkResponse()
        ..exitCode = EXIT_CODE_ERROR
        ..output = msg;
    }
  }

  /**
   * Run the worker loop.
   */
  @override
  Future<Null> run() async {
    errorSink = errorBuffer;
    outSink = outBuffer;
    exitHandler = (int exitCode) {
      return throw new StateError('Exit called: $exitCode');
    };
    await super.run();
  }

  String _getErrorOutputBuffersText() {
    String msg = '';
    if (errorBuffer.isNotEmpty) {
      msg += errorBuffer.toString() + '\n';
    }
    if (outBuffer.isNotEmpty) {
      msg += outBuffer.toString() + '\n';
    }
    return msg;
  }
}

/**
 * Analyzer used when the "--build-mode" option is supplied.
 */
class BuildMode {
  final ResourceProvider resourceProvider;
  final CommandLineOptions options;
  final AnalysisStats stats;

  SummaryDataStore summaryDataStore;
  InternalAnalysisContext context;
  Map<Uri, File> uriToFileMap;
  final List<Source> explicitSources = <Source>[];
  final List<PackageBundle> unlinkedBundles = <PackageBundle>[];

  PackageBundleAssembler assembler;
  final Set<Source> processedSources = new Set<Source>();
  final Map<Uri, UnlinkedUnit> uriToUnit = <Uri, UnlinkedUnit>{};

  BuildMode(this.resourceProvider, this.options, this.stats);

  bool get _shouldOutputSummary =>
      options.buildSummaryOutput != null ||
      options.buildSummaryOutputSemantic != null;

  /**
   * Perform package analysis according to the given [options].
   */
  ErrorSeverity analyze() {
    // Write initial progress message.
    if (!options.machineFormat) {
      outSink.writeln("Analyzing ${options.sourceFiles.join(', ')}...");
    }

    // Create the URI to file map.
    uriToFileMap = _createUriToFileMap(options.sourceFiles);
    if (uriToFileMap == null) {
      io.exitCode = ErrorSeverity.ERROR.ordinal;
      return ErrorSeverity.ERROR;
    }

    // BuildMode expects sourceFiles in the format "<uri>|<filepath>",
    // but the rest of the code base does not understand this format.
    // Rewrite sourceFiles, stripping the "<uri>|" prefix, so that it
    // does not cause problems with code that does not expect this format.
    options.rewriteSourceFiles(options.sourceFiles
        .map((String uriPipePath) =>
            uriPipePath.substring(uriPipePath.indexOf('|') + 1))
        .toList());

    // Prepare the analysis context.
    try {
      _createContext();
    } on ConflictingSummaryException catch (e) {
      errorSink.writeln('$e');
      io.exitCode = ErrorSeverity.ERROR.ordinal;
      return ErrorSeverity.ERROR;
    }

    // Add sources.
    ChangeSet changeSet = new ChangeSet();
    for (Uri uri in uriToFileMap.keys) {
      File file = uriToFileMap[uri];
      if (!file.exists) {
        errorSink.writeln('File not found: ${file.path}');
        io.exitCode = ErrorSeverity.ERROR.ordinal;
        return ErrorSeverity.ERROR;
      }
      Source source = new FileSource(file, uri);
      explicitSources.add(source);
      changeSet.addedSource(source);
    }
    context.applyChanges(changeSet);

    if (!options.buildSummaryOnly) {
      // Perform full analysis.
      while (true) {
        AnalysisResult analysisResult = context.performAnalysisTask();
        if (!analysisResult.hasMoreWork) {
          break;
        }
      }
    }

    // Write summary.
    assembler = new PackageBundleAssembler();
    if (_shouldOutputSummary) {
      if (options.buildSummaryOnlyUnlinked) {
        for (var src in explicitSources) {
          // Note: This adds the unit to the assembler if it needed to be
          // computed, so we don't need to explicitly do that.
          _unlinkedUnitForUri('${src.uri}');
        }
      } else {
        Set<String> unlinkedUris =
            explicitSources.map((Source s) => s.uri.toString()).toSet();
        for (var bundle in unlinkedBundles) {
          unlinkedUris.addAll(bundle.unlinkedUnitUris);
        }

        _serializeAstBasedSummary(unlinkedUris);
        assembler.recordDependencies(summaryDataStore);
      }
      // Write the whole package bundle.
      PackageBundleBuilder bundle = assembler.assemble();
      if (options.buildSummaryOutput != null) {
        io.File file = new io.File(options.buildSummaryOutput);
        file.writeAsBytesSync(bundle.toBuffer(), mode: io.FileMode.WRITE_ONLY);
      }
      if (options.buildSummaryOutputSemantic != null) {
        bundle.flushInformative();
        io.File file = new io.File(options.buildSummaryOutputSemantic);
        file.writeAsBytesSync(bundle.toBuffer(), mode: io.FileMode.WRITE_ONLY);
      }
    }

    if (options.buildSummaryOnly) {
      return ErrorSeverity.NONE;
    } else {
      // Process errors.
      _printErrors(outputPath: options.buildAnalysisOutput);
      return _computeMaxSeverity();
    }
  }

  ErrorSeverity _computeMaxSeverity() {
    ErrorSeverity maxSeverity = ErrorSeverity.NONE;
    if (!options.buildSuppressExitCode) {
      for (Source source in explicitSources) {
        AnalysisErrorInfo errorInfo = context.getErrors(source);
        for (AnalysisError error in errorInfo.errors) {
          ErrorSeverity processedSeverity = determineProcessedSeverity(
              error, options, context.analysisOptions);
          if (processedSeverity != null) {
            maxSeverity = maxSeverity.max(processedSeverity);
          }
        }
      }
    }
    return maxSeverity;
  }

  void _createContext() {
    // Read the summaries.
    summaryDataStore = new SummaryDataStore(<String>[],
        recordDependencyInfo: _shouldOutputSummary);

    // Adds a bundle at `path` to `summaryDataStore`.
    PackageBundle addBundle(String path) {
      var bundle =
          new PackageBundle.fromBuffer(new io.File(path).readAsBytesSync());
      summaryDataStore.addBundle(path, bundle);
      return bundle;
    }

    for (var path in options.buildSummaryInputs) {
      var bundle = addBundle(path);
      if (bundle.linkedLibraryUris.isEmpty &&
          bundle.unlinkedUnitUris.isNotEmpty) {
        throw new ArgumentError(
            'Got an unlinked summary for --build-summary-input at `$path`. '
            'Unlinked summaries should be provided with the '
            '--build-summary-unlinked-input argument.');
      }
    }

    for (var path in options.buildSummaryUnlinkedInputs) {
      var bundle = addBundle(path);
      unlinkedBundles.add(bundle);
      if (bundle.linkedLibraryUris.isNotEmpty) {
        throw new ArgumentError(
            'Got a linked summary for --build-summary-input-unlinked at `$path`'
            '. Linked bundles should be provided with the '
            '--build-summary-input argument.');
      }
    }

    DartSdk sdk;
    PackageBundle sdkBundle;
    if (options.dartSdkSummaryPath != null) {
      SummaryBasedDartSdk summarySdk = new SummaryBasedDartSdk(
          options.dartSdkSummaryPath, options.strongMode);
      sdk = summarySdk;
      sdkBundle = summarySdk.bundle;
    } else {
      FolderBasedDartSdk dartSdk = new FolderBasedDartSdk(resourceProvider,
          resourceProvider.getFolder(options.dartSdkPath), options.strongMode);
      dartSdk.analysisOptions =
          Driver.createAnalysisOptionsForCommandLineOptions(
              resourceProvider, options);
      dartSdk.useSummary = !options.buildSummaryOnly;
      sdk = dartSdk;
      sdkBundle = dartSdk.getSummarySdkBundle(options.strongMode);
    }

    // Include SDK bundle to avoid parsing SDK sources.
    summaryDataStore.addBundle(null, sdkBundle);

    // Create the context.
    context = AnalysisEngine.instance.createAnalysisContext();
    context.sourceFactory = new SourceFactory(<UriResolver>[
      new DartUriResolver(sdk),
      new InSummaryUriResolver(resourceProvider, summaryDataStore),
      new ExplicitSourceResolver(uriToFileMap)
    ]);

    // Set context options.
    Driver.declareVariables(context.declaredVariables, options);
    AnalysisOptionsImpl analysisOptions = Driver
        .createAnalysisOptionsForCommandLineOptions(resourceProvider, options);
    context.analysisOptions = analysisOptions;

    if (!options.buildSummaryOnly) {
      // Configure using summaries.
      context.typeProvider = sdk.context.typeProvider;
      context.resultProvider =
          new InputPackagesResultProvider(context, summaryDataStore);
    }
  }

  /**
   * Convert [sourceEntities] (a list of file specifications of the form
   * "$uri|$path") to a map from URI to path.  If an error occurs, report the
   * error and return null.
   */
  Map<Uri, File> _createUriToFileMap(List<String> sourceEntities) {
    Map<Uri, File> uriToFileMap = <Uri, File>{};
    for (String sourceFile in sourceEntities) {
      int pipeIndex = sourceFile.indexOf('|');
      if (pipeIndex == -1) {
        // TODO(paulberry): add the ability to guess the URI from the path.
        errorSink.writeln(
            'Illegal input file (must be "\$uri|\$path"): $sourceFile');
        return null;
      }
      Uri uri = Uri.parse(sourceFile.substring(0, pipeIndex));
      String path = sourceFile.substring(pipeIndex + 1);
      uriToFileMap[uri] = resourceProvider.getFile(path);
    }
    return uriToFileMap;
  }

  /**
   * Print errors for all explicit sources.  If [outputPath] is supplied, output
   * is sent to a new file at that path.
   */
  void _printErrors({String outputPath}) {
    StringBuffer buffer = new StringBuffer();
    var severityProcessor = (AnalysisError error) =>
        determineProcessedSeverity(error, options, context.analysisOptions);
    ErrorFormatter formatter = options.machineFormat
        ? new MachineErrorFormatter(buffer, options, stats,
            severityProcessor: severityProcessor)
        : new HumanErrorFormatter(buffer, options, stats,
            severityProcessor: severityProcessor);
    for (Source source in explicitSources) {
      AnalysisErrorInfo errorInfo = context.getErrors(source);
      formatter.formatErrors([errorInfo]);
    }
    formatter.flush();
    if (!options.machineFormat) {
      stats.print(buffer);
    }
    if (outputPath == null) {
      StringSink sink = options.machineFormat ? errorSink : outSink;
      sink.write(buffer);
    } else {
      new io.File(outputPath).writeAsStringSync(buffer.toString());
    }
  }

  /**
   * Serialize the package with the given [sources] into [assembler] using only
   * their ASTs and [LinkedUnit]s of input packages.
   */
  void _serializeAstBasedSummary(Set<String> unlinkedUris) {
    LinkedLibrary _getDependency(String absoluteUri) =>
        summaryDataStore.linkedMap[absoluteUri];

    Map<String, LinkedLibraryBuilder> linkResult = link(
        unlinkedUris,
        _getDependency,
        _unlinkedUnitForUri,
        context.declaredVariables.get,
        options.strongMode);
    linkResult.forEach(assembler.addLinkedLibrary);
  }

  /**
   * Returns the [UnlinkedUnit] for [absoluteUri], either by computing it or
   * using the stored one in [uriToUnit].
   *
   * If the [UnlinkedUnit] needed to be computed, it will also be added to the
   * [assembler].
   */
  UnlinkedUnit _unlinkedUnitForUri(String absoluteUri) {
    // Maybe an input package contains the source.
    {
      UnlinkedUnit unlinkedUnit = summaryDataStore.unlinkedMap[absoluteUri];
      if (unlinkedUnit != null) {
        return unlinkedUnit;
      }
    }
    // Parse the source and serialize its AST.
    Uri uri = Uri.parse(absoluteUri);
    Source source = context.sourceFactory.forUri2(uri);
    if (!source.exists()) {
      // TODO(paulberry): we should report a warning/error because DDC
      // compilations are unlikely to work.
      return null;
    }
    return uriToUnit.putIfAbsent(uri, () {
      CompilationUnit unit = context.computeResult(source, PARSED_UNIT);
      UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
      assembler.addUnlinkedUnit(source, unlinkedUnit);
      return unlinkedUnit;
    });
  }
}

/**
 * Instances of the class [ExplicitSourceResolver] map URIs to files on disk
 * using a fixed mapping provided at construction time.
 */
class ExplicitSourceResolver extends UriResolver {
  final Map<Uri, File> uriToFileMap;
  final Map<String, Uri> pathToUriMap;

  /**
   * Construct an [ExplicitSourceResolver] based on the given [uriToFileMap].
   */
  ExplicitSourceResolver(Map<Uri, File> uriToFileMap)
      : uriToFileMap = uriToFileMap,
        pathToUriMap = _computePathToUriMap(uriToFileMap);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    File file = uriToFileMap[uri];
    actualUri ??= uri;
    if (file == null) {
      return new NonExistingSource(
          uri.toString(), actualUri, UriKind.fromScheme(actualUri.scheme));
    } else {
      return new FileSource(file, actualUri);
    }
  }

  @override
  Uri restoreAbsolute(Source source) {
    return pathToUriMap[source.fullName];
  }

  /**
   * Build the inverse mapping of [uriToSourceMap].
   */
  static Map<String, Uri> _computePathToUriMap(Map<Uri, File> uriToSourceMap) {
    Map<String, Uri> pathToUriMap = <String, Uri>{};
    uriToSourceMap.forEach((Uri uri, File file) {
      pathToUriMap[file.path] = uri;
    });
    return pathToUriMap;
  }
}
