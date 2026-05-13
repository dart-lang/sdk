// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedMemberUse_BlazeWorkspaceTest);
    defineReflectiveTests(DeprecatedMemberUse_GnWorkspaceTest);
    defineReflectiveTests(DeprecatedMemberUse_PackageBuildWorkspaceTest);
    defineReflectiveTests(DeprecatedMemberUse_PackageConfigWorkspaceTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DeprecatedMemberUse_BlazeWorkspaceTest
    extends BlazeWorkspaceResolutionTest {
  test_dart() async {
    newFile('$workspaceRootPath/foo/bar/lib/a.dart', r'''
@deprecated
class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:foo.bar/a.dart';

void f(A a) {}
//     ^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
''');
  }

  test_thirdPartyDart() async {
    newFile('$workspaceThirdPartyDartPath/aaa/lib/a.dart', r'''
@deprecated
class A {}
''');

    assertBlazeWorkspaceFor(testFile);

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f(A a) {}
//     ^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
''');
  }
}

@reflectiveTest
class DeprecatedMemberUse_GnWorkspaceTest extends ContextResolutionTest {
  @override
  List<String> get collectionIncludedPaths => [workspaceRootPath];

  String get genPath => '$outPath/dartlang/gen';

  String get myPackageLibPath => '$myPackageRootPath/lib';

  String get myPackageRootPath => '$workspaceRootPath/my';

  Folder get outFolder => getFolder(outPath);

  String get outPath => '$workspaceRootPath/out/default';

  @override
  File get testFile => getFile('$myPackageLibPath/my.dart');

  String get workspaceRootPath => '/workspace';

  @override
  void setUp() {
    super.setUp();
    newFolder('$workspaceRootPath/.jiri_root');

    newFile('$workspaceRootPath/.fx-build-dir', '''
${outFolder.path}
''');

    newBuildGnFile(myPackageRootPath, '');
  }

  test_differentPackage() async {
    newBuildGnFile('$workspaceRootPath/aaa', '');

    var myPackageConfig = getFile('$genPath/my/my_package_config.json');
    _writeWorkspacePackagesFile(myPackageConfig, {
      'aaa': '$workspaceRootPath/aaa/lib',
      'my': myPackageLibPath,
    });

    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f(A a) {}
//     ^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
''');
  }

  @override
  void verifyCreatedCollection() {
    super.verifyCreatedCollection();
    assertGnWorkspaceFor(testFile);
  }

  void _writeWorkspacePackagesFile(
    File file,
    Map<String, String> nameToLibPath,
  ) {
    var packages = nameToLibPath.entries.map(
      (entry) =>
          '''{
    "languageVersion": "2.2",
    "name": "${entry.key}",
    "packageUri": ".",
    "rootUri": "${toUriStr(entry.value)}"
  }''',
    );

    newFile(file.path, '''{
  "configVersion": 2,
  "packages": [ ${packages.join(', ')} ]
}''');
  }
}

@reflectiveTest
class DeprecatedMemberUse_PackageBuildWorkspaceTest
    extends _PackageConfigWorkspaceBase {
  test_generated() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootFolder: getFolder('$workspaceRootPath/aaa')),
    );

    newPubspecYamlFile(testPackageRootPath, 'name: test');
    _newTestPackageGeneratedFile(
      packageName: 'aaa',
      pathInLib: 'a.dart',
      content: r'''
@deprecated
class A {}
''',
    );

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f(A a) {}
//     ^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
''');
  }

  test_lib() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootFolder: getFolder('$workspaceRootPath/aaa')),
    );

    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
class A {}
''');

    newPubspecYamlFile(testPackageRootPath, 'name: test');
    _createTestPackageBuildMarker();

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f(A a) {}
//     ^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
''');
  }
}

@reflectiveTest
class DeprecatedMemberUse_PackageConfigWorkspaceTest
    extends PubPackageResolutionTest {
  String get externalLibPath => '$workspaceRootPath/aaa/lib/a.dart';

  String get externalLibUri => 'package:aaa/a.dart';

  Future<void> assertErrorsInCode2(
    List<ExpectedDiagnostic> expectedDiagnostics, {
    required String externalCode,
    required String code,
  }) async {
    newFile(externalLibPath, externalCode);

    await assertErrorsInCode('''
import '$externalLibUri';
$code
''', expectedDiagnostics);
  }

  Future<void> assertNoErrorsInCode2({
    required String externalCode,
    required String code,
  }) async {
    newFile(externalLibPath, externalCode);

    await assertNoErrorsInCode('''
