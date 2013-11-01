// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--support_find_in_context=true

// Regression test: this used to crash the VM.

library test.find_in_context_fake_function;

import "dart:mirrors";
import "package:expect/expect.dart";

var topLevelField = 1;
get topLevelGetter => 2;
topLevelFunction() => 3;

class FakeFunction1 {
  var field = 4;
  get getter => 5;
  method() => 6;
  static var staticField = 7;
  static get staticGetter => 8;
  staticFunction() => 9;
  call(x) {
    var local = x * 2;
    return local;
  }
}

class FakeFunction2 implements Function {
  var field = 10;
  get getter => 11;
  method() => 12;
  static var staticField = 13;
  static get staticGetter => 14;
  staticFunction() => 15;
  noSuchMethod(msg) {
    var local = msg.positionalArguments;
    if (msg.memberName != #call) return super.noSuchMethod(msg);
    return local.join('+');
  }
}

doFindInContext(cm, name, value) {
  Expect.equals(value,
                cm.findInContext(name).reflectee);
}
dontFindInContext(cm, name) {
  Expect.isNull(cm.findInContext(name));
}

main() {
  ClosureMirror cm = reflect(new FakeFunction1());
  dontFindInContext(cm, #local);
  dontFindInContext(cm, const Symbol('this'));
  dontFindInContext(cm, #field);
  dontFindInContext(cm, #getter);
  dontFindInContext(cm, #method);
  dontFindInContext(cm, #staticField);
  dontFindInContext(cm, #staticGetter);
  dontFindInContext(cm, #staticFunction);
  dontFindInContext(cm, #topLevelField);
  dontFindInContext(cm, #topLevelGetter);
  dontFindInContext(cm, #topLevelFunction);

  cm = reflect(new FakeFunction2());
  dontFindInContext(cm, #local);
  dontFindInContext(cm, const Symbol('this'));
  dontFindInContext(cm, #field);
  dontFindInContext(cm, #getter);
  dontFindInContext(cm, #method);
  dontFindInContext(cm, #staticField);
  dontFindInContext(cm, #staticGetter);
  dontFindInContext(cm, #staticFunction);
  dontFindInContext(cm, #topLevelField);
  dontFindInContext(cm, #topLevelGetter);
  dontFindInContext(cm, #topLevelFunction);
}
