// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names

import 'dart:core';

import 'package:analyzer_utilities/src/api_summary/src/api_description.dart';
import 'package:analyzer_utilities/src/api_summary/src/node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utilities.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ApiDescriptionTest);
  });
}

@reflectiveTest
class ApiDescriptionTest extends ApiSummaryTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  void setUp() {
    newPackage('foo').addFile('lib/foo.dart', r'''
foo() {}
class Foo {}
''');
    super.setUp();
  }

  Future<void> test_field_deprecated() async {
    // Marking a field as deprecated causes its corresponding getter and setter
    // to be marked as deprecated in the summary.
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
class C {
  @deprecated
  int x = 0;
}
''',
    });
    expect(summary, '''
package:test/file.dart:
  C (class extends Object):
    new (constructor: C Function())
    x (getter: int, deprecated)
    x= (setter: int, deprecated)
dart:core:
  Object (referenced)
  int (referenced)
''');
  }

  Future<void> test_field_experimental() async {
    // Marking a field as experimental causes its corresponding getter and setter
    // to be marked as experimental in the summary.
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
import 'package:meta/meta.dart';

class C {
  @experimental
  int x = 0;
}
''',
    });
    expect(summary, '''
package:test/file.dart:
  C (class extends Object):
    new (constructor: C Function())
    x (getter: int, experimental)
    x= (setter: int, experimental)
dart:core:
  Object (referenced)
  int (referenced)
''');
  }

  Future<void> test_member_field() async {
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
class C {
  int x = 0;
}
''',
    });
    // The summary output contains the getters and setters induced by the field,
    // not the field itself.
    expect(summary, '''
package:test/file.dart:
  C (class extends Object):
    new (constructor: C Function())
    x (getter: int)
    x= (setter: int)
dart:core:
  Object (referenced)
  int (referenced)
''');
  }

  Future<void> test_member_getterSetterPair() async {
    // This test verifies that even if a getter and a setter have the same name,
    // both are included in the summary output.
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
class C {
  get x => 0;
  set x(value) {}
}
''',
    });
    expect(summary, '''
package:test/file.dart:
  C (class extends Object):
    new (constructor: C Function())
    x (getter: dynamic)
    x= (setter: dynamic)
dart:core:
  Object (referenced)
''');
  }

  Future<void> test_member_method() async {
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
class C {
  void f() {}
}
''',
    });
    expect(summary, '''
package:test/file.dart:
  C (class extends Object):
    new (constructor: C Function())
    f (method: void Function())
dart:core:
  Object (referenced)
''');
  }

  Future<void> test_member_privateName() async {
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
class C {
  f() {
    _f();
  }
  _f() {}
}
''',
    });
    // The private member _f is not included in the summary output.
    expect(summary, '''
package:test/file.dart:
  C (class extends Object):
    new (constructor: C Function())
    f (method: dynamic Function())
dart:core:
  Object (referenced)
''');
  }

  Future<void> test_minimallyDescribesReferencedNamesInOtherPackages() async {
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
import 'package:foo/foo.dart';

void f(Foo foo) {}
''',
    });
    expect(summary, '''
package:test/file.dart:
  f (function: void Function(Foo))
package:foo/foo.dart:
  Foo (referenced)
''');
  }

  Future<void> test_minimallyDescribesReferencedNonPublicNames() async {
    var summary = await _build({
      '$testPackageLibPath/public.dart': '''
import 'src/private.dart';

void f(Foo foo) {}
''',
      '$testPackageLibPath/src/private.dart': 'class Foo {}',
    });
    expect(summary, '''
package:test/public.dart:
  f (function: void Function(Foo))
package:test/src/private.dart:
  Foo (non-public)
''');
  }

  Future<void> test_nonConstructibleClass() async {
    // TODO(paulberry): annotate abstract, final, and interface properties of
    // classes
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
abstract final class C1 {}
abstract interface class C2 {}
sealed class C3 {}
''',
    });
    // These classes can't be constructed from outside the library, so their
    // constructors aren't included in the summary output.
    expect(summary, '''
package:test/file.dart:
  C1 (class extends Object)
  C2 (class extends Object)
  C3 (class extends Object, sealed)
dart:core:
  Object (referenced)
''');
  }

  Future<void> test_sealedClass() async {
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
sealed class C {}
// Note: immediate subinterfaces will be sorted in summary output
class C2 extends C {}
class C1 extends C {}
''',
    });
    expect(summary, '''
package:test/file.dart:
  C (class extends Object, sealed (immediate subtypes: C1, C2))
  C1 (class extends C):
    new (constructor: C1 Function())
  C2 (class extends C):
    new (constructor: C2 Function())
dart:core:
  Object (referenced)
''');
  }

  Future<void> test_sealedClass_allKindsAndRelationships() async {
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
sealed class S {}
class C1 extends S {}
class C2 implements S {}
mixin M1 on S {}
mixin M2 implements S {}
enum E1 implements S { v }
extension type T(C1 c) implements S {}
''',
    });
    expect(summary, '''
package:test/file.dart:
  C1 (class extends S):
    new (constructor: C1 Function())
  C2 (class extends Object implements S):
    new (constructor: C2 Function())
  E1 (enum implements S):
    v (static getter: E1)
    values (static getter: List<E1>)
  M1 (mixin on S)
  M2 (mixin on Object implements S)
  S (class extends Object, sealed (immediate subtypes: C1, C2, E1, M1, M2, T))
  T (extension type implements S):
    new (constructor: T Function(C1))
    c (getter: C1)
dart:core:
  List (referenced)
  Object (referenced)
''');
  }

  Future<void> test_topLevel_collapsesRedundantElements() async {
    // When an element is exported by multiple libraries, it is only described
    // once; later references use the text "(see above)".
    var summary = await _build({
      '$testPackageLibPath/file1.dart': 'export "file2.dart";',
      '$testPackageLibPath/file2.dart': 'class C {}',
      '$testPackageLibPath/file3.dart': 'export "file2.dart";',
    });
    expect(summary, '''
package:test/file1.dart:
  C (class extends Object):
    new (constructor: C Function())
package:test/file2.dart:
  C (see above)
package:test/file3.dart:
  C (see above)
dart:core:
  Object (referenced)
''');
  }

  Future<void> test_topLevel_disambiguatesNames() async {
    // If two libraries declare top level elements with the same name, the names
    // are disambiguated so that references are clear.
    var summary = await _build({
      '$testPackageLibPath/file1.dart': '''
class A {}
class B extends A {}
''',
      '$testPackageLibPath/file2.dart': '''
class A {}
class B extends A {}
''',
    });
    expect(summary, '''
package:test/file1.dart:
  A@1 (class extends Object):
    new (constructor: A@1 Function())
  B@1 (class extends A@1):
    new (constructor: B@1 Function())
package:test/file2.dart:
  A@2 (class extends Object):
    new (constructor: A@2 Function())
  B@2 (class extends A@2):
    new (constructor: B@2 Function())
dart:core:
  Object (referenced)
''');
  }

  Future<void> test_topLevel_extension() async {
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
extension E on int {
  void f() {}
}
''',
    });
    expect(summary, '''
package:test/file.dart:
  E (extension on int):
    f (method: void Function())
dart:core:
  int (referenced)
''');
  }

  Future<void> test_topLevel_filesInSrc() async {
    var summary = await _build({'$testPackageLibPath/src/file.dart': 'f() {}'});
    expect(summary, '');
  }

  Future<void> test_topLevel_getterSetterPair() async {
    // This test verifies that even if getter and a setter have the same name,
    // both are included in the summary output.
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
get x => 0;
set x(value) {}
''',
    });
    expect(summary, '''
package:test/file.dart:
  x (static getter: dynamic)
  x= (static setter: dynamic)
''');
  }

  Future<void> test_topLevel_interfaceType() async {
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
class I {}
class B {}
class C<T> extends B implements I {}
enum E implements I { e1 }
mixin M on B implements I {}
extension type T(int i) {}
''',
    });
    expect(summary, '''
package:test/file.dart:
  B (class extends Object):
    new (constructor: B Function())
  C (class<T> extends B implements I):
    new (constructor: C<T> Function())
  E (enum implements I):
    e1 (static getter: E)
    values (static getter: List<E>)
  I (class extends Object):
    new (constructor: I Function())
  M (mixin on B implements I)
  T (extension type):
    new (constructor: T Function(int))
    i (getter: int)
dart:core:
  List (referenced)
  Object (referenced)
  int (referenced)
''');
  }

  Future<void> test_topLevel_nonDartFile() async {
    var summary = await _build({'$testPackageLibPath/file.dar': 'f() {}'});
    expect(summary, '');
  }

  Future<void> test_topLevel_otherPackagePublicApi() async {
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
import 'package:foo/foo.dart';

main() {
  foo();
}
''',
    });
    expect(summary, '''
package:test/file.dart:
  main (function: dynamic Function())
''');
  }

  Future<void> test_topLevel_partFile() async {
    // Declarations in a part file are considered part of the public API of the
    // containing library.
    var summary = await _build({
      '$testPackageLibPath/lib.dart': 'part "part.dart";',
      '$testPackageLibPath/part.dart': '''
part of "lib.dart";

f() {}
''',
    });
    expect(summary, '''
package:test/lib.dart:
  f (function: dynamic Function())
''');
  }

  Future<void> test_topLevel_privateName() async {
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
f() {
  _g();
}

_g() {}
''',
    });
    // The private member _g is not included in the summary output.
    expect(summary, '''
package:test/file.dart:
  f (function: dynamic Function())
''');
  }

  Future<void> test_topLevel_sorted() async {
    // This test just verifies that sorting occurs. See `member_test.dart` for
    // tests of the precise nature of the sort order.
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
g() {}
f() {}
get x => 0;
class C {}
''',
    });
    expect(summary, '''
package:test/file.dart:
  x (static getter: dynamic)
  f (function: dynamic Function())
  g (function: dynamic Function())
  C (class extends Object):
    new (constructor: C Function())
dart:core:
  Object (referenced)
''');
  }

  Future<void> test_topLevel_sortsLibrariesByUri() async {
    var summary = await _build({
      '$testPackageLibPath/file2.dart': '',
      '$testPackageLibPath/file1.dart': '',
      '$testPackageLibPath/file3.dart': '',
    });
    expect(summary, '''
package:test/file1.dart:
package:test/file2.dart:
package:test/file3.dart:
''');
  }

  Future<void> test_topLevel_typedef() async {
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
typedef void oldStyleFunctionTypedef();
typedef void oldStyleFunctionTypedefGeneric<T>(T t);
typedef newStyleFunctionTypedef = void Function();
typedef newStyleFunctionTypedefGeneric = void Function<T>(T);
typedef nonFunctionTypedef = int;
''',
    });
    expect(summary, '''
package:test/file.dart:
  newStyleFunctionTypedef (type alias for void Function())
  newStyleFunctionTypedefGeneric (type alias for void Function<T>(T))
  nonFunctionTypedef (type alias for int)
  oldStyleFunctionTypedef (type alias for void Function())
  oldStyleFunctionTypedefGeneric (type alias<T> for void Function(T))
dart:core:
  int (referenced)
''');
  }

  Future<void> test_types() async {
    var summary = await _build({
      '$testPackageLibPath/file.dart': '''
import 'dart:async';

// Dynamic type
dynamic get d => 0;

// Null type
Null get n => null;

// FutureOr type
FutureOr<int>? get fo => null;

// Function types
void Function(int requiredPositionalParam, [int? optionalPositionalParam])
    get f1 => throw '';
void Function({
    // Note: named params will be sorted by name
    required int requiredNamedParam, int? optionalNamedParam})? get f2 => null;
void f3(@deprecated int i, [@deprecated int? j]) {}
void f4({@deprecated int? i}) {}
void f5<T>(T t1, T? t2) {} // Also tests type parameter types
void f6<T extends num>(T t) {}

// Interface types
void f7(Map<String, int> m1, Map<String, int>? m2) {}

// Record types
void f8((int, String) r1, (int, {String s})? r2,
    // Note: named record fields will be sorted by name
    ({String s, int i}) r3) {}
''',
    });
    expect(summary, '''
package:test/file.dart:
  d (static getter: dynamic)
  f1 (static getter: void Function(int, [int?]))
  f2 (static getter: void Function({int? optionalNamedParam, required int requiredNamedParam})?)
  fo (static getter: FutureOr<int>?)
  n (static getter: Null)
  f3 (function: void Function(deprecated int, [deprecated int?]))
  f4 (function: void Function({deprecated int? i}))
  f5 (function: void Function<T>(T, T?))
  f6 (function: void Function<T extends num>(T))
  f7 (function: void Function(Map<String, int>, Map<String, int>?))
  f8 (function: void Function((int, String), (int, {String s})?, ({int i, String s})))
dart:async:
  FutureOr (referenced)
dart:core:
  Map (referenced)
  Null (referenced)
  String (referenced)
  int (referenced)
  num (referenced)
''');
  }

  Future<String> _build(Map<String, String> files) async {
    // Create all the files.
    files.forEach(newFile);

    // As a sanity check, make sure there are no errors in any of the files.
    for (var file in files.keys) {
      if (file.endsWith('.dart')) await assertNoDiagnosticsInFile(file);
    }

    // Generate the API description.
    var context = contextCollection.contextFor(convertPath(testPackageLibPath));
    var apiDescription = ApiDescription('test');
    var stringBuffer = StringBuffer();
    printNodes(stringBuffer, await apiDescription.build(context));
    return stringBuffer.toString();
  }
}
