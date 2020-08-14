// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests resolution of identifiers inside of extension methods

// Test various static error corner cases around internal resolution.

import "package:expect/expect.dart";

/////////////////////////////////////////////////////////////////////////
// Note: These imports may be deliberately unused.  They bring certain
// names into scope, in order to test that certain resolution choices are
// made even in the presence of other symbols.
/////////////////////////////////////////////////////////////////////////

// Do Not Delete.
// Bring global members into scope.
import "helpers/global_scope.dart";

// Do Not Delete.
// Bring a class AGlobal with instance members and global members into scope.
import "helpers/class_shadow.dart";

extension GenericExtension<T> on T {
  T get self => this;
  // Check that capture is avoided when expanding out
  // self references.
  void shadowTypeParam<T>(T x) {
    T y = self;
    //    ^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    // [cfe] A value of type '#T' can't be assigned to a variable of type 'T'.
  }

  void castToShadowedTypeParam<T>() {
    dynamic s = self;
    (s as T);
  }

  List<T> mkList() => <T>[];
  void castToShadowedTypeList<T>() {
    (mkList() as List<T>);
  }
}

const bool extensionValue = true;

void checkExtensionValue(bool x) {
  Expect.equals(x, extensionValue);
}

extension StaticExt on AGlobal {
  // Valid to overlap static names with the target type symbols
  static bool get fieldInInstanceScope => extensionValue;
  //              ^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE
  static bool get getterInInstanceScope => extensionValue;
  //              ^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE
  static set setterInInstanceScope(bool x) {
    //       ^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE
    checkExtensionValue(x);
  }

  static bool methodInInstanceScope() => extensionValue;
  //          ^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE

  // Add the global symbols
  static bool get fieldInGlobalScope => extensionValue;
  static bool get getterInGlobalScope => extensionValue;
  static set setterInGlobalScope(bool x) {
    checkExtensionValue(x);
  }

  static bool methodInGlobalScope() => extensionValue;

  // Invalid to overlap the static and extension scopes
  bool get fieldInInstanceScope => extensionValue;
  //       ^
  // [cfe] 'fieldInInstanceScope' is already declared in this scope.
  bool get getterInInstanceScope => extensionValue;
  //       ^
  // [cfe] 'getterInInstanceScope' is already declared in this scope.
  set setterInInstanceScope(bool x) {
    //^
    // [cfe] 'setterInInstanceScope' is already declared in this scope.
    checkExtensionValue(x);
  }

  bool methodInInstanceScope() => extensionValue;
  //   ^
  // [cfe] 'methodInInstanceScope' is already declared in this scope.

  void testNakedIdentifiers() {
    // Symbols in the global scope and the local static scope resolve to
    // the local static scope.
    {
      // No errors: see static_extension_internal_resolution_6_test.dart
    }

    // Symbols in the global scope, the instance scope, and the local static scope
    // resolve to the local static scope.
    {
      // No errors: see static_extension_internal_resolution_6_test.dart
    }
  }

  void instanceTest() {
    StaticExt(this).testNakedIdentifiers();
  }
}

void main() {
  var a = new AGlobal();
  a.instanceTest();

  Expect.throwsTypeError(() => 3.castToShadowedTypeParam<String>());
  Expect.throwsTypeError(() => 3.castToShadowedTypeList<String>());
}
