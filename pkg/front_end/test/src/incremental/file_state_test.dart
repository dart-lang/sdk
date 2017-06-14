// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/memory_file_system.dart';
import 'package:front_end/src/fasta/translate_uri.dart';
import 'package:front_end/src/incremental/byte_store.dart';
import 'package:front_end/src/incremental/file_state.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mock_sdk.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileSystemStateTest);
  });
}

@reflectiveTest
class FileSystemStateTest {
  final byteStore = new MemoryByteStore();
  final fileSystem = new MemoryFileSystem(Uri.parse('file:///'));
  final TranslateUri uriTranslator = new TranslateUri({}, {}, {});
  FileSystemState fsState;

  Uri _coreUri;
  List<Uri> _newFileUris = <Uri>[];

  void setUp() {
    Map<String, Uri> dartLibraries = createSdkFiles(fileSystem);
    uriTranslator.dartLibraries.addAll(dartLibraries);
    _coreUri = Uri.parse('dart:core');
    expect(_coreUri, isNotNull);
    fsState = new FileSystemState(byteStore, fileSystem, uriTranslator, <int>[],
        (uri) {
      _newFileUris.add(uri);
      return new Future.value();
    });
  }

  test_apiSignature() async {
    var path = '/a.dart';
    var uri = writeFile(path, '');
    FileState file = await fsState.getFile(uri);

    List<int> lastSignature = file.apiSignature;

    /// Assert that the given [newCode] has the same API signature as
    /// the last computed.
    Future<Null> assertSameSignature(String newCode) async {
      writeFile(path, newCode);
      await file.refresh();
      List<int> newSignature = file.apiSignature;
      expect(newSignature, lastSignature);
    }

    /// Assert that the given [newCode] does not have the same API signature as
    /// the last computed, and update the last signature to the new one.
    Future<Null> assertNotSameSignature(String newCode) async {
      writeFile(path, newCode);
      await file.refresh();
      List<int> newSignature = file.apiSignature;
      expect(newSignature, isNot(lastSignature));
      lastSignature = newSignature;
    }

    await assertNotSameSignature('''
var v = 1;
foo() {
  print(2);
}
bar() {
  print(3);
}
baz() => 4;
''');

    // [S] Add comments.
    await assertSameSignature('''
var v = 1; // comment
/// comment 1
/// comment 2
foo() {
  print(2);
}
bar() {
  print(3);
}
/**
 *  Comment
 */
baz() => 4;
''');

    // [S] Remove comments.
    await assertSameSignature('''
var v = 1;
foo() {
  print(2);
}
bar() {
  print(3);
}
baz() => 4;
''');

    // [NS] Change the top-level variable initializer.
    await assertNotSameSignature('''
var v = 11;
foo() {
  print(2);
}
bar() {
  print(3);
}
baz() => 4;
''');

    // [S] Change in a block function body.
    await assertSameSignature('''
var v = 11;
foo() {
  print(22);
}
bar() {
  print(33);
}
baz() => 4;
''');

    // [NS] Change in an expression function body.
    await assertNotSameSignature('''
var v = 11;
foo() {
  print(22);
}
bar() {
  print(33);
}
baz() => 44;
''');
  }

  test_gc() async {
    var a = writeFile('/a.dart', '');
    var b = writeFile('/b.dart', '');
    var c = writeFile('/c.dart', 'import "a.dart";');
    var d = writeFile('/d.dart', 'import "b.dart";');
    var e = writeFile(
        '/e.dart',
        r'''
import "c.dart";
import "d.dart";
''');

    var eFile = await fsState.getFile(e);

    // The root and four files.
    expect(fsState.fileUris, contains(e));
    expect(fsState.fileUris, contains(a));
    expect(fsState.fileUris, contains(b));
    expect(fsState.fileUris, contains(c));
    expect(fsState.fileUris, contains(d));

    // No changes after GC.
    expect(fsState.gc(e), isEmpty);
    expect(fsState.fileUris, contains(e));
    expect(fsState.fileUris, contains(a));
    expect(fsState.fileUris, contains(b));
    expect(fsState.fileUris, contains(c));
    expect(fsState.fileUris, contains(d));

    // Update e.dart so that it does not reference c.dart anymore.
    // Then GC removes both c.dart and a.dart it references.
    writeFile(
        '/e.dart',
        r'''
import "d.dart";
''');
    await eFile.refresh();
    {
      var gcFiles = fsState.gc(e);
      expect(gcFiles.map((file) => file.uri), unorderedEquals([a, c]));
    }
    expect(fsState.fileUris, contains(e));
    expect(fsState.fileUris, isNot(contains(a)));
    expect(fsState.fileUris, contains(b));
    expect(fsState.fileUris, isNot(contains(c)));
    expect(fsState.fileUris, contains(d));
  }

