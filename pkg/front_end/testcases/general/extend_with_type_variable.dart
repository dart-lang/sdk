// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue #39774.

class SuperClass {}

mixin Mixin<T> {}

class Class1<T, S extends SuperClass> extends S with Mixin<T> {}

class Class2<T, M extends Mixin<T>> extends SuperClass with M {}

main() {}
