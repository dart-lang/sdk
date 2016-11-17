// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' show PerformanceLog;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisOptions, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/util/fast_uri.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../context/mock_sdk.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileSystemStateTest);
  });
}

@reflectiveTest
class FileSystemStateTest {
  static final MockSdk sdk = new MockSdk();

  final MemoryResourceProvider provider = new MemoryResourceProvider();
  final ByteStore byteStore = new MemoryByteStore();
  final FileContentOverlay contentOverlay = new FileContentOverlay();

  final StringBuffer logBuffer = new StringBuffer();
  PerformanceLog logger;

  FileSystemState fileSystemState;

  void setUp() {
    logger = new PerformanceLog(logBuffer);
    SourceFactory sourceFactory = new SourceFactory([
      new DartUriResolver(sdk),
      new PackageMapUriResolver(provider, <String, List<Folder>>{
        'aaa': [provider.getFolder(_p('/aaa/lib'))],
        'bbb': [provider.getFolder(_p('/bbb/lib'))],
      }),
      new ResourceUriResolver(provider)
    ], null, provider);
    AnalysisOptions analysisOptions = new AnalysisOptionsImpl()
      ..strongMode = true;
    fileSystemState = new FileSystemState(logger, byteStore, contentOverlay,
        provider, sourceFactory, analysisOptions, new Uint32List(0));
  }

