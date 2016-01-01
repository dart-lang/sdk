// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.source.embedder;

import 'dart:collection' show HashMap;
import 'dart:core' hide Resource;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/java_io.dart' show JavaFile;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart' show FileBasedSource;
import 'package:path/path.dart' as pathos;
import 'package:yaml/yaml.dart';

/// Given a packageMap, check in each package's lib directory for the
/// existence of an `_embedder.yaml` file. If the file contains a top level
/// YamlMap, it will be added to the [embedderYamls] map.
class EmbedderYamlLocator {
  static const String EMBEDDER_FILE_NAME = '_embedder.yaml';

  // Map from package's library directory to the parsed
  // YamlMap.
  final Map<Folder, YamlMap> embedderYamls = new HashMap<Folder, YamlMap>();

  EmbedderYamlLocator(Map<String, List<Folder>> packageMap) {
    if (packageMap != null) {
      refresh(packageMap);
    }
  }

  void refresh(Map<String, List<Folder>> packageMap) {
    // Clear existing.
    embedderYamls.clear();
    if (packageMap == null) {
      return;
    }
    packageMap.forEach(_processPackage);
  }

  /// Programatically add an _embedder.yaml mapping.
  void addEmbedderYaml(Folder libDir, String embedderYaml) {
    _processEmbedderYaml(libDir, embedderYaml);
  }

  /// Given a package [name] and a list of folders ([libDirs]),
  /// add any found `_embedder.yaml` files.
  void _processPackage(String name, List<Folder> libDirs) {
    for (Folder libDir in libDirs) {
      String embedderYaml = _readEmbedderYaml(libDir);
      if (embedderYaml != null) {
        _processEmbedderYaml(libDir, embedderYaml);
      }
    }
  }

  /// Given the yaml for an embedder ([embedderYaml]) and a folder
  /// ([libDir]), setup the uri mapping.
  void _processEmbedderYaml(Folder libDir, String embedderYaml) {
    YamlNode yaml;
    try {
      yaml = loadYaml(embedderYaml);
    } catch (_) {
      // TODO(pquitslund): Notify developer that something is wrong with the
      // _embedder.yaml file in libDir.
      return;
    }
    if (yaml == null) {
      // TODO(pquitslund): Notify developer that something is wrong with the
      // _embedder.yaml file in libDir.
      return;
    }
    if (yaml is! YamlMap) {
      // TODO(pquitslund): Notify developer that something is wrong with the
      // _embedder.yaml file in libDir.
      return;
    }
    embedderYamls[libDir] = yaml;
  }


  /// Read the contents of [libDir]/[EMBEDDER_FILE_NAME] as a string.
  /// Returns null if the file doesn't exist.
  String _readEmbedderYaml(Folder libDir) {
    File file = libDir.getChild(EMBEDDER_FILE_NAME);
    try {
      return file.readAsStringSync();
    } on FileSystemException {
      // File can't be read.
      return null;
    }
  }
}

/// Given the [embedderYamls] from [EmbedderYamlLocator] check each one for the
/// top level key 'embedder_libs'. Under the 'embedder_libs' key are key value
/// pairs. Each key is a 'dart:' library uri and each value is a path
/// (relative to the directory containing `_embedder.yaml`) to a dart script
/// for the given library. For example:
///
/// embedder_libs:
///   'dart:io': '../../sdk/io/io.dart'
///
/// If a key doesn't begin with `dart:` it is ignored.
///
class EmbedderUriResolver extends UriResolver {
  static const String DART_COLON_PREFIX = 'dart:';

  final Map<String, String> _urlMappings = <String, String>{};

  /// Construct a [EmbedderUriResolver] from a package map
  /// (see [PackageMapProvider]).
  EmbedderUriResolver(Map<Folder, YamlMap> embedderYamls) {
    if (embedderYamls == null) {
      return;
    }
    embedderYamls.forEach(_processEmbedderYaml);
  }

  void _processEmbedderYaml(Folder libDir, YamlMap map) {
    YamlNode embedder_libs = map['embedder_libs'];
    if (embedder_libs == null) {
      return;
    }
    if (embedder_libs is! YamlMap) {
      return;
    }
    (embedder_libs as YamlMap).forEach((k, v) =>
        _processEmbedderLibs(k, v, libDir));
  }

  /// Install the mapping from [name] to [libDir]/[file].
  void _processEmbedderLibs(String name, String file, Folder libDir) {
    if (!name.startsWith(DART_COLON_PREFIX)) {
      // SDK libraries must begin with 'dart:'.
      // TODO(pquitslund): Notify developer that something is wrong with the
      // _embedder.yaml file in libDir.
      return;
    }
    String key = name;
    String value = libDir.canonicalizePath(file);
    _urlMappings[key] = value;
  }

  /// Number of embedder libraries.
  int get length => _urlMappings.length;

  /// Return the path mapping for [libName] or null if there is none.
  String operator [](String libName) => _urlMappings[libName];

  @override
  Source resolveAbsolute(Uri importUri, [Uri actualUri]) {
    String libraryName = _libraryName(importUri);
    String partPath = _partPath(importUri);
    // Lookup library name in mappings.
    String mapping = _urlMappings[libraryName];
    if (mapping == null) {
      // Not found.
      return null;
    }
    // This mapping points to the main entry file of the dart: library.
    Uri libraryEntry = new Uri.file(mapping);
    if (!libraryEntry.isAbsolute) {
      // We expect an absolute path.
      return null;
    }

    if (partPath != null) {
      return _resolvePart(libraryEntry, partPath, importUri);
    } else {
      return _resolveEntry(libraryEntry, importUri);
    }
  }

  @override
  Uri restoreAbsolute(Source source) {
    String extensionName = _findExtensionNameFor(source.fullName);
    if (extensionName != null) {
      return Uri.parse(extensionName);
    }
    // TODO(johnmccutchan): Handle restoring parts.
    return null;
  }

  /// Return the extension name for [fullName] or `null`.
  String _findExtensionNameFor(String fullName) {
    String result;
    _urlMappings.forEach((extensionName, pathMapping) {
      if (pathMapping == fullName) {
        result = extensionName;
      }
    });
    return result;
  }

  /// Return the library name of [importUri].
  String _libraryName(Uri importUri) {
    String uri = importUri.toString();
    int index = uri.indexOf('/');
    if (index >= 0) {
      return uri.substring(0, index);
    }
    return uri;
  }

  /// Return the part path of [importUri].
  String _partPath(Uri importUri) {
    String uri = importUri.toString();
    int index = uri.indexOf('/');
    if (index >= 0) {
      return uri.substring(index + 1);
    }
    return null;
  }

  /// Resolve an import of an sdk extension.
  Source _resolveEntry(Uri libraryEntry, Uri importUri) {
    // Library entry.
    JavaFile javaFile = new JavaFile.fromUri(libraryEntry);
    return new FileBasedSource(javaFile, importUri);
  }

  /// Resolve a 'part' statement inside an sdk extension.
  Source _resolvePart(Uri libraryEntry, String partPath, Uri importUri) {
    // Library part.
    String directory = pathos.dirname(libraryEntry.path);
    Uri partUri = new Uri.file(pathos.join(directory, partPath));
    assert(partUri.isAbsolute);
    JavaFile javaFile = new JavaFile.fromUri(partUri);
    return new FileBasedSource(javaFile, importUri);
  }
}
