// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.5

/*library: nnbd=false*/

import 'opt_in.dart';

/*class: LegacyClass1:Class1,LegacyClass1,Object*/
class LegacyClass1 extends Class1 {}

/*class: LegacyClass2:Class2<T*>,LegacyClass2<T*>,Object*/
class LegacyClass2<T> extends Class2<T> {}

/*class: LegacyClass3a:
 Class3<T*>,
 GenericInterface<T*>,
 LegacyClass3a<T*>,
 Object
*/
class LegacyClass3a<T> extends Class3<T> {}

/*class: LegacyClass3b:
 Class3<T*>,
 GenericInterface<T*>,
 LegacyClass3b<T*>,
 Object
*/
class LegacyClass3b<T> extends Class3<T> implements GenericInterface<T> {}

/*cfe.class: LegacyClass4a:Class4a,GenericInterface<num*>,LegacyClass4a,Object*/
/*cfe:builder|analyzer.class: LegacyClass4a:Class4a,GenericInterface<num>,LegacyClass4a,Object*/
class LegacyClass4a extends Class4a {}

/*class: LegacyClass4b:GenericInterface<num*>,LegacyClass4b,Object*/
class LegacyClass4b implements GenericInterface<num> {}

/*class: LegacyClass4c:Class4a,GenericInterface<num*>,LegacyClass4c,Object*/
class LegacyClass4c extends Class4a implements GenericInterface<num> {}

/*cfe|cfe:builder.class: LegacyClass4d:Class4a,Class4b,GenericInterface<num*>,LegacyClass4d,Object*/
/*analyzer.class: LegacyClass4d:Class4a,Class4b,GenericInterface<num>,LegacyClass4d,Object*/
class LegacyClass4d implements Class4a, Class4b {}

/*cfe|cfe:builder.class: LegacyClass5:Class5,GenericInterface<dynamic>,LegacyClass5,Object*/
/*analyzer.class: LegacyClass5:Class5,GenericInterface<Object*>,LegacyClass5,Object*/
/*analyzer.error: CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES*/
class
/*cfe|cfe:builder.error: AmbiguousSupertypes*/
    LegacyClass5 extends Class5 implements GenericInterface<Object> {}

/*class: LegacyClass6a:
 Class3<T*>,
 GenericInterface<T*>,
 GenericSubInterface<T*>,
 LegacyClass6a<T*>,
 Object
*/
class LegacyClass6a<T> extends Class3<T> implements GenericSubInterface<T> {}

/*class: LegacyClass6b:
 Class3<T*>,
 GenericInterface<T*>,
 GenericSubInterface<T*>,
 LegacyClass3a<T*>,
 LegacyClass6b<T*>,
 Object
*/
class LegacyClass6b<T> extends LegacyClass3a<T>
    implements GenericSubInterface<T> {}