  test_getFileForPath_doesNotExist() {
    String path = _p('/aaa/lib/a.dart');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.path, path);
    expect(file.uri, FastUri.parse('package:aaa/a.dart'));
    expect(file.content, '');
    expect(file.contentHash, _md5(''));
    expect(file.importedFiles, isEmpty);
    expect(file.exportedFiles, isEmpty);
    expect(file.partedFiles, isEmpty);
    expect(file.dependencies, isEmpty);
    expect(file.isPart, isFalse);
    expect(file.library, isNull);
    expect(file.unlinked, isNotNull);
    expect(file.unlinked.classes, isEmpty);
  }

  test_getFileForPath_library() {
    String a1 = _p('/aaa/lib/a1.dart');
    String a2 = _p('/aaa/lib/a2.dart');
    String a3 = _p('/aaa/lib/a3.dart');
    String a4 = _p('/aaa/lib/a4.dart');
    String b1 = _p('/bbb/lib/b1.dart');
    String b2 = _p('/bbb/lib/b2.dart');
    String content_a1 = r'''
import 'package:aaa/a2.dart';
import 'package:bbb/b1.dart';
export 'package:bbb/b2.dart';
export 'package:aaa/a3.dart';
part 'a4.dart';

class A1 {}
''';
    provider.newFile(a1, content_a1);

    FileState file = fileSystemState.getFileForPath(a1);
    expect(file.path, a1);
    expect(file.content, content_a1);
    expect(file.contentHash, _md5(content_a1));

    expect(file.isPart, isFalse);
    expect(file.library, isNull);
    expect(file.unlinked, isNotNull);
    expect(file.unlinked.classes, hasLength(1));
    expect(file.unlinked.classes[0].name, 'A1');

    expect(file.importedFiles, hasLength(2));
    expect(file.importedFiles[0].path, a2);
    expect(file.importedFiles[0].uri, FastUri.parse('package:aaa/a2.dart'));
    expect(file.importedFiles[0].source, isNotNull);
    expect(file.importedFiles[1].path, b1);
    expect(file.importedFiles[1].uri, FastUri.parse('package:bbb/b1.dart'));
    expect(file.importedFiles[1].source, isNotNull);

    expect(file.exportedFiles, hasLength(2));
    expect(file.exportedFiles[0].path, b2);
    expect(file.exportedFiles[0].uri, FastUri.parse('package:bbb/b2.dart'));
    expect(file.exportedFiles[0].source, isNotNull);
    expect(file.exportedFiles[1].path, a3);
    expect(file.exportedFiles[1].uri, FastUri.parse('package:aaa/a3.dart'));
    expect(file.exportedFiles[1].source, isNotNull);

    expect(file.partedFiles, hasLength(1));
    expect(file.partedFiles[0].path, a4);
    expect(file.partedFiles[0].uri, FastUri.parse('package:aaa/a4.dart'));

    expect(file.dependencies, hasLength(5));

    expect(fileSystemState.getFilesForPath(a1), [file]);
  }

  test_getFileForPath_part() {
    String a1 = _p('/aaa/lib/a1.dart');
    String a2 = _p('/aaa/lib/a2.dart');
    provider.newFile(
        a1,
        r'''
library a1;
part 'a2.dart';
''');
    provider.newFile(
        a2,
        r'''
part of a1;
class A2 {}
''');

    FileState file_a2 = fileSystemState.getFileForPath(a2);
    expect(file_a2.path, a2);
    expect(file_a2.uri, FastUri.parse('package:aaa/a2.dart'));

    expect(file_a2.unlinked, isNotNull);
    expect(file_a2.unlinked.classes, hasLength(1));
    expect(file_a2.unlinked.classes[0].name, 'A2');

    expect(file_a2.importedFiles, isEmpty);
    expect(file_a2.exportedFiles, isEmpty);
    expect(file_a2.partedFiles, isEmpty);
    expect(file_a2.dependencies, isEmpty);

    // The library is not known yet.
    expect(file_a2.isPart, isTrue);
    expect(file_a2.library, isNull);

    // Ask for the library.
    FileState file_a1 = fileSystemState.getFileForPath(a1);
    expect(file_a1.partedFiles, hasLength(1));
    expect(file_a1.partedFiles[0], same(file_a2));
    expect(file_a1.dependencies, unorderedEquals([file_a2]));

    // Now the part knows its library.
    expect(file_a2.library, same(file_a1));

    // Now update the library, and refresh its file.
    // The 'a2.dart' is not referenced anymore.
    // So the part file does not have the library anymore.
    provider.newFile(
        a1,
        r'''
library a1;
part 'not-a2.dart';
''');
    file_a1.refresh();
    expect(file_a2.library, isNull);
  }

  test_getFileForPath_samePath() {
    String path = _p('/aaa/lib/a.dart');
    FileState file1 = fileSystemState.getFileForPath(path);
    FileState file2 = fileSystemState.getFileForPath(path);
    expect(file2, same(file1));
  }

  test_getFileForUri_packageVsFileUri() {
    String path = _p('/aaa/lib/a.dart');
    var packageUri = FastUri.parse('package:aaa/a.dart');
    var fileUri = provider.pathContext.toUri(path);

    // The files with `package:` and `file:` URIs are different.
    FileState filePackageUri = fileSystemState.getFileForUri(packageUri);
    FileState fileFileUri = fileSystemState.getFileForUri(fileUri);
    expect(filePackageUri, isNot(same(fileFileUri)));

    expect(filePackageUri.path, path);
    expect(filePackageUri.uri, packageUri);

    expect(fileFileUri.path, path);
    expect(fileFileUri.uri, fileUri);

    // The file with the `package:` style URI is canonical, and is the first.
    var files = fileSystemState.getFilesForPath(path);
    expect(files, [filePackageUri, fileFileUri]);
  }

  test_refresh_differentApiSignature() {
    String path = _p('/aaa/lib/a.dart');
    provider.newFile(
        path,
        r'''
class A {}
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.unlinked.classes[0].name, 'A');
    List<int> signature = file.apiSignature;

    // Update the resource and refresh the file state.
    provider.newFile(
        path,
        r'''
class B {}
''');
    bool apiSignatureChanged = file.refresh();
    expect(apiSignatureChanged, isTrue);

    expect(file.unlinked.classes[0].name, 'B');
    expect(file.apiSignature, isNot(signature));
  }

  test_refresh_sameApiSignature() {
    String path = _p('/aaa/lib/a.dart');
    provider.newFile(
        path,
        r'''
class C {
  foo() {
    print(111);
  }
}
''');
    FileState file = fileSystemState.getFileForPath(path);
    List<int> signature = file.apiSignature;

    // Update the resource and refresh the file state.
    provider.newFile(
        path,
        r'''
class C {
  foo() {
    print(222);
  }
}
''');
    bool apiSignatureChanged = file.refresh();
    expect(apiSignatureChanged, isFalse);

    expect(file.apiSignature, signature);
  }

  String _p(String path) => provider.convertPath(path);

  static String _md5(String content) {
    return hex.encode(md5.convert(UTF8.encode(content)).bytes);
  }
}
