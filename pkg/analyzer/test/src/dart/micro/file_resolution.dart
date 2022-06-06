// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/micro/cider_byte_store.dart';
import 'package:analyzer/src/dart/micro/library_graph.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/workspace/bazel.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:linter/src/rules.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../resolution/resolution.dart';

/// [FileResolver] based implementation of [ResolutionTest].
class FileResolutionTest with ResourceProviderMixin, ResolutionTest {
  static final String _testFile = '/workspace/dart/test/lib/test.dart';

  final MemoryCiderByteStore byteStore = MemoryCiderByteStore();

  final FileResolverTestView testData = FileResolverTestView();

  final StringBuffer logBuffer = StringBuffer();
  late PerformanceLog logger;

  late FileResolver fileResolver;

  final _KeyShorter _keyShorter = _KeyShorter();

  FileSystemState get fsState => fileResolver.fsState!;

  LibraryContext get libraryContext {
    return fileResolver.libraryContext!;
  }

  Folder get sdkRoot => newFolder('/sdk');

  File get testFile => getFile(testFilePath);

  @override
  String get testFilePath => _testFile;

  String get testPackageLibPath => '$testPackageRootPath/lib';

  String get testPackageRootPath => '$workspaceRootPath/dart/test';

  String get workspaceRootPath => '/workspace';

  @override
  void addTestFile(String content) {
    newFile(_testFile, content);
  }

  void assertStateString(String expected) {
    final buffer = StringBuffer();
    ResolverStatePrinter(resourceProvider, buffer, _keyShorter).write(byteStore,
        fileResolver.fsState!, libraryContext.elementFactory, testData);
    final actual = buffer.toString();

    if (actual != expected) {
      print(actual);
    }
    expect(actual, expected);
  }

  /// Create a new [FileResolver] into [fileResolver].
  ///
  /// We do this the first time, and to test reusing results from [byteStore].
  void createFileResolver() {
    var workspace = BazelWorkspace.find(
      resourceProvider,
      convertPath(_testFile),
    )!;

    byteStore.testView = CiderByteStoreTestView();
    fileResolver = FileResolver(
      logger: logger,
      resourceProvider: resourceProvider,
      byteStore: byteStore,
      sourceFactory: workspace.createSourceFactory(
        FolderBasedDartSdk(resourceProvider, sdkRoot),
        null,
      ),
      getFileDigest: (String path) => _getDigest(path),
      workspace: workspace,
      prefetchFiles: null,
      isGenerated: null,
    );
    fileResolver.testView = testData;
  }

  Future<ErrorsResult> getTestErrors() async {
    var path = convertPath(_testFile);
    return fileResolver.getErrors2(path: path);
  }

  @override
  Future<ResolvedUnitResult> resolveFile(
    String path, {
    OperationPerformanceImpl? performance,
  }) async {
    result = await fileResolver.resolve2(
      path: path,
      performance: performance,
    );
    return result;
  }

  @override
  Future<void> resolveTestFile() async {
    var path = convertPath(_testFile);
    result = await resolveFile(path);
    findNode = FindNode(result.content, result.unit);
    findElement = FindElement(result.unit);
  }

  void setUp() {
    registerLintRules();

    logger = PerformanceLog(logBuffer);
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    newFile('/workspace/WORKSPACE', '');
    newFile('/workspace/dart/test/BUILD', r'''
dart_package(
  null_safety = True,
)
''');
    createFileResolver();
  }

  String _getDigest(String path) {
    try {
      var content = resourceProvider.getFile(path).readAsStringSync();
      var contentBytes = utf8.encode(content);
      return md5.convert(contentBytes).toString();
    } catch (_) {
      return '';
    }
  }
}

class ResolverStatePrinter {
  final ResourceProvider _resourceProvider;

  /// The target sink to print.
  final StringSink _sink;

  final _KeyShorter _keyShorter;

  String _indent = '';

  ResolverStatePrinter(this._resourceProvider, this._sink, this._keyShorter);

  void write(MemoryCiderByteStore byteStore, FileSystemState fileSystemState,
      LinkedElementFactory elementFactory, FileResolverTestView testData) {
    _writelnWithIndent('files');
    _withIndent(() {
      final fileMap = testData.fileSystemTestData.files;
      final fileDataList = fileMap.values.toList();
      fileDataList.sortBy((fileData) => fileData.file.path);

      for (final fileData in fileDataList) {
        final file = fileData.file;
        _writelnWithIndent(_posixPath(file));
        _withIndent(() {
          final current = fileSystemState.getExistingFileForResource(file);
          if (current != null) {
            _writelnWithIndent('current');
            _withIndent(() {
              final unlinkedShort = _keyShorter.shortKey(current.unlinkedKey);
              _writelnWithIndent('unlinkedKey: $unlinkedShort');
            });
          }

          final shortGets = _keyShorter.shortKeys(fileData.unlinkedKeyGet);
          final shortPuts = _keyShorter.shortKeys(fileData.unlinkedKeyPut);
          _writelnWithIndent('unlinkedGet: $shortGets');
          _writelnWithIndent('unlinkedPut: $shortPuts');
        });
      }
    });

    _writelnWithIndent('libraryCycles');
    _withIndent(() {
      final entries = testData.libraryCycles.entries
          .mapKey((key) => key.map(_posixPath).join(' '))
          .toList();
      entries.sortBy((e) => e.key);

      for (final entry in entries) {
        _writelnWithIndent(entry.key);
        _withIndent(() {
          final shortGets = _keyShorter.shortKeys(entry.value.getKeys);
          final shortPuts = _keyShorter.shortKeys(entry.value.putKeys);
          _writelnWithIndent('get: $shortGets');
          _writelnWithIndent('put: $shortPuts');
        });
      }
    });

    _writelnWithIndent('elementFactory');
    _withIndent(() {
      _writeUriList(
        'hasElement',
        elementFactory.uriListWithLibraryElements,
      );
      _writeUriList(
        'hasReader',
        elementFactory.uriListWithLibraryReaders,
      );
    });

    _writelnWithIndent('byteStore');
    _withIndent(() {
      final groups = byteStore.map.entries.groupListsBy((element) {
        return element.value.refCount;
      });

      for (final groupEntry in groups.entries) {
        final keys = groupEntry.value.map((e) => e.key).toList();
        final shortKeys = _keyShorter.shortKeys(keys)..sort();
        _writelnWithIndent('${groupEntry.key}: $shortKeys');
      }
    });
  }

  /// If the path style is `Windows`, returns the corresponding Posix path.
  /// Otherwise the path is already a Posix path, and it is returned as is.
  String _posixPath(File file) {
    final pathContext = _resourceProvider.pathContext;
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

  void _writelnWithIndent(String line) {
    _sink.write(_indent);
    _sink.writeln(line);
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

/// Keys in the byte store are long hashes, which are hard to read.
/// So, we generate short unique versions for them.
class _KeyShorter {
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
