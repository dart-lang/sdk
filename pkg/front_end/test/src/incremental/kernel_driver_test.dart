// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/src/api_prototype/byte_store.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:front_end/src/api_prototype/summary_generator.dart';
import 'package:front_end/src/base/performance_logger.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/kernel/utils.dart';
import 'package:front_end/src/fasta/uri_translator_impl.dart';
import 'package:front_end/src/incremental/kernel_driver.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/verifier.dart';
import 'package:package_config/src/packages_impl.dart';
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
  final fileSystem = new MemoryFileSystem(Uri.parse('org-dartlang-test:///'));

  /// The object under test.
  KernelDriver driver;

  void setUp() {
    _createDriver();
  }

  test_getKernel_chain() async {
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
''');

    {
      KernelResult result = await driver.getKernel(cUri);
      _assertKernelResult(result, cUri,
          includes: [aUri, bUri, Uri.parse('dart:core')]);
      expect(_getLibraryText(result.libraryResult.library), r'''
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
    writeFile(bPath, r'''
import 'a.dart';
var b = 1.2;
''');
    driver.invalidate(bUri);
    {
      KernelResult result = await driver.getKernel(cUri);
      _assertKernelResult(result, cUri,
          includes: [aUri, bUri, Uri.parse('dart:core')]);
      expect(_getLibraryText(result.libraryResult.library), r'''
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

  test_getKernel_cycle() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    String cPath = '/test/lib/c.dart';
    Uri aUri = writeFile(aPath, 'var a = 1;');
    Uri bUri = writeFile(bPath, r'''
import 'c.dart';
var b1 = c1;
var b2 = c2;
''');
    Uri cUri = writeFile(cPath, r'''
import 'a.dart';
import 'b.dart';
var c1 = a;
var c2 = b1;
''');

    {
      KernelResult result = await driver.getKernel(cUri);
      // b.dart and c.dart form a cycle.
      // We still get c.dart as the library, and b.dart in dependencies.
      _assertKernelResult(result, cUri,
          includes: [aUri, bUri, Uri.parse('dart:core')]);
      expect(_getLibraryText(result.libraryResult.library), r'''
library;
import self as self;
import "dart:core" as core;
import "./a.dart" as a;
import "./b.dart" as b;

static field core::int c1 = a::a;
static field core::int c2 = b::b1;
''');
    }

    // Update a.dart and recompile c.dart
    writeFile(aPath, r'''
var a = 1.2;
''');
    driver.invalidate(aUri);
    {
      KernelResult result = await driver.getKernel(cUri);
      _assertKernelResult(result, cUri,
          includes: [aUri, bUri, Uri.parse('dart:core')]);
      expect(_getLibraryText(result.libraryResult.library), r'''
library;
import self as self;
import "dart:core" as core;
import "./a.dart" as a;
import "./b.dart" as b;

static field core::double c1 = a::a;
static field core::double c2 = b::b1;
''');
    }
  }

  test_getKernelSequence_chain() async {
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
      KernelSequenceResult result = await driver.getKernelSequence(cUri);
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
      KernelSequenceResult result = await driver.getKernelSequence(cUri);
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

  test_getKernelSequence_export() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    String cPath = '/test/lib/c.dart';
    String dPath = '/test/lib/d.dart';
    writeFile(aPath, 'class A {}');
    Uri bUri = writeFile(bPath, 'export "a.dart";');
    Uri cUri = writeFile(cPath, 'export "b.dart";');
    Uri dUri = writeFile(dPath, r'''
import 'c.dart';
A a;
''');

    KernelSequenceResult result = await driver.getKernelSequence(dUri);
    Library library = _getLibrary(result, dUri);
    expect(_getLibraryText(_getLibrary(result, bUri)), r'''
library;
import self as self;
import "./a.dart" as a;
additionalExports = (a::A)

''');
    expect(_getLibraryText(_getLibrary(result, cUri)), r'''
library;
import self as self;
import "./a.dart" as a;
additionalExports = (a::A)

''');
    expect(_getLibraryText(library), r'''
library;
import self as self;
import "./a.dart" as a;

static field a::A a;
''');
  }

  test_getKernelSequence_export_cycle() async {
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
      KernelSequenceResult result = await driver.getKernelSequence(cUri);
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
      KernelSequenceResult result = await driver.getKernelSequence(cUri);
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

  test_getKernelSequence_export_hideWithLocal() async {
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

    KernelSequenceResult result = await driver.getKernelSequence(cUri);
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

  test_getKernelSequence_recompileMixin() async {
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
      KernelSequenceResult result = await driver.getKernelSequence(aUri);
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
      KernelSequenceResult result = await driver.getKernelSequence(aUri);
      _assertLibraryUris(result,
          includes: [aUri, bUri, cUri, Uri.parse('dart:core')]);
      // Compiled: c.dart (changed), and b.dart (has mixin).
      _assertCompiledUris(includes: [cUri, bUri], excludes: [aUri]);
    }
  }

  test_getKernelSequence_redirectingConstructor() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    writeFile(aPath, r'''
class A {
  factory A() = B;
}

class B implements A {
  B();
}
''');
    Uri bUri = writeFile(bPath, r'''
import 'a.dart';
var a = new A();
''');

    // Initially "new A()" is resolved to "new B()".
    {
      KernelSequenceResult result = await driver.getKernelSequence(bUri);
      Library library = _getLibrary(result, bUri);
      expect(_getLibraryText(library), r'''
library;
import self as self;
import "./a.dart" as a;

static field a::A a = new a::B::•();
''');
    }

    // Update b.dart and recompile.
    // We should not lose information about redirecting constructors.
    // Som "new A()" should still be resolved to "new B()".
    writeFile(bPath, r'''
import 'a.dart';
var a2 = new A();
''');
    driver.invalidate(bUri);
    {
      KernelSequenceResult result = await driver.getKernelSequence(bUri);
      Library library = _getLibrary(result, bUri);
      expect(_getLibraryText(library), r'''
library;
import self as self;
import "./a.dart" as a;

static field a::A a2 = new a::B::•();
''');
    }
  }

  test_getKernelSequence_typedef() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    writeFile(aPath, 'typedef int F<T>(T x);');
    Uri bUri = writeFile(bPath, r'''
import 'a.dart';
F<String> f;
''');

    KernelSequenceResult result = await driver.getKernelSequence(bUri);
    Library library = _getLibrary(result, bUri);
    expect(_getLibraryText(library), r'''
library;
import self as self;
import "dart:core" as core;

static field (core::String) → core::int f;
''');
  }

  test_getKernelSequence_typedef_storeReference() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    String cPath = '/test/lib/c.dart';
    writeFile(aPath, 'typedef int F();');
    writeFile(bPath, r'''
import 'a.dart';
F f;
''');
    Uri cUri = writeFile(cPath, r'''
import 'b.dart';
var fc = f;
''');

    // Compile first time, b.dart should store F typedef reference.
    {
      KernelSequenceResult result = await driver.getKernelSequence(cUri);
      Library library = _getLibrary(result, cUri);
      expect((library.fields[0].type as FunctionType).typedef.name, 'F');
    }

    // Update c.dart and recompile using the serialized b.dart kernel.
    // We should be able to read the F typedef reference.
    {
      writeFile(cPath, r'''
import 'b.dart';
var fc2 = f;
''');
      driver.invalidate(cUri);
      KernelSequenceResult result = await driver.getKernelSequence(cUri);
      Library library = _getLibrary(result, cUri);
      expect((library.fields[0].type as FunctionType).typedef.name, 'F');
    }
  }

  test_getKernelSequence_typeEnvironment() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    Uri aUri = writeFile(aPath, 'class A {}');

    KernelSequenceResult result = await driver.getKernelSequence(aUri);
    expect(result.types.coreTypes.intClass, isNotNull);
    expect(result.types.hierarchy, isNotNull);
  }

  test_getKernelSequence_useSdkOutline() async {
    List<int> sdkOutlineBytes = await _computeSdkOutlineBytes();

    // Configure the driver to use the SDK outline.
    _createDriver(sdkOutlineBytes: sdkOutlineBytes);

    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    Uri aUri = writeFile(aPath, r'''
int getValue() {
  return 1;
}
''');
    Uri bUri = writeFile(bPath, r'''
import 'dart:async';
import 'a.dart';
var a = 1;
Future<String> b;
''');

    KernelSequenceResult result = await driver.getKernelSequence(bUri);

    // SDK libraries were not compiled.
    _assertCompiledUris(
        includes: [bUri],
        excludes: [Uri.parse('dart:core'), Uri.parse('dart:async')]);
    _assertLibraryUris(result, includes: [aUri, bUri]);

    // The types of top-level variables are resolved.
    var library = _getLibrary(result, bUri);
    expect(library.fields[0].type.toString(), 'dart.core::int');
    expect(library.fields[1].type.toString(),
        'dart.async::Future<dart.core::String>');

    {
      // Update a.dart and recompile.
      writeFile(aPath, r'''
int getValue() {
  return 2;
}
''');
      driver.invalidate(aUri);
      var kernelResult = await driver.getKernelSequence(bUri);
      var allLibraries = kernelResult.results
          .map((c) => c.libraryResults.map((result) => result.library))
          .expand((libs) => libs)
          .toList();

      // The result does not include SDK libraries.
      _assertCompiledUris(
          includes: [aUri],
          excludes: [Uri.parse('dart:core'), Uri.parse('dart:async')]);
      _assertLibraryUris(result, includes: [aUri, bUri]);

      // The types of top-level variables are resolved.
      var library = _getLibrary(result, bUri);
      expect(library.fields[0].type.toString(), 'dart.core::int');
      expect(library.fields[1].type.toString(),
          'dart.async::Future<dart.core::String>');

      // We should be able to serialize the libraries without SDK.
      var program =
          new Program(nameRoot: kernelResult.nameRoot, libraries: allLibraries);
      serializeProgram(program,
          filter: (library) => !library.importUri.isScheme('dart'));
    }

    // Ask dart:core, should be served from the outline.
    {
      var dartCoreUri = Uri.parse('dart:core');
      var kernelResult = await driver.getKernelSequence(dartCoreUri);
      bool hasDartCore = false;
      for (var libraryResult in kernelResult.results) {
        for (var libResult in libraryResult.libraryResults) {
          if (libResult.library.importUri == dartCoreUri) {
            hasDartCore = true;
            break;
          }
        }
      }
      expect(hasDartCore, isTrue);
    }
  }

  test_limitedStore_exportDependencies() async {
    writeFile('/test/.packages', 'test:lib/');
    String aPath = '/test/lib/a.dart';
    String bPath = '/test/lib/b.dart';
    String cPath = '/test/lib/c.dart';
    Uri aUri = writeFile(aPath, 'class A {}');
    var bUri = writeFile(bPath, 'export "a.dart";');
    Uri cUri = writeFile(cPath, r'''
import 'b.dart';
A a;
''');

    // Compile all libraries initially.
    await driver.getKernelSequence(cUri);

    // Update c.dart and compile.
    // When we load "b", we should correctly read its exports.
    writeFile(cPath, r'''
import 'b.dart';
A a2;
''');
    driver.invalidate(cUri);
    {
      KernelSequenceResult result = await driver.getKernelSequence(cUri);
      Library library = _getLibrary(result, cUri);

      Library getDepLib(Library lib, int index) {
        return lib.dependencies[index].importedLibraryReference.asLibrary;
      }

      var b = getDepLib(library, 0);
      var a = getDepLib(b, 0);
      expect(b.importUri, bUri);
      expect(a.importUri, aUri);
    }
  }

  test_limitedStore_memberReferences() async {
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

    KernelSequenceResult result = await driver.getKernelSequence(bUri);

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
      KernelSequenceResult result = await driver.getKernelSequence(aFileUri);
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
      KernelSequenceResult result = await driver.getKernelSequence(aFileUri);
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
    KernelSequenceResult result = await driver.getKernelSequence(libUri);
    Library library = _getLibrary(result, libUri);
    expect(_getLibraryText(library), r'''
library foo;
import self as self;
import "dart:core" as core;

static field core::int a = 1;
static field core::int c = self::b;
static field core::int b = 2 /* from org-dartlang-test:///test/lib/bar.dart */;
static field core::int d = self::a /* from org-dartlang-test:///test/lib/bar.dart */;
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
      KernelSequenceResult result = await driver.getKernelSequence(libUri);
      Library library = _getLibrary(result, libUri);
      expect(_getLibraryText(library), r'''
library foo;
import self as self;
import "dart:core" as core;

static field core::int a = 1;
static field core::double c = self::b;
static field core::double b = 2.3 /* from org-dartlang-test:///test/lib/bar.dart */;
static field core::int d = self::a /* from org-dartlang-test:///test/lib/bar.dart */;
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
      KernelSequenceResult result = await driver.getKernelSequence(libUri);
      Library library = _getLibrary(result, libUri);
      expect(_getLibraryText(library), r'''
library foo;
import self as self;
import "dart:core" as core;

static field core::String a = "aaa";
static field core::double c = self::b;
static field core::double b = 2.3 /* from org-dartlang-test:///test/lib/bar.dart */;
static field core::String d = self::a /* from org-dartlang-test:///test/lib/bar.dart */;
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
      await driver.getKernelSequence(cUri);
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
      await driver.getKernelSequence(cUri);
      // The only new file is b.dart now.
      expect(usedFiles, [bUri]);
      usedFiles.clear();
    }
  }

  /// Write the given [text] of the file with the given [path] into the
  /// virtual filesystem.  Return the URI of the file.
  Uri writeFile(String path, String text) {
    Uri uri = Uri.parse('org-dartlang-test://$path');
    fileSystem.entityForUri(uri).writeAsStringSync(text);
    return uri;
  }

  List<Library> _allLibraries(KernelSequenceResult result) {
    return result.results
        .map((cycle) => cycle.libraryResults.map((result) => result.library))
        .expand((libraries) => libraries)
        .toList();
  }

  void _assertCompiledUris(
      {Iterable<Uri> includes: const [], Iterable<Uri> excludes: const []}) {
    var compiledCycles = driver.test.compiledCycles;
    Set<Uri> compiledUris = compiledCycles
        .map((cycle) => cycle.libraries.map((file) => file.uri))
        .expand((uris) => uris)
        .toSet();
    for (var shouldInclude in includes) {
      expect(compiledUris, contains(shouldInclude));
    }
    for (var shouldExclude in excludes) {
      expect(compiledUris, isNot(contains(shouldExclude)));
    }
  }

  void _assertKernelResult(KernelResult result, Uri libraryUri,
      {List<Uri> includes: const [], List<Uri> excludes: const []}) {
    expect(result.libraryResult?.library, isNotNull);
    expect(result.libraryResult.library.importUri, libraryUri);

    List<Uri> dependencyUris = [];
    for (var library in result.dependencies) {
      dependencyUris.add(library.importUri);
    }
    for (var shouldInclude in includes) {
      expect(dependencyUris, contains(shouldInclude));
    }
    for (var shouldExclude in excludes) {
      expect(dependencyUris, isNot(contains(shouldExclude)));
    }
  }

  void _assertLibraryUris(KernelSequenceResult result,
      {List<Uri> includes: const [], List<Uri> excludes: const []}) {
    Map<Uri, Source> uriToSource = {};
    List<Uri> libraryUris = [];
    for (LibraryCycleResult cycleResult in result.results) {
      uriToSource.addAll(cycleResult.uriToSource);
      for (var result in cycleResult.libraryResults) {
        libraryUris.add(result.library.importUri);
      }
    }
    for (var shouldInclude in includes) {
      expect(libraryUris, contains(shouldInclude));
      var shouldIncludeFileUri = _resolveUriToFileUri(shouldInclude);
      expect(uriToSource.keys, contains(shouldIncludeFileUri));
    }
    for (var shouldExclude in excludes) {
      expect(libraryUris, isNot(contains(shouldExclude)));
      var shouldExcludeFileUri = _resolveUriToFileUri(shouldExclude);
      expect(uriToSource.keys, isNot(contains(shouldExcludeFileUri)));
    }
  }

  Future<List<int>> _computeSdkOutlineBytes() async {
    var options = new CompilerOptions()
      ..fileSystem = fileSystem
      ..sdkRoot = Uri.parse('org-dartlang-test:///sdk/')
      ..compileSdk = true
      ..chaseDependencies = true
      ..strongMode = true
      ..target = new NoneTarget(new TargetFlags(strongMode: true));
    var inputs = [Uri.parse('dart:core')];
    return summaryFor(inputs, options);
  }

  /// Create new [KernelDriver] instance and put it into the [driver] field.
  void _createDriver(
      {List<int> sdkOutlineBytes,
      Map<String, Uri> packages,
      KernelDriverFileAddedFn fileAddedFn}) {
    var uriTranslator = new UriTranslatorImpl(
        createSdkFiles(fileSystem), new MapPackages(packages));

    var options = new CompilerOptions()
      ..logger = new PerformanceLog(null)
      ..fileSystem = fileSystem
      ..byteStore = new MemoryByteStore()
      ..strongMode = true
      ..target = new NoneTarget(new TargetFlags(strongMode: true));

    driver = new KernelDriver(
        new ProcessedOptions(options), uriTranslator, new KernelErrorListener(),
        sdkOutlineBytes: sdkOutlineBytes, fileAddedFn: fileAddedFn);
  }

  Library _getLibrary(KernelSequenceResult result, Uri uri) {
    for (var cycleResult in result.results) {
      for (var result in cycleResult.libraryResults) {
        if (result.library.importUri == uri) return result.library;
      }
    }
    fail('No library found with URI "$uri"');
  }

  Library _getLibraryFromProgram(Program program, Uri uri) {
    for (var library in program.libraries) {
      if (library.importUri == uri) return library;
    }
    fail('No library found with URI "$uri"');
  }

  String _getLibraryText(Library library) {
    StringBuffer buffer = new StringBuffer();
    new Printer(buffer, syntheticNames: new NameSystem())
        .writeLibraryFile(library);
    return buffer.toString();
  }

  /// Resolve the given `dart` or `package` [inputUri] into the corresponding
  /// file URI, or return the same URI if it is already a file URI.
  Uri _resolveUriToFileUri(Uri inputUri) {
    var translator = driver.uriTranslator;
    var outputUri = translator.translate(inputUri) ?? inputUri;
    return outputUri;
  }

  /// Return the [Uri] for the given Posix [path].
  static Uri _folderUri(String path) {
    if (!path.endsWith('/')) path += '/';
    return Uri.parse('org-dartlang-test://$path');
  }
}