import '$externalLibUri';
$code
''');
  }

  Future<void> resolveTestCodeWithDiagnostics2({
    required String externalCode,
    required String code,
  }) async {
    newFile(externalLibPath, externalCode);

    await resolveTestCodeWithDiagnostics('''
import '$externalLibUri';
$code
''');
  }

  @override
  void setUp() {
    super.setUp();

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootFolder: getFolder('$workspaceRootPath/aaa')),
    );
  }

  test_assignmentExpression_compound_deprecatedGetter() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int get x => 0;

set x(int _) {}
''',
      code: r'''
void f() {
  x += 2;
//^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_assignmentExpression_compound_deprecatedSetter() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
int get x => 0;

@deprecated
set x(int _) {}
''',
      code: r'''
void f() {
  x += 2;
//^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_assignmentExpression_simple_deprecatedGetter() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int get x => 0;

set x(int _) {}
''',
      code: r'''
void f() {
  x = 0;
}
''',
    );
  }

  test_assignmentExpression_simple_deprecatedGetterSetter() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  x = 0;
//^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_assignmentExpression_simple_deprecatedSetter() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
int get x => 0;

@deprecated
set x(int _) {}
''',
      code: r'''
void f() {
  x = 0;
//^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_call() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {
  @deprecated
  call() {}
}
''',
      code: r'''
void f(A a) {
  a();
//^^^
// [diag.deprecatedMemberUse] 'call' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_class() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
class A {}
''',
      code: r'''
void f(A a) {}
//     ^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
''',
    );
  }

  test_class_inDeprecatedFunctionTypeAlias() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

@deprecated
typedef A T();
''');
  }

  test_class_inDeprecatedGenericTypeAlias() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
class A {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

@deprecated
typedef T = A Function();
''');
  }

  test_compoundAssignment() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {
  @deprecated
  A operator+(A a) { return a; }
}
''',
      code: r'''
f(A a, A b) {
  a += b;
//^^^^^^
// [diag.deprecatedMemberUse] '+' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_constructor_inAnnotation() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class MyAnnotation {
  @deprecated
  const MyAnnotation();
}
''',
      code: r'''
@MyAnnotation()
// [diag.deprecatedMemberUse][column 2][length 12] 'MyAnnotation' is deprecated and shouldn't be used.
void g() {}
''',
    );
  }

  test_deprecatedField_inObjectPattern_explicitName() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class C {
  @Deprecated('')
  final int foo = 0;
}
''',
      code: '''
int g(Object s) =>
  switch (s) {
    C(foo: var f) => f,
//    ^^^
// [diag.deprecatedMemberUse] 'foo' is deprecated and shouldn't be used.
    _ => 7,
  };
''',
    );
  }

  test_deprecatedField_inObjectPattern_inferredName() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class C {
  @Deprecated('')
  final int foo = 0;
}
''',
      code: '''
int g(Object s) =>
  switch (s) {
    C(:var foo) => foo,
//         ^^^
// [diag.deprecatedMemberUse] 'foo' is deprecated and shouldn't be used.
    _ => 7,
  };
''',
    );
  }

  test_dotShorthandConstructorInvocation_deprecatedClass_deprecatedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
class A {
  @deprecated
  A();
}
void wantA(A _) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  wantA(.new());
//      ^^^^^^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
//       ^^^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
}
''');
  }

  test_dotShorthandConstructorInvocation_deprecatedClass_undeprecatedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
class A {
  A();
}
void wantA(A _) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  wantA(.new());
//      ^^^^^^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
}
''');
  }

  test_dotShorthandConstructorInvocation_deprecatedClass_undeprecatedNamedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
class A {
  A.a();
}
void wantA(A _) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  wantA(.a());
//      ^^^^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
}
''');
  }

  test_dotShorthandConstructorInvocation_namedConstructor() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {
  @deprecated
  A.named(int i) {}
}
void wantA(A _) {}
''',
      code: r'''
f() {
  wantA(.named(1));
//       ^^^^^
// [diag.deprecatedMemberUse] 'A.named' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_dotShorthandConstructorInvocation_undeprecatedClass_deprecatedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @deprecated
  A();
}
void wantA(A _) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  wantA(.new());
//       ^^^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
}
''');
  }

  test_dotShorthandInvocation_deprecatedMethod() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @deprecated
  static A m() => A();
}
void wantA(A _) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  wantA(.m());
//       ^
// [diag.deprecatedMemberUse] 'm' is deprecated and shouldn't be used.
}
''');
  }

  test_dotShorthandPropertyAccess() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @deprecated
  static A get x => A();
}
void wantA(A _) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  wantA(.x);
//       ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''');
  }

  test_export() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
