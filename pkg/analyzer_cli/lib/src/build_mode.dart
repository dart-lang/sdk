// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.src.build_mode;

import 'dart:core' hide Resource;
import 'dart:io' as io;

import 'package:analyzer/dart/ast/ast.dart' show CompilationUnit;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer_cli/src/analyzer_impl.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:bazel_worker/bazel_worker.dart';

/**
 * Persistent Bazel worker.
 */
class AnalyzerWorkerLoop extends SyncWorkerLoop {
  final StringBuffer errorBuffer = new StringBuffer();
  final StringBuffer outBuffer = new StringBuffer();

  final String dartSdkPath;

  AnalyzerWorkerLoop(SyncWorkerConnection connection, {this.dartSdkPath})
      : super(connection: connection);

  factory AnalyzerWorkerLoop.std(
      {io.Stdin stdinStream, io.Stdout stdoutStream, String dartSdkPath}) {
    SyncWorkerConnection connection = new StdSyncWorkerConnection(
        stdinStream: stdinStream, stdoutStream: stdoutStream);
    return new AnalyzerWorkerLoop(connection, dartSdkPath: dartSdkPath);
  }

  /**
   * Performs analysis with given [options].
   */
  void analyze(CommandLineOptions options) {
    new BuildMode(options, new AnalysisStats()).analyze();
    AnalysisEngine.instance.clearCaches();
  }

