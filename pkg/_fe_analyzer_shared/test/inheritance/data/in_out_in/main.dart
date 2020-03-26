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
  /*member: SubClass2.method:int? Function(int)*/
}

/*class: GenericSubClass1a:GenericClass1,GenericInterface<int?>,GenericLegacyClass1a,GenericSubClass1a,Object*/
/*analyzer.error: CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES*/ abstract class GenericSubClass1a
    extends GenericLegacyClass1a implements GenericInterface<int?> {
  /*member: GenericSubClass1a.method:int? Function(int?)*/
}

/*class: GenericSubClass1b:GenericClass1,GenericInterface<int?>,GenericLegacyClass1b,GenericSubClass1b,Object*/
/*analyzer.error: CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES*/ abstract class GenericSubClass1b
    extends GenericLegacyClass1b implements GenericInterface<int?> {
  /*member: GenericSubClass1b.method:int? Function(int?)*/
}

/*class: GenericSubClass2a:GenericClass2,GenericInterface<int>,GenericLegacyClass2a,GenericSubClass2a,Object*/
/*analyzer.error: CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES*/ abstract class GenericSubClass2a
    extends GenericLegacyClass2a implements GenericInterface<int> {
  /*member: GenericSubClass2a.method:int Function(int)*/
}

/*class: GenericSubClass2b:GenericClass2,GenericInterface<int>,GenericLegacyClass2b,GenericSubClass2b,Object*/
/*analyzer.error: CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES*/ abstract class GenericSubClass2b
    extends GenericLegacyClass2b implements GenericInterface<int> {
  /*member: GenericSubClass2b.method:int Function(int)*/
}
