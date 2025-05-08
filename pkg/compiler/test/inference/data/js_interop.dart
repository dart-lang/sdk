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
  /*member: Class1.:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  external factory Class1({
    /*[exact=JSUInt31|powerset={I}{O}]*/ a,
    /*Value([exact=JSString|powerset={I}{O}], value: "", powerset: {I}{O})*/ b,
  });
}

/*member: anonymousClass:[subclass=LegacyJavaScriptObject|powerset={I}{O}]*/
anonymousClass() => Class1(a: 1, b: '');

@JS()
class JsInteropClass {
  /*member: JsInteropClass.:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  external JsInteropClass();

  /*member: JsInteropClass.getter:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  external int get getter;

  external void set setter(int /*[subclass=JSInt|powerset={I}{O}]*/ value);

  /*member: JsInteropClass.method:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  external int method(int /*[exact=JSUInt31|powerset={I}{O}]*/ a);
}

/*member: jsInteropClass:[subclass=JSInt|powerset={I}{O}]*/
jsInteropClass() {
  JsInteropClass cls = JsInteropClass();
  return cls. /*update: [exact=JsInteropClass|powerset={I}{O}]*/ setter =
      cls. /*[exact=JsInteropClass|powerset={I}{O}]*/ getter /*invoke: [subclass=JSInt|powerset={I}{O}]*/ +
      cls. /*invoke: [exact=JsInteropClass|powerset={I}{O}]*/ method(
        0,
      ) /*invoke: [subclass=JSInt|powerset={I}{O}]*/ +
      10;
}