library a;
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'package:aaa/a.dart';
// [diag.deprecatedMemberUse][column 1][length 28] 'package:aaa/a.dart' is deprecated and shouldn't be used.
''');
  }

  test_export_fromSamePackage() async {
    newFile('$testPackageLibPath/lib2.dart', r'''
@deprecated
library a;
''');

    await resolveTestCodeWithDiagnostics(r'''
export 'lib2.dart';
''');
  }

  test_extensionOverride() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
extension E on int {
  int get foo => 0;
}
''',
      code: '''
void f() {
  E(0).foo;
//^
// [diag.deprecatedMemberUse] 'E' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_field_implicitGetter() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @deprecated
  int foo = 0;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo;
//  ^^^
// [diag.deprecatedMemberUse] 'foo' is deprecated and shouldn't be used.
}
''');
  }

  test_field_implicitSetter() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @deprecated
  int foo = 0;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo = 0;
//  ^^^
// [diag.deprecatedMemberUse] 'foo' is deprecated and shouldn't be used.
}
''');
  }

  test_field_inDeprecatedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @deprecated
  int x = 0;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

class B extends A {
  @deprecated
  B() {
    x;
    x = 1;
  }
}
''');
  }

  test_hideCombinator() async {
    newFile(externalLibPath, r'''
@deprecated
class A {}
''');
    await resolveTestCodeWithDiagnostics(r'''
// ignore: unused_import
import 'package:aaa/a.dart' hide A;
''');
  }

  test_import() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
library a;
''');

    await resolveTestCodeWithDiagnostics(r'''
// ignore:unused_import
import 'package:aaa/a.dart';
// [diag.deprecatedMemberUse][column 1][length 28] 'package:aaa/a.dart' is deprecated and shouldn't be used.
''');
  }

  test_incorrectlyNestedNamedParameterDeclaration() async {
    // This is a regression test; previously this code would cause an analyzer
    // crash in DeprecatedMemberUseVerifier.
    await resolveTestCodeWithDiagnostics(r'''
class C {
  final String x;
  final bool y;

  const C({
//      ^
// [diag.finalNotInitializedConstructor1] All final variables must be initialized, but 'y' isn't.
    required this.x,
    {this.y = false}
//  ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find '}'.
  });
}

const z = C(x: '');
''');
  }

  test_inDeprecatedClass() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
f() {}
''',
      code: r'''
@deprecated
class C {
  m() {
    f();
  }
}
''',
    );
  }

  test_inDeprecatedDefaultFormalParameter() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
@deprecated
class C {
  const C();
}
''',
      code: r'''
f({@deprecated C? c = const C()}) {}
''',
    );
  }

  test_inDeprecatedEnum() async {
    await assertNoErrorsInCode2(
      externalCode: r'''
@deprecated
void f() {}
''',
      code: r'''
@deprecated
enum E {
  one, two;

  void m() {
    f();
  }
}
''',
    );
  }

  test_inDeprecatedExtension() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
void f() {}
''',
      code: r'''
@deprecated
extension E on int {
  void m() {
    f();
  }
}
''',
    );
  }

  test_inDeprecatedExtensionType() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
f() {}
''',
      code: '''
@deprecated
extension type E(int i) {
  m() {
    f();
  }
}
''',
    );
  }

  test_inDeprecatedField() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
class C {}
''',
      code: r'''
class X {
  @deprecated
  C f;
  X(this.f);
}
''',
    );
  }

  test_inDeprecatedFieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
class C {}
''',
      code: r'''
class A {
  Object? o;
  A({@deprecated C? this.o});
}
''',
    );
  }

  test_inDeprecatedFunction() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
f() {}
''',
      code: '''
@deprecated
g() {
  f();
}
''',
    );
  }

  test_inDeprecatedFunctionTypedFormalParameter() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
class C {}
''',
      code: r'''
f({@deprecated C? callback()?}) {}
''',
    );
  }

  test_inDeprecatedLibrary() async {
    newFile(externalLibPath, r'''
@deprecated
f() {}
''');
    await resolveTestCodeWithDiagnostics(r'''
