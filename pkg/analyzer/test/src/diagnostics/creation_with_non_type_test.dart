// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CreationWithNonTypeTest);
  });
}

@reflectiveTest
class CreationWithNonTypeTest extends PubPackageResolutionTest {
  test_const_nonPrefix_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
void nonPrefix() {}
f() {
  const nonPrefix.Class<int>();
//      ^^^^^^^^^
// [diag.prefixShadowedByLocalDeclaration] The prefix 'nonPrefix' can't be used here because it's shadowed by a local declaration.
}
''');
  }

  test_const_nonPrefix_genericNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void nonPrefix() {}
f() {
  const nonPrefix.Class<int>.named();
//      ^^^^^^^^^
// [diag.prefixShadowedByLocalDeclaration] The prefix 'nonPrefix' can't be used here because it's shadowed by a local declaration.
}
''');
  }

  test_const_nonPrefix_named() async {
    await resolveTestCodeWithDiagnostics(r'''
void nonPrefix() {}
f() {
  const nonPrefix.Class.named();
//      ^^^^^^^^^
// [diag.prefixShadowedByLocalDeclaration] The prefix 'nonPrefix' can't be used here because it's shadowed by a local declaration.
}
''');
  }

  test_const_nonPrefix_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void nonPrefix() {}
f() {
  const nonPrefix.Class();
//      ^^^^^^^^^
// [diag.prefixShadowedByLocalDeclaration] The prefix 'nonPrefix' can't be used here because it's shadowed by a local declaration.
}
''');
  }

  test_const_nonType_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
void NonType<T>() {}
f() {
  const NonType<int>();
//      ^^^^^^^
// [diag.constWithNonType] The name 'NonType' isn't a class.
}
''');
  }

  test_const_nonType_genericNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void NonType<T>() {}
f() {
  const NonType<int>.named();
//      ^^^^^^^
// [diag.constWithNonType] The name 'NonType' isn't a class.
}
''');
  }

  test_const_nonType_named() async {
    await resolveTestCodeWithDiagnostics(r'''
void NonType() {}
f() {
  const NonType.named();
//      ^^^^^^^
// [diag.prefixShadowedByLocalDeclaration] The prefix 'NonType' can't be used here because it's shadowed by a local declaration.
}
''');
  }

  test_const_nonType_prefixed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

void NonType() {}
f() {
  const prefix.NonType();
//             ^^^^^^^
// [diag.constWithNonType] The name 'NonType' isn't a class.
}
''');
  }

  test_const_nonType_prefixedGeneric() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

void NonType<T>() {}
f() {
  const prefix.NonType<int>();
//             ^^^^^^^
// [diag.constWithNonType] The name 'NonType' isn't a class.
}
''');
  }

  test_const_nonType_prefixedGenericNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

void NonType<T>() {}
f() {
  const prefix.NonType<int>.named();
//             ^^^^^^^
// [diag.constWithNonType] The name 'NonType' isn't a class.
}
''');
  }

  test_const_nonType_prefixedNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

void NonType() {}
f() {
  const prefix.NonType.named();
//             ^^^^^^^
// [diag.constWithNonType] The name 'NonType' isn't a class.
}
''');
  }

  test_const_nonType_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void NonType() {}
f() {
  const NonType();
//      ^^^^^^^
// [diag.constWithNonType] The name 'NonType' isn't a class.
}
''');
  }

  test_const_unresolvedClass_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  const UnresolvedClass<int>();
//      ^^^^^^^^^^^^^^^
// [diag.constWithNonType] The name 'UnresolvedClass' isn't a class.
}
''');
  }

  test_const_unresolvedClass_genericNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  const UnresolvedClass<int>.named();
//      ^^^^^^^^^^^^^^^
// [diag.constWithNonType] The name 'UnresolvedClass' isn't a class.
}
''');
  }

  test_const_unresolvedClass_named() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  const UnresolvedClass.named();
//      ^^^^^^^^^^^^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'UnresolvedClass'.
}
''');
  }

  test_const_unresolvedClass_prefixed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

f() {
  const prefix.UnresolvedClass();
//             ^^^^^^^^^^^^^^^
// [diag.constWithNonType] The name 'UnresolvedClass' isn't a class.
}
''');
  }

  test_const_unresolvedClass_prefixedGeneric() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

