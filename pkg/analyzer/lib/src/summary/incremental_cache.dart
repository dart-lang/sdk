// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show ChunkedConversionSink, UTF8;
import 'dart:core' hide Resource;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:convert/convert.dart';
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
  final Map<Source, List<int>> _libraryClosureHashMap = <Source, List<int>>{};
  final Map<Source, List<int>> _sourceContentHashMap = <Source, List<int>>{};

  /**
   * Mapping from a library closure key to its [PackageBundle].
   */
  final Map<String, PackageBundle> _bundleMap = <String, PackageBundle>{};

  final Map<String, Source> _absoluteUriMap = <String, Source>{};

  IncrementalCache(this.storage, this.context, this.configSalt);

  /**
   * Clear internal caches so that we read from file system again.
   */
  void clearInternalCaches() {
    _sourceContentMap.clear();
    _libraryClosureMap.clear();
    _sourceContentHashMap.clear();
    _bundleMap.clear();
  }

  /**
   * Return all summaries that are required to provide results about the library
   * with the given [librarySource] from its summary.  It includes all of the
   * bundles in the import/export closure of the library.  If any of the
   * bundles are not in the cache, then `null` is returned.  If any of the
   * [LibraryBundleWithId]s were already returned as a part of the closure of
   * another library, they are still included - it is up to the client to
   * decide whether a bundle should be used or not, but it is easy to do
   * using [LibraryBundleWithId.id].
   */
  List<LibraryBundleWithId> getLibraryClosureBundles(Source librarySource) {
    try {
      List<Source> closureSources = _getLibraryClosure(librarySource);
      List<LibraryBundleWithId> closureBundles = <LibraryBundleWithId>[];
      for (Source source in closureSources) {
        if (source.isInSystemLibrary) {
          continue;
        }
        if (getSourceKind(source) == SourceKind.PART) {
          continue;
        }
        String key = _getLibraryBundleKey(source);
        PackageBundle bundle = _getLibraryBundle(key);
        if (bundle == null) {
          return null;
        }
        closureBundles.add(new LibraryBundleWithId(source, key, bundle));
      }
      return closureBundles;
    } catch (e) {
      return null;
    }
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
   * Write information about the [libraryElement] into the cache.
   */
  void putLibrary(LibraryElement libraryElement) {
    _writeCacheSourceContents(libraryElement);
    String key = _getLibraryBundleKey(libraryElement.source);
    PackageBundleAssembler assembler = new PackageBundleAssembler();
    assembler.serializeLibraryElement(libraryElement);
    List<int> bytes = assembler.assemble().toBuffer();
    storage.put(key, bytes);
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
        Source partSource = _resolveUri(librarySource, partUri);
        if (partSource == null) {
          throw new StateError('Unable to resolve $partUri in $librarySource');
        }
        closure.add(partSource);
      }
      // Append imports and exports.
      void appendLibrarySources(String refUri) {
        Source refSource = _resolveUri(librarySource, refUri);
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
    String hashStr = hex.encode(hash);
    return '$hashStr.content';
  }

  /**
   * Get the bundle for the given key.
   */
  PackageBundle _getLibraryBundle(String key) {
    PackageBundle bundle = _bundleMap[key];
    if (bundle == null) {
      List<int> bytes = storage.get(key);
      if (bytes == null) {
        return null;
      }
      bundle = new PackageBundle.fromBuffer(bytes);
      _bundleMap[key] = bundle;
    }
    return bundle;
  }

  /**
   * Return the key of the bundle of the [librarySource].
   */
  String _getLibraryBundleKey(Source librarySource) {
    List<int> hash = _getLibraryClosureHash(librarySource);
    String hashStr = hex.encode(hash);
    return '$hashStr.summary';
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
    return _libraryClosureHashMap.putIfAbsent(librarySource, () {
      List<Source> closure = _getLibraryClosure(librarySource);

      Digest digest;

      var digestSink = new ChunkedConversionSink<Digest>.withCallback(
          (List<Digest> digests) {
        digest = digests.single;
      });

      var byteSink = md5.startChunkedConversion(digestSink);

      for (Source source in closure) {
        List<int> sourceHash = _getSourceContentHash(source);
        byteSink.add(sourceHash);
      }
      byteSink.add(configSalt);

      byteSink.close();
      // TODO(paulberry): this call to `close` should not be needed.
      // Can be removed once
      //   https://github.com/dart-lang/crypto/issues/33
      // is fixed – ensure the min version constraint on crypto is updated, tho.
      // Does not cause any problems in the mean time.
      digestSink.close();

      return digest.bytes;
    });
  }

  /**
   * Compute a hash of the given [source] contents.
   */
  List<int> _getSourceContentHash(Source source) {
    return _sourceContentHashMap.putIfAbsent(source, () {
      String sourceText = source.contents.data;
      List<int> sourceBytes = UTF8.encode(sourceText);
      return md5.convert(sourceBytes).bytes;
    });
  }

  /**
   * Return a source representing the URI that results from resolving the given
   * (possibly relative) [containedUri] against the URI associated with the
   * [containingSource], whether or not the resulting source exists, or `null`
   * if either the [containedUri] is invalid or if it cannot be resolved against
   * the [containingSource]'s URI.
   */
  Source _resolveUri(Source containingSource, String containedUri) {
    // Cache absolute URIs.
    if (containedUri.startsWith('dart:') ||
        containedUri.startsWith('package:')) {
      return _absoluteUriMap.putIfAbsent(containedUri, () {
        return context.sourceFactory.resolveUri(containingSource, containedUri);
      });
    }
    // Resolve relative URIs without caching.
    return context.sourceFactory.resolveUri(containingSource, containedUri);
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

/**
 * The bundle for a source in the context.
 */
class LibraryBundleWithId {
  /**
   * The source of the library this bundle is for.
   */
  final Source source;

  /**
   * The unique ID of the [bundle] of the [source] in the context.
   */
  final String id;

  /**
   * The payload bundle.
   */
  final PackageBundle bundle;

  LibraryBundleWithId(this.source, this.id, this.bundle);
}
