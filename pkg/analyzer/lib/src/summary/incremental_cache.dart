// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show UTF8;
import 'dart:core' hide Resource;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:crypto/crypto.dart';

/**
 * The cache of per-library [PackageBundle]s.
 *
 * Note that currently this class is not intended for interactive use.
 */
class LibraryBundleCache {
  /**
   * To ensure that operations of writing files are atomic we create a temporary
   * file with this name in the [cacheFolder] and then rename it once we are
   * done writing.
   */
  final String tempFileName;

  /**
   * The folder to read and write files.
   */
  final Folder cacheFolder;

  /**
   * The context in which this cache is used.
   */
  final AnalysisContext context;

  /**
   * Opaque data that reflects the current configuration, such as the [context]
   * options, and is mixed into the hashes.
   */
  final List<int> configSalt;

  final Map<Source, CacheLibraryUris> _libraryUrisMap =
      <Source, CacheLibraryUris>{};
  final Map<Source, List<Source>> _libraryClosureMap = <Source, List<Source>>{};
  final Map<Source, List<int>> _sourceContentHashMap = <Source, List<int>>{};

  LibraryBundleCache(
      this.tempFileName, this.cacheFolder, this.context, this.configSalt);

  /**
   * Clear internal caches so that we read from file system again.
   */
  void clearInternalCaches() {
    _libraryUrisMap.clear();
    _libraryClosureMap.clear();
    _sourceContentHashMap.clear();
  }

  /**
   * Write information about the [library] into the cache.
   */
  void putLibrary(LibraryElement library) {
    try {
      _writeUris(library);
      List<int> hash = _getLibraryClosureHash(library.source);
      String hashStr = CryptoUtils.bytesToHex(hash);
      PackageBundleAssembler assembler = new PackageBundleAssembler();
      assembler.serializeLibraryElement(library);
      List<int> bytes = assembler.assemble().toBuffer();
      _safeWriteBytes('$hashStr.sum', bytes);
    } catch (e) {}
  }

  /**
   * Read the [PackageBundle] for the library with the given [source] from
   * the cache. The returned bundle will correspond to the state when the set
   * of direct and indirect dependencies is resolved in the [context]. Return
   * `null` if such bundle does not exist.
   */
  PackageBundle readBundle(Source source) {
    try {
      List<int> hash = _getLibraryClosureHash(source);
      String hashStr = CryptoUtils.bytesToHex(hash);
      List<int> bytes = _safeReadBytes('$hashStr.sum');
      if (bytes == null) {
        return null;
      }
      return new PackageBundle.fromBuffer(bytes);
    } catch (e) {
      return null;
    }
  }

  /**
   * Fill the whole source closure of the library with the given
   * [librarySource]. It includes defining units and parts of the library and
   * all its directly or indirectly imported or exported libraries.
   */
  void _appendLibraryClosure(Set<Source> closure, Source librarySource) {
    if (closure.add(librarySource)) {
      CacheLibraryUris libraryUris = _getUris(librarySource);
      if (libraryUris == null) {
        throw new StateError('No URIs for $librarySource');
      }
      // Append parts.
      for (String partUri in libraryUris.partUris) {
        Source partSource =
            context.sourceFactory.resolveUri(librarySource, partUri);
        if (partSource == null) {
          throw new StateError('Unable to resolve $partUri in $librarySource');
        }
        closure.add(partSource);
      }
      // Append imports and exports.
      void appendLibrarySources(String refUri) {
        Source refSource =
            context.sourceFactory.resolveUri(librarySource, refUri);
        if (refSource == null) {
          throw new StateError('Unable to resolve $refUri in $librarySource');
        }
        _appendLibraryClosure(closure, refSource);
      }
      libraryUris.importedUris.forEach(appendLibrarySources);
      libraryUris.exportedUris.forEach(appendLibrarySources);
    }
  }

  /**
   * Return the whole source closure of the library with the given
   * [librarySource]. It includes defining units and parts of the library and
   * of all its directly or indirectly imported or exported libraries.
   */
  List<Source> _getLibraryClosure(Source librarySource) {
    return _libraryClosureMap.putIfAbsent(librarySource, () {
      Set<Source> closure = new Set<Source>();
      _appendLibraryClosure(closure, librarySource);
      return closure.toList();
    });
  }

