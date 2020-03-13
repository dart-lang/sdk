// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import 'opt_in.dart';
import 'opt_out.dart';

/*class: SubClass1:Class,Interface,LegacyClass1,Object,SubClass1*/
class SubClass1 extends LegacyClass1 {
  /*member: SubClass1.method:int* Function(int*)**/
}

/*class: SubClass2:Class,Interface,LegacyClass2,Object,SubClass2*/
class SubClass2 extends LegacyClass2 implements Interface {
  /*cfe|cfe:builder.member: SubClass2.method:int? Function(int)*/
  /*analyzer.member: SubClass2.method:int* Function(int*)**/
}
