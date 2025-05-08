// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
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

/*member: _assumeDynamic:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
@pragma('dart2js:assumeDynamic')
_assumeDynamic(/*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/ o) => o;

/*member: assumeDynamic:[null|powerset={null}]*/
assumeDynamic() {
  _assumeDynamic(0);
}

////////////////////////////////////////////////////////////////////////////////
// As above but without the annotation.
////////////////////////////////////////////////////////////////////////////////

/*member: _notAssumeDynamic:[exact=JSUInt31|powerset={I}{O}]*/
_notAssumeDynamic(/*[exact=JSUInt31|powerset={I}{O}]*/ o) => o;

/*member: notAssumeDynamic:[null|powerset={null}]*/
notAssumeDynamic() {
  _notAssumeDynamic(0);
}

////////////////////////////////////////////////////////////////////////////////
// No annotation is needed to trust return type annotation.
////////////////////////////////////////////////////////////////////////////////

/*member: trustReturnTypeString:[exact=JSString|powerset={I}{O}]*/
String trustReturnTypeString() {
  return _assumeDynamic(0);
}

////////////////////////////////////////////////////////////////////////////////
// No annotation is needed to trust parameter type annotation.
////////////////////////////////////////////////////////////////////////////////

/*member: _trustParameterTypeString:[null|powerset={null}]*/
_trustParameterTypeString(String /*[exact=JSString|powerset={I}{O}]*/ o) {}

/*member: trustParameterTypeString:[null|powerset={null}]*/
trustParameterTypeString() {
  _trustParameterTypeString(_assumeDynamic(0));
}
