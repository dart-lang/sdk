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

/*cfe|cfe:builder.class: GenericLegacyClass1a:GenericClass1,GenericInterface<int*>,GenericLegacyClass1a,Object*/
/*analyzer.class: GenericLegacyClass1a:GenericClass1,GenericInterface<int>,GenericLegacyClass1a,Object*/
abstract class GenericLegacyClass1a extends GenericClass1 {
  /*cfe|cfe:builder.member: GenericLegacyClass1a.method:int* Function(int*)*/
  /*analyzer.member: GenericLegacyClass1a.method:int* Function(int*)**/
}

/*class: GenericLegacyClass1b:GenericClass1,GenericInterface<int*>,GenericLegacyClass1b,Object*/
abstract class GenericLegacyClass1b extends GenericClass1
    implements GenericInterface<int> {
  /*cfe|cfe:builder.member: GenericLegacyClass1b.method:int* Function(int*)*/
  /*analyzer.member: GenericLegacyClass1b.method:int* Function(int*)**/
}

/*cfe|cfe:builder.class: GenericLegacyClass2a:GenericClass2,GenericInterface<int*>,GenericLegacyClass2a,Object*/
/*analyzer.class: GenericLegacyClass2a:GenericClass2,GenericInterface<int?>,GenericLegacyClass2a,Object*/
abstract class GenericLegacyClass2a extends GenericClass2 {
  /*cfe|cfe:builder.member: GenericLegacyClass2a.method:int* Function(int*)*/
  /*analyzer.member: GenericLegacyClass2a.method:int* Function(int*)**/
}

/*class: GenericLegacyClass2b:GenericClass2,GenericInterface<int*>,GenericLegacyClass2b,Object*/
abstract class GenericLegacyClass2b extends GenericClass2
    implements GenericInterface<int> {
  /*cfe|cfe:builder.member: GenericLegacyClass2b.method:int* Function(int*)*/
  /*analyzer.member: GenericLegacyClass2b.method:int* Function(int*)**/
}
