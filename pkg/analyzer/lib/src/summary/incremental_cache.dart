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
 * Storage for cache data.
 */
abstract class CacheStorage {
  /**
   * Return bytes for the given [key], `null` if [key] is not in the storage.
   */
  List<int> get(String key);

  /**
   * Associate the [key] with the given [bytes].
   *
   * If the [key] was already in the storage, its associated value is changed.
   * Otherwise the key-value pair is added to the storage.
   *
   * It is not guaranteed that data will always be accessible using [get], in
   * some implementations association may silently fail or become inaccessible
   * after some time.
   */
  void put(String key, List<int> bytes);
}

/**
 * A [Folder] based implementation of [CacheStorage].
 */
class FolderCacheStorage implements CacheStorage {
  /**
   * The folder to read and write files.
   */
  final Folder folder;

  /**
   * To ensure that operations of writing files are atomic we create a temporary
   * file with this name in the [folder] and then rename it once we are
   * done writing.
   */
  final String tempFileName;

  FolderCacheStorage(this.folder, this.tempFileName);

  @override
  List<int> get(String key) {
    Resource file = folder.getChild(key);
    if (file is File) {
      try {
        return file.readAsBytesSync();
      } on FileSystemException {}
    }
    return null;
  }

  @override
  void put(String key, List<int> bytes) {
    String absPath = folder.getChild(key).path;
    File tempFile = folder.getChild(tempFileName);
    tempFile.writeAsBytesSync(bytes);
    try {
      tempFile.renameSync(absPath);
    } catch (e) {}
  }
}

/**
 * Cache of information to support incremental analysis.
 *
 * Note that currently this class is not intended for interactive use.
 */
class IncrementalCache {
  /**
   * The storage for the cache data.
   */
  final CacheStorage storage;

  /**
   * The context in which this cache is used.
   */
  final AnalysisContext context;

  /**
   * Opaque data that reflects the current configuration, such as the [context]
   * options, and is mixed into the hashes.
   */
  final List<int> configSalt;

  final Map<Source, CacheSourceContent> _sourceContentMap =
      <Source, CacheSourceContent>{};
  final Map<Source, List<Source>> _libraryClosureMap = <Source, List<Source>>{};
  final Map<Source, List<int>> _sourceContentHashMap = <Source, List<int>>{};

  IncrementalCache(this.storage, this.context, this.configSalt);

  /**
   * Clear internal caches so that we read from file system again.
   */
  void clearInternalCaches() {
    _sourceContentMap.clear();
    _libraryClosureMap.clear();
    _sourceContentHashMap.clear();
  }

  /**
   * Return the kind of the given [source], or `null` if unknown.
   */
  SourceKind getSourceKind(Source source) {
    try {
      CacheSourceContent contentSource = _getCacheSourceContent(source);
      if (contentSource != null) {
        if (contentSource.kind == CacheSourceKind.library) {
          return SourceKind.LIBRARY;
        }
        if (contentSource.kind == CacheSourceKind.part) {
          return SourceKind.PART;
        }
      }
    } catch (e) {}
    return null;
  }

  /**
   * Write information about the [library] into the cache.
   */
  void putLibrary(LibraryElement library) {
    _writeCacheSourceContents(library);
    List<int> hash = _getLibraryClosureHash(library.source);
    String hashStr = CryptoUtils.bytesToHex(hash);
    PackageBundleAssembler assembler = new PackageBundleAssembler();
    assembler.serializeLibraryElement(library);
    List<int> bytes = assembler.assemble().toBuffer();
    storage.put('$hashStr.sum', bytes);
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
      List<int> bytes = storage.get('$hashStr.sum');
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
      CacheSourceContent contentSource = _getCacheSourceContent(librarySource);
      if (contentSource == null) {
        throw new StateError('No structure for $librarySource');
      }
      // Append parts.
      for (String partUri in contentSource.partUris) {
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
      contentSource.importedUris.forEach(appendLibrarySources);
      contentSource.exportedUris.forEach(appendLibrarySources);
    }
  }

  /**
   * Get the content based information about the given [source], maybe `null`
   * if the information is not in the cache.
   */
  CacheSourceContent _getCacheSourceContent(Source source) {
    CacheSourceContent content = _sourceContentMap[source];
    if (content == null) {
      String key = _getCacheSourceContentKey(source);
      List<int> bytes = storage.get(key);
      if (bytes == null) {
        return null;
      }
      content = new CacheSourceContent.fromBuffer(bytes);
      _sourceContentMap[source] = content;
    }
    return content;
  }

  /**
   * Return the key of the content based [source] information.
   */
  String _getCacheSourceContentKey(Source source) {
    List<int> hash = _getSourceContentHash(source);
    String hashStr = CryptoUtils.bytesToHex(hash);
    return '$hashStr.content';
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
   * Write the content based information about the given [source].
   */
  void _writeCacheSourceContent(Source source, CacheSourceContentBuilder b) {
    String key = _getCacheSourceContentKey(source);
    List<int> bytes = b.toBuffer();
    storage.put(key, bytes);
    // Put into the cache to avoid reading it later.
    _sourceContentMap[source] = new CacheSourceContent.fromBuffer(bytes);
  }

  /**
   * Write [CacheSourceContent] for every unit of the given [library] and its
   * direct and indirect imports/exports.
   */
  void _writeCacheSourceContents(LibraryElement library,
      [Set<LibraryElement> writtenLibraries]) {
    Source librarySource = library.source;
    // Do nothing if already cached.
    if (_sourceContentMap.containsKey(librarySource)) {
      return;
    }
    // Stop recursion cycle.
    writtenLibraries ??= new Set<LibraryElement>();
    if (!writtenLibraries.add(library)) {
      return;
    }
    // Write parts.
    List<String> partUris = <String>[];
    for (CompilationUnitElement part in library.parts) {
      partUris.add(part.uri);
      Source partSource = part.source;
      if (context.getKindOf(partSource) == SourceKind.PART) {
        _writeCacheSourceContent(partSource,
            new CacheSourceContentBuilder(kind: CacheSourceKind.part));
      }
    }
    // Write imports.
    List<String> importUris = <String>[];
    for (ImportElement element in library.imports) {
      String uri = element.uri;
      if (uri != null) {
        importUris.add(uri);
        _writeCacheSourceContents(element.importedLibrary, writtenLibraries);
      }
    }
    // Write exports.
    List<String> exportUris = <String>[];
    for (ExportElement element in library.exports) {
      String uri = element.uri;
      if (uri != null) {
        exportUris.add(uri);
        _writeCacheSourceContents(element.exportedLibrary, writtenLibraries);
      }
    }
    // Write the library.
    _writeCacheSourceContent(
        librarySource,
        new CacheSourceContentBuilder(
            kind: CacheSourceKind.library,
            importedUris: importUris,
            exportedUris: exportUris,
            partUris: partUris));
  }
}
