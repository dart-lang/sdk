// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/memory_file_system.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/fasta/uri_translator_impl.dart';
import 'package:front_end/src/incremental/byte_store.dart';
import 'package:front_end/src/incremental/kernel_driver.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/verifier.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mock_sdk.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(KernelDriverTest);
  });
}

@reflectiveTest
class KernelDriverTest {
  /// Virtual filesystem for testing.
  final fileSystem = new MemoryFileSystem(Uri.parse('file:///'));

  /// The object under test.
  KernelDriver driver;

  void setUp() {
    _createDriver();
  }

  test_compile_chain() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    String cPath = '/test/lib/c.dart';
    Uri aUri = writeFile(aPath, 'var a = 1;');
    Uri bUri = writeFile(bPath, r'''
import 'a.dart';
var b = a;
''');
    Uri cUri = writeFile(cPath, r'''
import 'a.dart';
import 'b.dart';
var c1 = a;
var c2 = b;
void main() {}
''');

    {
      KernelResult result = await driver.getKernel(cUri);
      _assertLibraryUris(result,
          includes: [aUri, bUri, cUri, Uri.parse('dart:core')]);
      Library library = _getLibrary(result, cUri);
      expect(_getLibraryText(library), r'''
library;
import self as self;
import "dart:core" as core;
import "./a.dart" as a;
import "./b.dart" as b;

static field core::int c1 = a::a;
static field core::int c2 = b::b;
static method main() → void {}
''');
    }

