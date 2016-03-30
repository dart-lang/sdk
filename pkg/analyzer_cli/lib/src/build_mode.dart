// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.src.build_mode;

import 'dart:convert';
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
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/prelink.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer_cli/src/analyzer_impl.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:analyzer_cli/src/options.dart';

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

  PackageBundleAssembler assembler = new PackageBundleAssembler();
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
    if (options.buildSummaryOutput != null) {
      for (Source source in explicitSources) {
        if (context.computeKindOf(source) == SourceKind.LIBRARY) {
          if (options.buildSummaryFallback) {
            assembler.addFallbackLibrary(source);
          } else if (options.buildSummaryOnlyAst) {
            _serializeAstBasedSummary(source);
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
      // Write the whole package bundle.
      PackageBundleBuilder sdkBundle = assembler.assemble();
      if (options.buildSummaryExcludeInformative) {
        sdkBundle.flushInformative();
        sdkBundle.unlinkedUnitHashes = null;
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
    sdk.useSummary = true;

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

    // Configure using summaries.
    context.typeProvider = sdk.context.typeProvider;
    context.resultProvider =
        new InputPackagesResultProvider(context, summaryDataStore);
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
   * Serialize the library with the given [source] into [assembler] using only
   * its AST, [UnlinkedUnit]s of input packages and ASTs (via [UnlinkedUnit]s)
   * of package sources.
   */
  void _serializeAstBasedSummary(Source source) {
    Source resolveRelativeUri(String relativeUri) {
      Source resolvedSource =
          context.sourceFactory.resolveUri(source, relativeUri);
      if (resolvedSource == null) {
        context.sourceFactory.resolveUri(source, relativeUri);
        throw new StateError('Could not resolve $relativeUri in the context of '
            '$source (${source.runtimeType})');
      }
      return resolvedSource;
    }

    UnlinkedUnit _getUnlinkedUnit(Source source) {
      // Maybe an input package contains the source.
      {
        String uriStr = source.uri.toString();
        UnlinkedUnit unlinkedUnit = summaryDataStore.unlinkedMap[uriStr];
        if (unlinkedUnit != null) {
          return unlinkedUnit;
        }
      }
      // Parse the source and serialize its AST.
      return uriToUnit.putIfAbsent(source.uri, () {
        CompilationUnit unit = context.computeResult(source, PARSED_UNIT);
        UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
        assembler.addUnlinkedUnit(source, unlinkedUnit);
        return unlinkedUnit;
      });
    }

    UnlinkedUnit getPart(String relativeUri) {
      return _getUnlinkedUnit(resolveRelativeUri(relativeUri));
    }

    UnlinkedPublicNamespace getImport(String relativeUri) {
      return getPart(relativeUri).publicNamespace;
    }

    UnlinkedUnitBuilder definingUnit = _getUnlinkedUnit(source);
    LinkedLibraryBuilder linkedLibrary =
        prelink(definingUnit, getPart, getImport);
    assembler.addLinkedLibrary(source.uri.toString(), linkedLibrary);
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

/**
 * Interface that every worker related data object has.
 */
abstract class WorkDataObject {
  /**
   * Translate the data in this class into a JSON map.
   */
  Map<String, Object> toJson();
}

/**
 * Connection between a worker and input / output.
 */
abstract class WorkerConnection {
  /**
   * Read a new line. Block until a line is read. Return `null` if EOF.
   */
  String readLineSync();

  /**
   * Write the given [json] as a new line to the output.
   */
  void writeJson(Map<String, Object> json);
}

/**
 * Persistent Bazel worker.
 */
class WorkerLoop {
  static const int EXIT_CODE_OK = 0;
  static const int EXIT_CODE_ERROR = 15;

  final WorkerConnection connection;

  final StringBuffer errorBuffer = new StringBuffer();
  final StringBuffer outBuffer = new StringBuffer();

  WorkerLoop(this.connection);

  factory WorkerLoop.std() {
    WorkerConnection connection = new _StdWorkerConnection();
    return new WorkerLoop(connection);
  }

  /**
   * Performs analysis with given [options].
   */
  void analyze(CommandLineOptions options) {
    new BuildMode(options, new AnalysisStats()).analyze();
  }

  /**
   * Perform a single loop step.  Return `true` if should exit the loop.
   */
  bool performSingle() {
    try {
      WorkRequest request = _readRequest();
      if (request == null) {
        return true;
      }
      // Prepare options.
      CommandLineOptions options =
          CommandLineOptions.parse(request.arguments, (String msg) {
        throw new ArgumentError(msg);
      });
      // Analyze and respond.
      analyze(options);
      String msg = _getErrorOutputBuffersText();
      _writeResponse(new WorkResponse(EXIT_CODE_OK, msg));
    } catch (e, st) {
      String msg = _getErrorOutputBuffersText();
      msg += '$e \n $st';
      _writeResponse(new WorkResponse(EXIT_CODE_ERROR, msg));
    }
    return false;
  }

  /**
   * Run the worker loop.
   */
  void run() {
    errorSink = errorBuffer;
    outSink = outBuffer;
    exitHandler = (int exitCode) {
      return throw new StateError('Exit called: $exitCode');
    };
    while (true) {
      errorBuffer.clear();
      outBuffer.clear();
      bool shouldExit = performSingle();
      if (shouldExit) {
        break;
      }
    }
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

  /**
   * Read a new [WorkRequest]. Return `null` if EOF.
   * Throw [ArgumentError] if cannot be parsed.
   */
  WorkRequest _readRequest() {
    String line = connection.readLineSync();
    if (line == null) {
      return null;
    }
    Object json = JSON.decode(line);
    if (json is Map) {
      return new WorkRequest.fromJson(json);
    } else {
      throw new ArgumentError('The request line is not a  JSON object: $line');
    }
  }

  void _writeResponse(WorkResponse response) {
    Map<String, Object> json = response.toJson();
    connection.writeJson(json);
  }
}

/**
 * Input file.
 */
class WorkInput implements WorkDataObject {
  final String path;
  final List<int> digest;

  WorkInput(this.path, this.digest);

  factory WorkInput.fromJson(Map<String, Object> json) {
    // Parse path.
    Object path2 = json['path'];
    if (path2 == null) {
      throw new ArgumentError('The field "path" is missing.');
    }
    if (path2 is! String) {
      throw new ArgumentError('The field "path" must be a string.');
    }
    // Parse digest.
    List<int> digest = const <int>[];
    {
      Object digestJson = json['digest'];
      if (digestJson != null) {
        if (digestJson is List && digestJson.every((e) => e is int)) {
          digest = digestJson;
        } else {
          throw new ArgumentError(
              'The field "digest" should be a list of int.');
        }
      }
    }
    // OK
    return new WorkInput(path2, digest);
  }

  @override
  Map<String, Object> toJson() {
    Map<String, Object> json = <String, Object>{};
    if (path != null) {
      json['path'] = path;
    }
    if (digest != null) {
      json['digest'] = digest;
    }
    return json;
  }
}

/**
 * Single work unit that Bazel sends to the worker.
 */
class WorkRequest implements WorkDataObject {
  /**
   * Command line arguments for this request.
   */
  final List<String> arguments;

  /**
   * Input files that the worker is allowed to read during execution of this
   * request.
   */
  final List<WorkInput> inputs;

  WorkRequest(this.arguments, this.inputs);

  factory WorkRequest.fromJson(Map<String, Object> json) {
    // Parse arguments.
    List<String> arguments = const <String>[];
    {
      Object argumentsJson = json['arguments'];
      if (argumentsJson != null) {
        if (argumentsJson is List && argumentsJson.every((e) => e is String)) {
          arguments = argumentsJson;
        } else {
          throw new ArgumentError(
              'The field "arguments" should be a list of strings.');
        }
      }
    }
    // Parse inputs.
    List<WorkInput> inputs = const <WorkInput>[];
    {
      Object inputsJson = json['inputs'];
      if (inputsJson != null) {
        if (inputsJson is List &&
            inputsJson.every((e) {
              return e is Map && e.keys.every((key) => key is String);
            })) {
          inputs = inputsJson
              .map((Map input) => new WorkInput.fromJson(input))
              .toList();
        } else {
          throw new ArgumentError(
              'The field "inputs" should be a list of objects.');
        }
      }
    }
    // No inputs.
    if (arguments.isEmpty && inputs.isEmpty) {
      throw new ArgumentError('Both "arguments" and "inputs" cannot be empty.');
    }
    // OK
    return new WorkRequest(arguments, inputs);
  }

  @override
  Map<String, Object> toJson() {
    Map<String, Object> json = <String, Object>{};
    if (arguments != null) {
      json['arguments'] = arguments;
    }
    if (inputs != null) {
      json['inputs'] = inputs.map((input) => input.toJson()).toList();
    }
    return json;
  }
}

/**
 * Result that the worker sends back to Bazel when it finished its work on a
 * [WorkRequest] message.
 */
class WorkResponse implements WorkDataObject {
  final int exitCode;
  final String output;

  WorkResponse(this.exitCode, this.output);

  @override
  Map<String, Object> toJson() {
    Map<String, Object> json = <String, Object>{};
    if (exitCode != null) {
      json['exit_code'] = exitCode;
    }
    if (output != null) {
      json['output'] = output;
    }
    return json;
  }
}

/**
 * Default implementation of [WorkerConnection] that works with stdio.
 */
class _StdWorkerConnection implements WorkerConnection {
  @override
  String readLineSync() {
    return io.stdin.readLineSync();
  }

  @override
  void writeJson(Map<String, Object> json) {
    io.stdout.writeln(JSON.encode(json));
  }
}
