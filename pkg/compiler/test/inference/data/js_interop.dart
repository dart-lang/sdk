// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_interop;

import 'package:js/js.dart';

/*member: main:[null|powerset={null}]*/
main() {
  anonymousClass();
  jsInteropClass();
}

@JS()
@anonymous
class Class1 {
  /*member: Class1.:[null|subclass=Object|powerset={null}{IN}]*/
  external factory Class1({
    /*[exact=JSUInt31|powerset={I}]*/ a,
    /*Value([exact=JSString|powerset={I}], value: "", powerset: {I})*/ b,
  });
}

/*member: anonymousClass:[subclass=LegacyJavaScriptObject|powerset={I}]*/
anonymousClass() => Class1(a: 1, b: '');

@JS()
class JsInteropClass {
  /*member: JsInteropClass.:[null|subclass=Object|powerset={null}{IN}]*/
  external JsInteropClass();

  /*member: JsInteropClass.getter:[null|subclass=Object|powerset={null}{IN}]*/
  external int get getter;

  external void set setter(int /*[subclass=JSInt|powerset={I}]*/ value);

  /*member: JsInteropClass.method:[null|subclass=Object|powerset={null}{IN}]*/
  external int method(int /*[exact=JSUInt31|powerset={I}]*/ a);
}

/*member: jsInteropClass:[subclass=JSInt|powerset={I}]*/
jsInteropClass() {
  JsInteropClass cls = JsInteropClass();
  return cls. /*update: [exact=JsInteropClass|powerset={I}]*/ setter =
      cls. /*[exact=JsInteropClass|powerset={I}]*/ getter /*invoke: [subclass=JSInt|powerset={I}]*/ +
      cls. /*invoke: [exact=JsInteropClass|powerset={I}]*/ method(
        0,
      ) /*invoke: [subclass=JSInt|powerset={I}]*/ +
      10;
}
