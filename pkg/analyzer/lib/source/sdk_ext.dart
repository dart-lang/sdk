// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source.sdk_ext;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:core' hide Resource;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/java_io.dart' show JavaFile;
import 'package:analyzer/src/generated/source_io.dart' show FileBasedSource;
import 'package:path/path.dart' as pathos;

class _SdkExtFileBasedSource extends FileBasedSource {
  _SdkExtFileBasedSource(JavaFile file, Uri uri)
      : super(file, uri);
}

/// Given a packageMap (see [PackageMapProvider]), check in each package's lib
/// directory for the existence of a `.sdkext` file. This file must contain a
/// JSON encoded map. Each key in the map is a `dart:` library name. Each value
/// is a path (relative to the directory containing `.sdkext`) to a dart script
/// for the given library. For example:
/// {
///   "dart:sky": "../sdk_ext/dart_sky.dart"
/// }
///
/// If a key doesn't begin with `dart:` it is ignored.
class SdkExtUriResolver extends UriResolver {
  static const String DOT_SDK_EXT_NAME = '.sdkext';
  static const String DART_COLON_PREFIX = 'dart:';

  final Map<String, String> _urlMappings = <String,String>{};

  /// Construct a [SdkExtUriResolver] from a package map
  /// (see [PackageMapProvider]).
  SdkExtUriResolver(Map<String, List<Folder>> packageMap) {
    if (packageMap == null) {
      return;
    }
    packageMap.forEach(_processPackage);
  }

  /// Programmatically add a new SDK extension given a JSON description
  /// ([sdkExtJSON]) and a lib directory ([libDir]).
  void addSdkExt(String sdkExtJSON, Folder libDir) {
    _processSdkExt(sdkExtJSON, libDir);
  }

  /// Return the path mapping for [libName] or null if there is none.
  String operator[](String libName) => _urlMappings[libName];

  /// Number of sdk extensions.
  int get length => _urlMappings.length;

  /// Resolve a 'part' statement inside an sdk extension.
  Source _resolvePart(Uri libraryEntry, String partPath, Uri importUri) {
    // Library part.
    var directory = pathos.dirname(libraryEntry.path);
    var partUri = new Uri.file(pathos.join(directory, partPath));
    assert(partUri.isAbsolute);
    JavaFile javaFile = new JavaFile.fromUri(partUri);
    return new _SdkExtFileBasedSource(javaFile, importUri);
  }

  /// Resolve an import of an sdk extension.
  Source _resolveEntry(Uri libraryEntry, Uri importUri) {
    // Library entry.
    JavaFile javaFile = new JavaFile.fromUri(libraryEntry);
    return new _SdkExtFileBasedSource(javaFile, importUri);
  }

  @override
  Source resolveAbsolute(Uri importUri) {
    // Split import uri into library name and (optionally) a part path.
    var uri = importUri.toString();
    String libraryName;
    String partPath;
    int index = uri.indexOf('/');
    if (index >= 0) {
      libraryName = uri.substring(0, index);
      partPath = uri.substring(index + 1);
    } else {
      libraryName = uri;
    }
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

    if (index >= 0) {
      return _resolvePart(libraryEntry, partPath, importUri);
    } else {
      return _resolveEntry(libraryEntry, importUri);
    }
  }

  @override
  Uri restoreAbsolute(Source source) {
    if (source is _SdkExtFileBasedSource) {
      return source.uri;
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

  /// Read the contents of [libDir]/[DOT_SDK_EXT_NAME] as a string.
  /// Returns null if the file doesn't exist.
  String _readDotSdkExt(Folder libDir) {
    var file = libDir.getChild(DOT_SDK_EXT_NAME);
    try {
      return file.readAsStringSync();
    } on FileSystemException catch (e) {
      // File can't be read.
      return null;
    }
  }

  /// Given the JSON for an SDK extension ([sdkExtJSON]) and a folder
  /// ([libDir]), setup the uri mapping.
  void _processSdkExt(String sdkExtJSON, Folder libDir) {
    var sdkExt;
    try {
      sdkExt = JSON.decode(sdkExtJSON);
    } catch (e) {
      return;
    }
    if ((sdkExt == null) || (sdkExt is! Map)) {
      return;
    }
    sdkExt.forEach((k, v) => _processSdkExtension(k, v, libDir));
  }

  /// Install the mapping from [name] to [libDir]/[file].
  void _processSdkExtension(String name, String file, Folder libDir) {
    if (!name.startsWith(DART_COLON_PREFIX)) {
      // SDK extensions must begin with 'dart:'.
      return;
    }
    var key = name;
    var value = libDir.canonicalizePath(file);
    _urlMappings[key] = value;
  }
}
