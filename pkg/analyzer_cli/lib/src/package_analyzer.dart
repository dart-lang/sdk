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
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/task/dart.dart';
import 'package:analyzer/task/dart.dart';
import 'package:analyzer/task/model.dart';
import 'package:analyzer_cli/src/analyzer_impl.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:path/path.dart' as pathos;

/**
 * If [uri] has the `package` scheme in form of `package:pkg/file.dart`,
 * return the `pkg` name.  Otherwise return `null`.
 */
String getPackageName(Uri uri) {
  if (uri.scheme != 'package') {
    return null;
  }
  String path = uri.path;
  int index = path.indexOf('/');
  if (index == -1) {
    return null;
  }
  return path.substring(0, index);
}

/**
 * A concrete resynthesizer that serves summaries from given file paths.
 */
class FileBasedSummaryResynthesizer extends SummaryResynthesizer {
  final Map<String, UnlinkedUnit> unlinkedMap = <String, UnlinkedUnit>{};
  final Map<String, LinkedLibrary> linkedMap = <String, LinkedLibrary>{};

  FileBasedSummaryResynthesizer(
      SummaryResynthesizer parent,
      AnalysisContext context,
      TypeProvider typeProvider,
      SourceFactory sourceFactory,
      bool strongMode,
      List<String> summaryPaths)
      : super(parent, context, typeProvider, sourceFactory, strongMode) {
    summaryPaths.forEach(_fillMaps);
  }

  @override
  LinkedLibrary getLinkedSummary(String uri) {
    return linkedMap[uri];
  }

  @override
  UnlinkedUnit getUnlinkedSummary(String uri) {
    return unlinkedMap[uri];
  }

  @override
  bool hasLibrarySummary(String uri) {
    return linkedMap.containsKey(uri);
  }

  void _fillMaps(String path) {
    io.File file = new io.File(path);
    List<int> buffer = file.readAsBytesSync();
    SdkBundle bundle = new SdkBundle.fromBuffer(buffer);
    for (int i = 0; i < bundle.unlinkedUnitUris.length; i++) {
      unlinkedMap[bundle.unlinkedUnitUris[i]] = bundle.unlinkedUnits[i];
    }
    for (int i = 0; i < bundle.linkedLibraryUris.length; i++) {
      linkedMap[bundle.linkedLibraryUris[i]] = bundle.linkedLibraries[i];
    }
  }
}

/**
 * The [ResourceProvider] that provides results from input package summaries.
 */
class InputPackagesResultProvider extends ResultProvider {
  final InternalAnalysisContext context;
  final Map<String, String> packageSummaryInputs;

  FileBasedSummaryResynthesizer resynthesizer;
  SummaryResultProvider sdkProvider;

  InputPackagesResultProvider(this.context, this.packageSummaryInputs) {
    InternalAnalysisContext sdkContext = context.sourceFactory.dartSdk.context;
    sdkProvider = sdkContext.resultProvider;
    // Set the type provider to prevent the context from computing it.
    context.typeProvider = sdkContext.typeProvider;
    // Create a chained resynthesizer.
    resynthesizer = new FileBasedSummaryResynthesizer(
        sdkProvider.resynthesizer,
        context,
        context.typeProvider,
        context.sourceFactory,
        false,
        packageSummaryInputs.values.toList());
  }

  bool compute(CacheEntry entry, ResultDescriptor result) {
    if (sdkProvider.compute(entry, result)) {
      return true;
    }
    AnalysisTarget target = entry.target;
    // Only library results are supported for now.
    if (target is Source) {
      Uri uri = target.uri;
      // We know how to server results to input packages.
      String sourcePackageName = getPackageName(uri);
      if (!packageSummaryInputs.containsKey(sourcePackageName)) {
        return false;
      }
      // Provide known results.
      String uriString = uri.toString();
      if (result == LIBRARY_ELEMENT1 ||
          result == LIBRARY_ELEMENT2 ||
          result == LIBRARY_ELEMENT3 ||
          result == LIBRARY_ELEMENT4 ||
          result == LIBRARY_ELEMENT5 ||
          result == LIBRARY_ELEMENT6 ||
          result == LIBRARY_ELEMENT7 ||
          result == LIBRARY_ELEMENT8 ||
          result == LIBRARY_ELEMENT ||
          false) {
        LibraryElement libraryElement =
            resynthesizer.getLibraryElement(uriString);
        entry.setValue(result, libraryElement, TargetedResult.EMPTY_LIST);
        return true;
      } else if (result == READY_LIBRARY_ELEMENT2 ||
          result == READY_LIBRARY_ELEMENT5 ||
          result == READY_LIBRARY_ELEMENT6) {
        entry.setValue(result, true, TargetedResult.EMPTY_LIST);
        return true;
      } else if (result == SOURCE_KIND) {
        if (resynthesizer.linkedMap.containsKey(uriString)) {
          entry.setValue(result, SourceKind.LIBRARY, TargetedResult.EMPTY_LIST);
          return true;
        }
        if (resynthesizer.unlinkedMap.containsKey(uriString)) {
          entry.setValue(result, SourceKind.PART, TargetedResult.EMPTY_LIST);
          return true;
        }
        return false;
      }
    }
    return false;
  }
}