@deprecated
library lib;
import 'package:aaa/a.dart';

class C {
  m() {
    f();
  }
}
''');
  }

  test_inDeprecatedMethod() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
f() {}
''',
      code: '''
class C {
  @deprecated
  m() {
    f();
  }
}
''',
    );
  }

  test_inDeprecatedMethod_inDeprecatedClass() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
f() {}
''',
      code: '''
@deprecated
class C {
  @deprecated
  m() {
    f();
  }
}
''',
    );
  }

  test_inDeprecatedMixin() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
f() {}
''',
      code: '''
@deprecated
mixin M {
  m() {
    f();
  }
}
''',
    );
  }

  test_inDeprecatedSimpleFormalParameter() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
class C {}
''',
      code: r'''
f({@deprecated C? c}) {}
''',
    );
  }

  test_inDeprecatedSuperFormalParameter() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
class C {}
''',
      code: r'''
class A {
  A({Object? o});
}
class B extends A {
  B({@deprecated C? super.o});
}
''',
    );
  }

  test_inDeprecatedTopLevelVariable() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
class C {}
var x = C();
''',
      code: r'''
@deprecated
C v = x;
''',
    );
  }

  test_indexExpression() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {
  @deprecated
  operator[](int i) {}
}
''',
      code: r'''
void f(A a) {
  return a[1];
//       ^^^^
// [diag.deprecatedMemberUse] '[]' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_inEnum() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
void f() {}
''',
      code: r'''
enum E {
  one, two;

  void m() {
    f();
//  ^
// [diag.deprecatedMemberUse] 'f' is deprecated and shouldn't be used.
  }
}
''',
    );
  }

  test_inExtension() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
void f() {}
''',
      code: r'''
extension E on int {
  void m() {
    f();
//  ^
// [diag.deprecatedMemberUse] 'f' is deprecated and shouldn't be used.
  }
}
''',
    );
  }

  test_instanceCreation_deprecatedClass_deprecatedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
class A {
  @deprecated
  A();
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  A();
//^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
}
''');
  }

  test_instanceCreation_deprecatedClass_undeprecatedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
class A {
  A();
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  A();
//^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
}
''');
  }

  test_instanceCreation_deprecatedClass_undeprecatedNamedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
class A {
  A.a();
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  A.a();
//^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
}
''');
  }

  test_instanceCreation_namedConstructor() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {
  @deprecated
  A.named(int i) {}
}
''',
      code: r'''
f() {
  return new A.named(1);
//           ^^^^^^^
// [diag.deprecatedMemberUse] 'A.named' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_instanceCreation_undeprecatedClass_deprecatedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @deprecated
  A();
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  A();
//^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
}
''');
  }

  test_instanceCreation_undeprecatedClass_deprecatedConstructor_primary() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A() {
  @deprecated
  this;
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  A();
//^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
}
''');
  }

  test_instanceCreation_unnamedConstructor() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {
  @deprecated
  A(int i) {}
}
''',
      code: r'''
f() {
  return new A(1);
//           ^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_methodInvocation() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @deprecated
  void foo() {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo();
//  ^^^
// [diag.deprecatedMemberUse] 'foo' is deprecated and shouldn't be used.
}
''');
  }

  test_methodInvocation_constantAnnotation() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int f() => 0;
''',
      code: r'''
var x = f();
//      ^
// [diag.deprecatedMemberUse] 'f' is deprecated and shouldn't be used.
''',
    );
  }

  test_methodInvocation_constructorAnnotation() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@Deprecated('0.9')
int f() => 0;
''',
      code: r'''
var x = f();
//      ^
// [diag.deprecatedMemberUseWithMessage] 'f' is deprecated and shouldn't be used. 0.9.
''',
    );
  }

  test_methodInvocation_constructorAnnotation_dot() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@Deprecated('0.9.')
int f() => 0;
''',
      code: r'''
var x = f();
//      ^
// [diag.deprecatedMemberUseWithMessage] 'f' is deprecated and shouldn't be used. 0.9.
''',
    );
  }

  test_methodInvocation_constructorAnnotation_exclamationMark() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@Deprecated(' Really! ')
int f() => 0;
''',
      code: r'''
