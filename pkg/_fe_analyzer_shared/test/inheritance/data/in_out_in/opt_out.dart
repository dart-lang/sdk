// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/

import 'opt_in.dart';

/*class: LegacyClass1:Class,Interface,LegacyClass1,Object*/
abstract class LegacyClass1 extends Class implements Interface {
  /*member: LegacyClass1.method:int* Function(int*)**/
}

/*class: LegacyClass2:Class,LegacyClass2,Object*/
abstract class LegacyClass2 extends Class {
  /*member: LegacyClass2.method:int* Function(int*)**/
}
