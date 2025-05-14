// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_interop;

import 'package:js/js.dart';

/*member: main:[null|powerset=1]*/
main() {
  anonymousClass();
  jsInteropClass();
}

@JS()
@anonymous
class Class1 {
  /*member: Class1.:[null|subclass=Object|powerset=1]*/
  external factory Class1({
    /*[exact=JSUInt31|powerset=0]*/ a,
    /*Value([exact=JSString|powerset=0], value: "", powerset: 0)*/ b,
  });
}

/*member: anonymousClass:[subclass=LegacyJavaScriptObject|powerset=0]*/
anonymousClass() => Class1(a: 1, b: '');

@JS()
class JsInteropClass {
  /*member: JsInteropClass.:[null|subclass=Object|powerset=1]*/
  external JsInteropClass();

  /*member: JsInteropClass.getter:[null|subclass=Object|powerset=1]*/
  external int get getter;

  external void set setter(int /*[subclass=JSInt|powerset=0]*/ value);

  /*member: JsInteropClass.method:[null|subclass=Object|powerset=1]*/
  external int method(int /*[exact=JSUInt31|powerset=0]*/ a);
}

/*member: jsInteropClass:[subclass=JSInt|powerset=0]*/
jsInteropClass() {
  JsInteropClass cls = JsInteropClass();
  return cls. /*update: [exact=JsInteropClass|powerset=0]*/ setter =
      cls. /*[exact=JsInteropClass|powerset=0]*/ getter /*invoke: [subclass=JSInt|powerset=0]*/ +
      cls. /*invoke: [exact=JsInteropClass|powerset=0]*/ method(
        0,
      ) /*invoke: [subclass=JSInt|powerset=0]*/ +
      10;
}
