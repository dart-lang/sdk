// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

// Regression test for Issue 17856.

void main() {
  var all = {"a": new A(), "b": new B()};

  A a = all["a"];
  a.load();
}

class A {
  Loader _loader = new Loader();

  load() => _loader.loadAll({'a1': {}});
}

class B {
  Loader _loader = new Loader();

  load() => _loader.loadAll({
        'a2': new DateTime.now(),
      });
}

class Loader {
  loadAll(Map assets) {
    for (String key in assets.keys) {
      Expect.isTrue(assets[key] is Map);
    }
  }
}