var x = f();
//      ^
// [diag.deprecatedMemberUseWithMessage] 'f' is deprecated and shouldn't be used. Really!
''',
    );
  }

  test_methodInvocation_constructorAnnotation_onlyDot() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@Deprecated('.')
int f() => 0;
''',
      code: r'''
var x = f();
//      ^
// [diag.deprecatedMemberUse] 'f' is deprecated and shouldn't be used.
''',
    );
  }

  test_methodInvocation_constructorAnnotation_questionMark() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@Deprecated('Are you sure?')
int f() => 0;
''',
      code: r'''
var x = f();
//      ^
// [diag.deprecatedMemberUseWithMessage] 'f' is deprecated and shouldn't be used. Are you sure?
''',
    );
  }

  test_methodInvocation_fromSamePackage() async {
    newFile('$testPackageLibPath/lib2.dart', r'''
class A {
  @deprecated
  void foo() {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'lib2.dart';

void f(A a) {
  a.foo();
}
''');
  }

  test_methodInvocation_inDeprecatedConstructor() async {
    newFile('$testPackageLibPath/lib2.dart', r'''
@deprecated
void foo() {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'lib2.dart';
class A {
  @deprecated
  A() {
    foo();
  }
}
''');
  }

  test_methodInvocation_inDeprecatedPrimaryConstructor() async {
    newFile('$testPackageLibPath/lib2.dart', r'''
@deprecated
void foo() {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'lib2.dart';
class A() {
  @deprecated
  this {
    foo();
  }
}
''');
  }

  test_methodInvocation_nonUseKind() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @Deprecated.extend()
  void foo() {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo();
}
''');
  }

  test_methodInvocation_unrelatedAnnotation() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @override
  void foo() {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo();
}
''');
  }

  test_methodInvocation_withMessage() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @Deprecated('0.9')
  void foo() {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo();
//  ^^^
// [diag.deprecatedMemberUseWithMessage] 'foo' is deprecated and shouldn't be used. 0.9.
}
''');
  }

  test_mixin_inDeprecatedClassTypeAlias() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
@deprecated
mixin A {}
''');

    await assertNoErrorsInCode(r'''
import 'package:aaa/a.dart';

@deprecated
class B = Object with A;
''');
  }

  test_namedParameterMissingName() async {
    // This is a regression test; previously this code would cause an analyzer
    // crash in DeprecatedMemberUseVerifier.
    await assertErrorsInCode(
      r'''
class C {
  const C({this.});
}
var z = C(x: '');
''',
      [
        error(diag.initializingFormalForNonExistentField, 21, 5),
        error(diag.missingIdentifier, 26, 1),
        error(diag.undefinedNamedParameter, 42, 1),
      ],
    );
  }

  test_operator() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {
  @deprecated
  operator+(A a) {}
}
''',
      code: r'''
f(A a, A b) {
  return a + b;
//       ^^^^^
// [diag.deprecatedMemberUse] '+' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_parameter_named() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
void f({@deprecated int x = 0}) {}
''',
      code: r'''
void g() => f(x: 1);
//            ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
''',
    );
  }

  test_parameter_named_inAnnotation() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class MyAnnotation {
  const MyAnnotation({@deprecated int? x});
}
''',
      code: r'''
@MyAnnotation(x: 1)
//            ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
void g() {}
''',
    );
  }

  test_parameter_named_inDefiningConstructor_asFieldFormalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int x;
  C({@deprecated this.x = 0});
}
''');
  }

  test_parameter_named_inDefiningConstructor_assertInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C({@deprecated int y = 0}) : assert(y > 0);
}
''');
  }

  test_parameter_named_inDefiningConstructor_fieldInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  int x;
  C({@deprecated int y = 0}) : x = y;
}
''');
  }

  test_parameter_named_inDefiningConstructor_inFieldFormalParameter_notName() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {}

@deprecated
class B extends A {
  const B();
}

const B instance = const B();
''',
      code: r'''
class C {
  final A a;
  C({B this.a = instance});
//   ^
// [diag.deprecatedMemberUse] 'B' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_parameter_named_inDefiningFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
f({@deprecated int x = 0}) => x;
''');
  }

  test_parameter_named_inDefiningLocalFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  m() {
    f({@deprecated int x = 0}) {
      return x;
    }
    return f();
  }
}
''');
  }

  test_parameter_named_inDefiningMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  m({@deprecated int x = 0}) {
    return x;
  }
}
''');
  }

  test_parameter_named_inNestedLocalFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  m({@deprecated int x = 0}) {
    f() {
      return x;
    }
    return f();
  }
}
''');
  }

  test_parameter_named_ofFunction() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
