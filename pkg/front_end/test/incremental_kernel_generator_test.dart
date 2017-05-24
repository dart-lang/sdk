// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/compiler_options.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:front_end/src/incremental/byte_store.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'src/incremental/mock_sdk.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IncrementalKernelGeneratorTest);
  });
}

@reflectiveTest
class IncrementalKernelGeneratorTest {
  /// Virtual filesystem for testing.
  final fileSystem = new MemoryFileSystem(Uri.parse('file:///'));

  /// The object under test.
  IncrementalKernelGenerator incrementalKernelGenerator;

  /// Compute the initial [Program] for the given [entryPoint].
  Future<Program> getInitialState(Uri entryPoint) async {
    Map<String, Uri> dartLibraries = createSdkFiles(fileSystem);
    // TODO(scheglov) Builder the SDK kernel and set it into the options.

    // TODO(scheglov) Make `.packages` file optional.

    var compilerOptions = new CompilerOptions()
      ..fileSystem = fileSystem
      ..byteStore = new MemoryByteStore()
//      ..logger = new PerformanceLog(stdout)
      ..strongMode = true
      ..chaseDependencies = true
      ..dartLibraries = dartLibraries
      ..packagesFileUri = Uri.parse('file:///test/.packages');
    incrementalKernelGenerator = await IncrementalKernelGenerator.newInstance(
        compilerOptions, entryPoint);
    return (await incrementalKernelGenerator.computeDelta()).newProgram;
  }

  test_compile_chain() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    String cPath = '/test/lib/c.dart';
    Uri aUri = writeFile(aPath, 'var a = 1;');
    Uri bUri = writeFile(
        bPath,
        r'''
import 'a.dart';
var b = a;
''');
    Uri cUri = writeFile(
        cPath,
        r'''
import 'a.dart';
import 'b.dart';
var c1 = a;
var c2 = b;
''');

    {
      Program program = await getInitialState(cUri);
      _assertLibraryUris(program,
          includes: [aUri, bUri, cUri, Uri.parse('dart:core')]);
      Library library = _getLibrary(program, cUri);
      expect(
          _getLibraryText(library),
          r'''
library;
import self as self;
import "dart:core" as core;
import "./a.dart" as a;
import "./b.dart" as b;

static field core::int c1 = a::a;
static field core::int c2 = b::b;
''');
    }