  test_getFile() async {
    var a = writeFile('/a.dart', '');
    var b = writeFile('/b.dart', '');
    var c = writeFile('/c.dart', '');
    var d = writeFile(
        '/d.dart',
        r'''
import "a.dart";
export "b.dart";
part "c.dart";
''');

    FileState aFile = await fsState.getFile(a);
    FileState bFile = await fsState.getFile(b);
    FileState cFile = await fsState.getFile(c);
    FileState dFile = await fsState.getFile(d);

    expect(dFile.fileUri, d);
    expect(dFile.exists, isTrue);
    _assertImportedUris(dFile, [a, _coreUri]);
    expect(dFile.importedLibraries, contains(aFile));
    expect(dFile.exportedLibraries, contains(bFile));
    expect(dFile.partFiles, contains(cFile));

    expect(aFile.fileUri, a);
    expect(aFile.exists, isTrue);
    _assertImportedUris(aFile, [_coreUri]);
    expect(aFile.exportedLibraries, isEmpty);
    expect(aFile.partFiles, isEmpty);

    expect(bFile.fileUri, b);
    expect(bFile.exists, isTrue);
    _assertImportedUris(bFile, [_coreUri]);
    expect(bFile.exportedLibraries, isEmpty);
    expect(bFile.partFiles, isEmpty);
  }

  test_getFile_exports() async {
    var a = writeFile('/a.dart', '');
    var b = writeFile('/b.dart', '');
    var c = writeFile('/c.dart', '');
    var d = writeFile(
        '/d.dart',
        r'''
export "a.dart" show A, B;
export "b.dart" hide C, D;
export "c.dart" show A, B, C, D hide C show A, D;
''');

    FileState aFile = await fsState.getFile(a);
    FileState bFile = await fsState.getFile(b);
    FileState cFile = await fsState.getFile(c);
    FileState dFile = await fsState.getFile(d);

    expect(dFile.exports, hasLength(3));
    {
      NamespaceExport export_ = dFile.exports[0];
      expect(export_.library, aFile);
      expect(export_.combinators, hasLength(1));
      expect(export_.combinators[0].isShow, isTrue);
      expect(export_.combinators[0].names, unorderedEquals(['A', 'B']));
      expect(export_.isExposed('A'), isTrue);
      expect(export_.isExposed('B'), isTrue);
      expect(export_.isExposed('C'), isFalse);
      expect(export_.isExposed('D'), isFalse);
    }
    {
      NamespaceExport export_ = dFile.exports[1];
      expect(export_.library, bFile);
      expect(export_.combinators, hasLength(1));
      expect(export_.combinators[0].isShow, isFalse);
      expect(export_.combinators[0].names, unorderedEquals(['C', 'D']));
      expect(export_.isExposed('A'), isTrue);
      expect(export_.isExposed('B'), isTrue);
      expect(export_.isExposed('C'), isFalse);
      expect(export_.isExposed('D'), isFalse);
    }
    {
      NamespaceExport export_ = dFile.exports[2];
      expect(export_.library, cFile);
      expect(export_.combinators, hasLength(3));
      expect(export_.combinators[0].isShow, isTrue);
      expect(
          export_.combinators[0].names, unorderedEquals(['A', 'B', 'C', 'D']));
      expect(export_.combinators[1].isShow, isFalse);
      expect(export_.combinators[1].names, unorderedEquals(['C']));
      expect(export_.combinators[2].isShow, isTrue);
      expect(export_.combinators[2].names, unorderedEquals(['A', 'D']));
      expect(export_.isExposed('A'), isTrue);
      expect(export_.isExposed('B'), isFalse);
      expect(export_.isExposed('C'), isFalse);
      expect(export_.isExposed('D'), isTrue);
    }
  }