  /**
   * Perform a single loop step.
   */
  WorkResponse performRequest(WorkRequest request) {
    errorBuffer.clear();
    outBuffer.clear();
    try {
      // Add in the dart-sdk argument if `dartSdkPath` is not null, otherwise it
      // will try to find the currently installed sdk.
      var arguments = new List.from(request.arguments);
      if (dartSdkPath != null &&
          !arguments.any((arg) => arg.startsWith('--dart-sdk'))) {
        arguments.add('--dart-sdk=$dartSdkPath');
      }
      // Prepare options.
      CommandLineOptions options =
          CommandLineOptions.parse(arguments, (String msg) {
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
  void run() {
    errorSink = errorBuffer;
    outSink = outBuffer;
    exitHandler = (int exitCode) {
      return throw new StateError('Exit called: $exitCode');
    };
    super.run();
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
  final CommandLineOptions options;
  final AnalysisStats stats;

  final ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
  SummaryDataStore summaryDataStore;
  InternalAnalysisContext context;
  Map<Uri, JavaFile> uriToFileMap;
  final List<Source> explicitSources = <Source>[];

  PackageBundleAssembler assembler;
  final Set<Source> processedSources = new Set<Source>();
  final Map<Uri, UnlinkedUnit> uriToUnit = <Uri, UnlinkedUnit>{};

  BuildMode(this.options, this.stats);

  /**
   * Perform package analysis according to the given [options].
   */
  ErrorSeverity analyze() {
    // Write initial progress message.
    if (!options.machineFormat) {
      outSink.writeln("Analyzing sources ${options.sourceFiles}...");
    }

    // Create the URI to file map.
    uriToFileMap = _createUriToFileMap(options.sourceFiles);
    if (uriToFileMap == null) {
      io.exitCode = ErrorSeverity.ERROR.ordinal;
      return ErrorSeverity.ERROR;
    }

    // Prepare the analysis context.
    _createContext();

    // Add sources.
    ChangeSet changeSet = new ChangeSet();
    for (Uri uri in uriToFileMap.keys) {
      JavaFile file = uriToFileMap[uri];
      if (!file.exists()) {
        errorSink.writeln('File not found: ${file.getPath()}');
        io.exitCode = ErrorSeverity.ERROR.ordinal;
        return ErrorSeverity.ERROR;
      }
      Source source = new FileBasedSource(file, uri);
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
    assembler = new PackageBundleAssembler(
        excludeHashes: options.buildSummaryExcludeInformative);
    if (options.buildSummaryOutput != null) {
      if (options.buildSummaryOnlyAst && !options.buildSummaryFallback) {
        _serializeAstBasedSummary(explicitSources);
      } else {
        for (Source source in explicitSources) {
          if (context.computeKindOf(source) == SourceKind.LIBRARY) {
            if (options.buildSummaryFallback) {
              assembler.addFallbackLibrary(source);
            } else {
              LibraryElement libraryElement =
                  context.computeLibraryElement(source);
              assembler.serializeLibraryElement(libraryElement);
            }
          }
          if (options.buildSummaryFallback) {
            assembler.addFallbackUnit(source);
          }
        }
      }
      // Write the whole package bundle.
      PackageBundleBuilder sdkBundle = assembler.assemble();
      if (options.buildSummaryExcludeInformative) {
        sdkBundle.flushInformative();
      }
      io.File file = new io.File(options.buildSummaryOutput);
      file.writeAsBytesSync(sdkBundle.toBuffer(), mode: io.FileMode.WRITE_ONLY);
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
          ProcessedSeverity processedSeverity =
              AnalyzerImpl.processError(error, options, context);
          if (processedSeverity != null) {
            maxSeverity = maxSeverity.max(processedSeverity.severity);
          }
        }
      }
    }
    return maxSeverity;
  }

  void _createContext() {
    DirectoryBasedDartSdk sdk =
        new DirectoryBasedDartSdk(new JavaFile(options.dartSdkPath));
    sdk.analysisOptions =
        Driver.createAnalysisOptionsForCommandLineOptions(options);
    sdk.useSummary = !options.buildSummaryOnlyAst;

    // Read the summaries.
    summaryDataStore = new SummaryDataStore(options.buildSummaryInputs);

    // In AST mode include SDK bundle to avoid parsing SDK sources.
    if (options.buildSummaryOnlyAst) {
      summaryDataStore.addBundle(null, sdk.getSummarySdkBundle());
    }

    // Create the context.
    context = AnalysisEngine.instance.createAnalysisContext();
    context.sourceFactory = new SourceFactory(<UriResolver>[
      new DartUriResolver(sdk),
      new InSummaryPackageUriResolver(summaryDataStore),
      new ExplicitSourceResolver(uriToFileMap)
    ]);

    // Set context options.
    Driver.setAnalysisContextOptions(context, options,
        (AnalysisOptionsImpl contextOptions) {
      if (options.buildSummaryOnlyDiet) {
        contextOptions.analyzeFunctionBodies = false;
      }
    });

    if (!options.buildSummaryOnlyAst) {
      // Configure using summaries.
      context.typeProvider = sdk.context.typeProvider;
      context.resultProvider =
          new InputPackagesResultProvider(context, summaryDataStore);
    }
  }

  /**
   * Print errors for all explicit sources.  If [outputPath] is supplied, output
   * is sent to a new file at that path.
   */
  void _printErrors({String outputPath}) {
    StringBuffer buffer = new StringBuffer();
    ErrorFormatter formatter = new ErrorFormatter(
        buffer,
        options,
        stats,
        (AnalysisError error) =>
            AnalyzerImpl.processError(error, options, context));
    for (Source source in explicitSources) {
      AnalysisErrorInfo errorInfo = context.getErrors(source);
      formatter.formatErrors([errorInfo]);
    }
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
  void _serializeAstBasedSummary(List<Source> sources) {
    Set<String> sourceUris =
        sources.map((Source s) => s.uri.toString()).toSet();

    LinkedLibrary _getDependency(String absoluteUri) =>
        summaryDataStore.linkedMap[absoluteUri];

    UnlinkedUnit _getUnit(String absoluteUri) {
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
      return uriToUnit.putIfAbsent(uri, () {
        CompilationUnit unit = context.computeResult(source, PARSED_UNIT);
        UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
        assembler.addUnlinkedUnit(source, unlinkedUnit);
        return unlinkedUnit;
      });
    }

    Map<String, LinkedLibraryBuilder> linkResult =
        link(sourceUris, _getDependency, _getUnit, options.strongMode);
    linkResult.forEach(assembler.addLinkedLibrary);
  }

  /**
   * Convert [sourceEntities] (a list of file specifications of the form
   * "$uri|$path") to a map from URI to path.  If an error occurs, report the
   * error and return null.
   */
  static Map<Uri, JavaFile> _createUriToFileMap(List<String> sourceEntities) {
    Map<Uri, JavaFile> uriToFileMap = <Uri, JavaFile>{};
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
      uriToFileMap[uri] = new JavaFile(path);
    }
    return uriToFileMap;
  }
}
