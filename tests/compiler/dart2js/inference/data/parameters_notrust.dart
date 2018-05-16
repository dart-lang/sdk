// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*element: main:[null]*/
main() {
  dontTrustParameters();
}

////////////////////////////////////////////////////////////////////////////////
// Test that we don't trust the explicit type of a parameter, but do trust
// the local type of parameters in Dart 2.
//
// This means that in both Dart 1 and Dart 2 we infer the parameter type to be
// either an int or a String. In Dart 1 we don't trust the static type of the
// parameter within the method, so the return type is inferred to be either an
// int or a String. In Dart 2 we _do_ trust the static type of the parameter
// within the method and therefore infer the return type to be an int.
////////////////////////////////////////////////////////////////////////////////

/*kernel.element: _dontTrustParameters:Union([exact=JSString], [exact=JSUInt31])*/
/*strong.element: _dontTrustParameters:[exact=JSUInt31]*/
_dontTrustParameters(int /*Union([exact=JSString], [exact=JSUInt31])*/ i) {
  return i;
}

/*element: dontTrustParameters:[null]*/
dontTrustParameters() {
  dynamic f = _dontTrustParameters;
  Expect.equals(0, f(0));
  Expect.throws(/*[null|subclass=Object]*/ () => f('foo'));
}
