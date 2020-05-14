// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class GenericInterface<T> {}

abstract class GenericSubInterface<T> extends GenericInterface<T> {}

class Class1 {}

class Class2<T> {}

class Class3<T> implements GenericInterface<T> {}

class Class4a implements GenericInterface<num> {}

class Class4b implements GenericInterface<num?> {}

class Class5 implements GenericInterface<dynamic> {}
