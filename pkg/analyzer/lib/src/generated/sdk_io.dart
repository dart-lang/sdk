// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@deprecated
library analyzer.src.generated.sdk_io;

import 'dart:collection';

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/summary/idl.dart' show PackageBundle;

/// An abstract implementation of a Dart SDK in which the available libraries
/// are stored in a library map. Subclasses are responsible for populating the
/// library map.
@deprecated
abstract class AbstractDartSdk implements DartSdk {
  /// A mapping from Dart library URI's to the library represented by that URI.
  LibraryMap libraryMap = LibraryMap();

  /// The [AnalysisOptions] to use to create the [context].
  AnalysisOptions _analysisOptions;

  /// The [AnalysisContext] which is used for all of the sources in this SDK.
  SdkAnalysisContext _analysisContext;

  /// The mapping from Dart URI's to the corresponding sources.
  final Map<String, Source> _uriToSourceMap = HashMap<String, Source>();

  /// Set the [options] for this SDK analysis context.  Throw [StateError] if
  /// the context has been already created.
  set analysisOptions(AnalysisOptions options) {
    if (_analysisContext != null) {
      throw StateError(
          'Analysis options cannot be changed after context creation.');
    }
    _analysisOptions = options;
  }

  @override
  AnalysisContext get context {
    if (_analysisContext == null) {
      var factory = SourceFactory([DartUriResolver(this)]);
      _analysisContext = SdkAnalysisContext(_analysisOptions, factory);
    }
    return _analysisContext;
  }

  @override
  List<SdkLibrary> get sdkLibraries => libraryMap.sdkLibraries;

  @override
  List<String> get uris => libraryMap.uris;

  /// Add the extensions from one or more sdk extension files to this sdk. The
  /// [extensions] should be a table mapping the names of extensions to the
  /// paths where those extensions can be found.
  void addExtensions(Map<String, String> extensions) {
    extensions.forEach((String uri, String path) {
      String shortName = uri.substring(uri.indexOf(':') + 1);
      SdkLibraryImpl library = SdkLibraryImpl(shortName);
      library.path = path;
      libraryMap.setLibrary(uri, library);
    });
  }

  @override
  Source fromFileUri(Uri uri) {
    JavaFile file = JavaFile.fromUri(uri);

    String path = _getPath(file);
    if (path == null) {
      return null;
    }
    try {
      return FileBasedSource(file, Uri.parse(path));
    } on FormatException catch (exception, stackTrace) {
      AnalysisEngine.instance.instrumentationService.logInfo(
          "Failed to create URI: $path",
          CaughtException(exception, stackTrace));
    }
    return null;
  }

  String getRelativePathFromFile(JavaFile file);

  @override
  SdkLibrary getSdkLibrary(String dartUri) => libraryMap.getLibrary(dartUri);

  /// Return the [PackageBundle] for this SDK, if it exists, or `null`
  /// otherwise. This method should not be used outside of `analyzer` and
  /// `analyzer_cli` packages.
  @deprecated
  PackageBundle getSummarySdkBundle(bool _);

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
      JavaFile file = JavaFile(filePath);
      return FileBasedSource(file, Uri.parse(dartUri));
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
    List<String> paths = List(length);
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