  test_hasMixinApplication_false() async {
    writeFile(
        '/a.dart',
        r'''
class A {}
class B extends Object with A {}
''');
    var uri = writeFile(
        '/test.dart',
        r'''
import 'a.dart';
class T1 extends A {}
class T2 extends B {}
''');
    FileState file = await fsState.getFile(uri);
    expect(file.hasMixinApplication, isFalse);
  }

  test_hasMixinApplication_true_class() async {
    var uri = writeFile(
        '/test.dart',
        r'''
class A {}
class B extends Object with A {}
''');
    FileState file = await fsState.getFile(uri);
    expect(file.hasMixinApplication, isTrue);
  }

  test_hasMixinApplication_true_named() async {
    var uri = writeFile(
        '/test.dart',
        r'''
class A {}
class B = Object with A;
''');
    FileState file = await fsState.getFile(uri);
    expect(file.hasMixinApplication, isTrue);
  }

  test_hasMixinApplicationLibrary_false() async {
    var partUri = writeFile(
        '/part.dart',
        r'''
part of test;
class A {}
''');
    var libUri = writeFile(
        '/test.dart',
        r'''
library test;
part 'part.dart';
class B extends A {}
''');

    FileState part = await fsState.getFile(partUri);
    FileState lib = await fsState.getFile(libUri);

    expect(part.hasMixinApplication, isFalse);
    expect(lib.hasMixinApplication, isFalse);
    expect(lib.hasMixinApplicationLibrary, isFalse);
  }

  test_hasMixinApplicationLibrary_true_inDefiningUnit() async {
    var partUri = writeFile(
        '/part.dart',
        r'''
part of test;
class A {}
''');
    var libUri = writeFile(
        '/test.dart',
        r'''
library test;
part 'part.dart';
class B extends Object with A {}
''');

    FileState part = await fsState.getFile(partUri);
    FileState lib = await fsState.getFile(libUri);

    expect(part.hasMixinApplication, isFalse);
    expect(lib.hasMixinApplication, isTrue);
    expect(lib.hasMixinApplicationLibrary, isTrue);
  }

  test_hasMixinApplicationLibrary_true_inPart() async {
    var partUri = writeFile(
        '/part.dart',
        r'''
part of test;
class A {}
class B extends Object with A {}
''');
    var libUri = writeFile(
        '/test.dart',
        r'''
library test;
part 'part.dart';
class C {}
''');

    FileState part = await fsState.getFile(partUri);
    FileState lib = await fsState.getFile(libUri);

    expect(part.hasMixinApplication, isTrue);
    expect(lib.hasMixinApplication, isFalse);
    expect(lib.hasMixinApplicationLibrary, isTrue);
  }

  test_newFileListener() async {
    var a = writeFile('/a.dart', '');
    var b = writeFile('/b.dart', '');
    var c = writeFile(
        '/c.dart',
        r'''
import 'a.dart';
''');

    FileState cFile = await fsState.getFile(c);

    // c.dart uses c.dart and a.dart, but not b.dart yet.
    expect(_newFileUris, contains(c));
    expect(_newFileUris, contains(a));
    expect(_newFileUris, isNot(contains(b)));
    _newFileUris.clear();

    // Update c.dart to use b.dart too.
    writeFile(
        '/c.dart',
        r'''
import 'a.dart';
import 'b.dart';
''');
    await cFile.refresh();

    // b.dart is the only new file.
    expect(_newFileUris, [b]);
  }

