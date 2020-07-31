// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
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

/*member: _assumeDynamic:[null|subclass=Object]*/
@pragma('dart2js:assumeDynamic')
_assumeDynamic(/*[null|subclass=Object]*/ o) => o;

/*member: assumeDynamic:[null]*/
assumeDynamic() {
  _assumeDynamic(0);
}

////////////////////////////////////////////////////////////////////////////////
// As above but without the annotation.
////////////////////////////////////////////////////////////////////////////////

/*member: _notAssumeDynamic:[exact=JSUInt31]*/
_notAssumeDynamic(/*[exact=JSUInt31]*/ o) => o;

/*member: notAssumeDynamic:[null]*/
notAssumeDynamic() {
  _notAssumeDynamic(0);
}

////////////////////////////////////////////////////////////////////////////////
// No annotation is needed to trust return type annotation.
////////////////////////////////////////////////////////////////////////////////

/*member: trustReturnTypeString:[null|exact=JSString]*/
String trustReturnTypeString() {
  return _assumeDynamic(0);
}

////////////////////////////////////////////////////////////////////////////////
// No annotation is needed to trust parameter type annotation.
////////////////////////////////////////////////////////////////////////////////

/*member: _trustParameterTypeString:[null]*/
_trustParameterTypeString(String /*[null|exact=JSString]*/ o) {}

/*member: trustParameterTypeString:[null]*/
trustParameterTypeString() {
  _trustParameterTypeString(_assumeDynamic(0));
}
