// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_interop;

import 'package:js/js.dart';

/*element: main:[null]*/
main() {
  anonymousClass();
}

@JS()
@anonymous
class Class1 {
  /*element: Class1.:[null|subclass=Object]*/
  external factory Class1(
      {/*[exact=JSUInt31]*/ a, /*Value mask: [""] type: [exact=JSString]*/ b});
}

/*element: anonymousClass:[null|subclass=Object]*/
anonymousClass() => new Class1(a: 1, b: '');
