// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@deprecated
library analyzer.src.generated.sdk_io;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/summary/idl.dart' show PackageBundle;
import 'package:analyzer/src/summary/package_bundle_reader.dart';

/**
 * An abstract implementation of a Dart SDK in which the available libraries are
 * stored in a library map. Subclasses are responsible for populating the
 * library map.
 */
@deprecated
abstract class AbstractDartSdk implements DartSdk {
  /**
   * A mapping from Dart library URI's to the library represented by that URI.
   */
  LibraryMap libraryMap = new LibraryMap();

  /**
   * The [AnalysisOptions] to use to create the [context].
   */
  AnalysisOptions _analysisOptions;

  /**
   * The flag that specifies whether an SDK summary should be used. This is a
   * temporary flag until summaries are enabled by default.
   */
  bool _useSummary = false;

  /**
   * The [AnalysisContext] which is used for all of the sources in this SDK.
   */
  InternalAnalysisContext _analysisContext;

  /**
   * The mapping from Dart URI's to the corresponding sources.
   */
  Map<String, Source> _uriToSourceMap = new HashMap<String, Source>();

  /**
   * Set the [options] for this SDK analysis context.  Throw [StateError] if the
   * context has been already created.
   */
  void set analysisOptions(AnalysisOptions options) {
    if (_analysisContext != null) {
      throw new StateError(
          'Analysis options cannot be changed after context creation.');
    }
    _analysisOptions = options;
  }

  @override
  AnalysisContext get context {
    if (_analysisContext == null) {
      _analysisContext = new SdkAnalysisContext(_analysisOptions);
      SourceFactory factory = new SourceFactory([new DartUriResolver(this)]);
      _analysisContext.sourceFactory = factory;
      if (_useSummary) {
        bool strongMode = _analysisOptions?.strongMode ?? false;
        PackageBundle sdkBundle = getSummarySdkBundle(strongMode);
        if (sdkBundle != null) {
          SummaryDataStore dataStore = new SummaryDataStore([]);
          dataStore.addBundle(null, sdkBundle);
          _analysisContext.resultProvider =
              new InputPackagesResultProvider(_analysisContext, dataStore);
        }
      }
    }
    return _analysisContext;
  }

  @override
  List<SdkLibrary> get sdkLibraries => libraryMap.sdkLibraries;

  @override
  List<String> get uris => libraryMap.uris;

  /**
   * Return `true` if the SDK summary will be used when available.
   */
  bool get useSummary => _useSummary;

  /**
   * Specify whether SDK summary should be used.
   */
  void set useSummary(bool use) {
    if (_analysisContext != null) {
      throw new StateError(
          'The "useSummary" flag cannot be changed after context creation.');
    }
    _useSummary = use;
  }

  /**
   * Add the extensions from one or more sdk extension files to this sdk. The
   * [extensions] should be a table mapping the names of extensions to the paths
   * where those extensions can be found.
   */
  void addExtensions(Map<String, String> extensions) {
    extensions.forEach((String uri, String path) {
      String shortName = uri.substring(uri.indexOf(':') + 1);
      SdkLibraryImpl library = new SdkLibraryImpl(shortName);
      library.path = path;
      libraryMap.setLibrary(uri, library);
    });
  }

  @override
  Source fromFileUri(Uri uri) {
    JavaFile file = new JavaFile.fromUri(uri);

    String path = _getPath(file);
    if (path == null) {
      return null;
    }
    try {
      return new FileBasedSource(file, Uri.parse(path));
    } on FormatException catch (exception, stackTrace) {
      AnalysisEngine.instance.logger.logInformation(
          "Failed to create URI: $path",
          new CaughtException(exception, stackTrace));
    }
    return null;
  }

  String getRelativePathFromFile(JavaFile file);

  @override
  SdkLibrary getSdkLibrary(String dartUri) => libraryMap.getLibrary(dartUri);

  /**
   * Return the [PackageBundle] for this SDK, if it exists, or `null` otherwise.
   * This method should not be used outside of `analyzer` and `analyzer_cli`
   * packages.
   */
  PackageBundle getSummarySdkBundle(bool strongMode);

