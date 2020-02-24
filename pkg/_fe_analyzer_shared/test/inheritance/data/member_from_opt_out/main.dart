// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import 'opt_out.dart';

/*class: Interface:Interface,Object*/
abstract class Interface {
  /*member: Interface.method:int Function(int?)*/
  int method(int? i) => i ?? 0;
}

/*class: Class:Class,Interface,LegacyClass,Object*/
abstract class Class extends LegacyClass implements Interface {
  /*cfe|cfe:builder.member: Class.method:int Function(int?)*/
  /*analyzer.member: Class.method:int* Function(int*)**/
}
