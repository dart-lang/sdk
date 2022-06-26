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
  final FileStateKindIdProvider fileStateKindIdProvider;
  final FileStateIdProvider fileStateIdProvider;
  final KeyShorter keyShorter;
  final LibraryContext libraryContext;
  final bool omitSdkFiles;
  final ResourceProvider resourceProvider;
  final StringSink sink;
  final bool withKeysGetPut;

  String _indent = '';

  AnalyzerStatePrinter({
    required this.byteStore,
    required this.fileStateKindIdProvider,
    required this.fileStateIdProvider,
    required this.keyShorter,
    required this.libraryContext,
    required this.omitSdkFiles,
    required this.resourceProvider,
    required this.sink,
    required this.withKeysGetPut,
  });

  FileSystemState get fileSystemState => libraryContext.fileSystemState;

  void writeAnalysisDriver(AnalysisDriverTestView testData) {
    _writeFiles(testData.fileSystem);
    _writeLibraryContext(testData.libraryContext);
    _writeElementFactory();
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

  /// TODO(scheglov) Support unresolved URIs, not augmentations, etc.
  void _writeAugmentations(LibraryOrAugmentationFileKind kind) {
    final files = kind.file.augmentationFiles.whereNotNull();
    if (files.isNotEmpty) {
      final keys = files.map((e) => fileStateIdProvider[e]).join(' ');
      _writelnWithIndent('augmentations: $keys');
    }
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

  void _writeElements<T>(String name, List<T> elements, void Function(T) f) {
    if (elements.isNotEmpty) {
      _writelnWithIndent(name);
      _withIndent(() {
        for (var element in elements) {
          f(element);
        }
      });
    }
  }

  void _writeFile(FileState file) {
    _withIndent(() {
      _writelnWithIndent('id: ${fileStateIdProvider[file]}');
      _writeFileKind(file);
      _writeReferencingFiles(file);
      _writeFileUnlinkedKey(file);
    });
  }

  void _writeFileExports(LibraryOrAugmentationFileKind file) {
    _writeElements<ExportDirectiveState>('exports', file.exports, (export) {
      if (export is ExportDirectiveWithFile) {
        final file = export.exportedFile;
        sink.write(_indent);

        final exportedLibrary = export.exportedLibrary;
        if (exportedLibrary != null) {
          expect(exportedLibrary.file, file);
          sink.write(fileStateKindIdProvider[exportedLibrary]);
        } else {
          sink.write('notLibrary ${fileStateIdProvider[file]}');
        }

        if (omitSdkFiles && file.uri.isScheme('dart')) {
          sink.write(' ${file.uri}');
        }
        sink.writeln();
      } else if (export is ExportDirectiveWithInSummarySource) {
        sink.write(_indent);
        sink.write('inSummary ${export.exportedSource.uri}');

        final librarySource = export.exportedLibrarySource;
        if (librarySource != null) {
          expect(librarySource, same(export.exportedSource));
        } else {
          sink.write(' notLibrary');
        }
        sink.writeln();
      } else {
        sink.write(_indent);
        sink.write('uri: ${export.directive.uri}');
        sink.writeln();
      }
    });
  }

  void _writeFileImports(LibraryOrAugmentationFileKind file) {
    _writeElements<ImportDirectiveState>('imports', file.imports, (import) {
      if (import is ImportDirectiveWithFile) {
        final file = import.importedFile;
        sink.write(_indent);

        final importedLibrary = import.importedLibrary;
        if (importedLibrary != null) {
          expect(importedLibrary.file, file);
          sink.write(fileStateKindIdProvider[importedLibrary]);
        } else {
          sink.write('notLibrary ${fileStateIdProvider[file]}');
        }

        if (omitSdkFiles && file.uri.isScheme('dart')) {
          sink.write(' ${file.uri}');
        }

        if (import.isSyntheticDartCoreImport) {
          sink.write(' synthetic');
        }
        sink.writeln();
      } else if (import is ImportDirectiveWithInSummarySource) {
        sink.write(_indent);
        sink.write('inSummary ${import.importedSource.uri}');

        final librarySource = import.importedLibrarySource;
        if (librarySource != null) {
          expect(librarySource, same(import.importedSource));
        } else {
          sink.write(' notLibrary');
        }

        if (import.isSyntheticDartCoreImport) {
          sink.write(' synthetic');
        }
        sink.writeln();
      } else {
        sink.write(_indent);
        sink.write('uri: ${import.directive.uri}');
        if (import.isSyntheticDartCoreImport) {
          sink.write(' synthetic');
        }
        sink.writeln();
      }
    });
  }

  void _writeFileKind(FileState file) {
    final kind = file.kind;
    expect(kind.file, same(file));

    _writelnWithIndent('kind: ${fileStateKindIdProvider[kind]}');
    if (kind is AugmentationKnownFileStateKind) {
      _withIndent(() {
        final augmented = kind.augmented;
        if (augmented != null) {
          final id = fileStateKindIdProvider[augmented];
          _writelnWithIndent('augmented: $id');
        } else {
          final id = fileStateIdProvider[kind.uriFile];
          _writelnWithIndent('uriFile: $id');
        }

        final library = kind.library;
        if (library != null) {
          final id = fileStateKindIdProvider[library];
          _writelnWithIndent('library: $id');
        }

        _writeFileImports(kind);
        _writeFileExports(kind);
        _writeAugmentations(kind);
      });
    } else if (kind is AugmentationUnknownFileStateKind) {
      _withIndent(() {
        _writelnWithIndent('uri: ${kind.directive.uri}');
      });
    } else if (kind is LibraryFileStateKind) {
      expect(kind.library, same(kind));

      _withIndent(() {
        final name = kind.name;
        if (name != null) {
          _writelnWithIndent('name: $name');
        }

        _writeFileImports(kind);
        _writeFileExports(kind);
        _writeLibraryParts(kind);
        _writeAugmentations(kind);
      });
    } else if (kind is PartOfNameFileStateKind) {
      _withIndent(() {
        final libraries = kind.libraries;
        if (libraries.isNotEmpty) {
          final keys = libraries
              .map((library) => fileStateKindIdProvider[library])
              .sorted(compareNatural)
              .join(' ');
          _writelnWithIndent('libraries: $keys');
        }

        final library = kind.library;
        if (library != null) {
          final id = fileStateKindIdProvider[library];
          _writelnWithIndent('library: $id');
        } else {
          _writelnWithIndent('name: ${kind.directive.name}');
        }
      });
    } else if (kind is PartOfUriKnownFileStateKind) {
      _withIndent(() {
        final library = kind.library;
        if (library != null) {
          final id = fileStateKindIdProvider[library];
          _writelnWithIndent('library: $id');
        } else {
          final id = fileStateIdProvider[kind.uriFile];
          _writelnWithIndent('uriFile: $id');
        }
      });
    } else if (kind is PartOfUriUnknownFileStateKind) {
      _withIndent(() {
        _writelnWithIndent('uri: ${kind.directive.uri}');
        expect(kind.library, isNull);
      });
    } else {
      throw UnimplementedError('${kind.runtimeType}');
    }
  }

  void _writeFiles(FileSystemTestData testData) {
    fileSystemState.pullReferencedFiles();

    final fileDataList = <FileTestData>[];
    for (final fileData in testData.files.values) {
      if (omitSdkFiles && fileData.uri.isScheme('dart')) {
        continue;
      }
      fileDataList.add(fileData);
    }
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
          _writelnWithIndent('uri: ${fileData.uri}');

          final current = fileSystemState.getExisting(file);
          if (current != null) {
            _writelnWithIndent('current');
            _writeFile(current);
          }

          if (withKeysGetPut) {
            final shortGets = keyShorter.shortKeys(fileData.unlinkedKeyGet);
            final shortPuts = keyShorter.shortKeys(fileData.unlinkedKeyPut);
            _writelnWithIndent('unlinkedGet: $shortGets');
            _writelnWithIndent('unlinkedPut: $shortPuts');
          }
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
      final cyclesToPrint = <_LibraryCycleToPrint>[];
      for (final entry in testData.libraryCycles.entries) {
        if (omitSdkFiles && entry.key.any((e) => e.uri.isScheme('dart'))) {
          continue;
        }
        cyclesToPrint.add(
          _LibraryCycleToPrint(
            entry.key.map((e) => _posixPath(e.file)).join(' '),
            entry.value,
          ),
        );
      }
      cyclesToPrint.sortBy((e) => e.pathListStr);

      final loadedBundlesMap = Map.fromEntries(
        libraryContext.loadedBundles.map((cycle) {
          final key = cycle.libraries
              .map((fileState) => fileState.resource)
              .map(_posixPath)
              .join(' ');
          return MapEntry(key, cycle);
        }),
      );

      for (final cycleToPrint in cyclesToPrint) {
        _writelnWithIndent(cycleToPrint.pathListStr);
        _withIndent(() {
          final current = loadedBundlesMap[cycleToPrint.pathListStr];
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

          final cycleData = cycleToPrint.data;
          final shortGets = keyShorter.shortKeys(cycleData.getKeys);
          final shortPuts = keyShorter.shortKeys(cycleData.putKeys);
          _writelnWithIndent('get: $shortGets');
          _writelnWithIndent('put: $shortPuts');
        });
      }
    });
  }

  /// TODO(scheglov) Support unresolved URIs, not parts, etc.
  void _writeLibraryParts(LibraryFileStateKind library) {
    final parts = library.file.partedFiles.whereNotNull();
    if (parts.isNotEmpty) {
      final partKeys = parts.map((e) => fileStateIdProvider[e]).join(' ');
      _writelnWithIndent('parts: $partKeys');
    }
  }

  void _writelnWithIndent(String line) {
    sink.write(_indent);
    sink.writeln(line);
  }

  void _writeReferencingFiles(FileState file) {
    final referencingFiles = file.referencingFiles;
    if (referencingFiles.isNotEmpty) {
      final fileIds = referencingFiles
          .map((e) => fileStateIdProvider[e])
          .sorted(compareNatural);
      _writelnWithIndent('referencingFiles: $fileIds');
    }
  }

  void _writeUriList(String name, Iterable<Uri> uriIterable) {
    final uriStrList = <String>[];
    for (final uri in uriIterable) {
      if (omitSdkFiles && uri.isScheme('dart')) {
        continue;
      }
      uriStrList.add('$uri');
    }

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

class FileStateKindIdProvider {
  final Map<FileStateKind, String> _map = Map.identity();

  String operator [](FileStateKind kind) {
    if (kind is AugmentationKnownFileStateKind) {
      return _map[kind] ??= 'augmentation_${_map.length}';
    } else if (kind is AugmentationUnknownFileStateKind) {
      return _map[kind] ??= 'augmentationUnknown_${_map.length}';
    } else if (kind is LibraryFileStateKind) {
      return _map[kind] ??= 'library_${_map.length}';
    } else if (kind is PartOfNameFileStateKind) {
      return _map[kind] ??= 'partOfName_${_map.length}';
    } else if (kind is PartOfUriKnownFileStateKind) {
      return _map[kind] ??= 'partOfUriKnown_${_map.length}';
    } else if (kind is PartFileStateKind) {
      return _map[kind] ??= 'partOfUriUnknown_${_map.length}';
    } else {
      throw UnimplementedError('${kind.runtimeType}');
    }
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

class _LibraryCycleToPrint {
  final String pathListStr;
  final LibraryCycleTestData data;

  _LibraryCycleToPrint(this.pathListStr, this.data);
}
