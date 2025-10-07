// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
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
    await assertErrorsInCode(
      r'''
void nonPrefix() {}
f() {
  const nonPrefix.Class<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.prefixShadowedByLocalDeclaration,
          34,
          9,
          messageContains: ["'nonPrefix'"],
        ),
      ],
    );
  }

  test_const_nonPrefix_genericNamed() async {
    await assertErrorsInCode(
      r'''
void nonPrefix() {}
f() {
  const nonPrefix.Class<int>.named();
}
''',
      [
        error(
          CompileTimeErrorCode.prefixShadowedByLocalDeclaration,
          34,
          9,
          messageContains: ["'nonPrefix'"],
        ),
      ],
    );
  }

  test_const_nonPrefix_named() async {
    await assertErrorsInCode(
      r'''
void nonPrefix() {}
f() {
  const nonPrefix.Class.named();
}
''',
      [
        error(
          CompileTimeErrorCode.prefixShadowedByLocalDeclaration,
          34,
          9,
          messageContains: ["'nonPrefix'"],
        ),
      ],
    );
  }

  test_const_nonPrefix_unnamed() async {
    await assertErrorsInCode(
      r'''
void nonPrefix() {}
f() {
  const nonPrefix.Class();
}
''',
      [
        error(
          CompileTimeErrorCode.prefixShadowedByLocalDeclaration,
          34,
          9,
          messageContains: ["'nonPrefix"],
        ),
      ],
    );
  }

  test_const_nonType_generic() async {
    await assertErrorsInCode(
      r'''
void NonType<T>() {}
f() {
  const NonType<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.constWithNonType,
          35,
          7,
          text: "The name 'NonType' isn't a class.",
        ),
      ],
    );
  }

  test_const_nonType_genericNamed() async {
    await assertErrorsInCode(
      r'''
void NonType<T>() {}
f() {
  const NonType<int>.named();
}
''',
      [
        error(
          CompileTimeErrorCode.constWithNonType,
          35,
          7,
          text: "The name 'NonType' isn't a class.",
        ),
      ],
    );
  }

  test_const_nonType_named() async {
    await assertErrorsInCode(
      r'''
void NonType() {}
f() {
  const NonType.named();
}
''',
      [
        error(
          CompileTimeErrorCode.prefixShadowedByLocalDeclaration,
          32,
          7,
          messageContains: ["'NonType"],
        ),
      ],
    );
  }

  test_const_nonType_prefixed() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

void NonType() {}
f() {
  const prefix.NonType();
}
''',
      [
        error(
          CompileTimeErrorCode.constWithNonType,
          70,
          7,
          text: "The name 'NonType' isn't a class.",
        ),
      ],
    );
  }

  test_const_nonType_prefixedGeneric() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

void NonType<T>() {}
f() {
  const prefix.NonType<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.constWithNonType,
          73,
          7,
          text: "The name 'NonType' isn't a class.",
        ),
      ],
    );
  }

  test_const_nonType_prefixedGenericNamed() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

void NonType<T>() {}
f() {
  const prefix.NonType<int>.named();
}
''',
      [
        error(
          CompileTimeErrorCode.constWithNonType,
          73,
          7,
          text: "The name 'NonType' isn't a class.",
        ),
      ],
    );
  }

  test_const_nonType_prefixedNamed() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

void NonType() {}
f() {
  const prefix.NonType.named();
}
''',
      [
        error(
          CompileTimeErrorCode.constWithNonType,
          70,
          7,
          text: "The name 'NonType' isn't a class.",
        ),
      ],
    );
  }

  test_const_nonType_unnamed() async {
    await assertErrorsInCode(
      r'''
void NonType() {}
f() {
  const NonType();
}
''',
      [
        error(
          CompileTimeErrorCode.constWithNonType,
          32,
          7,
          text: "The name 'NonType' isn't a class.",
        ),
      ],
    );
  }

  test_const_unresolvedClass_generic() async {
    await assertErrorsInCode(
      r'''
