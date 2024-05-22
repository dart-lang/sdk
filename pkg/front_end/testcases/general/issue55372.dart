// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  double? foo1;
  String? foo2;
  int foo3 = 0;

  void operator []=(bool key, String? value) {}
  String? operator [](bool key) => "";
}

class B extends A {
  test() {
    // IfNullSuperIndexSet
    {
      super[false] ??= ""; // forEffect=true
      var x = super[false] ??= ""; // forEffect=false
    }
  }
}

extension E on dynamic {
  void operator []=(String key, int? value) {}
  int? operator [](String key) => 0;
}

main() {
  // NullAwareIfNullSet
  {
    A a = new A();
    a?.foo1 ??= 42; // forEffect=true
    var x = a?.foo1 ??= 42; // forEffect=false
  }

  // IfNullIndexSet
  {
    final Map<String, Map<String, String>> nestedMap =
        <String, Map<String, String>>{};
    nestedMap?['hello'] ??= <String, String>{}; // forEffect=true
    var x = nestedMap?['hello'] ??= <String, String>{}; // forEffect=false
  }

  // IfNullExtensionIndexSet
  {
    E(false)['hello'] ??= 1; // forEffect=true
    var x = E(false)['hello'] ??= 1; // forEffect=false
  }

  // IfNullPropertySet
  {
    A a = new A();
    a.foo2 ??= ""; // forEffect=true
    var x = a.foo2 ??= ""; // forEffect=false
  }

  // IfNullSet
  {
    bool? b1;
    bool? b2;
    b1 ??= false; // forEffect=true
    var x = b2 ??= false; // forEffect=false
  }

  // NullAwareCompoundSet
  {
    A? a = new A();
    a?.foo3 += 1;
  }
}