void foo({@deprecated int a}) {}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f() {
  foo(a: 0);
//    ^
// [diag.deprecatedMemberUse] 'a' is deprecated and shouldn't be used.
}
''');
  }

  test_parameter_named_ofMethod() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  void foo({@deprecated int a}) {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo(a: 0);
//      ^
// [diag.deprecatedMemberUse] 'a' is deprecated and shouldn't be used.
}
''');
  }

  test_parameter_namedInPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A({@deprecated int x = 0});
''',
      code: '''
var x = A(x: 7);
//        ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
''',
    );
  }

  test_parameter_positionalOptional() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {
  void foo([@deprecated int x = 0]) {}
}
''',
      code: '''
void f(A a) {
  a.foo(0);
//      ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_parameter_positionalOptional_inDeprecatedConstructor() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
void foo([@deprecated int x = 0]) {}
''',
      code: r'''
class A {
  @deprecated
  A() {
    foo(0);
  }
}
''',
    );
  }

  test_parameter_positionalOptional_inDeprecatedFunction() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {
  void foo([@deprecated int x = 0]) {}
}
''',
      code: r'''
@deprecated
void f(A a) {
  a.foo(0);
}
''',
    );
  }

  test_parameter_positionalOptional_inDeprecatedPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
void foo([@deprecated int x = 0]) {}
''',
      code: r'''
class A() {
  @deprecated
  this {
    foo(0);
  }
}
''',
    );
  }

  test_parameter_positionalOptionalInPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A([@deprecated int x = 0]);
''',
      code: '''
var x = A(7);
//        ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
''',
    );
  }

  test_parameter_positionalRequired() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {
  void foo(@deprecated int x) {}
}
''',
      code: r'''
void f(A a) {
  a.foo(0);
}
''',
    );
  }

  test_parameterInSuper_explicitInvocation() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  A([@deprecated int? p]);
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

class B extends A {
  B() : super(7);
//            ^
// [diag.deprecatedMemberUse] 'p' is deprecated and shouldn't be used.
}
''');
  }

  test_parameterInSuper_explicitInvocation_inPrimaryConstructorBody() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  A([@deprecated int? p]);
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

class B() extends A {
  this : super(7);
//             ^
// [diag.deprecatedMemberUse] 'p' is deprecated and shouldn't be used.
}
''');
  }

  test_parameterInSuper_explicitInvocation_namedParameter() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  A({@deprecated int? p});
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

class B extends A {
  B() : super(p: 7);
//            ^
// [diag.deprecatedMemberUse] 'p' is deprecated and shouldn't be used.
}
''');
  }

  test_parameterInSuper_implicitArgument() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  A([@deprecated int? p]);
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

class B extends A {
  B([super.p]);
//   ^^^^^^^
// [diag.deprecatedMemberUse] 'p' is deprecated and shouldn't be used.
}
''');
  }

  test_parameterInSuper_implicitArgument_alsoDeprecated() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  A([@deprecated int? p]);
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

class B extends A {
  B([@deprecated super.p]);
}
''');
  }

  test_parameterInSuper_implicitArgument_alsoDeprecated_inPrimaryConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  A([@deprecated int? p]);
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

class B([@deprecated super.p]) extends A;
''');
  }

  test_parameterInSuper_implicitArgument_explicitInvocation() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  A.named([@deprecated int? p]);
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

class B extends A {
  B([super.p]) : super.named();
//   ^^^^^^^
// [diag.deprecatedMemberUse] 'p' is deprecated and shouldn't be used.
}
''');
  }

  test_parameterInSuper_implicitArgument_explicitInvocation_inPrimaryConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  A.named([@deprecated int? p]);
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

class B([super.p]) extends A {
//       ^^^^^^^
// [diag.deprecatedMemberUse] 'p' is deprecated and shouldn't be used.
  this : super.named();
}
''');
  }

  test_parameterInSuper_implicitArgument_inPrimaryConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  A([@deprecated int? p]);
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

class B([super.p]) extends A;
//       ^^^^^^^
// [diag.deprecatedMemberUse] 'p' is deprecated and shouldn't be used.
''');
  }

  test_parameterInSuper_implicitInvocation_namedParameter() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  A({@deprecated int? p});
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

class B extends A {
  B({super.p});
//   ^^^^^^^
// [diag.deprecatedMemberUse] 'p' is deprecated and shouldn't be used.
}
''');
  }

  test_parameterOfGenericFunctionType_inCommentReference() async {
    await resolveTestCodeWithDiagnostics(r'''
/// [x]
typedef F = void Function(@deprecated int x);
''');
  }

  test_postfixExpression_deprecatedGetter() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int get x => 0;

