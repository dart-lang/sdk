// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/

import 'opt_in.dart';

/*class: LegacyClass:Class,LegacyClass,Object*/
class LegacyClass extends Class {
  /*member: LegacyClass.method:int* Function(int*)**/
}

/*class: LegacyInterface:Interface,LegacyInterface,Object*/
abstract class LegacyInterface implements Interface {
  /*member: LegacyInterface.method:int* Function(int*)**/
}

/*class: LegacySubClass:Class,Interface,LegacyClass,LegacyInterface,LegacySubClass,Object*/
class LegacySubClass extends LegacyClass implements LegacyInterface {
  /*member: LegacySubClass.method:int* Function(int*)**/
}

/*class: LegacyClass2:Class2,Interface,LegacyClass2,Object*/
abstract class LegacyClass2 extends Class2 {
  /*member: LegacyClass2.method:int* Function(int*)**/
}
