// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.5

/*library: nnbd=false*/

/*class: GenericInterface:GenericInterface<T*>,Object*/
abstract class GenericInterface<T> {}

/*class: GenericSubInterface:
 GenericInterface<T*>,
 GenericSubInterface<T*>,
 Object
*/
abstract class GenericSubInterface<T> implements GenericInterface<T> {}

/*class: LegacyClass1:LegacyClass1,Object*/
class LegacyClass1 {}

/*class: LegacyClass2:LegacyClass2<T*>,Object*/
class LegacyClass2<T> {}

/*class: LegacyClass3:GenericInterface<T*>,LegacyClass3<T*>,Object*/
class LegacyClass3<T> implements GenericInterface<T> {}

/*class: LegacyClass4:GenericInterface<num*>,LegacyClass4,Object*/
class LegacyClass4 implements GenericInterface<num> {}

/*class: LegacyClass5:
 GenericInterface<T*>,
 LegacyClass3<T*>,
 LegacyClass5<T*>,
 Object
*/
class LegacyClass5<T> extends LegacyClass3<T> implements GenericInterface<T> {}

/*class: LegacyClass6:GenericInterface<T*>,LegacyClass3<T*>,LegacyClass6<T*>,Object*/
class LegacyClass6<T> extends Object
    with LegacyClass3<T>
    implements GenericInterface<T> {}

/*class: LegacyClass7:
 GenericInterface<T*>,
 GenericSubInterface<T*>,
 LegacyClass3<T*>,
 LegacyClass7<T*>,
 Object
*/
class LegacyClass7<T> extends LegacyClass3<T>
    implements GenericSubInterface<T> {}

/*class: LegacyClass8:GenericInterface<T*>,GenericSubInterface<T*>,LegacyClass3<T*>,LegacyClass8<T*>,Object*/
class LegacyClass8<T> extends Object
    with LegacyClass3<T>
    implements GenericSubInterface<T> {}