set x(int _) {}
''',
      code: r'''
void f() {
  x++;
//^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_postfixExpression_deprecatedNothing() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
int get x => 0;

set x(int _) {}
''',
      code: r'''
void f() {
  x++;
}
''',
    );
  }

  test_postfixExpression_deprecatedSetter() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
int get x => 0;

@deprecated
set x(int _) {}
''',
      code: r'''
void f() {
  x++;
//^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_prefixedIdentifier_identifier() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {
  @deprecated
  static const foo = 0;
}
''',
      code: r'''
void f() {
  A.foo;
//  ^^^
// [diag.deprecatedMemberUse] 'foo' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_prefixedIdentifier_prefix() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
class A {
  static const foo = 0;
}
''',
      code: r'''
void f() {
  A.foo;
//^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_prefixExpression_deprecatedGetter() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int get x => 0;

set x(int _) {}
''',
      code: r'''
void f() {
  ++x;
//  ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_prefixExpression_deprecatedSetter() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
int get x => 0;

@deprecated
set x(int _) {}
''',
      code: r'''
void f() {
  ++x;
//  ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_propertyAccess_super() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {
  @deprecated
  int get foo => 0;
}
''',
      code: r'''
class B extends A {
  void bar() {
    super.foo;
//        ^^^
// [diag.deprecatedMemberUse] 'foo' is deprecated and shouldn't be used.
  }
}
''',
    );
  }

  test_redirectedConstructor_fromFactoryConstructor() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
import 'package:test/test.dart';
class B extends A {
  @deprecated
  B();
}
''',
      code: r'''
class A {
  factory A.two() = B;
//                  ^
// [diag.deprecatedMemberUse] 'B' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_redirectedParameter_redirectingFactoryConstructor() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
import 'package:test/test.dart';
class B extends A {
  B([@deprecated int? p]);
}
''',
      code: r'''
class A {
  factory A.two([int? p]) = B;
//               ^^^^^^
// [diag.deprecatedMemberUse] 'p' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_redirectedParameter_redirectingFactoryConstructor_deprecatedFunctionTypedParameter() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
import 'package:test/test.dart';
class B extends A {
  B([@deprecated void p()?]);
}
''',
      code: r'''
class A {
  factory A.two([@deprecated void p()?]) = B;
}
''',
    );
  }

  test_redirectedParameter_redirectingFactoryConstructor_deprecatedParameter() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
import 'package:test/test.dart';
class B extends A {
  B([@deprecated int? p]);
}
''',
      code: r'''
class A {
  factory A.two([@deprecated int? p]) = B;
}
''',
    );
  }

  test_redirectedParameter_redirectingFactoryConstructor_functionTypedParameter() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
import 'package:test/test.dart';
class B extends A {
  B([@deprecated void p()?]);
}
''',
      code: r'''
class A {
  factory A.two([void p()?]) = B;
//               ^^^^^^^^^
// [diag.deprecatedMemberUse] 'p' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_redirectedParameter_redirectingFactoryConstructor_named() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
import 'package:test/test.dart';
class B extends A {
  B({@deprecated int? p});
}
''',
      code: r'''
class A {
  factory A.two({int? p}) = B;
//               ^^^^^^
// [diag.deprecatedMemberUse] 'p' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_redirectingConstructorInvocation_namedParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A({@deprecated int a = 0}) {}
  A.named() : this(a: 0);
}
''');
  }

  test_setterInvocation() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', r'''
class A {
  @deprecated
  set foo(int _) {}
}
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo = 0;
//  ^^^
// [diag.deprecatedMemberUse] 'foo' is deprecated and shouldn't be used.
}
''');
  }

  test_showCombinator() async {
    newFile(externalLibPath, r'''
@deprecated
class A {}
''');
    await resolveTestCodeWithDiagnostics(r'''
// ignore: unused_import
import 'package:aaa/a.dart' show A;
//                               ^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
''');
  }

  test_superConstructor_factoryConstructor() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {
  @deprecated
  A();
  A.two();
}
''',
      code: r'''
class B extends A {
  factory B() => B.two();
  B.two() : super.two();
}
''',
    );
  }

  test_superConstructor_implicitCall() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {
  @deprecated
  A();
}
''',
      code: r'''