f() {
  const prefix.UnresolvedClass<int>();
//             ^^^^^^^^^^^^^^^
// [diag.constWithNonType] The name 'UnresolvedClass' isn't a class.
}
''');
  }

  test_const_unresolvedClass_prefixedGenericNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

f() {
  const prefix.UnresolvedClass<int>.named();
//             ^^^^^^^^^^^^^^^
// [diag.constWithNonType] The name 'UnresolvedClass' isn't a class.
}
''');
  }

  test_const_unresolvedClass_prefixedNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

f() {
  const prefix.UnresolvedClass.named();
//             ^^^^^^^^^^^^^^^
// [diag.constWithNonType] The name 'UnresolvedClass' isn't a class.
}
''');
  }

  test_const_unresolvedClass_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  const UnresolvedClass();
//      ^^^^^^^^^^^^^^^
// [diag.constWithNonType] The name 'UnresolvedClass' isn't a class.
}
''');
  }

  test_const_unresolvedPrefix_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  const unresolved.Class<int>();
//      ^^^^^^^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unresolved'.
}
''');
  }

  test_const_unresolvedPrefix_genericNamed() async {
    // TODO(johnniwinther): This could be "Undefined prefix 'unresolved'.".
    await resolveTestCodeWithDiagnostics(r'''
f() {
  const unresolved.Class<int>.named();
//      ^^^^^^^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unresolved'.
}
''');
  }

  test_const_unresolvedPrefix_named() async {
    // TODO(johnniwinther): This could be "Undefined prefix 'unresolved'.".
    await resolveTestCodeWithDiagnostics(r'''
f() {
  const unresolved.Class.named();
//      ^^^^^^^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unresolved'.
}
''');
  }

  test_const_unresolvedPrefix_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  const unresolved.Class();
//      ^^^^^^^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unresolved'.
}
''');
  }

  test_implicit_nonPrefix_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
void nonPrefix() {}
f() {
  nonPrefix.Class<int>();
//          ^^^^^
// [diag.undefinedMethod] The method 'Class' isn't defined for the type 'Function'.
}
''');
  }

  test_implicit_nonPrefix_genericNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void nonPrefix() {}
f() {
  nonPrefix.Class<int>.named();
//          ^^^^^
// [diag.undefinedGetter] The getter 'Class' isn't defined for the type 'void Function()'.
}
''');
  }

  test_implicit_nonPrefix_named() async {
    await resolveTestCodeWithDiagnostics(r'''
void nonPrefix() {}
f() {
  nonPrefix.Class.named();
//          ^^^^^
// [diag.undefinedGetter] The getter 'Class' isn't defined for the type 'void Function()'.
}
''');
  }

  test_implicit_nonPrefix_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void nonPrefix() {}
f() {
  nonPrefix.Class();
//          ^^^^^
// [diag.undefinedMethod] The method 'Class' isn't defined for the type 'Function'.
}
''');
  }

  test_implicit_nonType_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
void NonType<T>() {}
f() {
  NonType<int>();
}
''');
  }

  test_implicit_nonType_genericNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void NonType<T>() {}
f() {
  NonType<int>.named();
//             ^^^^^
// [diag.undefinedMethod] The method 'named' isn't defined for the type 'Function'.
}
''');
  }

  test_implicit_nonType_named() async {
    await resolveTestCodeWithDiagnostics(r'''
void NonType() {}
f() {
  NonType.named();
//        ^^^^^
// [diag.undefinedMethod] The method 'named' isn't defined for the type 'Function'.
}
''');
  }

  test_implicit_nonType_prefixed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

void NonType() {}
f() {
  prefix.NonType();
}
''');
  }

  test_implicit_nonType_prefixedGeneric() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

void NonType<T>() {}
f() {
  prefix.NonType<int>();
}
''');
  }

  test_implicit_nonType_prefixedGenericNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

void NonType<T>() {}
f() {
  prefix.NonType<int>.named();
//                    ^^^^^
// [diag.undefinedMethod] The method 'named' isn't defined for the type 'Function'.
}
''');
  }

  test_implicit_nonType_prefixedNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