    // Update b.dart and recompile c.dart
    writeFile(bPath, r'''
import 'a.dart';
var b = 1.2;
''');
    driver.invalidate(bUri);
    {
      KernelResult result = await driver.getKernel(cUri);
      _assertLibraryUris(result,
          includes: [aUri, bUri, cUri, Uri.parse('dart:core')]);
      Library library = _getLibrary(result, cUri);
      expect(_getLibraryText(library), r'''
library;
import self as self;
import "dart:core" as core;
import "./a.dart" as a;
import "./b.dart" as b;

static field core::int c1 = a::a;
static field core::double c2 = b::b;
static method main() → void {}
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
    Uri cUri = writeFile(cPath, r'''
import 'b.dart';
A a;
''');

    KernelResult result = await driver.getKernel(cUri);
    Library library = _getLibrary(result, cUri);
    expect(_getLibraryText(library), r'''
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
    Uri cUri = writeFile(cPath, r'''
import 'b.dart';
A a;
B b;
''');

    {
      KernelResult result = await driver.getKernel(cUri);
      Library library = _getLibrary(result, cUri);
      expect(_getLibraryText(library), r'''
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
    writeFile(cPath, r'''
import 'b.dart';
A a;
B b;
int c;
''');
    driver.invalidate(cUri);
    {
      KernelResult result = await driver.getKernel(cUri);
      Library library = _getLibrary(result, cUri);
      expect(_getLibraryText(library), r'''
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
    Uri cUri = writeFile(cPath, r'''
import 'b.dart';
A a;
B b;
''');

    KernelResult result = await driver.getKernel(cUri);
    Library library = _getLibrary(result, cUri);
    expect(_getLibraryText(library), r'''
library;
import self as self;
import "./a.dart" as a;
import "./b.dart" as b;

static field a::A a;
static field b::B b;
''');
  }

  test_compile_recompileMixin() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    String cPath = '/test/lib/c.dart';

    Uri aUri = writeFile(aPath, r'''
import 'b.dart';
main() {
  new B().foo();
}
''');
    Uri bUri = writeFile(bPath, r'''
import 'c.dart';
class B extends Object with C {}
''');
    Uri cUri = writeFile(cPath, r'''
class C {
  void foo() {
    print(0);
  }
}
''');

    {
      KernelResult result = await driver.getKernel(aUri);
      _assertLibraryUris(result,
          includes: [aUri, bUri, cUri, Uri.parse('dart:core')]);
    }

    // Update c.dart and compute the delta.
    // Includes: c.dart, b.dart and a.dart files.
    // Compiled: c.dart (changed) and b.dart (has mixin), but not a.dart file.
    writeFile(cPath, r'''
class C {
  void foo() {
    print(1);
  }
}
''');
    driver.invalidate(cUri);
    {
      KernelResult result = await driver.getKernel(aUri);
      _assertLibraryUris(result,
          includes: [aUri, bUri, cUri, Uri.parse('dart:core')]);
      // Compiled: c.dart (changed), and b.dart (has mixin).
      _assertCompiledUris([cUri, bUri]);
    }
  }

  test_compile_typedef() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    writeFile(aPath, 'typedef int F<T>(T x);');
    Uri bUri = writeFile(bPath, r'''
import 'a.dart';
F<String> f;
''');

    KernelResult result = await driver.getKernel(bUri);
    Library library = _getLibrary(result, bUri);
    expect(_getLibraryText(library), r'''
library;
import self as self;
import "dart:core" as core;

static field (core::String) → core::int f;
''');
  }

  test_limited_ast_to_binary() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    writeFile(aPath, r'''
int topField = 0;
int get topGetter => 0;
int topFunction({p}) => 0;

abstract class I {
  int interfaceField;
  int get interfaceGetter;
  int interfaceMethod();
}

class A implements I {
  static int staticField;
  static int get staticGetter => 0;
  static int staticMethod() => 0;

  int instanceField;
  int get instanceGetter => 0;
  int instanceMethod() => 0;

  int interfaceField;
  int get interfaceGetter => 0;
  int interfaceMethod() => 0;

  A();
  A.named();
}
''');
    Uri bUri = writeFile(bPath, r'''
import 'a.dart';

class B extends A {
  B() : super();
  B.named() : super.named();

  void foo() {
    super.instanceMethod();
    instanceMethod();

    super.interfaceField;
    super.interfaceField = 0;
    super.interfaceGetter;
    super.interfaceMethod();
  }

  int instanceMethod() => 0;

  int interfaceField;
  int get interfaceGetter => 0;
  int interfaceMethod() => 0;
}

main() {
  topField;
  topField = 0;
  var v1 = topGetter;
  var v2 = topFunction(p: 0);

  A.staticField;
  A.staticField = 0;
  var v3 = A.staticGetter;
  var v4 = A.staticMethod();

  var a = new A();

  a.instanceField;
  a.instanceField = 0;
  var v5 = a.instanceGetter;
  var v6 = a.instanceMethod();

  a.interfaceField;
  a.interfaceField = 0;
  var v7 = a.interfaceGetter;
  var v8 = a.interfaceMethod();
}
''');

    KernelResult result = await driver.getKernel(bUri);

    Program program = new Program(
        nameRoot: result.nameRoot, libraries: _allLibraries(result));

    String initialKernelText;
    List<int> bytes;
    {
      Library initialLibrary = _getLibraryFromProgram(program, bUri);
      initialKernelText = _getLibraryText(initialLibrary);

      bytes = serializeProgram(program,
          filter: (library) => library.importUri == bUri);

      // Remove b.dart from the program.
      // So, the program is now ready for re-adding the library.
      program.mainMethod = null;
      program.libraries.remove(initialLibrary);
      program.root.removeChild(initialLibrary.importUri.toString());
    }

    // Load b.dart from bytes using the initial name root, so that
    // serialized canonical names can be linked to corresponding nodes.
    Library loadedLibrary;
    {
      var programForLoading = new Program(nameRoot: program.root);
      var reader = new BinaryBuilder(bytes);
      reader.readProgram(programForLoading);
      loadedLibrary = _getLibraryFromProgram(programForLoading, bUri);
    }

    // Add the library into the program.
    program.libraries.add(loadedLibrary);
    loadedLibrary.parent = program;
    program.mainMethod = loadedLibrary.procedures
        .firstWhere((procedure) => procedure.name.name == 'main');

    expect(_getLibraryText(loadedLibrary), initialKernelText);
    verifyProgram(program);
  }

  test_updatePackageSourceUsingFileUri() async {
    _createDriver(packages: {'test': _folderUri('/test/lib')});

    writeFile('/test/.packages', 'test:lib/');
    Uri aFileUri = writeFile('/test/bin/a.dart', r'''
import 'package:test/b.dart';
var a = b;
''');
    Uri bFileUri = writeFile('/test/lib/b.dart', 'var b = 1;');
    Uri bPackageUri = Uri.parse('package:test/b.dart');

    // Compute the initial state.
    {
      KernelResult result = await driver.getKernel(aFileUri);
      Library library = _getLibrary(result, aFileUri);
      expect(_getLibraryText(library), r'''
library;
import self as self;
import "dart:core" as core;
import "package:test/b.dart" as b;

static field core::int a = b::b;
''');
    }

    // Update b.dart and use file URI to invalidate it.
    // The delta is recomputed even though b.dart is used with the package URI.
    writeFile('/test/lib/b.dart', 'var b = 1.2;');
    driver.invalidate(bFileUri);
    {
      KernelResult result = await driver.getKernel(aFileUri);
      _assertLibraryUris(result, includes: [aFileUri, bPackageUri]);
      Library library = _getLibrary(result, aFileUri);
      expect(_getLibraryText(library), r'''
library;
import self as self;
import "dart:core" as core;
import "package:test/b.dart" as b;

static field core::double a = b::b;
''');
    }
  }

