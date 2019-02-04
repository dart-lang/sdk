// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*element: main:[null]*/
main() {
  assumeDynamic();
  notAssumeDynamic();
  trustReturnTypeString();
  trustParameterTypeString();
}

////////////////////////////////////////////////////////////////////////////////
// Use annotation to assume parameter of [_assumeDynamic] is 'dynamic', i.e.
// could be any object, regardless of actuall call sites.
//
// [_assumeDynamic] is used in several tests below to force inference to create
// the 'dynamic' type.
////////////////////////////////////////////////////////////////////////////////

/*element: _assumeDynamic:[null|subclass=Object]*/
@AssumeDynamic()
_assumeDynamic(/*[null|subclass=Object]*/ o) => o;

/*element: assumeDynamic:[null]*/
assumeDynamic() {
  _assumeDynamic(0);
}

////////////////////////////////////////////////////////////////////////////////
// As above but without the annotation.
////////////////////////////////////////////////////////////////////////////////

/*element: _notAssumeDynamic:[exact=JSUInt31]*/
_notAssumeDynamic(/*[exact=JSUInt31]*/ o) => o;

/*element: notAssumeDynamic:[null]*/
notAssumeDynamic() {
  _notAssumeDynamic(0);
}

////////////////////////////////////////////////////////////////////////////////
// No annotation is needed to trust return type annotation.
////////////////////////////////////////////////////////////////////////////////

/*element: trustReturnTypeString:[null|exact=JSString]*/
String trustReturnTypeString() {
  return _assumeDynamic(0);
}

////////////////////////////////////////////////////////////////////////////////
// No annotation is needed to trust parameter type annotation.
////////////////////////////////////////////////////////////////////////////////

/*element: _trustParameterTypeString:[null]*/
_trustParameterTypeString(String /*[null|exact=JSString]*/ o) {}

/*element: trustParameterTypeString:[null]*/
trustParameterTypeString() {
  _trustParameterTypeString(_assumeDynamic(0));
}