  FileBasedSource internalMapDartUri(String dartUri) {
    // TODO(brianwilkerson) Figure out how to unify the implementations in the
    // two subclasses.
    String libraryName;
    String relativePath;
    int index = dartUri.indexOf('/');
    if (index >= 0) {
      libraryName = dartUri.substring(0, index);
      relativePath = dartUri.substring(index + 1);
    } else {
      libraryName = dartUri;
      relativePath = "";
    }
    SdkLibrary library = getSdkLibrary(libraryName);
    if (library == null) {
      return null;
    }
    String srcPath;
    if (relativePath.isEmpty) {
      srcPath = library.path;
    } else {
      String libraryPath = library.path;
      int index = libraryPath.lastIndexOf(JavaFile.separator);
      if (index == -1) {
        index = libraryPath.lastIndexOf('/');
        if (index == -1) {
          return null;
        }
      }
      String prefix = libraryPath.substring(0, index + 1);
      srcPath = '$prefix$relativePath';
    }
    String filePath = srcPath.replaceAll('/', JavaFile.separator);
    try {
      JavaFile file = new JavaFile(filePath);
      return new FileBasedSource(file, Uri.parse(dartUri));
    } on FormatException {
      return null;
    }
  }

  @override
  Source mapDartUri(String dartUri) {
    Source source = _uriToSourceMap[dartUri];
    if (source == null) {
      source = internalMapDartUri(dartUri);
      _uriToSourceMap[dartUri] = source;
    }
    return source;
  }

  String _getPath(JavaFile file) {
    List<SdkLibrary> libraries = libraryMap.sdkLibraries;
    int length = libraries.length;
    List<String> paths = new List(length);
    String filePath = getRelativePathFromFile(file);
    if (filePath == null) {
      return null;
    }
    for (int i = 0; i < length; i++) {
      SdkLibrary library = libraries[i];
      String libraryPath = library.path.replaceAll('/', JavaFile.separator);
      if (filePath == libraryPath) {
        return library.shortName;
      }
      paths[i] = libraryPath;
    }
    for (int i = 0; i < length; i++) {
      SdkLibrary library = libraries[i];
      String libraryPath = paths[i];
      int index = libraryPath.lastIndexOf(JavaFile.separator);
      if (index >= 0) {
        String prefix = libraryPath.substring(0, index + 1);
        if (filePath.startsWith(prefix)) {
          String relPath = filePath
              .substring(prefix.length)
              .replaceAll(JavaFile.separator, '/');
          return '${library.shortName}/$relPath';
        }
      }
    }
    return null;
  }
}

/**
 * An object used to read and parse the libraries file
 * (dart-sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart) for information
 * about the libraries in an SDK. The library information is represented as a
 * Dart file containing a single top-level variable whose value is a const map.
 * The keys of the map are the names of libraries defined in the SDK and the
 * values in the map are info objects defining the library. For example, a
 * subset of a typical SDK might have a libraries file that looks like the
 * following:
 *
 *     final Map<String, LibraryInfo> LIBRARIES = const <LibraryInfo> {
 *       // Used by VM applications
 *       "builtin" : const LibraryInfo(
 *         "builtin/builtin_runtime.dart",
 *         category: "Server",
 *         platforms: VM_PLATFORM),
 *
 *       "compiler" : const LibraryInfo(
 *         "compiler/compiler.dart",
 *         category: "Tools",
 *         platforms: 0),
 *     };
 */
@deprecated
class SdkLibrariesReader {
  /**
   * A flag indicating whether the dart2js path should be used when it is
   * available.
   */
  final bool _useDart2jsPaths;

  /**
   * Initialize a newly created library reader to use the dart2js path if
   * [_useDart2jsPaths] is `true`.
   */
  SdkLibrariesReader(this._useDart2jsPaths);

  /**
   * Return the library map read from the given [file], given that the content
   * of the file is already known to be [libraryFileContents].
   */
  LibraryMap readFromFile(JavaFile file, String libraryFileContents) =>
      readFromSource(new FileBasedSource(file), libraryFileContents);

  /**
   * Return the library map read from the given [source], given that the content
   * of the file is already known to be [libraryFileContents].
   */
  LibraryMap readFromSource(Source source, String libraryFileContents) {
    BooleanErrorListener errorListener = new BooleanErrorListener();
    Scanner scanner = new Scanner(
        source, new CharSequenceReader(libraryFileContents), errorListener);
    Parser parser = new Parser(source, errorListener);
    CompilationUnit unit = parser.parseCompilationUnit(scanner.tokenize());
    SdkLibrariesReader_LibraryBuilder libraryBuilder =
        new SdkLibrariesReader_LibraryBuilder(_useDart2jsPaths);
    // If any syntactic errors were found then don't try to visit the AST
    // structure.
    if (!errorListener.errorReported) {
      unit.accept(libraryBuilder);
    }
    return libraryBuilder.librariesMap;
  }
}
