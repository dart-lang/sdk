// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart = 2.5
import 'opt_in.dart';

/*class: LegacyClass1:Class,LegacyClass1,Object*/
abstract class LegacyClass1 extends Class {
  /*member: LegacyClass1.getter:int**/
  /*member: LegacyClass1.method:int* Function()**/
}

/*class: LegacyClass2:Class,LegacyClass1,LegacyClass2,Object*/
class LegacyClass2 extends Class implements LegacyClass1 {
  /*member: LegacyClass2.method:int* Function()**/
  method() => 0;

  /*member: LegacyClass2.getter:int**/
  get getter => 0;
}

/*class: LegacyClass3:Class,LegacyClass1,LegacyClass3,Object*/
class LegacyClass3 extends LegacyClass1 {
  /*member: LegacyClass3.method:int* Function()**/
  method() => 0;

  /*member: LegacyClass3.getter:int**/
  get getter => 0;
}

/*class: EnvironmentMap:
 EnvironmentMap,Map<String*, String*>,
 MapBase<String*, String*>,
 MapMixin<String*, String*>,
 Object,
 UnmodifiableMapBase<String*, String*>,
 _UnmodifiableMapMixin<String*, String*>
*/
class EnvironmentMap extends UnmodifiableMapBase<String, String> {
  /*member: EnvironmentMap.keys:Iterable<String*>**/
  get keys => null;
}
