// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_context.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

class AnalyzerStatePrinter {
  final MemoryByteStore byteStore;
  final FileStateIdProvider fileStateIdProvider;
  final KeyShorter keyShorter;
  final LibraryContext libraryContext;
  final ResourceProvider resourceProvider;
  final StringSink sink;

  String _indent = '';

  AnalyzerStatePrinter({
    required this.byteStore,
    required this.fileStateIdProvider,
    required this.keyShorter,
    required this.libraryContext,
    required this.resourceProvider,
    required this.sink,
  });

  FileSystemState get fileSystemState => libraryContext.fileSystemState;

  void writeAnalysisDriver(AnalysisDriverTestView testData) {
    _writeFiles(testData.fileSystem);
    _writeLibraryContext(testData.libraryContext);
    _writeElementFactory();
    _writeByteStore();
  }

  void writeFileResolver(FileResolverTestData testData) {
    _writeFiles(testData.fileSystem);
    _writeLibraryContext(testData.libraryContext);
    _writeElementFactory();
    _writeByteStore();
  }

  /// If the path style is `Windows`, returns the corresponding Posix path.
  /// Otherwise the path is already a Posix path, and it is returned as is.
  String _posixPath(File file) {
    final pathContext = resourceProvider.pathContext;
    if (pathContext.style == Style.windows) {
      final components = pathContext.split(file.path);
      return '/${components.skip(1).join('/')}';
    } else {
      return file.path;
    }
  }

  void _withIndent(void Function() f) {
    var indent = _indent;
    _indent = '$_indent  ';
    f();
    _indent = indent;
  }

  void _writeByteStore() {
    _writelnWithIndent('byteStore');
    _withIndent(() {
      final groups = byteStore.map.entries.groupListsBy((element) {
        return element.value.refCount;
      });

      for (final groupEntry in groups.entries) {
        final keys = groupEntry.value.map((e) => e.key).toList();
        final shortKeys = keyShorter.shortKeys(keys)..sort();
        _writelnWithIndent('${groupEntry.key}: $shortKeys');
      }
    });
  }

  void _writeElementFactory() {
    _writelnWithIndent('elementFactory');
    _withIndent(() {
      final elementFactory = libraryContext.elementFactory;
      _writeUriList(
        'hasElement',
        elementFactory.uriListWithLibraryElements,
      );
      _writeUriList(
        'hasReader',
        elementFactory.uriListWithLibraryReaders,
      );
    });
  }

  void _writeFile(FileState file) {
    _withIndent(() {
      _writelnWithIndent('id: ${fileStateIdProvider[file]}');
      _writeFileKind(file);
      _writeFileUnlinkedKey(file);
    });
  }

  void _writeFileKind(FileState file) {
    final kind = file.kind;
    if (kind is LibraryFileStateKind) {
      _writelnWithIndent('kind: library');
      expect(kind.library.file, same(file));
    } else if (kind is PartOfNameFileStateKind) {
      _writelnWithIndent('kind: partOfName');
      _withIndent(() {
        final library = kind.library;
        if (library != null) {
          final id = fileStateIdProvider[library.file];
          _writelnWithIndent('library: $id');
        } else {
          _writelnWithIndent('name: ${kind.directive.name}');
        }
      });
    } else if (kind is PartOfUriKnownFileStateKind) {
      _writelnWithIndent('kind: partOfUriKnown');
      _withIndent(() {
        final library = kind.library;
        if (library != null) {
          final id = fileStateIdProvider[library.file];
          _writelnWithIndent('library: $id');
        } else {
          final id = fileStateIdProvider[kind.uriFile];
          _writelnWithIndent('uriFile: $id');
        }
      });
    } else {
      throw UnimplementedError('${kind.runtimeType}');
    }
  }

