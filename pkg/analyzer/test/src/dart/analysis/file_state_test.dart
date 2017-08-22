// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/top_level_declaration.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisOptions, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/byte_store/byte_store.dart';
import 'package:mockito/mockito.dart';
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
  final MemoryResourceProvider provider = new MemoryResourceProvider();
  MockSdk sdk;

  final ByteStore byteStore = new MemoryByteStore();
  final FileContentOverlay contentOverlay = new FileContentOverlay();

  final StringBuffer logBuffer = new StringBuffer();
  final UriResolver generatedUriResolver = new _GeneratedUriResolverMock();
  SourceFactory sourceFactory;
  PerformanceLog logger;

  FileSystemState fileSystemState;

  void setUp() {
    logger = new PerformanceLog(logBuffer);
    sdk = new MockSdk(resourceProvider: provider);
    sourceFactory = new SourceFactory([
      new DartUriResolver(sdk),
      generatedUriResolver,
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

  test_definedClassMemberNames() {
    String path = _p('/aaa/lib/a.dart');
    provider.newFile(path, r'''
class A {
  int a, b;
  A();
  A.c();
  d() {}
  get e => null;
  set f(_) {}
}
class B {
  g() {}
}
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.definedClassMemberNames,
        unorderedEquals(['a', 'b', 'd', 'e', 'f', 'g']));
  }

  test_definedTopLevelNames() {
    String path = _p('/aaa/lib/a.dart');
    provider.newFile(path, r'''
class A {}
class B = Object with A;
typedef C();
D() {}
get E => null;
set F(_) {}
var G, H;
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.definedTopLevelNames,
        unorderedEquals(['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']));
  }

  test_exportedTopLevelDeclarations_export() {
    String a = _p('/aaa/lib/a.dart');
    String b = _p('/aaa/lib/b.dart');
    provider.newFile(a, r'''
class A {}
''');
    provider.newFile(b, r'''
export 'a.dart';
class B {}
''');
    FileState file = fileSystemState.getFileForPath(b);
    Map<String, TopLevelDeclaration> declarations =
        file.exportedTopLevelDeclarations;
    expect(declarations.keys, unorderedEquals(['A', 'B']));
  }

  test_exportedTopLevelDeclarations_export2_show() {
    String a = _p('/aaa/lib/a.dart');
    String b = _p('/aaa/lib/b.dart');
    String c = _p('/aaa/lib/c.dart');
    provider.newFile(a, r'''
class A1 {}
class A2 {}
class A3 {}
''');
    provider.newFile(b, r'''
export 'a.dart' show A1, A2;
class B1 {}
class B2 {}
''');
    provider.newFile(c, r'''
export 'b.dart' show A2, A3, B1;
class C {}
''');
    _assertExportedTopLevelDeclarations(c, ['A2', 'B1', 'C']);
  }

  test_exportedTopLevelDeclarations_export_flushOnChange() {
    String a = _p('/aaa/lib/a.dart');
    String b = _p('/aaa/lib/b.dart');
    provider.newFile(a, r'''
class A {}
''');
    provider.newFile(b, r'''
export 'a.dart';
class B {}
''');

    // Initial exported declarations.
    _assertExportedTopLevelDeclarations(b, ['A', 'B']);

    // Update a.dart, so a.dart and b.dart exported declarations are flushed.
    provider.newFile(a, 'class A {} class A2 {}');
    fileSystemState.getFileForPath(a).refresh();
    _assertExportedTopLevelDeclarations(b, ['A', 'A2', 'B']);
  }

  test_exportedTopLevelDeclarations_export_hide() {
    String a = _p('/aaa/lib/a.dart');
    String b = _p('/aaa/lib/b.dart');
    provider.newFile(a, r'''
class A1 {}
class A2 {}
class A3 {}
''');
    provider.newFile(b, r'''
export 'a.dart' hide A2;
class B {}
''');
    _assertExportedTopLevelDeclarations(b, ['A1', 'A3', 'B']);
  }

  test_exportedTopLevelDeclarations_export_preferLocal() {
    String a = _p('/aaa/lib/a.dart');
    String b = _p('/aaa/lib/b.dart');
    provider.newFile(a, r'''
class V {}
''');
    provider.newFile(b, r'''
export 'a.dart';
int V;
''');
    FileState file = fileSystemState.getFileForPath(b);
    Map<String, TopLevelDeclaration> declarations =
        file.exportedTopLevelDeclarations;
    expect(declarations.keys, unorderedEquals(['V']));
    expect(declarations['V'].kind, TopLevelDeclarationKind.variable);
  }

  test_exportedTopLevelDeclarations_export_show() {
    String a = _p('/aaa/lib/a.dart');
    String b = _p('/aaa/lib/b.dart');
    provider.newFile(a, r'''
class A1 {}
class A2 {}
''');
    provider.newFile(b, r'''
export 'a.dart' show A2;
class B {}
''');
    _assertExportedTopLevelDeclarations(b, ['A2', 'B']);
  }

  test_exportedTopLevelDeclarations_export_show2() {
    String a = _p('/aaa/lib/a.dart');
    String b = _p('/aaa/lib/b.dart');
    String c = _p('/aaa/lib/c.dart');
    String d = _p('/aaa/lib/d.dart');
    provider.newFile(a, r'''
export 'b.dart' show Foo;
export 'c.dart' show Bar;
''');
    provider.newFile(b, r'''
export 'd.dart';
''');
    provider.newFile(c, r'''
export 'd.dart';
''');
    provider.newFile(d, r'''
class Foo {}
class Bar {}
''');
    _assertExportedTopLevelDeclarations(a, ['Foo', 'Bar']);
  }

  test_exportedTopLevelDeclarations_import() {
    String a = _p('/aaa/lib/a.dart');
    String b = _p('/aaa/lib/b.dart');
    provider.newFile(a, r'''
class A {}
''');
    provider.newFile(b, r'''
import 'a.dart';
class B {}
''');
    _assertExportedTopLevelDeclarations(b, ['B']);
  }

  test_exportedTopLevelDeclarations_parts() {
    String a = _p('/aaa/lib/a.dart');
    String a2 = _p('/aaa/lib/a2.dart');
    provider.newFile(a, r'''
library lib;
part 'a2.dart';
class A1 {}
''');
    provider.newFile(a2, r'''
part of lib;
class A2 {}
''');
    _assertExportedTopLevelDeclarations(a, ['A1', 'A2']);
  }

  test_getFileForPath_doesNotExist() {
    String path = _p('/aaa/lib/a.dart');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.path, path);
    expect(file.uri, Uri.parse('package:aaa/a.dart'));
    expect(file.content, '');
    expect(file.contentHash, _md5(''));
    expect(_excludeSdk(file.importedFiles), isEmpty);
    expect(file.exportedFiles, isEmpty);
    expect(file.partedFiles, isEmpty);
    expect(_excludeSdk(file.directReferencedFiles), isEmpty);
    expect(file.isPart, isFalse);
    expect(file.library, isNull);
    expect(file.unlinked, isNotNull);
    expect(file.unlinked.classes, isEmpty);
  }

  test_getFileForPath_emptyUri() {
    String path = _p('/test.dart');
    provider.newFile(path, r'''
import '';
export '';
part '';
''');

    FileState file = fileSystemState.getFileForPath(path);
    _assertIsUnresolvedFile(file.importedFiles[0]);
    _assertIsUnresolvedFile(file.exportedFiles[0]);
    _assertIsUnresolvedFile(file.partedFiles[0]);
  }

  test_getFileForPath_hasLibraryDirective_hasPartOfDirective() {
    String a = _p('/test/lib/a.dart');
    provider.newFile(a, r'''
library L;
part of L;
''');
    FileState file = fileSystemState.getFileForPath(a);
    expect(file.isPart, isFalse);
  }

  test_getFileForPath_invalidUri() {
    String a = _p('/aaa/lib/a.dart');
    String a1 = _p('/aaa/lib/a1.dart');
    String a2 = _p('/aaa/lib/a2.dart');
    String a3 = _p('/aaa/lib/a3.dart');
    String content_a1 = r'''
import 'package:aaa/a1.dart';
import '[invalid uri]';

export 'package:aaa/a2.dart';
export '[invalid uri]';

part 'a3.dart';
part '[invalid uri]';
''';
    provider.newFile(a, content_a1);

    FileState file = fileSystemState.getFileForPath(a);

    expect(_excludeSdk(file.importedFiles), hasLength(2));
    expect(file.importedFiles[0].path, a1);
    expect(file.importedFiles[0].uri, Uri.parse('package:aaa/a1.dart'));
    expect(file.importedFiles[0].source, isNotNull);
    _assertIsUnresolvedFile(file.importedFiles[1]);

    expect(_excludeSdk(file.exportedFiles), hasLength(2));
    expect(file.exportedFiles[0].path, a2);
    expect(file.exportedFiles[0].uri, Uri.parse('package:aaa/a2.dart'));
    expect(file.exportedFiles[0].source, isNotNull);
    _assertIsUnresolvedFile(file.exportedFiles[1]);

    expect(_excludeSdk(file.partedFiles), hasLength(2));
    expect(file.partedFiles[0].path, a3);
    expect(file.partedFiles[0].uri, Uri.parse('package:aaa/a3.dart'));
    expect(file.partedFiles[0].source, isNotNull);
    _assertIsUnresolvedFile(file.partedFiles[1]);
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

    expect(_excludeSdk(file.importedFiles), hasLength(2));
    expect(file.importedFiles[0].path, a2);
    expect(file.importedFiles[0].uri, Uri.parse('package:aaa/a2.dart'));
    expect(file.importedFiles[0].source, isNotNull);
    expect(file.importedFiles[1].path, b1);
    expect(file.importedFiles[1].uri, Uri.parse('package:bbb/b1.dart'));
    expect(file.importedFiles[1].source, isNotNull);

    expect(file.exportedFiles, hasLength(2));
    expect(file.exportedFiles[0].path, b2);
    expect(file.exportedFiles[0].uri, Uri.parse('package:bbb/b2.dart'));
    expect(file.exportedFiles[0].source, isNotNull);
    expect(file.exportedFiles[1].path, a3);
    expect(file.exportedFiles[1].uri, Uri.parse('package:aaa/a3.dart'));
    expect(file.exportedFiles[1].source, isNotNull);

    expect(file.partedFiles, hasLength(1));
    expect(file.partedFiles[0].path, a4);
    expect(file.partedFiles[0].uri, Uri.parse('package:aaa/a4.dart'));

    expect(_excludeSdk(file.directReferencedFiles), hasLength(5));

    expect(fileSystemState.getFilesForPath(a1), [file]);
  }

  test_getFileForPath_onlyDartFiles() {
    String not_dart = _p('/test/lib/not_dart.txt');
    String a = _p('/test/lib/a.dart');
    String b = _p('/test/lib/b.dart');
    String c = _p('/test/lib/c.dart');
    String d = _p('/test/lib/d.dart');
    provider.newFile(a, r'''
library lib;
import 'dart:math';
import 'b.dart';
import 'not_dart.txt';
export 'c.dart';
export 'not_dart.txt';
part 'd.dart';
part 'not_dart.txt';
''');
    FileState file = fileSystemState.getFileForPath(a);
    expect(_excludeSdk(file.importedFiles).map((f) => f.path),
        unorderedEquals([b, not_dart]));
    expect(
        file.exportedFiles.map((f) => f.path), unorderedEquals([c, not_dart]));
    expect(file.partedFiles.map((f) => f.path), unorderedEquals([d, not_dart]));
    expect(_excludeSdk(fileSystemState.knownFilePaths),
        unorderedEquals([a, b, c, d, not_dart]));
  }

  test_getFileForPath_part() {
    String a1 = _p('/aaa/lib/a1.dart');
    String a2 = _p('/aaa/lib/a2.dart');
    provider.newFile(a1, r'''
library a1;
part 'a2.dart';
''');
    provider.newFile(a2, r'''
part of a1;
class A2 {}
''');

    FileState file_a2 = fileSystemState.getFileForPath(a2);
    expect(file_a2.path, a2);
    expect(file_a2.uri, Uri.parse('package:aaa/a2.dart'));

    expect(file_a2.unlinked, isNotNull);
    expect(file_a2.unlinked.classes, hasLength(1));
    expect(file_a2.unlinked.classes[0].name, 'A2');

    expect(_excludeSdk(file_a2.importedFiles), isEmpty);
    expect(file_a2.exportedFiles, isEmpty);
    expect(file_a2.partedFiles, isEmpty);
    expect(_excludeSdk(file_a2.directReferencedFiles), isEmpty);

    // The library is not known yet.
    expect(file_a2.isPart, isTrue);
    expect(file_a2.library, isNull);

    // Ask for the library.
    FileState file_a1 = fileSystemState.getFileForPath(a1);
    expect(file_a1.partedFiles, hasLength(1));
    expect(file_a1.partedFiles[0], same(file_a2));
    expect(
        _excludeSdk(file_a1.directReferencedFiles), unorderedEquals([file_a2]));

    // Now the part knows its library.
    expect(file_a2.library, same(file_a1));

    // Now update the library, and refresh its file.
    // The 'a2.dart' is not referenced anymore.
    // So the part file does not have the library anymore.
    provider.newFile(a1, r'''
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
    var packageUri = Uri.parse('package:aaa/a.dart');
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

  test_hasUri() {
    Uri uri = Uri.parse('package:aaa/foo.dart');
    String templatePath = _p('/aaa/lib/foo.dart');
    String generatedPath = _p('/generated/aaa/lib/foo.dart');

    Source generatedSource = new _SourceMock();
    when(generatedSource.fullName).thenReturn(generatedPath);
    when(generatedSource.uri).thenReturn(uri);

    when(generatedUriResolver.resolveAbsolute(uri, uri))
        .thenReturn(generatedSource);

    expect(fileSystemState.hasUri(templatePath), isFalse);
    expect(fileSystemState.hasUri(generatedPath), isTrue);
  }

  test_referencedNames() {
    String path = _p('/aaa/lib/a.dart');
    provider.newFile(path, r'''
A foo(B p) {
  foo(null);
  C c = new C(p);
  return c;
}
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.referencedNames, unorderedEquals(['A', 'B', 'C']));
  }

  test_refresh_differentApiSignature() {
    String path = _p('/aaa/lib/a.dart');
    provider.newFile(path, r'''
class A {}
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.unlinked.classes[0].name, 'A');
    List<int> signature = file.apiSignature;

    // Update the resource and refresh the file state.
    provider.newFile(path, r'''
class B {}
''');
    bool apiSignatureChanged = file.refresh();
    expect(apiSignatureChanged, isTrue);

    expect(file.unlinked.classes[0].name, 'B');
    expect(file.apiSignature, isNot(signature));
  }

  test_refresh_sameApiSignature() {
    String path = _p('/aaa/lib/a.dart');
    provider.newFile(path, r'''
class C {
  foo() {
    print(111);
  }
}
''');
    FileState file = fileSystemState.getFileForPath(path);
    List<int> signature = file.apiSignature;

    // Update the resource and refresh the file state.
    provider.newFile(path, r'''
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

  test_store_zeroLengthUnlinked() {
    String path = _p('/test.dart');
    provider.newFile(path, 'class A {}');

    // Get the file, prepare unlinked.
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.unlinked, isNotNull);

    // Make the unlinked unit in the byte store zero-length, damaged.
    byteStore.put(file.test.unlinkedKey, <int>[]);

    // Refresh should not fail, zero bytes in the store are ignored.
    file.refresh();
    expect(file.unlinked, isNotNull);
  }

  test_subtypedNames() {
    String path = _p('/test.dart');
    provider.newFile(path, r'''
class X extends A {}
class Y extends A with B {}
class Z implements C, D {}
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.referencedNames, unorderedEquals(['A', 'B', 'C', 'D']));
  }

  test_topLevelDeclarations() {
    String path = _p('/aaa/lib/a.dart');
    provider.newFile(path, r'''
class C {}
typedef F();
enum E {E1, E2}
void f() {}
var V1;
get V2 => null;
set V3(_) {}
get V4 => null;
set V4(_) {}

class _C {}
typedef _F();
enum _E {E1, E2}
void _f() {}
var _V1;
get _V2 => null;
set _V3(_) {}
''');
    FileState file = fileSystemState.getFileForPath(path);

    Map<String, TopLevelDeclaration> declarations = file.topLevelDeclarations;

    void assertHas(String name, TopLevelDeclarationKind kind) {
      expect(declarations[name]?.kind, kind);
    }

    expect(declarations.keys,
        unorderedEquals(['C', 'F', 'E', 'f', 'V1', 'V2', 'V3', 'V4']));
    assertHas('C', TopLevelDeclarationKind.type);
    assertHas('F', TopLevelDeclarationKind.type);
    assertHas('E', TopLevelDeclarationKind.type);
    assertHas('f', TopLevelDeclarationKind.function);
    assertHas('V1', TopLevelDeclarationKind.variable);
    assertHas('V2', TopLevelDeclarationKind.variable);
    assertHas('V3', TopLevelDeclarationKind.variable);
    assertHas('V4', TopLevelDeclarationKind.variable);
  }

  test_transitiveFiles() {
    String pa = _p('/aaa/lib/a.dart');
    String pb = _p('/aaa/lib/b.dart');
    String pc = _p('/aaa/lib/c.dart');
    String pd = _p('/aaa/lib/d.dart');

    FileState fa = fileSystemState.getFileForPath(pa);
    FileState fb = fileSystemState.getFileForPath(pb);
    FileState fc = fileSystemState.getFileForPath(pc);
    FileState fd = fileSystemState.getFileForPath(pd);

    // Compute transitive closures for all files.
    fa.transitiveFiles;
    fb.transitiveFiles;
    fc.transitiveFiles;
    fd.transitiveFiles;
    expect(
        _excludeSdk(fileSystemState.test.filesWithoutTransitiveFiles), isEmpty);

    // No imports, so just a single file.
    provider.newFile(pa, "");
    _assertTransitiveFiles(fa, [fa]);

    // Import b.dart into a.dart, two files now.
    provider.newFile(pa, "import 'b.dart';");
    fa.refresh();
    _assertFilesWithoutTransitiveFiles([fa]);
    _assertTransitiveFiles(fa, [fa, fb]);

    // Update b.dart so that it imports c.dart now.
    provider.newFile(pb, "import 'c.dart';");
    fb.refresh();
    _assertFilesWithoutTransitiveFiles([fa, fb]);
    _assertTransitiveFiles(fa, [fa, fb, fc]);
    _assertTransitiveFiles(fb, [fb, fc]);
    _assertFilesWithoutTransitiveFiles([]);

    // Update b.dart so that it exports d.dart instead.
    provider.newFile(pb, "export 'd.dart';");
    fb.refresh();
    _assertFilesWithoutTransitiveFiles([fa, fb]);
    _assertTransitiveFiles(fa, [fa, fb, fd]);
    _assertTransitiveFiles(fb, [fb, fd]);
    _assertFilesWithoutTransitiveFiles([]);

    // Update a.dart so that it does not import b.dart anymore.
    provider.newFile(pa, "");
    fa.refresh();
    _assertFilesWithoutTransitiveFiles([fa]);
    _assertTransitiveFiles(fa, [fa]);
  }

  test_transitiveFiles_cycle() {
    String pa = _p('/aaa/lib/a.dart');
    String pb = _p('/aaa/lib/b.dart');

    provider.newFile(pa, "import 'b.dart';");
    provider.newFile(pb, "import 'a.dart';");

    FileState fa = fileSystemState.getFileForPath(pa);
    FileState fb = fileSystemState.getFileForPath(pb);

    // Compute transitive closures for all files.
    fa.transitiveFiles;
    fb.transitiveFiles;
    _assertFilesWithoutTransitiveFiles([]);

    // It's a cycle.
    _assertTransitiveFiles(fa, [fa, fb]);
    _assertTransitiveFiles(fb, [fa, fb]);

    // Update a.dart so that it does not import b.dart anymore.
    provider.newFile(pa, "");
    fa.refresh();
    _assertFilesWithoutTransitiveFiles([fa, fb]);
    _assertTransitiveFiles(fa, [fa]);
    _assertTransitiveFiles(fb, [fa, fb]);
  }

  test_transitiveSignature() {
    String pa = _p('/aaa/lib/a.dart');
    String pb = _p('/aaa/lib/b.dart');
    String pc = _p('/aaa/lib/c.dart');
    String pd = _p('/aaa/lib/d.dart');

    provider.newFile(pa, "class A {}");
    provider.newFile(pb, "import 'a.dart';");
    provider.newFile(pc, "import 'b.dart';");
    provider.newFile(pd, "class D {}");

    FileState fa = fileSystemState.getFileForPath(pa);
    FileState fb = fileSystemState.getFileForPath(pb);
    FileState fc = fileSystemState.getFileForPath(pc);
    FileState fd = fileSystemState.getFileForPath(pd);

    // Compute transitive closures for all files.
    expect(fa.transitiveSignature, isNotNull);
    expect(fb.transitiveSignature, isNotNull);
    expect(fc.transitiveSignature, isNotNull);
    expect(fd.transitiveSignature, isNotNull);
    expect(
        _excludeSdk(fileSystemState.test.filesWithoutTransitiveFiles), isEmpty);

    // Make an update to a.dart that does not change its API signature.
    // All transitive signatures are still valid.
    provider.newFile(pa, "class A {} // the same API signature");
    fa.refresh();
    expect(
        _excludeSdk(fileSystemState.test.filesWithoutTransitiveFiles), isEmpty);

    // Change a.dart API signature, also flush signatures of b.dart and c.dart,
    // but d.dart is still OK.
    provider.newFile(pa, "class A2 {}");
    fa.refresh();
    _assertFilesWithoutTransitiveSignatures([fa, fb, fc]);
  }

  void _assertExportedTopLevelDeclarations(String path, List<String> expected) {
    FileState file = fileSystemState.getFileForPath(path);
    Map<String, TopLevelDeclaration> declarations =
        file.exportedTopLevelDeclarations;
    expect(declarations.keys, unorderedEquals(expected));
  }

  void _assertFilesWithoutTransitiveFiles(List<FileState> expected) {
    var actual = fileSystemState.test.filesWithoutTransitiveFiles;
    expect(_excludeSdk(actual), unorderedEquals(expected));
  }

  void _assertFilesWithoutTransitiveSignatures(List<FileState> expected) {
    var actual = fileSystemState.test.filesWithoutTransitiveSignature;
    expect(_excludeSdk(actual), unorderedEquals(expected));
  }

  void _assertIsUnresolvedFile(FileState file) {
    expect(file.path, isNull);
    expect(file.uri, isNull);
    expect(file.source, isNull);
  }

  void _assertTransitiveFiles(FileState file, List<FileState> expected) {
    expect(_excludeSdk(file.transitiveFiles), unorderedEquals(expected));
  }

  List<T> _excludeSdk<T>(Iterable<T> files) {
    return files.where((Object file) {
      if (file is FileState) {
        return file.uri?.scheme != 'dart';
      } else {
        return !(file as String).startsWith(_p('/sdk'));
      }
    }).toList();
  }

  String _p(String path) => provider.convertPath(path);

  static String _md5(String content) {
    return hex.encode(md5.convert(UTF8.encode(content)).bytes);
  }
}

class _GeneratedUriResolverMock extends Mock implements UriResolver {}

class _SourceMock extends Mock implements Source {}
