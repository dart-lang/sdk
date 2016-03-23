// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.src.build_mode;

import 'dart:core' hide Resource;
import 'dart:io' as io;

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
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
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
  InternalAnalysisContext context;
  Map<Uri, JavaFile> uriToFileMap;
  final List<Source> explicitSources = <Source>[];

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
      PackageBundleAssembler assembler = new PackageBundleAssembler();
      for (Source source in explicitSources) {
        if (context.computeKindOf(source) != SourceKind.LIBRARY) {
          continue;
        }
        LibraryElement libraryElement = context.computeLibraryElement(source);
        assembler.serializeLibraryElement(libraryElement);
      }
      // Write the whole package bundle.
      PackageBundleBuilder sdkBundle = assembler.assemble();
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

    // Read the summaries.
    SummaryDataStore summaryDataStore =
        new SummaryDataStore(options.buildSummaryInputs);

    // Create the context.
    context = AnalysisEngine.instance.createAnalysisContext();
    context.sourceFactory = new SourceFactory(<UriResolver>[
      new DartUriResolver(sdk),
      new InSummaryPackageUriResolver(summaryDataStore),
      new ExplicitSourceResolver(uriToFileMap)
    ]);

    // Set context options.
    Driver.setAnalysisContextOptions(
        context, options, (AnalysisOptionsImpl contextOptions) {});

    // Configure using summaries.
    sdk.useSummary = true;
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