class B extends A {
  B();
//^^^^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_superConstructor_namedConstructor() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {
  @deprecated
  A.named() {}
}
''',
      code: r'''
class B extends A {
  B() : super.named() {}
//      ^^^^^^^^^^^^^
// [diag.deprecatedMemberUse] 'A.named' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_superConstructor_primaryConstructor() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A() {
  @deprecated
  this;
}
''',
      code: r'''
class B extends A {
  B() : super();
//      ^^^^^^^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_superConstructor_redirectingConstructor() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {
  @deprecated
  A();
  A.two();
}
''',
      code: r'''
class B extends A {
  B() : this.two();
  B.two() : super.two();
}
''',
    );
  }

  test_superConstructor_unnamedConstructor() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
class A {
  @deprecated
  A() {}
}
''',
      code: r'''
class B extends A {
  B() : super() {}
//      ^^^^^^^
// [diag.deprecatedMemberUse] 'A' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_argument() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  print(x);
//      ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_assignment_right() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f(int a) {
  a = x;
//    ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_binaryExpression() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  x + 1;
//^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_constructorFieldInitializer() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
const int x = 1;
''',
      code: r'''
class A {
  final int f;
  A() : f = x;
//          ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_expressionFunctionBody() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
int f() => x;
//         ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
''',
    );
  }

  test_topLevelVariable_expressionStatement() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  x;
//^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_forElement_condition() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
var x = true;
''',
      code: r'''
void f() {
  [for (;x;) 0];
//       ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_forStatement_condition() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
var x = true;
''',
      code: r'''
void f() {
  for (;x;) {}
//      ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_ifElement_condition() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
var x = true;
''',
      code: r'''
void f() {
  [if (x) 0];
//     ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_ifStatement_condition() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
var x = true;
''',
      code: r'''
void f() {
  if (x) {}
//    ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_listLiteral() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  [x];
// ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_mapLiteralEntry() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  ({0: x, x: 0});
//     ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
//        ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_namedExpression() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void g({int a = 0}) {}
void f() {
  g(a: x);
//     ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_returnStatement() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
int f() {
  return x;
//       ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_setLiteral() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  ({x});
//  ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_spreadElement() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
var x = [0];
''',
      code: r'''
void f() {
  [...x];
//    ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_switchCase() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
const int x = 1;
''',
      code: r'''
void f(int a) {
  switch (a) {
    case x:
//       ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
      break;
  }
}
''',
    );
  }

  test_topLevelVariable_switchCase_language219() async {
    newFile(externalLibPath, r'''
@deprecated
const int x = 1;
''');
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
import 'package:aaa/a.dart';
void f(int a) {
  switch (a) {
    case x:
//       ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
      break;
  }
}
''');
  }

  test_topLevelVariable_switchStatement() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  switch (x) {}
//        ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_switchStatement_language219() async {
    newFile(externalLibPath, r'''
@deprecated
int x = 1;
''');
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
import 'package:aaa/a.dart';
void f() {
  switch (x) {}
//        ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''');
  }

  test_topLevelVariable_unaryExpression() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
int x = 1;
''',
      code: r'''
void f() {
  -x;
// ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_variableDeclaration_initializer() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
var x = 1;
''',
      code: r'''
void f() {
  // ignore: unused_local_variable
  var v = x;
//        ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  test_topLevelVariable_whileStatement_condition() async {
    await resolveTestCodeWithDiagnostics2(
      externalCode: r'''
@deprecated
var x = true;
''',
      code: r'''
void f() {
  while (x) {}
//       ^
// [diag.deprecatedMemberUse] 'x' is deprecated and shouldn't be used.
}
''',
    );
  }

  @override
  void verifyCreatedCollection() {
    super.verifyCreatedCollection();
    assertPackageConfigWorkspaceFor(testFile);
  }
}

class _PackageConfigWorkspaceBase extends PubPackageResolutionTest {
  String get testPackageGeneratedPath {
    return '$testPackageRootPath/.dart_tool/build/generated';
  }

  @override
  void verifyCreatedCollection() {
    super.verifyCreatedCollection();
    assertPackageConfigWorkspaceFor(testFile);
  }

  void _createTestPackageBuildMarker() {
    newFolder(testPackageGeneratedPath);
  }

  void _newTestPackageGeneratedFile({
    required String packageName,
    required String pathInLib,
    required String content,
  }) {
    newFile('$testPackageGeneratedPath/$packageName/lib/$pathInLib', content);
  }
}
