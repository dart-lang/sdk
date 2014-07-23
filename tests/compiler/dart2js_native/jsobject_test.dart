// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:_js_helper' show Native, Creates, setNativeSubclassDispatchRecord;
import 'dart:_interceptors' show
    JSObject,                 // The interface, which may be re-exported by a
                              // js-interop library.
    JavaScriptObject,         //   The interceptor abstract class.
    PlainJavaScriptObject,    //     The interceptor concrete class.
    UnknownJavaScriptObject,  //     The interceptor concrete class.
    Interceptor;

// Test for JavaScript objects from outside the Dart program.  Although we only
// export the interface [JSObject] to user level code, this test makes sure we
// can distinguish plain JavaScript objects from ones with a complex prototype.

class Q native 'QQ' {}

makeA() native;
makeB() native;
makeQ() native;

void setup() native r"""
makeA = function(){return {hello: 123};};

function BB(){}
makeB = function(){return new BB();};

function QQ(){}
makeQ = function(){return new QQ();};
""";

class Is<T> {
  bool check(x) => x is T;
}

static_test() {
  var x = makeA();
  Expect.isTrue(x is JSObject);
  Expect.isTrue(x is JavaScriptObject);
  Expect.isTrue(x is PlainJavaScriptObject);
  Expect.isTrue(x is !UnknownJavaScriptObject);
  Expect.equals(JSObject, x.runtimeType);

  x = makeB();
  Expect.isTrue(x is JSObject);
  Expect.isTrue(x is JavaScriptObject);
  Expect.isTrue(x is !PlainJavaScriptObject);
  Expect.isTrue(x is UnknownJavaScriptObject);
  Expect.equals(JSObject, x.runtimeType);

  x = makeQ();
  Expect.isFalse(x is JSObject);
  Expect.isFalse(x is JavaScriptObject);
  Expect.isFalse(x is PlainJavaScriptObject);
  Expect.isFalse(x is UnknownJavaScriptObject);
  Expect.isFalse(x.runtimeType == JSObject);
  Expect.isTrue(x is Q);
}

dynamic_test() {
  var x = makeA();
  var isJSObject = new Is<JSObject>().check;
  var isJavaScriptObject = new Is<JavaScriptObject>().check;
  var isPlainJavaScriptObject = new Is<PlainJavaScriptObject>().check;
  var isUnknownJavaScriptObject = new Is<UnknownJavaScriptObject>().check;
  var isQ = new Is<Q>().check;

  Expect.isTrue(isJSObject(x));
  Expect.isTrue(isJavaScriptObject(x));
  Expect.isTrue(isPlainJavaScriptObject(x));
  Expect.isTrue(!isUnknownJavaScriptObject(x));
  Expect.equals(JSObject, x.runtimeType);

  x = makeB();
  Expect.isTrue(isJSObject(x));
  Expect.isTrue(isJavaScriptObject(x));
  Expect.isTrue(!isPlainJavaScriptObject(x));
  Expect.isTrue(isUnknownJavaScriptObject(x));
  Expect.equals(JSObject, x.runtimeType);

  x = makeQ();
  Expect.isFalse(isJSObject(x));
  Expect.isFalse(isJavaScriptObject(x));
  Expect.isFalse(isPlainJavaScriptObject(x));
  Expect.isFalse(isUnknownJavaScriptObject(x));
  Expect.isTrue(isQ(x));
  Expect.isFalse(x.runtimeType == JSObject);
}

main() {
  setup();

  dynamic_test();
  static_test();
}
