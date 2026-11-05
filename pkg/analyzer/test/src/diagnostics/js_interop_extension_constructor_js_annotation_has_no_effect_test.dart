// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      JsInteropExtensionConstructorJsAnnotationHasNoEffectTest,
    );
  });
}

@reflectiveTest
class JsInteropExtensionConstructorJsAnnotationHasNoEffectTest
    extends PubPackageResolutionTest {
  test_constructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:js_interop';

extension type Foo(JSObject _) {
  @JS()
// ^^
// [diag.jsInteropExtensionConstructorJsAnnotationHasNoEffect] The '@JS' annotation on an extension type constructor has no effect and is disallowed.
  external Foo.bar();
}
''');
  }

  test_constructor_named() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:js_interop';

extension type Foo(JSObject _) {
  @JS('Bar')
// ^^
// [diag.jsInteropExtensionConstructorJsAnnotationHasNoEffect] The '@JS' annotation on an extension type constructor has no effect and is disallowed.
  external Foo.bar();
}
''');
  }

  test_constructor_packageJs() async {
    newFile('$workspaceRootPath/js/lib/js.dart', r'''
export 'dart:_js_annotations' show JS;
''');
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'js', rootFolder: getFolder('$workspaceRootPath/js')),
    );

    await resolveTestCodeWithDiagnostics(r'''
import 'dart:js_interop' as js;
import 'package:js/js.dart';

extension type Foo(js.JSObject _) {
  @JS()
// ^^
// [diag.jsInteropExtensionConstructorJsAnnotationHasNoEffect] The '@JS' annotation on an extension type constructor has no effect and is disallowed.
  external Foo.bar();
}
''');
  }

  test_constructor_prefixedAnnotation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:js_interop' as js;

extension type Foo(js.JSObject _) {
  @js.JS()
// ^^^^^
// [diag.jsInteropExtensionConstructorJsAnnotationHasNoEffect] The '@JS' annotation on an extension type constructor has no effect and is disallowed.
  external Foo.bar();
}
''');
  }

  test_factory() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:js_interop';

extension type Foo(JSObject _) {
  @JS()
// ^^
// [diag.jsInteropExtensionConstructorJsAnnotationHasNoEffect] The '@JS' annotation on an extension type constructor has no effect and is disallowed.
  external factory Foo.bar();
}
''');
  }

  test_nestedInteropRepresentationType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:js_interop';

extension type Wrapper(JSObject _) {}

extension type Foo(Wrapper _) {
  @JS()
// ^^
// [diag.jsInteropExtensionConstructorJsAnnotationHasNoEffect] The '@JS' annotation on an extension type constructor has no effect and is disallowed.
  external Foo.bar();
}
''');
  }

  test_notReported_cyclicRepresentationType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:js_interop';

extension type A(B _) {
//             ^
// [diag.extensionTypeRepresentationDependsOnItself] The extension type representation can't depend on itself.
  @JS()
  external A.bar();
}

extension type B(A _) {}
//             ^
// [diag.extensionTypeRepresentationDependsOnItself] The extension type representation can't depend on itself.
''');
  }

  /// The CFE only indexes extension types whose representation type is an
  /// interop type, so an extension type over `int` is invisible to its interop
  /// checks.
  test_notReported_nonInteropRepresentationType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:js_interop';

extension type Foo(int _) {
  @JS()
  external Foo.bar();
}
''');
  }

  /// The CFE's `_isJSInteropMember` returns `false` for non-external members,
  /// so it never reports this case.
  test_notReported_notExternal() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:js_interop';

extension type Foo(JSObject _) {
  @JS()
  Foo.bar(JSObject o) : this(o);
}
''');
  }

  test_notReported_onClassConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:js_interop';

@JS()
@staticInterop
class Foo {
  @JS()
  external factory Foo.bar();
}
''');
  }

  test_notReported_onExtensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:js_interop';

@JS()
extension type Foo(JSObject _) {
  external Foo.bar();
}
''');
  }

  test_notReported_onMembers() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:js_interop';

extension type Foo(JSObject _) {
  @JS()
  external void m();

  @JS()
  external int get g;

  @JS()
  external set s(int v);
}
''');
  }
}