f() {
  const UnresolvedClass<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.constWithNonType,
          14,
          15,
          text: "The name 'UnresolvedClass' isn't a class.",
        ),
      ],
    );
  }

  test_const_unresolvedClass_genericNamed() async {
    await assertErrorsInCode(
      r'''
f() {
  const UnresolvedClass<int>.named();
}
''',
      [
        error(
          CompileTimeErrorCode.constWithNonType,
          14,
          15,
          text: "The name 'UnresolvedClass' isn't a class.",
        ),
      ],
    );
  }

  test_const_unresolvedClass_named() async {
    await assertErrorsInCode(
      r'''
f() {
  const UnresolvedClass.named();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedIdentifier,
          14,
          21,
          text: "Undefined name 'UnresolvedClass'.",
        ),
      ],
    );
  }

  test_const_unresolvedClass_prefixed() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

f() {
  const prefix.UnresolvedClass();
}
''',
      [
        error(
          CompileTimeErrorCode.constWithNonType,
          52,
          15,
          text: "The name 'UnresolvedClass' isn't a class.",
        ),
      ],
    );
  }

  test_const_unresolvedClass_prefixedGeneric() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

f() {
  const prefix.UnresolvedClass<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.constWithNonType,
          52,
          15,
          text: "The name 'UnresolvedClass' isn't a class.",
        ),
      ],
    );
  }

  test_const_unresolvedClass_prefixedGenericNamed() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

f() {
  const prefix.UnresolvedClass<int>.named();
}
''',
      [
        error(
          CompileTimeErrorCode.constWithNonType,
          52,
          15,
          text: "The name 'UnresolvedClass' isn't a class.",
        ),
      ],
    );
  }

  test_const_unresolvedClass_prefixedNamed() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

f() {
  const prefix.UnresolvedClass.named();
}
''',
      [
        error(
          CompileTimeErrorCode.constWithNonType,
          52,
          15,
          text: "The name 'UnresolvedClass' isn't a class.",
        ),
      ],
    );
  }

  test_const_unresolvedClass_unnamed() async {
    await assertErrorsInCode(
      r'''
f() {
  const UnresolvedClass();
}
''',
      [
        error(
          CompileTimeErrorCode.constWithNonType,
          14,
          15,
          text: "The name 'UnresolvedClass' isn't a class.",
        ),
      ],
    );
  }

  test_const_unresolvedPrefix_generic() async {
    await assertErrorsInCode(
      r'''
f() {
  const unresolved.Class<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedIdentifier,
          14,
          16,
          text: "Undefined name 'unresolved'.",
        ),
      ],
    );
  }

  test_const_unresolvedPrefix_genericNamed() async {
    await assertErrorsInCode(
      r'''
f() {
  const unresolved.Class<int>.named();
}
''',
      [
        error(
          // TODO(johnniwinther): This could be
          //  "Undefined prefix 'unresolved'.".
          CompileTimeErrorCode.undefinedIdentifier,
          14,
          16,
          text: "Undefined name 'unresolved'.",
        ),
      ],
    );
  }

  test_const_unresolvedPrefix_named() async {
    await assertErrorsInCode(
      r'''
f() {
  const unresolved.Class.named();
}
''',
      [
        error(
          // TODO(johnniwinther): This could be
          //  "Undefined prefix 'unresolved'.".
          CompileTimeErrorCode.undefinedIdentifier,
          14,
          16,
          text: "Undefined name 'unresolved'.",
        ),
      ],
    );
  }

  test_const_unresolvedPrefix_unnamed() async {
    await assertErrorsInCode(
      r'''
f() {
  const unresolved.Class();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedIdentifier,
          14,
          16,
          text: "Undefined name 'unresolved'.",
        ),
      ],
    );
  }

  test_implicit_nonPrefix_generic() async {
    await assertErrorsInCode(
      r'''
void nonPrefix() {}
f() {
  nonPrefix.Class<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedMethod,
          38,
          5,
          messageContains: ["'Class'"],
        ),
      ],
    );
  }

  test_implicit_nonPrefix_genericNamed() async {
    await assertErrorsInCode(
      r'''
void nonPrefix() {}
f() {
  nonPrefix.Class<int>.named();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedGetter,
          38,
          5,
          messageContains: ["'Class'"],
        ),
      ],
    );
  }

  test_implicit_nonPrefix_named() async {
    await assertErrorsInCode(
      r'''
void nonPrefix() {}
f() {
  nonPrefix.Class.named();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedGetter,
          38,
          5,
          messageContains: ["'Class'"],
        ),
      ],
    );
  }

  test_implicit_nonPrefix_unnamed() async {
    await assertErrorsInCode(
      r'''
void nonPrefix() {}
f() {
  nonPrefix.Class();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedMethod,
          38,
          5,
          messageContains: ["'Class'"],
        ),
      ],
    );
  }

  test_implicit_nonType_generic() async {
    await assertNoErrorsInCode(r'''
void NonType<T>() {}
f() {
  NonType<int>();
}
''');
  }

  test_implicit_nonType_genericNamed() async {
    await assertErrorsInCode(
      r'''
void NonType<T>() {}
f() {
  NonType<int>.named();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedMethod,
          42,
          5,
          messageContains: ["'named"],
        ),
      ],
    );
  }

  test_implicit_nonType_named() async {
    await assertErrorsInCode(
      r'''
void NonType() {}
f() {
  NonType.named();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedMethod,
          34,
          5,
          messageContains: ["'named'"],
        ),
      ],
    );
  }

  test_implicit_nonType_prefixed() async {
    await assertNoErrorsInCode(r'''
import 'test.dart' as prefix;

void NonType() {}
f() {
  prefix.NonType();
}
''');
  }

  test_implicit_nonType_prefixedGeneric() async {
    await assertNoErrorsInCode(r'''
import 'test.dart' as prefix;

void NonType<T>() {}
f() {
  prefix.NonType<int>();
}
''');
  }

  test_implicit_nonType_prefixedGenericNamed() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

