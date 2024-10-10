// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'main.dart';

/*class: Extension:
 builder-name=Extension,
 builder-onType=int,
 extension-members=[
  intMethod=Extension|intMethod,
  tearoff intMethod=Extension|get#intMethod],
 extension-name=Extension,
 extension-onType=int!
*/
extension Extension on int {
  /*member: Extension|intMethod:
   builder-name=intMethod,
   builder-params=[#this],
   member-name=Extension|intMethod,
   member-params=[#this]
  */
  /*member: Extension|get#intMethod:
   builder-name=intMethod,
   builder-params=[#this],
   member-name=Extension|get#intMethod,
   member-params=[#this]
  */
  intMethod() {}
}

/*class: _extension#1:
 builder-name=_extension#1,
 builder-onType=String,
 extension-members=[
  stringMethod=_extension#1|stringMethod,
  tearoff stringMethod=_extension#1|get#stringMethod],
 extension-name=_extension#1,
 extension-onType=String!
*/
extension on String {
  /*member: _extension#1|get#stringMethod:
   builder-name=stringMethod,
   builder-params=[#this],
   member-name=_extension#1|get#stringMethod,
   member-params=[#this]
  */
  /*member: _extension#1|stringMethod:
   builder-name=stringMethod,
   builder-params=[#this],
   member-name=_extension#1|stringMethod,
   member-params=[#this]
  */
  stringMethod() {}
}
