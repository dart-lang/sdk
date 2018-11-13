// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:core';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/java_io.dart' show JavaFile;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart' show FileBasedSource;
import 'package:analyzer/src/source/package_map_provider.dart'
    show PackageMapProvider;
import 'package:path/path.dart' as pathos;

/// Given a packageMap (see [PackageMapProvider]), check in each package's lib
/// directory for the existence of a `_sdkext` file. This file must contain a
/// JSON encoded map. Each key in the map is a `dart:` library name. Each value
/// is a path (relative to the directory containing `_sdkext`) to a dart script
/// for the given library. For example:
/// {
///   "dart:sky": "../sdk_ext/dart_sky.dart"
/// }
///
/// If a key doesn't begin with `dart:` it is ignored.
class SdkExtUriResolver extends UriResolver {
  static const String SDK_EXT_NAME = '_sdkext';
  static const String DART_COLON_PREFIX = 'dart:';

  final Map<String, String> _urlMappings = <String, String>{};

  /**
   * The absolute paths of the extension files that contributed to the
   * [_urlMappings].
   */
  final List<String> extensionFilePaths = <String>[];

  /// Construct a [SdkExtUriResolver] from a package map
  /// (see [PackageMapProvider]).
  SdkExtUriResolver(Map<String, List<Folder>> packageMap) {
    if (packageMap == null) {
      return;
    }
    packageMap.forEach(_processPackage);
  }

  /// Number of sdk extensions.
  int get length => _urlMappings.length;

  /**
   * Return a table mapping the names of extensions to the paths where those
   * extensions can be found.
   */
  Map<String, String> get urlMappings =>
      new Map<String, String>.from(_urlMappings);

  /// Return the path mapping for [libName] or null if there is none.
  String operator [](String libName) => _urlMappings[libName];

  /// Programmatically add a new SDK extension given a JSON description
  /// ([sdkExtJSON]) and a lib directory ([libDir]).
  void addSdkExt(String sdkExtJSON, Folder libDir) {
    _processSdkExt(sdkExtJSON, libDir);
  }

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
    // This mapping points to the main entry file of the sdk extension.
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
    var result;
    _urlMappings.forEach((extensionName, pathMapping) {
      if (pathMapping == fullName) {
        result = extensionName;
      }
    });
    return result;
  }

  /// Return the library name of [importUri].
  String _libraryName(Uri importUri) {
    var uri = importUri.toString();
    int index = uri.indexOf('/');
    if (index >= 0) {
      return uri.substring(0, index);
    }
    return uri;
  }

  /// Return the part path of [importUri].
  String _partPath(Uri importUri) {
    var uri = importUri.toString();
    int index = uri.indexOf('/');
    if (index >= 0) {
      return uri.substring(index + 1);
    }
    return null;
  }

  /// Given a package [name] and a list of folders ([libDirs]),
  /// add any found sdk extensions.
  void _processPackage(String name, List<Folder> libDirs) {
    for (var libDir in libDirs) {
      var sdkExt = _readDotSdkExt(libDir);
      if (sdkExt != null) {
        _processSdkExt(sdkExt, libDir);
      }
    }
  }

  /// Given the JSON for an SDK extension ([sdkExtJSON]) and a folder
  /// ([libDir]), setup the uri mapping.
  void _processSdkExt(String sdkExtJSON, Folder libDir) {
    var sdkExt;
    try {
      sdkExt = json.decode(sdkExtJSON);
    } catch (e) {
      return;
    }
    if ((sdkExt == null) || (sdkExt is! Map)) {
      return;
    }
    bool contributed = false;
    sdkExt.forEach((k, v) {
      if (_processSdkExtension(k, v, libDir)) {
        contributed = true;
      }
    });
    if (contributed) {
      extensionFilePaths.add(libDir.getChild(SDK_EXT_NAME).path);
    }
  }

  /// Install the mapping from [name] to [libDir]/[file].
  bool _processSdkExtension(String name, String file, Folder libDir) {
    if (!name.startsWith(DART_COLON_PREFIX)) {
      // SDK extensions must begin with 'dart:'.
      return false;
    }
    var key = name;
    var value = libDir.canonicalizePath(file);
    _urlMappings[key] = value;
    return true;
  }

  /// Read the contents of [libDir]/[SDK_EXT_NAME] as a string.
  /// Returns null if the file doesn't exist.
  String _readDotSdkExt(Folder libDir) {
    File file = libDir.getChild(SDK_EXT_NAME);
    try {
      return file.readAsStringSync();
    } on FileSystemException {
      // File can't be read.
      return null;
    }
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
    var directory = pathos.dirname(libraryEntry.path);
    var partUri = new Uri.file(pathos.join(directory, partPath));
    assert(partUri.isAbsolute);
    JavaFile javaFile = new JavaFile.fromUri(partUri);
    return new FileBasedSource(javaFile, importUri);
  }
}
