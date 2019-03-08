// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/top_level_declaration.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisOptions, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileSystemStateTest);
  });
}

@reflectiveTest
class FileSystemStateTest with ResourceProviderMixin {
  MockSdk sdk;

  final ByteStore byteStore = new MemoryByteStore();
  final FileContentOverlay contentOverlay = new FileContentOverlay();

  final StringBuffer logBuffer = new StringBuffer();
  final _GeneratedUriResolverMock generatedUriResolver =
      new _GeneratedUriResolverMock();
  SourceFactory sourceFactory;
  PerformanceLog logger;

  FileSystemState fileSystemState;

  void setUp() {
    logger = new PerformanceLog(logBuffer);
    sdk = new MockSdk(resourceProvider: resourceProvider);
    sourceFactory = new SourceFactory([
      new DartUriResolver(sdk),
      generatedUriResolver,
      new PackageMapUriResolver(resourceProvider, <String, List<Folder>>{
        'aaa': [getFolder('/aaa/lib')],
        'bbb': [getFolder('/bbb/lib')],
      }),
      new ResourceUriResolver(resourceProvider)
    ], null, resourceProvider);
    AnalysisOptions analysisOptions = new AnalysisOptionsImpl();
    fileSystemState = new FileSystemState(
        logger,
        byteStore,
        contentOverlay,
        resourceProvider,
        sourceFactory,
        analysisOptions,
        new Uint32List(0),
        new Uint32List(0));
  }

