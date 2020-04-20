// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.5

import 'inheritance_from_opt_in_lib.dart';

class LegacyClass1 extends Class1 {}

class LegacyClass2<T> extends Class2<T> {}

class LegacyClass3a<T> extends Class3<T> {}

class LegacyClass3b<T> extends Class3<T> implements GenericInterface<T> {}

class LegacyClass4a extends Class4a {}

class LegacyClass4b implements GenericInterface<num> {}

class LegacyClass4c implements GenericInterface<num?> {}

class LegacyClass4d extends Class4a implements GenericInterface<num> {}

class LegacyClass4e implements Class4a, Class4b {}

class LegacyClass5 extends Class5 implements GenericInterface<Object> {}

class LegacyClass6a<T> extends Class3<T> implements GenericSubInterface<T> {}

class LegacyClass6b<T> extends LegacyClass3a<T>
    implements GenericSubInterface<T> {}
