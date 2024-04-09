// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/minitest.dart';

import 'util.dart';

main() {
  setUpJS();
  test('String-is-not-js', () {
    var e = confuse('kombucha');
    // A String should not be a JS interop type. The type test flags are added
    // to Interceptor, but should be added to the class that implements all
    // the JS-interop methods.
    expect(e is HTMLDivElement, isFalse);
    expect(e is StaticHTMLDivElement, isFalse);
  });
}