    // Update b.dart and recompile c.dart
    writeFile(
        bPath,
        r'''
import 'a.dart';
var b = 1.2;
''');
    incrementalKernelGenerator.invalidate(bUri);
    {
      DeltaProgram delta = await incrementalKernelGenerator.computeDelta();
      Program program = delta.newProgram;
      _assertLibraryUris(program,
          includes: [bUri, cUri], excludes: [aUri, Uri.parse('dart:core')]);
      Library library = _getLibrary(program, cUri);
      expect(
          _getLibraryText(library),
          r'''
library;
import self as self;
import "dart:core" as core;
import "./a.dart" as a;
import "./b.dart" as b;

static field core::int c1 = a::a;
static field core::double c2 = b::b;
''');
    }
  }

  test_compile_export() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    String cPath = '/test/lib/c.dart';
    writeFile(aPath, 'class A {}');
    writeFile(bPath, 'export "a.dart";');
    Uri cUri = writeFile(
        cPath,
        r'''
import 'b.dart';
A a;
''');

    Program program = await getInitialState(cUri);
    Library library = _getLibrary(program, cUri);
    expect(
        _getLibraryText(library),
        r'''
library;
import self as self;
import "./a.dart" as a;

static field a::A a;
''');
  }

  test_compile_export_cycle() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    String cPath = '/test/lib/c.dart';
    writeFile(aPath, 'export "b.dart"; class A {}');
    writeFile(bPath, 'export "a.dart"; class B {}');
    Uri cUri = writeFile(
        cPath,
        r'''
import 'b.dart';
A a;
B b;
''');

    {
      Program program = await getInitialState(cUri);
      Library library = _getLibrary(program, cUri);
      expect(
          _getLibraryText(library),
          r'''
library;
import self as self;
import "./a.dart" as a;
import "./b.dart" as b;

static field a::A a;
static field b::B b;
''');
    }

    // Update c.dart and compile.
    // We should load the cycle [a.dart, b.dart] from the byte store.
    // This tests that we compute export scopes after loading.
    writeFile(
        cPath,
        r'''
import 'b.dart';
A a;
B b;
int c;
''');
    incrementalKernelGenerator.invalidate(cUri);
    {
      DeltaProgram delta = await incrementalKernelGenerator.computeDelta();
      Program program = delta.newProgram;
      Library library = _getLibrary(program, cUri);
      expect(
          _getLibraryText(library),
          r'''
library;
import self as self;
import "./a.dart" as a;
import "./b.dart" as b;
import "dart:core" as core;

static field a::A a;
static field b::B b;
static field core::int c;
''');
    }
  }

  test_compile_export_hideWithLocal() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    String cPath = '/test/lib/c.dart';
    writeFile(aPath, 'class A {} class B {}');
    writeFile(bPath, 'export "a.dart"; class B {}');
    Uri cUri = writeFile(
        cPath,
        r'''
import 'b.dart';
A a;
B b;
''');

    Program program = await getInitialState(cUri);
    Library library = _getLibrary(program, cUri);
    expect(
        _getLibraryText(library),
        r'''
library;
import self as self;
import "./a.dart" as a;
import "./b.dart" as b;

static field a::A a;
static field b::B b;
''');
  }

  test_compile_includePathToMain() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    String cPath = '/test/lib/c.dart';
    String dPath = '/test/lib/d.dart';

    // A --> B -> C
    //   \-> D

    Uri aUri = writeFile(
        aPath,
        r'''
import 'b.dart';
import 'd.dart';
main() {
  b();
  d();
}
''');
    Uri bUri = writeFile(
        bPath,
        r'''
import 'c.dart';
b() {
  c();
}
''');
    Uri cUri = writeFile(cPath, 'c() { print(0); }');
    Uri dUri = writeFile(dPath, 'd() {}');

    {
      Program program = await getInitialState(aUri);
      _assertLibraryUris(program,
          includes: [aUri, bUri, cUri, dUri, Uri.parse('dart:core')]);
    }

    // Update c.dart and compute the delta.
    // It should include the changed c.dart, the affected b.dart, and
    // also a.dart because VM requires this (because of possible inlining).
    // But d.dart is not on the path from main() to the changed c.dart,
    // so it is not included.
    writeFile(cPath, 'c() { print(1); }');
    incrementalKernelGenerator.invalidate(cUri);
    {
      DeltaProgram delta = await incrementalKernelGenerator.computeDelta();
      Program program = delta.newProgram;
      _assertLibraryUris(program,
          includes: [aUri, bUri, cUri],
          excludes: [dUri, Uri.parse('dart:core')]);
    }
  }

  test_compile_typedef() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    writeFile(aPath, 'typedef int F<T>(T x);');
    Uri bUri = writeFile(
        bPath,
        r'''
import 'a.dart';
F<String> f;
''');

    Program program = await getInitialState(bUri);
    Library library = _getLibrary(program, bUri);
    expect(
        _getLibraryText(library),
        r'''
library;
import self as self;
import "dart:core" as core;

static field (core::String) → core::int f;
''');
  }

  test_updateEntryPoint() async {
    writeFile('/test/.packages', 'test:lib/');
    String path = '/test/lib/test.dart';
    Uri uri = writeFile(
        path,
        r'''
main() {
  var v = 1;
}
''');

    String initialText = r'''
library;
import self as self;
import "dart:core" as core;

static method main() → dynamic {
  core::int v = 1;
}
''';

    // Compute the initial state.
    {
      Program program = await getInitialState(uri);
      Library library = _getLibrary(program, uri);
      expect(_getLibraryText(library), initialText);
    }

    // Update the entry point library.
    writeFile(
        path,
        r'''
main() {
  var v = 2.3;
}
''');

    // We have not invalidated the file, so the delta is empty.
    {
      DeltaProgram delta = await incrementalKernelGenerator.computeDelta();
      expect(delta.newProgram.libraries, isEmpty);
    }

    // Invalidate the file, so get the new text.
    incrementalKernelGenerator.invalidate(uri);
    {
      DeltaProgram delta = await incrementalKernelGenerator.computeDelta();
      Program program = delta.newProgram;
      _assertLibraryUris(program, includes: [uri]);
      Library library = _getLibrary(program, uri);
      expect(
          _getLibraryText(library),
          r'''
library;
import self as self;
import "dart:core" as core;

static method main() → dynamic {
  core::double v = 2.3;
}
''');
    }
  }

  test_updatePart() async {
    writeFile('/test/.packages', 'test:lib/');
    String libPath = '/test/lib/test.dart';
    String partPath = '/test/lib/bar.dart';
    Uri libUri = writeFile(
        libPath,
        r'''
library foo;
part 'bar.dart';
var a = 1;
var c = b;
void main() {}
''');
    Uri partUri = writeFile(
        partPath,
        r'''
part of foo;
var b = 2;
var d = a;
''');

    // Check the initial state - types flow between the part and the library.
    Program program = await getInitialState(libUri);
    Library library = _getLibrary(program, libUri);
    expect(
        _getLibraryText(library),
        r'''
library foo;
import self as self;
import "dart:core" as core;

static field core::int a = 1;
static field core::int c = self::b;
static field core::int b = 2 /* from file:///test/lib/bar.dart */;
static field core::int d = self::a /* from file:///test/lib/bar.dart */;
static method main() → void {}
''');

    // Update [b] in the part, the type is changed in the part and library.
    {
      writeFile(
          partPath,
          r'''
part of foo;
var b = 2.3;
var d = a;
''');
      incrementalKernelGenerator.invalidate(partUri);
      DeltaProgram delta = await incrementalKernelGenerator.computeDelta();
      Library library = _getLibrary(delta.newProgram, libUri);
      expect(
          _getLibraryText(library),
          r'''
library foo;
import self as self;
import "dart:core" as core;

static field core::int a = 1;
static field core::double c = self::b;
static field core::double b = 2.3 /* from file:///test/lib/bar.dart */;
static field core::int d = self::a /* from file:///test/lib/bar.dart */;
static method main() → void {}
''');
    }

    // Update [a] in the library, the type is changed in the part and library.
    {
      writeFile(
          libPath,
          r'''
library foo;
part 'bar.dart';
var a = 'aaa';
var c = b;
void main() {}
''');
      incrementalKernelGenerator.invalidate(libUri);
      DeltaProgram delta = await incrementalKernelGenerator.computeDelta();
      Library library = _getLibrary(delta.newProgram, libUri);
      expect(
          _getLibraryText(library),
          r'''
library foo;
import self as self;
import "dart:core" as core;

static field core::String a = "aaa";
static field core::double c = self::b;
static field core::double b = 2.3 /* from file:///test/lib/bar.dart */;
static field core::String d = self::a /* from file:///test/lib/bar.dart */;
static method main() → void {}
''');
    }
  }

  /// Write the given [text] of the file with the given [path] into the
  /// virtual filesystem.  Return the URI of the file.
  Uri writeFile(String path, String text) {
    Uri uri = Uri.parse('file://$path');
    fileSystem.entityForUri(uri).writeAsStringSync(text);
    return uri;
  }

  /// Write the given file contents to the virtual filesystem.
  void writeFiles(Map<String, String> contents) {
    contents.forEach(writeFile);
  }

  void _assertLibraryUris(Program program,
      {List<Uri> includes: const [], List<Uri> excludes: const []}) {
    List<Uri> libraryUris =
        program.libraries.map((library) => library.importUri).toList();
    for (var shouldInclude in includes) {
      expect(libraryUris, contains(shouldInclude));
    }
    for (var shouldExclude in excludes) {
      expect(libraryUris, isNot(contains(shouldExclude)));
    }
  }

  Library _getLibrary(Program program, Uri uri) {
    for (var library in program.libraries) {
      if (library.importUri == uri) return library;
    }
    throw fail('No library found with URI "$uri"');
  }

  String _getLibraryText(Library library) {
    StringBuffer buffer = new StringBuffer();
    new Printer(buffer, syntheticNames: new NameSystem())
        .writeLibraryFile(library);
    return buffer.toString();
  }
}
