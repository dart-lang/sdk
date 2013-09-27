// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "stringify.dart";

import "package:expect/expect.dart";

import "closure_mirror_import1.dart";
import "closure_mirror_import1.dart" as imp1;
import "closure_mirror_import1.dart" as imp1_hidden
    hide globalVariableInImport, StaticClass;
import "closure_mirror_import2.dart" as imp2;

var globalVariable = "globalVariable";

globalFoo() => 17;

class S { 
  static staticFooInS() => "staticFooInS";
  static var staticInS = "staticInS";
  var instanceInS = "instanceInS";
}

class C extends S { 
  static staticFooInC() => "staticFooInC";
  static var staticInC = "staticInC";
  var instanceInC = "instanceInC";

  foo() => null;

  bar() {
    var x = 7;
    var instanceInC = 11;  // Shadowing the instance field.
    var y = 3;  // Not in context.
    baz() {
      if (x) {}
      if (instanceInC) {}
    };
    return reflect(baz);
  }

  baz() {
    var instanceInC = null; // Shadowing with a null value.
    return reflect(() => instanceInC);
  }
}

main() {
  C c = new C();
  ClosureMirror cm = reflect(c.foo);

  var result;

  result = cm.findInContext(#globalVariable);
  expect("Instance(value = globalVariable)", result);

  result = cm.findInContext(#globalFoo);
  Expect.isTrue(result is ClosureMirror);
  expect("Instance(value = 17)", result.apply(const []));

  result = cm.findInContext(#S.staticInS);
  expect("Instance(value = staticInS)", result);

  result = cm.findInContext(#staticInS);
  Expect.isFalse(result is InstanceMirror);
  Expect.equals(null, result);

  result = cm.findInContext(#staticFooInS);
  Expect.isTrue(result is ClosureMirror);
  expect("Instance(value = staticFooInS)", result.apply(const []));

  result = cm.findInContext(#C.staticFooInS);
  Expect.isTrue(result is ClosureMirror);
  expect("Instance(value = staticFooInS)", result.apply(const []));

  result = cm.findInContext(#C.staticInC);
  expect("Instance(value = staticInC)", result);

  result = cm.findInContext(#staticInC);
  expect("Instance(value = staticInC)", result);

  result = cm.findInContext(#C.staticFooInC);
  Expect.isTrue(result is ClosureMirror);
  expect("Instance(value = staticFooInC)", result.apply(const []));

  result = cm.findInContext(#staticFooInC);
  Expect.isTrue(result is ClosureMirror);
  expect("Instance(value = staticFooInC)", result.apply(const []));

  result = cm.findInContext(#instanceInC);
  expect("Instance(value = instanceInC)", result);

  result = cm.findInContext(#instanceInS);
  expect("Instance(value = instanceInS)", result);

  result = cm.findInContext(#globalVariableInImport1);
  expect("Instance(value = globalVariableInImport1)", result);

  result = cm.findInContext(#StaticClass.staticField);
  expect("Instance(value = staticField)", result);

  result = cm.findInContext(#StaticClass.staticFunctionInStaticClass);
  Expect.isTrue(result is ClosureMirror);
  expect("Instance(value = staticFunctionInStaticClass)",
         result.apply(const []));

  result = cm.findInContext(#imp1.StaticClass.staticFunctionInStaticClass);
  Expect.isTrue(result is ClosureMirror);
  expect("Instance(value = staticFunctionInStaticClass)",
         result.apply(const []));

  result = cm.findInContext(#imp1.globalVariableInImport1);
  expect("Instance(value = globalVariableInImport1)", result);

  result = cm.findInContext(#imp2.globalVariableInImport);
  Expect.isFalse(result is InstanceMirror);
  Expect.equals(null, result);

  result = cm.findInContext(#imp1.StaticClass.staticField);
  expect("Instance(value = staticField)", result);

  result = cm.findInContext(#imp1_hidden.StaticClass.staticField);
  Expect.isFalse(result is InstanceMirror);
  Expect.equals(null, result);

  result = cm.findInContext(#firstGlobalVariableInImport2);
  expect("Instance(value = firstGlobalVariableInImport2)", result);

  result = cm.findInContext(#secondGlobalVariableInImport2);
  Expect.isFalse(result is InstanceMirror);
  Expect.equals(null, result);

  result = cm.findInContext(#imp2.secondGlobalVariableInImport2);
  expect("Instance(value = secondGlobalVariableInImport2)", result);

  result = c.bar().findInContext(#x);
  expect("Instance(value = 7)", result);

  result = c.bar().findInContext(#instanceInC);
  expect("Instance(value = 11)", result);

  result = c.bar().findInContext(#y);
  Expect.isFalse(result is InstanceMirror);
  Expect.equals(null, result);

  result = c.baz().findInContext(#instanceInC);
  expect("Instance(value = <null>)", result);
}
