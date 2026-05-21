// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeOfFfiClassInExtendsTest);
    defineReflectiveTests(SubtypeOfFfiClassInImplementsTest);
    defineReflectiveTests(SubtypeOfFfiClassInWithTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SubtypeOfFfiClassInExtendsTest extends PubPackageResolutionTest {
  test_Double() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C extends Double {}
//                    ^^^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Double' can't be extended outside of its library because it's a final class.
''');
  }

  test_Double_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.19
import 'dart:ffi';
class C extends Double {}
//              ^^^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Double' can't be extended outside of its library because it's a final class.
''');
  }

  test_Finalizable() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C extends Finalizable {}
//              ^^^^^^^^^^^
// [diag.noGenerativeConstructorsInSuperclass] The class 'C' can't extend 'Finalizable' because 'Finalizable' only has factory constructors (no generative constructors), and 'C' has at least one generative constructor.
''');
  }

  test_Float() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C extends Float {}
//              ^^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Float' can't be extended outside of its library because it's a final class.
''');
  }

  test_Int16() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C extends Int16 {}
//              ^^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Int16' can't be extended outside of its library because it's a final class.
''');
  }

  test_Int32() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C extends Int32 {}
//              ^^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Int32' can't be extended outside of its library because it's a final class.
''');
  }

  test_Int64() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C extends Int64 {}
//              ^^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Int64' can't be extended outside of its library because it's a final class.
''');
  }

  test_Int8() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C extends Int8 {}
//              ^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Int8' can't be extended outside of its library because it's a final class.
''');
  }

  test_Pointer() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C extends Pointer {
//              ^^^^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Pointer' can't be extended outside of its library because it's a final class.
  external factory C();
}
''');
  }

  test_Struct() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C extends Struct {
  external Pointer notEmpty;
}
''');
  }

  test_Uint16() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C extends Uint16 {}
//              ^^^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Uint16' can't be extended outside of its library because it's a final class.
''');
  }

  test_Uint32() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C extends Uint32 {}
//              ^^^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Uint32' can't be extended outside of its library because it's a final class.
''');
  }

  test_Uint64() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C extends Uint64 {}
//              ^^^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Uint64' can't be extended outside of its library because it's a final class.
''');
  }

  test_Uint8() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C extends Uint8 {}
//              ^^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Uint8' can't be extended outside of its library because it's a final class.
''');
  }

  test_Union() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C extends Union {
  external Pointer notEmpty;
}
''');
  }

  test_Void() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C extends Void {}
//              ^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Void' can't be extended outside of its library because it's a final class.
''');
  }
}

@reflectiveTest
class SubtypeOfFfiClassInImplementsTest extends PubPackageResolutionTest {
  test_Double() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C implements Double {}
//                 ^^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Double' can't be implemented outside of its library because it's a final class.
''');
  }

  test_Double_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.19
import 'dart:ffi';
class C implements Double {}
//                 ^^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Double' can't be implemented outside of its library because it's a final class.
''');
  }

  test_Double_prefixed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi' as ffi;
class C implements ffi.Double {}
//                 ^^^^^^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Double' can't be implemented outside of its library because it's a final class.
''');
  }

  test_Finalizable() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C implements Finalizable {}
''');
  }

  test_Float() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C implements Float {}
//                 ^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Float' can't be implemented outside of its library because it's a final class.
''');
  }

  test_Int16() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C implements Int16 {}
//                 ^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Int16' can't be implemented outside of its library because it's a final class.
''');
  }

  test_Int32() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C implements Int32 {}
//                 ^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Int32' can't be implemented outside of its library because it's a final class.
''');
  }

  test_Int64() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C implements Int64 {}
//                 ^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Int64' can't be implemented outside of its library because it's a final class.
''');
  }

  test_Int8() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C implements Int8 {}
//                 ^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Int8' can't be implemented outside of its library because it's a final class.
''');
  }

  test_Pointer() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C implements Pointer {}
//    ^
// [diag.nonAbstractClassInheritsAbstractMemberOne] Missing concrete implementation of 'Pointer.cast'.
//                 ^^^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Pointer' can't be implemented outside of its library because it's a final class.
''');
  }

  test_Struct() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C implements Struct {}
//                       ^^^^^^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'Struct' can't be implemented outside of its library because it's a base class.
''');
  }

  test_Uint16() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C implements Uint16 {}
//                 ^^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Uint16' can't be implemented outside of its library because it's a final class.
''');
  }

  test_Uint32() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C implements Uint32 {}
//                 ^^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Uint32' can't be implemented outside of its library because it's a final class.
''');
  }

  test_Uint64() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C implements Uint64 {}
//                 ^^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Uint64' can't be implemented outside of its library because it's a final class.
''');
  }

  test_Uint8() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C implements Uint8 {}
//                 ^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Uint8' can't be implemented outside of its library because it's a final class.
''');
  }

  test_Union() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C implements Union {}
//                       ^^^^^
// [diag.baseClassImplementedOutsideOfLibrary] The class 'Union' can't be implemented outside of its library because it's a base class.
''');
  }

  test_Void() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C implements Void {}
//                 ^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Void' can't be implemented outside of its library because it's a final class.
''');
  }
}

@reflectiveTest
class SubtypeOfFfiClassInWithTest extends PubPackageResolutionTest {
  test_Double() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C with Double {}
//           ^^^^^^
// [diag.classUsedAsMixin] The class 'Double' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_Double_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart=2.19
import 'dart:ffi';
class C with Double {}
//           ^^^^^^
// [diag.classUsedAsMixin] The class 'Double' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_Double_prefixed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi' as ffi;
class C with ffi.Double {}
//           ^^^^^^^^^^
// [diag.classUsedAsMixin] The class 'Double' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_Float() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C with Float {}
//           ^^^^^
// [diag.classUsedAsMixin] The class 'Float' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_Int16() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C with Int16 {}
//           ^^^^^
// [diag.classUsedAsMixin] The class 'Int16' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_Int32() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C with Int32 {}
//           ^^^^^
// [diag.classUsedAsMixin] The class 'Int32' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_Int64() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C with Int64 {}
//           ^^^^^
// [diag.classUsedAsMixin] The class 'Int64' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_Int8() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C with Int8 {}
//           ^^^^
// [diag.classUsedAsMixin] The class 'Int8' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_Pointer() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C with Pointer {}
//           ^^^^^^^
// [diag.classUsedAsMixin] The class 'Pointer' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_Struct() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C with Struct {}
//                 ^^^^^^
// [diag.classUsedAsMixin] The class 'Struct' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_Uint16() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C with Uint16 {}
//           ^^^^^^
// [diag.classUsedAsMixin] The class 'Uint16' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_Uint32() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C with Uint32 {}
//           ^^^^^^
// [diag.classUsedAsMixin] The class 'Uint32' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_Uint64() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C with Uint64 {}
//           ^^^^^^
// [diag.classUsedAsMixin] The class 'Uint64' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_Uint8() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C with Uint8 {}
//           ^^^^^
// [diag.classUsedAsMixin] The class 'Uint8' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_Union() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
final class C with Union {}
//                 ^^^^^
// [diag.classUsedAsMixin] The class 'Union' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_Void() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class C with Void {}
//           ^^^^
// [diag.classUsedAsMixin] The class 'Void' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }
}
