// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.5

/*library: nnbd=false*/

/*class: GenericInterface:GenericInterface<T*>,Object*/
abstract class GenericInterface<T> {}

/*class: LegacyClass1:LegacyClass1,Object*/
class LegacyClass1 {}

/*class: LegacyClass2:LegacyClass2<T*>,Object*/
class LegacyClass2<T> {}

/*class: LegacyClass3:GenericInterface<T*>,LegacyClass3<T*>,Object*/
class LegacyClass3<T> implements GenericInterface<T> {}

/*class: LegacyClass4:GenericInterface<num*>,LegacyClass4,Object*/
class LegacyClass4 implements GenericInterface<num> {}