void NonType() {}
f() {
  prefix.NonType.named();
//               ^^^^^
// [diag.undefinedMethod] The method 'named' isn't defined for the type 'Function'.
}
''');
  }

  test_implicit_nonType_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void NonType() {}
f() {
  NonType();
}
''');
  }

  test_implicit_unresolvedClass_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  UnresolvedClass<int>();
//^^^^^^^^^^^^^^^
// [diag.undefinedFunction] The function 'UnresolvedClass' isn't defined.
}
''');
  }

  test_implicit_unresolvedClass_genericNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  UnresolvedClass<int>.named();
//^^^^^^^^^^^^^^^
// [diag.newWithNonType] The name 'UnresolvedClass' isn't a class.
}
''');
  }

  test_implicit_unresolvedClass_named() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  UnresolvedClass.named();
//^^^^^^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'UnresolvedClass'.
}
''');
  }

  test_implicit_unresolvedClass_prefixed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

f() {
  prefix.UnresolvedClass();
//       ^^^^^^^^^^^^^^^
// [diag.undefinedFunction] The function 'UnresolvedClass' isn't defined.
}
''');
  }

  test_implicit_unresolvedClass_prefixedGeneric() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

f() {
  prefix.UnresolvedClass<int>();
//       ^^^^^^^^^^^^^^^
// [diag.undefinedFunction] The function 'UnresolvedClass' isn't defined.
}
''');
  }

  test_implicit_unresolvedClass_prefixedGenericNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

f() {
  prefix.UnresolvedClass<int>.named();
//       ^^^^^^^^^^^^^^^
// [diag.newWithNonType] The name 'UnresolvedClass' isn't a class.
}
''');
  }

  test_implicit_unresolvedClass_prefixedNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

f() {
  prefix.UnresolvedClass.named();
//       ^^^^^^^^^^^^^^^
// [diag.undefinedPrefixedName] The name 'UnresolvedClass' is being referenced through the prefix 'prefix', but it isn't defined in any of the libraries imported using that prefix.
}
''');
  }

  test_implicit_unresolvedClass_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  UnresolvedClass();
//^^^^^^^^^^^^^^^
// [diag.undefinedFunction] The function 'UnresolvedClass' isn't defined.
}
''');
  }

  test_implicit_unresolvedPrefix_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  unresolved.Class<int>();
//^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unresolved'.
}
''');
  }

  test_implicit_unresolvedPrefix_genericNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  unresolved.Class<int>.named();
//^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unresolved'.
}
''');
  }

  test_implicit_unresolvedPrefix_named() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  unresolved.Class.named();
//^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unresolved'.
}
''');
  }

  test_implicit_unresolvedPrefix_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  unresolved.Class();
//^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unresolved'.
}
''');
  }

  test_new_nonPrefix_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
void nonPrefix() {}
f() {
  new nonPrefix.Class<int>();
//    ^^^^^^^^^
// [diag.prefixShadowedByLocalDeclaration] The prefix 'nonPrefix' can't be used here because it's shadowed by a local declaration.
}
''');
  }

  test_new_nonPrefix_genericNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void nonPrefix() {}
f() {
  new nonPrefix.Class<int>.named();
//    ^^^^^^^^^
// [diag.prefixShadowedByLocalDeclaration] The prefix 'nonPrefix' can't be used here because it's shadowed by a local declaration.
}
''');
  }

  test_new_nonPrefix_named() async {
    await resolveTestCodeWithDiagnostics(r'''
void nonPrefix() {}
f() {
  new nonPrefix.Class.named();
//    ^^^^^^^^^
// [diag.prefixShadowedByLocalDeclaration] The prefix 'nonPrefix' can't be used here because it's shadowed by a local declaration.
}
''');
  }

  test_new_nonPrefix_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void nonPrefix() {}
f() {
  new nonPrefix.Class();
//    ^^^^^^^^^
// [diag.prefixShadowedByLocalDeclaration] The prefix 'nonPrefix' can't be used here because it's shadowed by a local declaration.
}
''');
  }

  test_new_nonType_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
void nonPrefix() {}
f() {
  new NonType<int>();
//    ^^^^^^^
// [diag.newWithNonType] The name 'NonType' isn't a class.
}
''');
  }

  test_new_nonType_genericNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void NonType<T>() {}