/**
 * The [UriResolver] that knows about sources that are parts of packages which
 * are served from their summaries.
 */
class InSummaryPackageUriResolver extends UriResolver {
  final Map<String, String> packageSummaryInputs;

  InSummaryPackageUriResolver(this.packageSummaryInputs);

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    actualUri ??= uri;
    String packageName = getPackageName(actualUri);
    if (packageSummaryInputs.containsKey(packageName)) {
      return new InSummarySource(actualUri);
    }
    return null;
  }
}

/**
 * A placeholder of a source that is part of a package whose analysis results
 * are served from its summary.  This source uses its URI as [fullName] and has
 * empty contents.
 */
class InSummarySource extends Source {
  final Uri uri;

  InSummarySource(this.uri);

  @override
  TimestampedData<String> get contents => new TimestampedData<String>(0, '');

  @override
  String get encoding => uri.toString();

  @override
  String get fullName => encoding;

  @override
  bool get isInSystemLibrary => false;

  @override
  int get modificationStamp => 0;

  @override
  String get shortName => pathos.basename(fullName);

  @override
  UriKind get uriKind => UriKind.PACKAGE_URI;

  @override
  bool exists() => true;

  @override
  Uri resolveRelativeUri(Uri relativeUri) {
    Uri baseUri = uri;
    return baseUri.resolveUri(relativeUri);
  }

  @override
  String toString() => uri.toString();
}

/**
 * The hermetic whole package analyzer.
 */
class PackageAnalyzer {
  final CommandLineOptions options;

  String packagePath;
  String packageLibPath;

  final ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
  InternalAnalysisContext context;
  final List<Source> explicitSources = <Source>[];

  final List<String> linkedLibraryUris = <String>[];
  final List<LinkedLibraryBuilder> linkedLibraries = <LinkedLibraryBuilder>[];
  final List<String> unlinkedUnitUris = <String>[];
  final List<UnlinkedUnitBuilder> unlinkedUnits = <UnlinkedUnitBuilder>[];

  PackageAnalyzer(this.options);

  /**
   * Perform package analysis according to the given [options].
   */
  ErrorSeverity analyze() {
    packagePath = options.packageModePath;
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
        path = resourceProvider.pathContext.absolute(path);
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

    // Perform full analysis.
    while (true) {
      AnalysisResult analysisResult = context.performAnalysisTask();
      if (!analysisResult.hasMoreWork) {
        break;
      }
    }

    // Write summary for Dart libraries.
    if (options.packageSummaryOutput != null) {
      for (Source source in context.librarySources) {
        if (pathos.isWithin(packageLibPath, source.fullName)) {
          LibraryElement libraryElement = context.getLibraryElement(source);
          if (libraryElement != null) {
            _serializeSingleLibrary(libraryElement);
          }
        }
      }
      // Write the whole package bundle.
      SdkBundleBuilder sdkBundle = new SdkBundleBuilder(
          linkedLibraryUris: linkedLibraryUris,
          linkedLibraries: linkedLibraries,
          unlinkedUnitUris: unlinkedUnitUris,
          unlinkedUnits: unlinkedUnits);
      io.File file = new io.File(options.packageSummaryOutput);
      file.writeAsBytesSync(sdkBundle.toBuffer(), mode: io.FileMode.WRITE_ONLY);
    }

    // Process errors.
    _printErrors();
    return _computeMaxSeverity();
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
    DirectoryBasedDartSdk sdk = DirectoryBasedDartSdk.defaultSdk;
    sdk.useSummary = true;

    // Create the context.
    context = AnalysisEngine.instance.createAnalysisContext();
    context.typeProvider = sdk.context.typeProvider;
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
    context.resultProvider =
        new InputPackagesResultProvider(context, options.packageSummaryInputs);

    // Set context options.
    Driver.setAnalysisContextOptions(
        context, options, (AnalysisOptionsImpl contextOptions) {});
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
        (AnalysisError error) =>
            AnalyzerImpl.processError(error, options, context));
    for (Source source in explicitSources) {
      AnalysisErrorInfo errorInfo = context.getErrors(source);
      formatter.formatErrors([errorInfo]);
    }
  }

  /**
   * Serialize the library with the given [element].
   */
  void _serializeSingleLibrary(LibraryElement element) {
    String uri = element.source.uri.toString();
    LibrarySerializationResult libraryResult =
        serializeLibrary(element, context.typeProvider, options.strongMode);
    linkedLibraryUris.add(uri);
    linkedLibraries.add(libraryResult.linked);
    unlinkedUnitUris.addAll(libraryResult.unitUris);
    unlinkedUnits.addAll(libraryResult.unlinkedUnits);
  }
}
