// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.src.package_analyzer;

import 'dart:core' hide Resource;
import 'dart:io' as io;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
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
import 'package:path/path.dart' as pathos;

/**
 * The hermetic whole package analyzer.
 */
class PackageAnalyzer {
  final CommandLineOptions options;
  final AnalysisStats stats;

  String packagePath;
  String packageLibPath;

  final ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
  InternalAnalysisContext context;
  final List<Source> explicitSources = <Source>[];

  PackageAnalyzer(this.options, this.stats);

  /**
   * Perform package analysis according to the given [options].
   */
  ErrorSeverity analyze() {
    packagePath = resourceProvider.pathContext.normalize(resourceProvider
        .pathContext
        .join(io.Directory.current.absolute.path, options.packageModePath));
    packageLibPath = resourceProvider.pathContext.join(packagePath, 'lib');
    if (packageLibPath == null) {
      errorSink.writeln('--package-mode-path must be set to the root '
          'folder of the package to analyze.');
      io.exitCode = ErrorSeverity.ERROR.ordinal;
      return ErrorSeverity.ERROR;
    }

    // Write the progress message.
    if (!options.machineFormat) {
      outSink.writeln("Analyzing sources ${options.sourceFiles}...");
    }

    // Prepare the analysis context.
    _createContext();

    // Add sources.
    ChangeSet changeSet = new ChangeSet();
    for (String path in options.sourceFiles) {
      if (AnalysisEngine.isDartFileName(path)) {
        File file = resourceProvider.getFile(path);
        if (!file.exists) {
          errorSink.writeln('File not found: $path');
          io.exitCode = ErrorSeverity.ERROR.ordinal;
          return ErrorSeverity.ERROR;
        }
        Source source = _createSourceInContext(file);
        explicitSources.add(source);
        changeSet.addedSource(source);
      }
    }
    context.applyChanges(changeSet);

    if (!options.packageSummaryOnly) {
      // Perform full analysis.
      while (true) {
        AnalysisResult analysisResult = context.performAnalysisTask();
        if (!analysisResult.hasMoreWork) {
          break;
        }
      }
    }

    // Write summary for Dart libraries.
    if (options.packageSummaryOutput != null) {
      PackageBundleAssembler assembler = new PackageBundleAssembler();
      for (Source source in explicitSources) {
        if (context.computeKindOf(source) != SourceKind.LIBRARY) {
          continue;
        }
        if (pathos.isWithin(packageLibPath, source.fullName)) {
          LibraryElement libraryElement = context.computeLibraryElement(source);
          assembler.serializeLibraryElement(libraryElement);
        }
      }
      // Write the whole package bundle.
      PackageBundleBuilder sdkBundle = assembler.assemble();
      io.File file = new io.File(options.packageSummaryOutput);
      file.writeAsBytesSync(sdkBundle.toBuffer(), mode: io.FileMode.WRITE_ONLY);
    }

    if (options.packageSummaryOnly) {
      return ErrorSeverity.NONE;
    } else {
      // Process errors.
      _printErrors();
      return _computeMaxSeverity();
    }
  }

  ErrorSeverity _computeMaxSeverity() {
    ErrorSeverity maxSeverity = ErrorSeverity.NONE;
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
    return maxSeverity;
  }

  void _createContext() {
    DirectoryBasedDartSdk sdk =
        new DirectoryBasedDartSdk(new JavaFile(options.dartSdkPath));

    // Create the context.
    context = AnalysisEngine.instance.createAnalysisContext();
    context.sourceFactory = new SourceFactory(<UriResolver>[
      new DartUriResolver(sdk),
      new InSummaryPackageUriResolver(options.packageSummaryInputs),
      new PackageMapUriResolver(resourceProvider, <String, List<Folder>>{
        options.packageName: <Folder>[
          resourceProvider.getFolder(packageLibPath)
        ],
      }),
      new FileUriResolver()
    ]);

    // Set context options.
    Driver.setAnalysisContextOptions(
        context, options, (AnalysisOptionsImpl contextOptions) {});

    // Configure using summaries.
    sdk.useSummary = true;
    context.typeProvider = sdk.context.typeProvider;
    context.resultProvider =
        new InputPackagesResultProvider(context, options.packageSummaryInputs);
  }

  /**
   * Create and return a source representing the given [file].
   */
  Source _createSourceInContext(File file) {
    Source source = file.createSource();
    if (context == null) {
      return source;
    }
    Uri uri = context.sourceFactory.restoreUri(source);
    return file.createSource(uri);
  }

  /**
   * Print errors for all explicit sources.
   */
  void _printErrors() {
    StringSink sink = options.machineFormat ? errorSink : outSink;
    ErrorFormatter formatter = new ErrorFormatter(
        sink,
        options,
        stats,
        (AnalysisError error) =>
            AnalyzerImpl.processError(error, options, context));
    for (Source source in explicitSources) {
      AnalysisErrorInfo errorInfo = context.getErrors(source);
      formatter.formatErrors([errorInfo]);
    }
    stats.print(sink);
  }
}