  test_definedClassMemberNames() {
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, content: r'''
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
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, content: r'''
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

  test_exportedTopLevelDeclarations_cycle() {
    String a = convertPath('/aaa/lib/a.dart');
    String b = convertPath('/aaa/lib/b.dart');
    String c = convertPath('/aaa/lib/c.dart');
    newFile(a, content: r'''
export 'b.dart';
class A {}
''');
    newFile(b, content: r'''
export 'c.dart';
class B {}
''');
    newFile(c, content: r'''
export 'a.dart';
class C {}
''');
    _assertExportedTopLevelDeclarations(a, ['A', 'B', 'C']);

    // We asked for 'a', and it was computed.
    // But 'b' and 'c' are not computed, because we detect that there is
    // cycle with 'a', so we cannot get all exported declarations of 'a'.
    _assertHasComputedExportedDeclarations([a]);
  }

  test_exportedTopLevelDeclarations_cycle_anotherOutsideCycle() {
    String a = convertPath('/aaa/lib/a.dart');
    String b = convertPath('/aaa/lib/b.dart');
    String c = convertPath('/aaa/lib/c.dart');
    String d = convertPath('/aaa/lib/d.dart');
    newFile(a, content: r'''
export 'b.dart';
class A {}
''');
    newFile(b, content: r'''
export 'c.dart';
class B {}
''');
    newFile(c, content: r'''
export 'b.dart';
export 'd.dart';
class C {}
''');
    newFile(d, content: r'''
class D {}
''');
    _assertExportedTopLevelDeclarations(a, ['A', 'B', 'C', 'D']);

    // To compute 'a' we compute 'b'.
    // But 'c' is not computed, because of the cycle [b, c].
    // However 'd' is not a part of a cycle, so it is computed too.
    _assertHasComputedExportedDeclarations([a, b, d]);
  }

  test_exportedTopLevelDeclarations_cycle_onSequence() {
    String a = convertPath('/aaa/lib/a.dart');
    String b = convertPath('/aaa/lib/b.dart');
    String c = convertPath('/aaa/lib/c.dart');
    String d = convertPath('/aaa/lib/d.dart');
    String e = convertPath('/aaa/lib/e.dart');
    newFile(a, content: r'''
export 'b.dart';
class A {}
''');
    newFile(b, content: r'''
export 'c.dart';
class B {}
''');
    newFile(c, content: r'''
export 'd.dart';
class C {}
''');
    newFile(d, content: r'''
export 'e.dart';
class D {}
''');
    newFile(e, content: r'''
export 'c.dart';
class E {}
''');
    // We compute 'a'.
    // To compute it we also compute 'b' and 'c'.
    // But 'd' and 'e' are not computed, because of the cycle [c, d, e].
    _assertExportedTopLevelDeclarations(a, ['A', 'B', 'C', 'D', 'E']);
    _assertHasComputedExportedDeclarations([a, b, c]);

    // We compute 'd', and try to compute 'e', because 'd' needs 'e'; 'e' can
    // be computed because 'c' is ready, so the cycle [c, d, e] is broken.
    _assertExportedTopLevelDeclarations(d, ['C', 'D', 'E']);
    _assertHasComputedExportedDeclarations([a, b, c, d, e]);
  }

  test_exportedTopLevelDeclarations_export() {
    String a = convertPath('/aaa/lib/a.dart');
    String b = convertPath('/aaa/lib/b.dart');
    newFile(a, content: r'''
class A {}
''');
    newFile(b, content: r'''
export 'a.dart';
class B {}
''');
    _assertExportedTopLevelDeclarations(b, ['A', 'B']);
    _assertHasComputedExportedDeclarations([a, b]);
  }

  test_exportedTopLevelDeclarations_export2_show() {
    String a = convertPath('/aaa/lib/a.dart');
    String b = convertPath('/aaa/lib/b.dart');
    String c = convertPath('/aaa/lib/c.dart');
    newFile(a, content: r'''
class A1 {}
class A2 {}
class A3 {}
''');
    newFile(b, content: r'''
export 'a.dart' show A1, A2;
class B1 {}
class B2 {}
''');
    newFile(c, content: r'''
export 'b.dart' show A2, A3, B1;
class C {}
''');
    _assertExportedTopLevelDeclarations(c, ['A2', 'B1', 'C']);
    _assertHasComputedExportedDeclarations([a, b, c]);
  }

  test_exportedTopLevelDeclarations_export_flushOnChange() {
    String a = convertPath('/aaa/lib/a.dart');
    String b = convertPath('/aaa/lib/b.dart');
    newFile(a, content: r'''
class A {}
''');
    newFile(b, content: r'''
export 'a.dart';
class B {}
''');

    // Initial exported declarations.
    _assertExportedTopLevelDeclarations(b, ['A', 'B']);

    // Update a.dart, so a.dart and b.dart exported declarations are flushed.
    newFile(a, content: 'class A {} class A2 {}');
    fileSystemState.getFileForPath(a).refresh();
    _assertExportedTopLevelDeclarations(b, ['A', 'A2', 'B']);
  }

  test_exportedTopLevelDeclarations_export_hide() {
    String a = convertPath('/aaa/lib/a.dart');
    String b = convertPath('/aaa/lib/b.dart');
    newFile(a, content: r'''
class A1 {}
class A2 {}
class A3 {}
''');
    newFile(b, content: r'''
export 'a.dart' hide A2;
class B {}
''');
    _assertExportedTopLevelDeclarations(b, ['A1', 'A3', 'B']);
  }

  test_exportedTopLevelDeclarations_export_preferLocal() {
    String a = convertPath('/aaa/lib/a.dart');
    String b = convertPath('/aaa/lib/b.dart');
    newFile(a, content: r'''
class V {}
''');
    newFile(b, content: r'''
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
    String a = convertPath('/aaa/lib/a.dart');
    String b = convertPath('/aaa/lib/b.dart');
    newFile(a, content: r'''
class A1 {}
class A2 {}
''');
    newFile(b, content: r'''
export 'a.dart' show A2;
class B {}
''');
    _assertExportedTopLevelDeclarations(b, ['A2', 'B']);
  }

  test_exportedTopLevelDeclarations_export_show2() {
    String a = convertPath('/aaa/lib/a.dart');
    String b = convertPath('/aaa/lib/b.dart');
    String c = convertPath('/aaa/lib/c.dart');
    String d = convertPath('/aaa/lib/d.dart');
    newFile(a, content: r'''
export 'b.dart' show Foo;
export 'c.dart' show Bar;
''');
    newFile(b, content: r'''
export 'd.dart';
''');
    newFile(c, content: r'''
export 'd.dart';
''');
    newFile(d, content: r'''
class Foo {}
class Bar {}
''');
    _assertExportedTopLevelDeclarations(a, ['Foo', 'Bar']);
  }

  test_exportedTopLevelDeclarations_import() {
    String a = convertPath('/aaa/lib/a.dart');
    String b = convertPath('/aaa/lib/b.dart');
    newFile(a, content: r'''
class A {}
''');
    newFile(b, content: r'''
import 'a.dart';
class B {}
''');
    _assertExportedTopLevelDeclarations(b, ['B']);
  }

  test_exportedTopLevelDeclarations_parts() {
    String a = convertPath('/aaa/lib/a.dart');
    String a2 = convertPath('/aaa/lib/a2.dart');
    newFile(a, content: r'''
library lib;
part 'a2.dart';
class A1 {}
''');
    newFile(a2, content: r'''
part of lib;
class A2 {}
''');
    _assertExportedTopLevelDeclarations(a, ['A1', 'A2']);
  }

  test_getFileForPath_doesNotExist() {
    String path = convertPath('/aaa/lib/a.dart');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.path, path);
    expect(file.uri, Uri.parse('package:aaa/a.dart'));
    expect(file.content, '');
    expect(file.contentHash, _md5(''));
    expect(_excludeSdk(file.importedFiles), isEmpty);
    expect(file.exportedFiles, isEmpty);
    expect(file.partedFiles, isEmpty);
    expect(file.libraryFiles, [file]);
    expect(_excludeSdk(file.directReferencedFiles), isEmpty);
    expect(file.isPart, isFalse);
    expect(file.library, isNull);
    expect(file.unlinked, isNotNull);
    expect(file.unlinked.classes, isEmpty);
  }

  test_getFileForPath_emptyUri() {
    String path = convertPath('/test.dart');
    newFile(path, content: r'''
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
    String a = convertPath('/test/lib/a.dart');
    newFile(a, content: r'''
library L;
part of L;
''');
    FileState file = fileSystemState.getFileForPath(a);
    expect(file.isPart, isFalse);
  }

  test_getFileForPath_invalidUri() {
    String a = convertPath('/aaa/lib/a.dart');
    String a1 = convertPath('/aaa/lib/a1.dart');
    String a2 = convertPath('/aaa/lib/a2.dart');
    String a3 = convertPath('/aaa/lib/a3.dart');
    String content_a1 = r'''
import 'package:aaa/a1.dart';
import ':[invalid uri]';

export 'package:aaa/a2.dart';
export ':[invalid uri]';

part 'a3.dart';
part ':[invalid uri]';
''';
    newFile(a, content: content_a1);

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
    String a1 = convertPath('/aaa/lib/a1.dart');
    String a2 = convertPath('/aaa/lib/a2.dart');
    String a3 = convertPath('/aaa/lib/a3.dart');
    String a4 = convertPath('/aaa/lib/a4.dart');
    String b1 = convertPath('/bbb/lib/b1.dart');
    String b2 = convertPath('/bbb/lib/b2.dart');
    String content_a1 = r'''
import 'package:aaa/a2.dart';
import 'package:bbb/b1.dart';
export 'package:bbb/b2.dart';
export 'package:aaa/a3.dart';
part 'a4.dart';

class A1 {}
''';
    newFile(a1, content: content_a1);

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

    expect(file.libraryFiles, [file, file.partedFiles[0]]);

    expect(_excludeSdk(file.directReferencedFiles), hasLength(5));

    expect(fileSystemState.getFilesForPath(a1), [file]);
  }

  test_getFileForPath_onlyDartFiles() {
    String not_dart = convertPath('/test/lib/not_dart.txt');
    String a = convertPath('/test/lib/a.dart');
    String b = convertPath('/test/lib/b.dart');
    String c = convertPath('/test/lib/c.dart');
    String d = convertPath('/test/lib/d.dart');
    newFile(a, content: r'''
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
    String a1 = convertPath('/aaa/lib/a1.dart');
    String a2 = convertPath('/aaa/lib/a2.dart');
    newFile(a1, content: r'''
library a1;
part 'a2.dart';
''');
    newFile(a2, content: r'''
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
    newFile(a1, content: r'''
library a1;
part 'not-a2.dart';
''');
    file_a1.refresh();
    expect(file_a2.library, isNull);
  }

  test_getFileForPath_samePath() {
    String path = convertPath('/aaa/lib/a.dart');
    FileState file1 = fileSystemState.getFileForPath(path);
    FileState file2 = fileSystemState.getFileForPath(path);
    expect(file2, same(file1));
  }

  test_getFileForUri_invalidUri() {
    var uri = Uri.parse('package:x');
    var file = fileSystemState.getFileForUri(uri);
    expect(file.isUnresolved, isTrue);
    expect(file.uri, isNull);
    expect(file.path, isNull);
    expect(file.isPart, isFalse);
  }

  test_getFileForUri_packageVsFileUri() {
    String path = convertPath('/aaa/lib/a.dart');
    var packageUri = Uri.parse('package:aaa/a.dart');
    var fileUri = toUri(path);

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

  test_getFilesSubtypingName() {
    String a = convertPath('/a.dart');
    String b = convertPath('/b.dart');

    newFile(a, content: r'''
class A {}
class B extends A {}
''');
    newFile(b, content: r'''
class A {}
class D implements A {}
''');

    FileState aFile = fileSystemState.getFileForPath(a);
    FileState bFile = fileSystemState.getFileForPath(b);

    expect(
      fileSystemState.getFilesSubtypingName('A'),
      unorderedEquals([aFile, bFile]),
    );

    // Change b.dart so that it does not subtype A.
    newFile(b, content: r'''
class C {}
class D implements C {}
''');
    bFile.refresh();
    expect(
      fileSystemState.getFilesSubtypingName('A'),
      unorderedEquals([aFile]),
    );
    expect(
      fileSystemState.getFilesSubtypingName('C'),
      unorderedEquals([bFile]),
    );
  }

  test_hasUri() {
    Uri uri = Uri.parse('package:aaa/foo.dart');
    String templatePath = convertPath('/aaa/lib/foo.dart');
    String generatedPath = convertPath('/generated/aaa/lib/foo.dart');

    Source generatedSource = new _SourceMock(generatedPath, uri);

    generatedUriResolver.resolveAbsoluteFunction =
        (uri, actualUri) => generatedSource;

    expect(fileSystemState.hasUri(templatePath), isFalse);
    expect(fileSystemState.hasUri(generatedPath), isTrue);
  }

  test_libraryCycle() {
    String pa = convertPath('/aaa/lib/a.dart');
    String pb = convertPath('/aaa/lib/b.dart');
    String pc = convertPath('/aaa/lib/c.dart');
    String pd = convertPath('/aaa/lib/d.dart');

    FileState fa = fileSystemState.getFileForPath(pa);
    FileState fb = fileSystemState.getFileForPath(pb);
    FileState fc = fileSystemState.getFileForPath(pc);
    FileState fd = fileSystemState.getFileForPath(pd);

    // Compute library cycles for all files.
    fa.libraryCycle;
    fb.libraryCycle;
    fc.libraryCycle;
    fd.libraryCycle;
    _assertFilesWithoutLibraryCycle([]);

    // No imports, so just a single file.
    newFile(pa);
    _assertLibraryCycle(fa, [fa], []);

    // Import b.dart into a.dart, two files now.
    newFile(pa, content: "import 'b.dart';");
    fa.refresh();
    _assertFilesWithoutLibraryCycle([fa]);
    _assertLibraryCycle(fa, [fa], [fb.libraryCycle]);

    // Update b.dart so that it imports c.dart now.
    newFile(pb, content: "import 'c.dart';");
    fb.refresh();
    _assertFilesWithoutLibraryCycle([fa, fb]);
    _assertLibraryCycle(fa, [fa], [fb.libraryCycle]);
    _assertLibraryCycle(fb, [fb], [fc.libraryCycle]);
    _assertFilesWithoutLibraryCycle([]);

    // Update b.dart so that it exports d.dart instead.
    newFile(pb, content: "export 'd.dart';");
    fb.refresh();
    _assertFilesWithoutLibraryCycle([fa, fb]);
    _assertLibraryCycle(fa, [fa], [fb.libraryCycle]);
    _assertLibraryCycle(fb, [fb], [fd.libraryCycle]);
    _assertFilesWithoutLibraryCycle([]);

    // Update a.dart so that it does not import b.dart anymore.
    newFile(pa);
    fa.refresh();
    _assertFilesWithoutLibraryCycle([fa]);
    _assertLibraryCycle(fa, [fa], []);
  }

  test_libraryCycle_cycle() {
    String pa = convertPath('/aaa/lib/a.dart');
    String pb = convertPath('/aaa/lib/b.dart');

    newFile(pa, content: "import 'b.dart';");
    newFile(pb, content: "import 'a.dart';");

    FileState fa = fileSystemState.getFileForPath(pa);
    FileState fb = fileSystemState.getFileForPath(pb);

    // Compute library cycles for all files.
    fa.libraryCycle;
    fb.libraryCycle;
    _assertFilesWithoutLibraryCycle([]);

    // It's a cycle.
    _assertLibraryCycle(fa, [fa, fb], []);
    _assertLibraryCycle(fb, [fa, fb], []);

    // Update a.dart so that it does not import b.dart anymore.
    newFile(pa);
    fa.refresh();
    _assertFilesWithoutLibraryCycle([fa, fb]);
    _assertLibraryCycle(fa, [fa], []);
    _assertLibraryCycle(fb, [fb], [fa.libraryCycle]);
  }

  test_referencedNames() {
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, content: r'''
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
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, content: r'''
class A {}
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.unlinked.classes[0].name, 'A');
    List<int> signature = file.apiSignature;

    // Update the resource and refresh the file state.
    newFile(path, content: r'''
class B {}
''');
    bool apiSignatureChanged = file.refresh();
    expect(apiSignatureChanged, isTrue);

    expect(file.unlinked.classes[0].name, 'B');
    expect(file.apiSignature, isNot(signature));
  }

  test_refresh_sameApiSignature() {
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, content: r'''
class C {
  foo() {
    print(111);
  }
}
''');
    FileState file = fileSystemState.getFileForPath(path);
    List<int> signature = file.apiSignature;

    // Update the resource and refresh the file state.
    newFile(path, content: r'''
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
    String path = convertPath('/test.dart');
    newFile(path, content: 'class A {}');

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
    String path = convertPath('/test.dart');
    newFile(path, content: r'''
class X extends A {}
class Y extends A with B {}
class Z implements C, D {}
''');
    FileState file = fileSystemState.getFileForPath(path);
    expect(file.referencedNames, unorderedEquals(['A', 'B', 'C', 'D']));
  }

  test_topLevelDeclarations() {
    String path = convertPath('/aaa/lib/a.dart');
    newFile(path, content: r'''
class C {}
typedef F();
enum E {E1, E2}
mixin M {}
void f() {}
var V1;
get V2 => null;
set V3(_) {}
get V4 => null;
set V4(_) {}

class _C {}
typedef _F();
enum _E {E1, E2}
mixin _M {}
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

    expect(
      declarations.keys,
      unorderedEquals(['C', 'F', 'E', 'M', 'f', 'V1', 'V2', 'V3', 'V4']),
    );
    assertHas('C', TopLevelDeclarationKind.type);
    assertHas('F', TopLevelDeclarationKind.type);
    assertHas('E', TopLevelDeclarationKind.type);
    assertHas('M', TopLevelDeclarationKind.type);
    assertHas('f', TopLevelDeclarationKind.function);
    assertHas('V1', TopLevelDeclarationKind.variable);
    assertHas('V2', TopLevelDeclarationKind.variable);
    assertHas('V3', TopLevelDeclarationKind.variable);
    assertHas('V4', TopLevelDeclarationKind.variable);
  }

  test_transitiveSignature() {
    String pa = convertPath('/aaa/lib/a.dart');
    String pb = convertPath('/aaa/lib/b.dart');
    String pc = convertPath('/aaa/lib/c.dart');
    String pd = convertPath('/aaa/lib/d.dart');

    newFile(pa, content: "class A {}");
    newFile(pb, content: "import 'a.dart';");
    newFile(pc, content: "import 'b.dart';");
    newFile(pd, content: "class D {}");

    FileState fa = fileSystemState.getFileForPath(pa);
    FileState fb = fileSystemState.getFileForPath(pb);
    FileState fc = fileSystemState.getFileForPath(pc);
    FileState fd = fileSystemState.getFileForPath(pd);

    // Compute transitive closures for all files.
    // This implicitly computes library cycles.
    expect(fa.transitiveSignature, isNotNull);
    expect(fb.transitiveSignature, isNotNull);
    expect(fc.transitiveSignature, isNotNull);
    expect(fd.transitiveSignature, isNotNull);
    _assertFilesWithoutLibraryCycle([]);

    // Make an update to a.dart that does not change its API signature.
    // All library cycles are still valid.
    newFile(pa, content: "class A {} // the same API signature");
    fa.refresh();
    _assertFilesWithoutLibraryCycle([]);

    // Change a.dart API signature.
    // This flushes signatures of b.dart and c.dart, but d.dart is still OK.
    newFile(pa, content: "class A2 {}");
    fa.refresh();
    _assertFilesWithoutLibraryCycle([fa, fb, fc]);
  }

  test_transitiveSignature_part() {
    var aPath = convertPath('/test/lib/a.dart');
    var bPath = convertPath('/test/lib/b.dart');

    newFile(aPath, content: r'''
part 'b.dart';
''');
    newFile(bPath, content: '''
part of 'a.dart';
''');

    var aFile = fileSystemState.getFileForPath(aPath);
    var bFile = fileSystemState.getFileForPath(bPath);

    var aSignature = aFile.transitiveSignature;
    var bSignature = bFile.transitiveSignature;

    // It is not valid to use a part as a library, and so ask its signature.
    // But when this happens, we should compute the transitive signature anyway.
    // And it should not be the signature of the containing library.
    expect(bSignature, isNot(aSignature));
  }

  void _assertExportedTopLevelDeclarations(String path, List<String> expected) {
    FileState file = fileSystemState.getFileForPath(path);
    Map<String, TopLevelDeclaration> declarations =
        file.exportedTopLevelDeclarations;
    expect(declarations.keys, unorderedEquals(expected));
  }

  void _assertFilesWithoutLibraryCycle(List<FileState> expected) {
    var actual = fileSystemState.test.filesWithoutLibraryCycle;
    expect(_excludeSdk(actual), unorderedEquals(expected));
  }

  void _assertHasComputedExportedDeclarations(List<String> expectedPathList) {
    FileSystemStateTestView test = fileSystemState.test;
    expect(test.librariesWithComputedExportedDeclarations.map((f) => f.path),
        unorderedEquals(expectedPathList));
  }

  void _assertIsUnresolvedFile(FileState file) {
    expect(file.path, isNull);
    expect(file.uri, isNull);
    expect(file.source, isNull);
  }

  void _assertLibraryCycle(
    FileState file,
    List<FileState> expectedLibraries,
    List<LibraryCycle> expectedDirectDependencies,
  ) {
    expect(file.libraryCycle.libraries, unorderedEquals(expectedLibraries));
    expect(
      _excludeSdk(file.libraryCycle.directDependencies),
      unorderedEquals(expectedDirectDependencies),
    );
  }

  List<T> _excludeSdk<T>(Iterable<T> files) {
    return files.where((Object file) {
      if (file is LibraryCycle) {
        return !file.libraries.any((file) => file.uri.isScheme('dart'));
      } else if (file is FileState) {
        return file.uri?.scheme != 'dart';
      } else {
        return !(file as String).startsWith(convertPath('/sdk'));
      }
    }).toList();
  }

  static String _md5(String content) {
    return hex.encode(md5.convert(utf8.encode(content)).bytes);
  }
}

class _GeneratedUriResolverMock implements UriResolver {
  Source Function(Uri, Uri) resolveAbsoluteFunction;

  Uri Function(Source) restoreAbsoluteFunction;

  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
  }

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    if (resolveAbsoluteFunction != null) {
      return resolveAbsoluteFunction(uri, actualUri);
    }
    return null;
  }

  @override
  Uri restoreAbsolute(Source source) {
    if (restoreAbsoluteFunction != null) {
      return restoreAbsoluteFunction(source);
    }
    return null;
  }
}

class _SourceMock implements Source {
  @override
  final String fullName;

  @override
  final Uri uri;

  _SourceMock(this.fullName, this.uri);

  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
  }
}
