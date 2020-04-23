// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.5

abstract class GenericInterface<T> {}

abstract class GenericSubInterface<T> implements GenericInterface<T> {}

class LegacyClass1 {}

class LegacyClass2<T> {}

class LegacyClass3<T> implements GenericInterface<T> {}

class LegacyClass4 implements GenericInterface<num> {}

class LegacyClass5<T> extends LegacyClass3<T> implements GenericInterface<T> {}

class LegacyClass6<T> extends Object
    with LegacyClass3<T>
    implements GenericInterface<T> {}

class LegacyClass7<T> extends LegacyClass3<T>
    implements GenericSubInterface<T> {}

class LegacyClass8<T> extends Object
    with LegacyClass3<T>
    implements GenericSubInterface<T> {}
