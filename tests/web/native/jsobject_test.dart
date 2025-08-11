// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';
import 'dart:_js_helper' show setNativeSubclassDispatchRecord;
import 'dart:_interceptors'
    show
        // The interface, which may be re-exported by a js-interop library.
        JSObject,
        // The interceptor base class for all non-Dart objects. @Native classes
        // should extend this class.
        JavaScriptObject,
        // The interceptor abstract class for non-Dart, non-@Native objects.
        LegacyJavaScriptObject,
        // The interceptor concrete sublass of LegacyJavaScriptObject for object
        // literals and objects with `null` prototype.
        PlainJavaScriptObject,
        // The interceptor concrete subclass of LegacyJavaScriptObject for
        // Objects with a prototype chain.
        UnknownJavaScriptObject;

// Test for JavaScript objects from outside the Dart program.  Although we only
// export the interface [JSObject] to user level code, this test makes sure we
// can distinguish plain JavaScript objects from ones with a complex prototype.

@Native('QQ')
class Q extends JavaScriptObject {}

makeA() native;
makeB() native;
makeQ() native;

void setup() {
  JS('', r"""
(function(){
self.makeA = function(){return {hello: 123};};

function BB(){}
self.makeB = function(){return new BB();};

function QQ(){}
self.makeQ = function(){return new QQ();};

self.nativeConstructor(QQ);
})()""");
  applyTestExtensions(['QQ']);
}

class Is<T> {
  bool check(x) => x is T;
}

static_test() {
  var x = makeA();
  Expect.isTrue(x is JSObject);
  Expect.isTrue(x is LegacyJavaScriptObject);
  Expect.isTrue(x is PlainJavaScriptObject);
  Expect.isFalse(x is UnknownJavaScriptObject);
  Expect.equals(JSObject, x.runtimeType);

  x = makeB();
  Expect.isTrue(x is JSObject);
  Expect.isTrue(x is LegacyJavaScriptObject);
  Expect.isFalse(x is PlainJavaScriptObject);
  Expect.isTrue(x is UnknownJavaScriptObject);
  Expect.equals(JSObject, x.runtimeType);

  x = makeQ();
  Expect.isTrue(x is JSObject);
  Expect.isFalse(x is LegacyJavaScriptObject);
  Expect.isFalse(x is PlainJavaScriptObject);
  Expect.isFalse(x is UnknownJavaScriptObject);
  Expect.isFalse(x.runtimeType == JSObject);
  Expect.isTrue(x is Q);
}

dynamic_test() {
  var x = makeA();
  var isJSObject = new Is<JSObject>().check;
  var isLegacyJavaScriptObject = new Is<LegacyJavaScriptObject>().check;
  var isPlainJavaScriptObject = new Is<PlainJavaScriptObject>().check;
  var isUnknownJavaScriptObject = new Is<UnknownJavaScriptObject>().check;
  var isQ = new Is<Q>().check;

  Expect.isTrue(isJSObject(x));
  Expect.isTrue(isLegacyJavaScriptObject(x));
  Expect.isTrue(isPlainJavaScriptObject(x));
  Expect.isFalse(isUnknownJavaScriptObject(x));
  Expect.equals(JSObject, x.runtimeType);

  x = makeB();
  Expect.isTrue(isJSObject(x));
  Expect.isTrue(isLegacyJavaScriptObject(x));
  Expect.isFalse(isPlainJavaScriptObject(x));
  Expect.isTrue(isUnknownJavaScriptObject(x));
  Expect.equals(JSObject, x.runtimeType);

  x = makeQ();
  Expect.isTrue(isJSObject(x));
  Expect.isFalse(isLegacyJavaScriptObject(x));
  Expect.isFalse(isPlainJavaScriptObject(x));
  Expect.isFalse(isUnknownJavaScriptObject(x));
  Expect.isTrue(isQ(x));
  Expect.isFalse(x.runtimeType == JSObject);
}

main() {
  nativeTesting();
  setup();

  dynamic_test();
  static_test();
}
