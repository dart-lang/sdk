// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import 'opt_out.dart';

/*class: Class1:Class1,LegacyClass1,Object*/
class Class1 extends LegacyClass1 {}

/*class: Class2:Class2<T>,LegacyClass2<T>,Object*/
class Class2<T> extends LegacyClass2<T> {}

/*class: Class3a:Class3a<T>,GenericInterface<T*>,LegacyClass3<T>,Object*/
class Class3a<T> extends LegacyClass3<T> {}

/*class: Class3b:Class3b<T>,GenericInterface<T>,LegacyClass3<T>,Object*/
class Class3b<T> extends LegacyClass3<T> implements GenericInterface<T> {}

/*class: Class4a:Class4a,GenericInterface<num*>,LegacyClass4,Object*/
class Class4a extends LegacyClass4 {}

/*class: Class4b:Class4b,GenericInterface<num>,Object*/
class Class4b implements GenericInterface<num> {}

/*class: Class4c:Class4c,GenericInterface<num?>,Object*/
class Class4c implements GenericInterface<num?> {}

/*class: Class4d:Class4d,GenericInterface<num>,LegacyClass4,Object*/
class Class4d extends LegacyClass4 implements GenericInterface<num> {}