  /**
   * Return the [context]-specific hash of the closure of the library with
   * the given [librarySource].
   */
  List<int> _getLibraryClosureHash(Source librarySource) {
    List<Source> closure = _getLibraryClosure(librarySource);
    MD5 md5 = new MD5();
    for (Source source in closure) {
      List<int> sourceHash = _getSourceContentHash(source);
      md5.add(sourceHash);
    }
    md5.add(configSalt);
    return md5.close();
  }

  /**
   * Compute a hash of the given [source] contents.
   */
  List<int> _getSourceContentHash(Source source) {
    return _sourceContentHashMap.putIfAbsent(source, () {
      String sourceText = source.contents.data;
      List<int> sourceBytes = UTF8.encode(sourceText);
      return (new MD5()..add(sourceBytes)).close();
    });
  }

  /**
   * Get the URIs information of the library with the given [librarySource],
   * maybe `null` if the information is not in the cache.
   */
  CacheLibraryUris _getUris(Source librarySource) {
    CacheLibraryUris uris = _libraryUrisMap[librarySource];
    if (uris == null) {
      String fileName = _getUrisFileName(librarySource);
      List<int> bytes = _safeReadBytes(fileName);
      if (bytes == null) {
        return null;
      }
      uris = new CacheLibraryUris.fromBuffer(bytes);
      _libraryUrisMap[librarySource] = uris;
    }
    return uris;
  }

  /**
   * Return the name of the file with the [librarySource] URIs information.
   */
  String _getUrisFileName(Source librarySource) {
    List<int> hash = _getSourceContentHash(librarySource);
    String hashStr = CryptoUtils.bytesToHex(hash);
    return '$hashStr.uris';
  }

  /**
   * Return bytes of the file with the given [relPath] in the cache, or `null`
   * if the file does not exist.
   */
  List<int> _safeReadBytes(String relPath) {
    Resource urisFile = cacheFolder.getChild(relPath);
    if (urisFile is File) {
      try {
        return urisFile.readAsBytesSync();
      } on FileSystemException {}
    }
    return null;
  }

  /**
   * Atomically write the given [bytes] into the file with the given [relPath].
   * Silently ignores any errors.
   */
  void _safeWriteBytes(String relPath, List<int> bytes) {
    try {
      String absPath = cacheFolder.getChild(relPath).path;
      File tempFile = cacheFolder.getChild(tempFileName);
      tempFile.writeAsBytesSync(bytes);
      tempFile.renameSync(absPath);
    } catch (e) {}
  }

  /**
   * Write URIs information for the given [library] and its direct and
   * indirect imports/exports.
   */
  void _writeUris(LibraryElement library,
      [Set<LibraryElement> writtenLibraries]) {
    Source librarySource = library.source;
    // Do nothing if already cached.
    if (_libraryUrisMap.containsKey(librarySource)) {
      return;
    }
    // Stop recursion cycle.
    writtenLibraries ??= new Set<LibraryElement>();
    if (!writtenLibraries.add(library)) {
      return;
    }
    // Prepare import/export URIs.
    List<String> importUris = <String>[];
    List<String> exportUris = <String>[];
    for (ImportElement element in library.imports) {
      String uri = element.uri;
      if (uri != null) {
        importUris.add(uri);
        _writeUris(element.importedLibrary, writtenLibraries);
      }
    }
    for (ExportElement element in library.exports) {
      String uri = element.uri;
      if (uri != null) {
        exportUris.add(uri);
        _writeUris(element.exportedLibrary, writtenLibraries);
      }
    }
    // Write the URIs.
    CacheLibraryUrisBuilder b = new CacheLibraryUrisBuilder(
        importedUris: importUris,
        exportedUris: exportUris,
        partUris: library.parts.map((e) => e.uri).toList());
    List<int> bytes = b.toBuffer();
    String fileName = _getUrisFileName(librarySource);
    _safeWriteBytes(fileName, bytes);
    // Put into the cache to avoid reading it later.
    _libraryUrisMap[librarySource] = new CacheLibraryUris.fromBuffer(bytes);
  }
}
