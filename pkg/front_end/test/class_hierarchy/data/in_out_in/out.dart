// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'in.dart';

/*class: LegacyClass:
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/
class LegacyClass extends Super {
  /*member: LegacyClass.method#cls:
   classBuilder=LegacyClass,
   isSynthesized,
   member=Super.method
  */
  /*member: LegacyClass.method#int:
   classBuilder=LegacyClass,
   covariance=Covariance.empty(),
   declarations=[Super.method],
   isSynthesized,
   memberSignature,
   type=int* Function(int*)*
  */
}

/*class: LegacyClassQ:
 maxInheritancePath=2,
 superclasses=[
  Object,
  SuperQ]
*/
class LegacyClassQ extends SuperQ {
  /*member: LegacyClassQ.method#cls:
   classBuilder=LegacyClassQ,
   isSynthesized,
   member=SuperQ.method
  */
  /*member: LegacyClassQ.method#int:
   classBuilder=LegacyClassQ,
   covariance=Covariance.empty(),
   declarations=[SuperQ.method],
   isSynthesized,
   memberSignature,
   type=int* Function(int*)*
  */
}
