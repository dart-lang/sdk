// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'in.dart';
import 'out.dart';

/*class: Class:
 interfaces=[SuperQ],
 maxInheritancePath=3,
 superclasses=[
  LegacyClass,
  Object,
  Super]
*/
class Class extends LegacyClass implements SuperQ {
  /*member: Class.method#cls:
   classBuilder=Class,
   inherited-implements=[Class.method],
   isSynthesized,
   member=Super.method
  */
  /*member: Class.method#int:
   classBuilder=Class,
   covariance=Covariance.empty(),
   declarations=[
    LegacyClass.method,
    SuperQ.method],
   isSynthesized,
   memberSignature,
   type=int? Function(int?)
  */
}

/*class: ClassQ:
 interfaces=[Super],
 maxInheritancePath=3,
 superclasses=[
  LegacyClassQ,
  Object,
  SuperQ]
*/
/*member: ClassQ.method#cls:
 classBuilder=ClassQ,
 inherited-implements=[ClassQ.method],
 isSynthesized,
 member=SuperQ.method
*/
/*member: ClassQ.method#int:
 classBuilder=ClassQ,
 covariance=Covariance.empty(),
 declarations=[
  LegacyClassQ.method,
  Super.method],
 isSynthesized,
 memberSignature,
 type=int Function(int)
*/
class ClassQ extends LegacyClassQ implements Super {}