f() {
  new NonType<int>.named();
//    ^^^^^^^
// [diag.newWithNonType] The name 'NonType' isn't a class.
}
''');
  }

  test_new_nonType_named() async {
    await resolveTestCodeWithDiagnostics(r'''
void NonType() {}
f() {
  new NonType.named();
//    ^^^^^^^
// [diag.prefixShadowedByLocalDeclaration] The prefix 'NonType' can't be used here because it's shadowed by a local declaration.
}
''');
  }

  test_new_nonType_prefixed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

void NonType() {}
f() {
  new prefix.NonType();
//           ^^^^^^^
// [diag.newWithNonType] The name 'NonType' isn't a class.
}
''');
  }

  test_new_nonType_prefixedGeneric() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

void NonType<T>() {}
f() {
  new prefix.NonType<int>();
//           ^^^^^^^
// [diag.newWithNonType] The name 'NonType' isn't a class.
}
''');
  }

  test_new_nonType_prefixedGenericNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

void NonType<T>() {}
f() {
  new prefix.NonType<int>.named();
//           ^^^^^^^
// [diag.newWithNonType] The name 'NonType' isn't a class.
}
''');
  }

  test_new_nonType_prefixedNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

void NonType() {}
f() {
  new prefix.NonType.named();
//           ^^^^^^^
// [diag.newWithNonType] The name 'NonType' isn't a class.
}
''');
  }

  test_new_nonType_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void NonType() {}
f() {
  new NonType();
//    ^^^^^^^
// [diag.newWithNonType] The name 'NonType' isn't a class.
}
''');
  }

  test_new_unresolvedClass_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  new UnresolvedClass<int>();
//    ^^^^^^^^^^^^^^^
// [diag.newWithNonType] The name 'UnresolvedClass' isn't a class.
}
''');
  }

  test_new_unresolvedClass_genericNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  new UnresolvedClass<int>.named();
//    ^^^^^^^^^^^^^^^
// [diag.newWithNonType] The name 'UnresolvedClass' isn't a class.
}
''');
  }

  test_new_unresolvedClass_named() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  new UnresolvedClass.named();
//    ^^^^^^^^^^^^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'UnresolvedClass'.
}
''');
  }

  test_new_unresolvedClass_prefixed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

f() {
  new prefix.UnresolvedClass();
//           ^^^^^^^^^^^^^^^
// [diag.newWithNonType] The name 'UnresolvedClass' isn't a class.
}
''');
  }

  test_new_unresolvedClass_prefixedGeneric() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

f() {
  new prefix.UnresolvedClass<int>();
//           ^^^^^^^^^^^^^^^
// [diag.newWithNonType] The name 'UnresolvedClass' isn't a class.
}
''');
  }

  test_new_unresolvedClass_prefixedGenericNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

f() {
  new prefix.UnresolvedClass<int>.named();
//           ^^^^^^^^^^^^^^^
// [diag.newWithNonType] The name 'UnresolvedClass' isn't a class.
}
''');
  }

  test_new_unresolvedClass_prefixedNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'test.dart' as prefix;

f() {
  new prefix.UnresolvedClass.named();
//           ^^^^^^^^^^^^^^^
// [diag.newWithNonType] The name 'UnresolvedClass' isn't a class.
}
''');
  }

  test_new_unresolvedClass_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  new UnresolvedClass();
//    ^^^^^^^^^^^^^^^
// [diag.newWithNonType] The name 'UnresolvedClass' isn't a class.
}
''');
  }

  test_new_unresolvedPrefix_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  new unresolved.Class<int>();
//    ^^^^^^^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unresolved'.
}
''');
  }

  test_new_unresolvedPrefix_genericNamed() async {
    // TODO(johnniwinther): This could be "Undefined prefix 'unresolved'.".
    await resolveTestCodeWithDiagnostics(r'''
f() {
  new unresolved.Class<int>.named();
//    ^^^^^^^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unresolved'.
}
''');
  }

  test_new_unresolvedPrefix_named() async {
    // TODO(johnniwinther): This could be "Undefined prefix 'unresolved'.".
    await resolveTestCodeWithDiagnostics(r'''
f() {
  new unresolved.Class.named();
//    ^^^^^^^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unresolved'.
}
''');
  }

  test_new_unresolvedPrefix_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  new unresolved.Class();
//    ^^^^^^^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unresolved'.
}
''');
  }
}
