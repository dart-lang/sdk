// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests resolution of identifiers inside of extension methods

// Test the non error cases for an extension MyExt with member names
// overlapping the instance scopes against:
//   - a class AGlobal which overlaps the names from the global scope as well
//     as providing its own members

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
import "helpers/class_no_shadow.dart";

const bool extensionValue = true;

void checkExtensionValue(bool x) {
  Expect.equals(x, extensionValue);
}

// Put the extension members in the global scope
int fieldInExtensionScope = globalValue;
int get getterInExtensionScope => globalValue;
set setterInExtensionScope(int x) {
  checkGlobalValue(x);
}

int methodInExtensionScope() => globalValue;

// Put the superclass members in the global scope
int fieldInInstanceScope = globalValue;
int get getterInInstanceScope => globalValue;
set setterInInstanceScope(int x) {
  checkGlobalValue(x);
}

int methodInInstanceScope() => globalValue;

// An extension which defines only its own members
extension MyExt on AGlobal {
  bool get fieldInExtensionScope => extensionValue;
  bool get getterInExtensionScope => extensionValue;
  set setterInExtensionScope(bool x) {
    checkExtensionValue(x);
  }

  bool methodInExtensionScope() => extensionValue;

  bool get fieldInInstanceScope => extensionValue;
  bool get getterInInstanceScope => extensionValue;
  set setterInInstanceScope(bool x) {
    checkExtensionValue(x);
  }

  bool methodInInstanceScope() => extensionValue;

  void testNakedIdentifiers() {
    // Members that are in the global namespace and the instance namespace
    // resolve to the global namespace.
    {
      int t0 = fieldInGlobalScope;
      checkGlobalValue(t0);
      int t1 = getterInGlobalScope;
      checkGlobalValue(t1);
      setterInGlobalScope = globalValue;
      int t2 = methodInGlobalScope();
      checkGlobalValue(t2);
    }

    // Members that are in the global namespace and the local namespace resolve
    // to the local namespace.
    {
      bool t0 = fieldInExtensionScope;
      checkExtensionValue(t0);
      bool t1 = getterInExtensionScope;
      checkExtensionValue(t1);
      setterInExtensionScope = extensionValue;
      bool t2 = methodInExtensionScope();
      checkExtensionValue(t2);
    }

    // Members that are in the global namespace and the instance and the local
    // namespace resolve to the local namespace.
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
    MyExt(this).testNakedIdentifiers();
  }
}

class B extends AGlobal {
  void testNakedIdentifiers() {
    // Members that are in the global namespace and the superclass namespace
    // should resolve to the global name space, and not to the members of the
    // superclass.
    {
      int t0 = fieldInGlobalScope;
      checkGlobalValue(t0);
      int t1 = getterInGlobalScope;
      checkGlobalValue(t1);
      setterInGlobalScope = globalValue;
      int t2 = methodInGlobalScope();
      checkGlobalValue(t2);
    }

    // Members that are in the global namespace and the extension namespace
    // should resolve to the global name space, and not to the members of the
    // extension.
    {
      int t0 = fieldInExtensionScope;
      checkGlobalValue(t0);
      int t1 = getterInExtensionScope;
      checkGlobalValue(t1);
      setterInExtensionScope = globalValue;
      int t2 = methodInExtensionScope();
      checkGlobalValue(t2);
    }

    // Members that are in the global namespace, and the superclass namespace,
    // and the extension namespace, should resolve to the global name space, and
    // not to the members of the extension nor the members of the superclass.
    {
      int t0 = fieldInInstanceScope;
      checkGlobalValue(t0);
      int t1 = getterInInstanceScope;
      checkGlobalValue(t1);
      setterInInstanceScope = globalValue;
      int t2 = methodInInstanceScope();
      checkGlobalValue(t2);
    }
  }
}

void main() {
  var a = new AGlobal();
  a.instanceTest();
  new B().testNakedIdentifiers();
}
