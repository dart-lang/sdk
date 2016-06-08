// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.context_factory;

import 'dart:convert';
import 'dart:core' hide Resource;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:yaml/yaml.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'dart:io' as io;

/// (Placeholder)
abstract class ContextFactory {
  /// Create an analysis context for the given [source] directory or file, with
  /// the given [defaultOptions].
  AnalysisContext createContext(
      io.FileSystemEntity source, AnalysisOptions defaultOptions);
}

/// Processes package maps, extracting SDK embedders and extenders, creating a
/// consolidated [libraryMap].
class PackageMapProcessor {
  static const String _EMBEDDED_LIB_MAP_KEY = 'embedded_libs';
  static const String _EMBEDDER_FILE_NAME = '_embedder.yaml';
  static const String _SDK_EXT_NAME = '_sdkext';

  /// Map of processed embedder libraries.
  final LibraryMap embeddedLibraries = new LibraryMap();

  /// Map of processed SDK extension libraries.
  final LibraryMap extendedLibraries = new LibraryMap();

  /// Combined map of processed libraries.
  LibraryMap get libraryMap {
    LibraryMap libraryMap = new LibraryMap();

    // Add extenders first, allowing for overwrite by embedders who take precedence.
    for (String uri in extendedLibraries.uris) {
      libraryMap.setLibrary(uri, extendedLibraries.getLibrary(uri));
    }
    for (String uri in embeddedLibraries.uris) {
      libraryMap.setLibrary(uri, embeddedLibraries.getLibrary(uri));
    }
    return libraryMap;
  }

  /// Create a processor for the given [packageMap].
  PackageMapProcessor(Map<String, List<Folder>> packageMap) {
    packageMap?.forEach(_processPackage);
  }

  /// Whether the package map contains an SDK embedder.
  bool get hasEmbedder => embeddedLibraries.size() > 0;

  /// Whether the package map contains an SDK extension.
  bool get hasSdkExtension => extendedLibraries.size() > 0;

  void _processEmbedderYaml(String embedderYaml, Folder libDir) {
    try {
      YamlNode map = loadYaml(embedderYaml);
      if (map is YamlMap) {
        YamlNode embedded_libs = map[_EMBEDDED_LIB_MAP_KEY];
        if (embedded_libs is YamlMap) {
          embedded_libs.forEach(
              (k, v) => _processMapping(embeddedLibraries, k, v, libDir));
        }
      }
    } catch (_) {
      // Ignored.
    }
  }

  void _processMapping(
      LibraryMap libraryMap, String name, String file, Folder libDir) {
    if (!_hasDartPrefix(name)) {
      // SDK libraries must begin with 'dart:'.
      return;
    }
    if (libraryMap.getLibrary(name) != null) {
      // Libraries can't be redefined.
      return;
    }
    String libPath = libDir.canonicalizePath(file);
    SdkLibraryImpl library = new SdkLibraryImpl(name)..path = libPath;
    libraryMap.setLibrary(name, library);
  }

  void _processPackage(String name, List<Folder> libDirs) {
    for (Folder libDir in libDirs) {
      String embedderYaml = _readEmbedderYaml(libDir);
      if (embedderYaml != null) {
        _processEmbedderYaml(embedderYaml, libDir);
      }
      String sdkExt = _readDotSdkExt(libDir);
      if (sdkExt != null) {
        _processSdkExt(sdkExt, libDir);
      }
    }
  }

  void _processSdkExt(String sdkExtJSON, Folder libDir) {
    try {
      var sdkExt = JSON.decode(sdkExtJSON);
      if (sdkExt is Map) {
        sdkExt.forEach(
            (k, v) => _processMapping(extendedLibraries, k, v, libDir));
      }
    } catch (_) {
      // Ignored.
    }
  }

  static bool _hasDartPrefix(String uri) =>
      uri.startsWith(DartSdk.DART_LIBRARY_PREFIX);

  static String _readDotSdkExt(Folder libDir) =>
      _safeRead(libDir.getChild(_SDK_EXT_NAME));

  static String _readEmbedderYaml(Folder libDir) =>
      _safeRead(libDir.getChild(_EMBEDDER_FILE_NAME));

  static String _safeRead(Resource file) {
    try {
      if (file is File) {
        return file.readAsStringSync();
      }
    } on FileSystemException {
      // File can't be read.
    }
    return null;
  }
}