void NonType<T>() {}
f() {
  prefix.NonType<int>.named();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedMethod,
          80,
          5,
          messageContains: ["'named'"],
        ),
      ],
    );
  }

  test_implicit_nonType_prefixedNamed() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

void NonType() {}
f() {
  prefix.NonType.named();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedMethod,
          72,
          5,
          messageContains: ["'named'"],
        ),
      ],
    );
  }

  test_implicit_nonType_unnamed() async {
    await assertNoErrorsInCode(r'''
void NonType() {}
f() {
  NonType();
}
''');
  }

  test_implicit_unresolvedClass_generic() async {
    await assertErrorsInCode(
      r'''
f() {
  UnresolvedClass<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedFunction,
          8,
          15,
          text: "The function 'UnresolvedClass' isn't defined.",
        ),
      ],
    );
  }

  test_implicit_unresolvedClass_genericNamed() async {
    await assertErrorsInCode(
      r'''
f() {
  UnresolvedClass<int>.named();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithNonType,
          8,
          15,
          text: "The name 'UnresolvedClass' isn't a class.",
        ),
      ],
    );
  }

  test_implicit_unresolvedClass_named() async {
    await assertErrorsInCode(
      r'''
f() {
  UnresolvedClass.named();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedIdentifier,
          8,
          15,
          text: "Undefined name 'UnresolvedClass'.",
        ),
      ],
    );
  }

  test_implicit_unresolvedClass_prefixed() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

f() {
  prefix.UnresolvedClass();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedFunction,
          46,
          15,
          text: "The function 'UnresolvedClass' isn't defined.",
        ),
      ],
    );
  }

  test_implicit_unresolvedClass_prefixedGeneric() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

f() {
  prefix.UnresolvedClass<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedFunction,
          46,
          15,
          text: "The function 'UnresolvedClass' isn't defined.",
        ),
      ],
    );
  }

  test_implicit_unresolvedClass_prefixedGenericNamed() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

f() {
  prefix.UnresolvedClass<int>.named();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithNonType,
          46,
          15,
          text: "The name 'UnresolvedClass' isn't a class.",
        ),
      ],
    );
  }

  test_implicit_unresolvedClass_prefixedNamed() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

f() {
  prefix.UnresolvedClass.named();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedPrefixedName,
          46,
          15,
          messageContains: ["'UnresolvedClass'"],
        ),
      ],
    );
  }

  test_implicit_unresolvedClass_unnamed() async {
    await assertErrorsInCode(
      r'''
f() {
  UnresolvedClass();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedFunction,
          8,
          15,
          text: "The function 'UnresolvedClass' isn't defined.",
        ),
      ],
    );
  }

  test_implicit_unresolvedPrefix_generic() async {
    await assertErrorsInCode(
      r'''
f() {
  unresolved.Class<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedIdentifier,
          8,
          10,
          text: "Undefined name 'unresolved'.",
        ),
      ],
    );
  }

  test_implicit_unresolvedPrefix_genericNamed() async {
    await assertErrorsInCode(
      r'''
f() {
  unresolved.Class<int>.named();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedIdentifier,
          8,
          10,
          text: "Undefined name 'unresolved.Class'.",
        ),
      ],
    );
  }

  test_implicit_unresolvedPrefix_named() async {
    await assertErrorsInCode(
      r'''
f() {
  unresolved.Class.named();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedIdentifier,
          8,
          10,
          text: "Undefined name 'unresolved'.",
        ),
      ],
    );
  }

  test_implicit_unresolvedPrefix_unnamed() async {
    await assertErrorsInCode(
      r'''
f() {
  unresolved.Class();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedIdentifier,
          8,
          10,
          text: "Undefined name 'unresolved'.",
        ),
      ],
    );
  }

  test_new_nonPrefix_generic() async {
    await assertErrorsInCode(
      r'''
void nonPrefix() {}
f() {
  new nonPrefix.Class<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.prefixShadowedByLocalDeclaration,
          32,
          9,
          messageContains: ["'nonPrefix'"],
        ),
      ],
    );
  }

  test_new_nonPrefix_genericNamed() async {
    await assertErrorsInCode(
      r'''
void nonPrefix() {}
f() {
  new nonPrefix.Class<int>.named();
}
''',
      [
        error(
          CompileTimeErrorCode.prefixShadowedByLocalDeclaration,
          32,
          9,
          messageContains: ["'nonPrefix'"],
        ),
      ],
    );
  }

  test_new_nonPrefix_named() async {
    await assertErrorsInCode(
      r'''
void nonPrefix() {}
f() {
  new nonPrefix.Class.named();
}
''',
      [
        error(
          CompileTimeErrorCode.prefixShadowedByLocalDeclaration,
          32,
          9,
          messageContains: ["'nonPrefix'"],
        ),
      ],
    );
  }

  test_new_nonPrefix_unnamed() async {
    await assertErrorsInCode(
      r'''
void nonPrefix() {}
f() {
  new nonPrefix.Class();
}
''',
      [
        error(
          CompileTimeErrorCode.prefixShadowedByLocalDeclaration,
          32,
          9,
          messageContains: ["nonPrefix"],
        ),
      ],
    );
  }

  test_new_nonType_generic() async {
    await assertErrorsInCode(
      r'''
void nonPrefix() {}
f() {
  new NonType<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithNonType,
          32,
          7,
          text: "The name 'NonType' isn't a class.",
        ),
      ],
    );
  }

  test_new_nonType_genericNamed() async {
    await assertErrorsInCode(
      r'''
void NonType<T>() {}
f() {
  new NonType<int>.named();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithNonType,
          33,
          7,
          text: "The name 'NonType' isn't a class.",
        ),
      ],
    );
  }

  test_new_nonType_named() async {
    await assertErrorsInCode(
      r'''
void NonType() {}
f() {
  new NonType.named();
}
''',
      [
        error(
          CompileTimeErrorCode.prefixShadowedByLocalDeclaration,
          30,
          7,
          messageContains: ["'NonType'"],
        ),
      ],
    );
  }

  test_new_nonType_prefixed() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

void NonType() {}
f() {
  new prefix.NonType();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithNonType,
          68,
          7,
          text: "The name 'NonType' isn't a class.",
        ),
      ],
    );
  }

  test_new_nonType_prefixedGeneric() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

void NonType<T>() {}
f() {
  new prefix.NonType<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithNonType,
          71,
          7,
          text: "The name 'NonType' isn't a class.",
        ),
      ],
    );
  }

  test_new_nonType_prefixedGenericNamed() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

void NonType<T>() {}
f() {
  new prefix.NonType<int>.named();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithNonType,
          71,
          7,
          text: "The name 'NonType' isn't a class.",
        ),
      ],
    );
  }

  test_new_nonType_prefixedNamed() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

void NonType() {}
f() {
  new prefix.NonType.named();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithNonType,
          68,
          7,
          text: "The name 'NonType' isn't a class.",
        ),
      ],
    );
  }

  test_new_nonType_unnamed() async {
    await assertErrorsInCode(
      r'''
void NonType() {}
f() {
  new NonType();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithNonType,
          30,
          7,
          text: "The name 'NonType' isn't a class.",
        ),
      ],
    );
  }

  test_new_unresolvedClass_generic() async {
    await assertErrorsInCode(
      r'''
f() {
  new UnresolvedClass<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithNonType,
          12,
          15,
          text: "The name 'UnresolvedClass' isn't a class.",
        ),
      ],
    );
  }

  test_new_unresolvedClass_genericNamed() async {
    await assertErrorsInCode(
      r'''
f() {
  new UnresolvedClass<int>.named();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithNonType,
          12,
          15,
          text: "The name 'UnresolvedClass' isn't a class.",
        ),
      ],
    );
  }

  test_new_unresolvedClass_named() async {
    await assertErrorsInCode(
      r'''
f() {
  new UnresolvedClass.named();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedIdentifier,
          12,
          21,
          text: "Undefined name 'UnresolvedClass'.",
        ),
      ],
    );
  }

  test_new_unresolvedClass_prefixed() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

f() {
  new prefix.UnresolvedClass();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithNonType,
          50,
          15,
          text: "The name 'UnresolvedClass' isn't a class.",
        ),
      ],
    );
  }

  test_new_unresolvedClass_prefixedGeneric() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

f() {
  new prefix.UnresolvedClass<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithNonType,
          50,
          15,
          text: "The name 'UnresolvedClass' isn't a class.",
        ),
      ],
    );
  }

  test_new_unresolvedClass_prefixedGenericNamed() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

f() {
  new prefix.UnresolvedClass<int>.named();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithNonType,
          50,
          15,
          text: "The name 'UnresolvedClass' isn't a class.",
        ),
      ],
    );
  }

  test_new_unresolvedClass_prefixedNamed() async {
    await assertErrorsInCode(
      r'''
import 'test.dart' as prefix;

f() {
  new prefix.UnresolvedClass.named();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithNonType,
          50,
          15,
          text: "The name 'UnresolvedClass' isn't a class.",
        ),
      ],
    );
  }

  test_new_unresolvedClass_unnamed() async {
    await assertErrorsInCode(
      r'''
f() {
  new UnresolvedClass();
}
''',
      [
        error(
          CompileTimeErrorCode.newWithNonType,
          12,
          15,
          text: "The name 'UnresolvedClass' isn't a class.",
        ),
      ],
    );
  }

  test_new_unresolvedPrefix_generic() async {
    await assertErrorsInCode(
      r'''
f() {
  new unresolved.Class<int>();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedIdentifier,
          12,
          16,
          text: "Undefined name 'unresolved'.",
        ),
      ],
    );
  }

  test_new_unresolvedPrefix_genericNamed() async {
    await assertErrorsInCode(
      r'''
f() {
  new unresolved.Class<int>.named();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedIdentifier,
          12,
          16,
          // TODO(johnniwinther): This could be
          //  "Undefined prefix 'unresolved'.".
          text: "Undefined name 'unresolved'.",
        ),
      ],
    );
  }

  test_new_unresolvedPrefix_named() async {
    await assertErrorsInCode(
      r'''
f() {
  new unresolved.Class.named();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedIdentifier,
          12,
          16,
          // TODO(johnniwinther): This could be
          //  "Undefined prefix 'unresolved'.".
          text: "Undefined name 'unresolved'.",
        ),
      ],
    );
  }

  test_new_unresolvedPrefix_unnamed() async {
    await assertErrorsInCode(
      r'''
f() {
  new unresolved.Class();
}
''',
      [
        error(
          CompileTimeErrorCode.undefinedIdentifier,
          12,
          16,
          text: "Undefined name 'unresolved'.",
        ),
      ],
    );
  }
}
