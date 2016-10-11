// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@deprecated
library analyzer.source.embedder;

import 'dart:collection' show HashMap;
import 'dart:core';
import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/package_map_provider.dart'
    show PackageMapProvider;
import 'package:analyzer/src/generated/java_io.dart' show JavaFile;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart' show FileBasedSource;
import 'package:analyzer/src/summary/idl.dart' show PackageBundle;
import 'package:yaml/yaml.dart';

export 'package:analyzer/src/context/builder.dart' show EmbedderYamlLocator;

const String _DART_COLON_PREFIX = 'dart:';
const String _EMBEDDED_LIB_MAP_KEY = 'embedded_libs';

/// Check if this map defines embedded libraries.
@deprecated
bool definesEmbeddedLibs(Map map) => map[_EMBEDDED_LIB_MAP_KEY] != null;

/// An SDK backed by URI mappings derived from an `_embedder.yaml` file.
@deprecated
class EmbedderSdk extends AbstractDartSdk {
  final Map<String, String> _urlMappings = new HashMap<String, String>();

  EmbedderSdk([Map<Folder, YamlMap> embedderYamls]) {
    embedderYamls?.forEach(_processEmbedderYaml);
  }

  // TODO(danrubel) Determine SDK version
  @override
  String get sdkVersion => '0';

  /// The url mappings for this SDK.
  Map<String, String> get urlMappings => _urlMappings;

  @override
  PackageBundle getLinkedBundle() => null;

  @override
  String getRelativePathFromFile(JavaFile file) => file.getAbsolutePath();

  @override
  PackageBundle getSummarySdkBundle(bool strongMode) => null;

  @override
  FileBasedSource internalMapDartUri(String dartUri) {
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
      int index = libraryPath.lastIndexOf(io.Platform.pathSeparator);
      if (index == -1) {
        index = libraryPath.lastIndexOf('/');
        if (index == -1) {
          return null;
        }
      }
      String prefix = libraryPath.substring(0, index + 1);
      srcPath = '$prefix$relativePath';
    }
    String filePath = srcPath.replaceAll('/', io.Platform.pathSeparator);
    try {
      JavaFile file = new JavaFile(filePath);
      return new FileBasedSource(file, Uri.parse(dartUri));
    } on FormatException {
      return null;
    }
  }

  /// Install the mapping from [name] to [libDir]/[file].
  void _processEmbeddedLibs(String name, String file, Folder libDir) {
    if (!name.startsWith(_DART_COLON_PREFIX)) {
      // SDK libraries must begin with 'dart:'.
      return;
    }
    String libPath = libDir.canonicalizePath(file);
    _urlMappings[name] = libPath;
    SdkLibraryImpl library = new SdkLibraryImpl(name);
    library.path = libPath;
    libraryMap.setLibrary(name, library);
  }

  /// Given the 'embedderYamls' from [EmbedderYamlLocator] check each one for the
  /// top level key 'embedded_libs'. Under the 'embedded_libs' key are key value
  /// pairs. Each key is a 'dart:' library uri and each value is a path
  /// (relative to the directory containing `_embedder.yaml`) to a dart script
  /// for the given library. For example:
  ///
  /// embedded_libs:
  ///   'dart:io': '../../sdk/io/io.dart'
  ///
  /// If a key doesn't begin with `dart:` it is ignored.
  void _processEmbedderYaml(Folder libDir, YamlMap map) {
    YamlNode embedded_libs = map[_EMBEDDED_LIB_MAP_KEY];
    if (embedded_libs is YamlMap) {
      embedded_libs.forEach((k, v) => _processEmbeddedLibs(k, v, libDir));
    }
  }
}

/// Given the 'embedderYamls' from [EmbedderYamlLocator] check each one for the
/// top level key 'embedded_libs'. Under the 'embedded_libs' key are key value
/// pairs. Each key is a 'dart:' library uri and each value is a path
/// (relative to the directory containing `_embedder.yaml`) to a dart script
/// for the given library. For example:
///
/// embedded_libs:
///   'dart:io': '../../sdk/io/io.dart'
///
/// If a key doesn't begin with `dart:` it is ignored.
///
/// This class is deprecated; use DartUriResolver directly. In particular, if
/// there used to be an instance creation of the form:
///
/// ```
/// new EmbedderUriResolver(embedderMap)
/// ```
///
/// This should be replaced by
///
/// ```
/// new DartUriResolver(new EmbedderSdk(embedderMap))
/// ```
@deprecated
class EmbedderUriResolver implements DartUriResolver {
  EmbedderSdk _embedderSdk;
  DartUriResolver _dartUriResolver;

  /// Construct a [EmbedderUriResolver] from a package map
  /// (see [PackageMapProvider]).
  EmbedderUriResolver(Map<Folder, YamlMap> embedderMap)
      : this._forSdk(new EmbedderSdk(embedderMap));

  /// (Provisional API.)
  EmbedderUriResolver._forSdk(this._embedderSdk) {
    _dartUriResolver = new DartUriResolver(_embedderSdk);
  }

  @override
  DartSdk get dartSdk => _embedderSdk;

  /// Number of embedded libraries.
  int get length => _embedderSdk?.urlMappings?.length ?? 0;

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) =>
      _dartUriResolver.resolveAbsolute(uri, actualUri);

  @override
  Uri restoreAbsolute(Source source) {
    String path = source.fullName;
    if (path.length > 3 && path[1] == ':' && path[2] == '\\') {
      path = '/${path[0]}:${path.substring(2).replaceAll('\\', '/')}';
    }
    Source sdkSource = dartSdk.fromFileUri(Uri.parse('file://$path'));
    return sdkSource?.uri;
  }
}
