// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests resolution of identifiers inside of extension methods

// Test various non-error corner cases around internal resolution.

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
  static bool get getterInInstanceScope => extensionValue;
  static set setterInInstanceScope(bool x) {
    checkExtensionValue(x);
  }

  static bool methodInInstanceScope() => extensionValue;

  // Add the global symbols
  static bool get fieldInGlobalScope => extensionValue;
  static bool get getterInGlobalScope => extensionValue;
  static set setterInGlobalScope(bool x) {
    checkExtensionValue(x);
  }

  static bool methodInGlobalScope() => extensionValue;

  void testNakedIdentifiers() {
    // Symbols in the global scope and the local static scope resolve to
    // the local static scope.
    {
      bool t0 = fieldInGlobalScope;
      checkExtensionValue(t0);
      bool t1 = getterInGlobalScope;
      checkExtensionValue(t1);
      setterInGlobalScope = extensionValue;
      bool t2 = methodInGlobalScope();
      checkExtensionValue(t2);
    }

    // Symbols in the global scope, the instance scope, and the local static scope
    // resolve to the local static scope.
    {
      bool t0 = fieldInInstanceScope;
      checkExtensionValue(t0);
      bool t1 = getterInInstanceScope;
      checkExtensionValue(t1);
      setterInInstanceScope = extensionValue;
      bool t2 = methodInInstanceScope();
      checkExtensionValue(t2);
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
}