  void _writeFiles(FileSystemTestData testData) {
    final fileMap = testData.files;
    final fileDataList = fileMap.values.toList();
    fileDataList.sortBy((fileData) => fileData.file.path);

    // Ask ID for every file in the sorted order, so that IDs are nice.
    for (final fileData in fileDataList) {
      final current = fileSystemState.getExisting(fileData.file);
      if (current != null) {
        fileStateIdProvider[current];
      }
    }

    _writelnWithIndent('files');
    _withIndent(() {
      for (final fileData in fileDataList) {
        final file = fileData.file;
        _writelnWithIndent(_posixPath(file));
        _withIndent(() {
          final current = fileSystemState.getExisting(file);
          if (current != null) {
            _writelnWithIndent('current');
            _writeFile(current);
          }

          final shortGets = keyShorter.shortKeys(fileData.unlinkedKeyGet);
          final shortPuts = keyShorter.shortKeys(fileData.unlinkedKeyPut);
          _writelnWithIndent('unlinkedGet: $shortGets');
          _writelnWithIndent('unlinkedPut: $shortPuts');

          _writelnWithIndent('uri: ${fileData.uri}');
        });
      }
    });
  }

  void _writeFileUnlinkedKey(FileState file) {
    final unlinkedShort = keyShorter.shortKey(file.unlinkedKey);
    _writelnWithIndent('unlinkedKey: $unlinkedShort');
  }

  void _writeLibraryContext(LibraryContextTestData testData) {
    _writelnWithIndent('libraryCycles');
    _withIndent(() {
      final entries = testData.libraryCycles.entries
          .mapKey((key) => key.map(_posixPath).join(' '))
          .toList();
      entries.sortBy((e) => e.key);

      final loadedBundlesMap = Map.fromEntries(
        libraryContext.loadedBundles.map((cycle) {
          final key = cycle.libraries
              .map((fileState) => fileState.resource)
              .map(_posixPath)
              .join(' ');
          return MapEntry(key, cycle);
        }),
      );

      for (final entry in entries) {
        _writelnWithIndent(entry.key);
        _withIndent(() {
          final current = loadedBundlesMap[entry.key];
          if (current != null) {
            _writelnWithIndent('current');
            _withIndent(() {
              final short = keyShorter.shortKey(current.resolutionKey!);
              _writelnWithIndent('key: $short');

              final fileIdList = current.libraries
                  .map((fileState) => fileStateIdProvider[fileState])
                  .toList();
              _writelnWithIndent('libraries: ${fileIdList.join(' ')}');
            });
          }

          final shortGets = keyShorter.shortKeys(entry.value.getKeys);
          final shortPuts = keyShorter.shortKeys(entry.value.putKeys);
          _writelnWithIndent('get: $shortGets');
          _writelnWithIndent('put: $shortPuts');
        });
      }
    });
  }

  void _writelnWithIndent(String line) {
    sink.write(_indent);
    sink.writeln(line);
  }

  void _writeUriList(String name, Iterable<Uri> uriIterable) {
    final uriStrList = uriIterable.map((uri) => '$uri').toList();
    if (uriStrList.isNotEmpty) {
      uriStrList.sort();
      _writelnWithIndent(name);
      _withIndent(() {
        for (final uriStr in uriStrList) {
          _writelnWithIndent(uriStr);
        }
      });
    }
  }
}

class FileStateIdProvider {
  final Map<FileState, String> _map = Map.identity();

  String operator [](FileState file) {
    return _map[file] ??= 'file_${_map.length}';
  }
}

/// Keys in the byte store are long hashes, which are hard to read.
/// So, we generate short unique versions for them.
class KeyShorter {
  final Map<String, String> _keyToShort = {};
  final Map<String, String> _shortToKey = {};

  String shortKey(String key) {
    var short = _keyToShort[key];
    if (short == null) {
      short = 'k${_keyToShort.length.toString().padLeft(2, '0')}';
      _keyToShort[key] = short;
      _shortToKey[short] = key;
    }
    return short;
  }

  List<String> shortKeys(List<String> keys) {
    return keys.map(shortKey).toList();
  }
}

extension<K, V> on Iterable<MapEntry<K, V>> {
  Iterable<MapEntry<K2, V>> mapKey<K2>(K2 Function(K key) convertKey) {
    return map((e) {
      final newKey = convertKey(e.key);
      return MapEntry(newKey, e.value);
    });
  }
}