  test_updatePart() async {
    writeFile('/test/.packages', 'test:lib/');
    String libPath = '/test/lib/test.dart';
    String partPath = '/test/lib/bar.dart';
    Uri libUri = writeFile(libPath, r'''
library foo;
part 'bar.dart';
var a = 1;
var c = b;
void main() {}
''');
    Uri partUri = writeFile(partPath, r'''
part of foo;
var b = 2;
var d = a;
''');

    // Check the initial state - types flow between the part and the library.
    KernelResult result = await driver.getKernel(libUri);
    Library library = _getLibrary(result, libUri);
    expect(_getLibraryText(library), r'''
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
      writeFile(partPath, r'''
part of foo;
var b = 2.3;
var d = a;
''');
      driver.invalidate(partUri);
      KernelResult result = await driver.getKernel(libUri);
      Library library = _getLibrary(result, libUri);
      expect(_getLibraryText(library), r'''
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
      writeFile(libPath, r'''
library foo;
part 'bar.dart';
var a = 'aaa';
var c = b;
void main() {}
''');
      driver.invalidate(libUri);
      KernelResult result = await driver.getKernel(libUri);
      Library library = _getLibrary(result, libUri);
      expect(_getLibraryText(library), r'''
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

  test_watch() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    String cPath = '/test/lib/c.dart';
    Uri aUri = writeFile(aPath, '');
    Uri bUri = writeFile(bPath, '');
    Uri cUri = writeFile(cPath, r'''
import 'a.dart';
''');

    var usedFiles = <Uri>[];
    _createDriver(fileAddedFn: (Uri uri) {
      usedFiles.add(uri);
      return new Future.value();
    });

    {
      await driver.getKernel(cUri);
      // We use at least c.dart and a.dart now.
      expect(usedFiles, contains(cUri));
      expect(usedFiles, contains(aUri));
      usedFiles.clear();
    }

    // Update c.dart to reference also b.dart file.
    writeFile(cPath, r'''
import 'a.dart';
import 'b.dart';
''');
    driver.invalidate(cUri);
    {
      await driver.getKernel(cUri);
      // The only new file is b.dart now.
      expect(usedFiles, [bUri]);
      usedFiles.clear();
    }
  }

  /// Write the given [text] of the file with the given [path] into the
  /// virtual filesystem.  Return the URI of the file.
  Uri writeFile(String path, String text) {
    Uri uri = Uri.parse('file://$path');
    fileSystem.entityForUri(uri).writeAsStringSync(text);
    return uri;
  }

  List<Library> _allLibraries(KernelResult result) {
    return result.results
        .map((cycle) => cycle.kernelLibraries)
        .expand((libraries) => libraries)
        .toList();
  }

  void _assertCompiledUris(Iterable<Uri> expected) {
    var compiledCycles = driver.test.compiledCycles;
    Set<Uri> compiledUris = compiledCycles
        .map((cycle) => cycle.libraries.map((file) => file.uri))
        .expand((uris) => uris)
        .toSet();
    expect(compiledUris, unorderedEquals(expected));
  }

  void _assertLibraryUris(KernelResult result,
      {List<Uri> includes: const [], List<Uri> excludes: const []}) {
    List<Uri> libraryUris = result.results
        .map((cycle) => cycle.kernelLibraries.map((lib) => lib.importUri))
        .expand((uris) => uris)
        .toList();
    for (var shouldInclude in includes) {
      expect(libraryUris, contains(shouldInclude));
    }
    for (var shouldExclude in excludes) {
      expect(libraryUris, isNot(contains(shouldExclude)));
    }
  }

  /// Create new [KernelDriver] instance and put it into the [driver] field.
  void _createDriver(
      {Map<String, Uri> packages, KernelDriverFileAddedFn fileAddedFn}) {
    Map<String, Uri> dartLibraries = createSdkFiles(fileSystem);
    var uriTranslator = new UriTranslatorImpl(dartLibraries, {}, packages);
    driver = new KernelDriver(
        new PerformanceLog(null),
        fileSystem,
        new MemoryByteStore(),
        uriTranslator,
        new NoneTarget(new TargetFlags(strongMode: true)),
        fileAddedFn: fileAddedFn);
  }

  Library _getLibrary(KernelResult result, Uri uri) {
    for (var cycleResult in result.results) {
      for (var library in cycleResult.kernelLibraries) {
        if (library.importUri == uri) return library;
      }
    }
    throw fail('No library found with URI "$uri"');
  }

  Library _getLibraryFromProgram(Program program, Uri uri) {
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

  /// Return the [Uri] for the given Posix [path].
  static Uri _folderUri(String path) {
    if (!path.endsWith('/')) path += '/';
    return Uri.parse('file://$path');
  }
}