  test_topologicalOrder_cycleBeforeTarget() async {
    var aUri = _writeFileDirectives('/a.dart');
    var bUri = _writeFileDirectives('/b.dart', imports: ['c.dart']);
    var cUri = _writeFileDirectives('/c.dart', imports: ['b.dart']);
    var dUri = _writeFileDirectives('/d.dart', imports: ['a.dart', 'b.dart']);

    FileState core = await fsState.getFile(_coreUri);
    FileState a = await fsState.getFile(aUri);
    FileState b = await fsState.getFile(bUri);
    FileState c = await fsState.getFile(cUri);
    FileState d = await fsState.getFile(dUri);

    List<LibraryCycle> cycles = d.topologicalOrder;
    expect(cycles, hasLength(4));

    expect(cycles[0].libraries, contains(core));
    expect(cycles[1].libraries, unorderedEquals([a]));
    expect(cycles[2].libraries, unorderedEquals([b, c]));
    expect(cycles[3].libraries, unorderedEquals([d]));

    expect(cycles[0].directUsers,
        unorderedEquals([cycles[1], cycles[2], cycles[3]]));
    expect(cycles[1].directUsers, unorderedEquals([cycles[3]]));
    expect(cycles[2].directUsers, unorderedEquals([cycles[3]]));
    expect(cycles[3].directUsers, isEmpty);
  }

  test_topologicalOrder_cycleBeforeTarget_export() async {
    var aUri = _writeFileDirectives('/a.dart');
    var bUri = _writeFileDirectives('/b.dart', exports: ['c.dart']);
    var cUri = _writeFileDirectives('/c.dart', imports: ['b.dart']);
    var dUri = _writeFileDirectives('/d.dart', imports: ['a.dart', 'b.dart']);

    FileState core = await fsState.getFile(_coreUri);
    FileState a = await fsState.getFile(aUri);
    FileState b = await fsState.getFile(bUri);
    FileState c = await fsState.getFile(cUri);
    FileState d = await fsState.getFile(dUri);

    List<LibraryCycle> order = d.topologicalOrder;
    expect(order, hasLength(4));
    expect(order[0].libraries, contains(core));
    expect(order[1].libraries, unorderedEquals([a]));
    expect(order[2].libraries, unorderedEquals([b, c]));
    expect(order[3].libraries, unorderedEquals([d]));
  }

  test_topologicalOrder_cycleWithTarget() async {
    var aUri = _writeFileDirectives('/a.dart');
    var bUri = _writeFileDirectives('/b.dart', imports: ['c.dart']);
    var cUri = _writeFileDirectives('/c.dart', imports: ['a.dart', 'b.dart']);

    FileState core = await fsState.getFile(_coreUri);
    FileState a = await fsState.getFile(aUri);
    FileState b = await fsState.getFile(bUri);
    FileState c = await fsState.getFile(cUri);

    List<LibraryCycle> order = c.topologicalOrder;
    expect(order, hasLength(3));
    expect(order[0].libraries, contains(core));
    expect(order[1].libraries, unorderedEquals([a]));
    expect(order[2].libraries, unorderedEquals([b, c]));
  }

  /// Write the given [text] of the file with the given [path] into the
  /// virtual filesystem.  Return the URI of the file.
  Uri writeFile(String path, String text) {
    Uri uri = Uri.parse('file://$path');
    fileSystem.entityForUri(uri).writeAsStringSync(text);
    return uri;
  }

  void _assertImportedUris(FileState file, List<Uri> expectedUris) {
    Iterable<Uri> importedUris = _toUris(file.importedLibraries);
    expect(importedUris, unorderedEquals(expectedUris));
  }

  Iterable<Uri> _toUris(List<FileState> files) {
    return files.map((f) => f.uri);
  }

  Uri _writeFileDirectives(String path,
      {List<String> imports: const [], List<String> exports: const []}) {
    return writeFile(
        path,
        '''
${imports.map((uri) => 'import "$uri";').join('\n')}
${exports.map((uri) => 'export "$uri";').join('\n')}
''');
  }
}
