// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

@JS()
library js_interop;

import 'package:js/js.dart';

/*member: main:[null]*/
main() {
  anonymousClass();
  jsInteropClass();
}

@JS()
@anonymous
class Class1 {
  /*member: Class1.:[null|subclass=Object]*/
  external factory Class1(
      {/*[exact=JSUInt31]*/ a, /*Value([exact=JSString], value: "")*/ b});
}

/*member: anonymousClass:[null|subclass=JavaScriptObject]*/
anonymousClass() => new Class1(a: 1, b: '');

@JS()
class JsInteropClass {
  /*member: JsInteropClass.:[null|subclass=Object]*/
  external JsInteropClass();

  /*member: JsInteropClass.getter:[null|subclass=Object]*/
  external int get getter;

  external void set setter(int /*[subclass=JSInt]*/ value);

  /*member: JsInteropClass.method:[null|subclass=Object]*/
  external int method(int /*[exact=JSUInt31]*/ a);
}

/*member: jsInteropClass:[subclass=JSInt]*/
jsInteropClass() {
  JsInteropClass cls = new JsInteropClass();
  return cls. /*update: [null|subclass=JavaScriptObject]*/ setter =
      cls. /*[null|subclass=JavaScriptObject]*/ getter
          /*invoke: [null|subclass=JSInt]*/ +
          cls. /*invoke: [subclass=JavaScriptObject]*/ method(0)
          /*invoke: [subclass=JSInt]*/ +
          10;
}
