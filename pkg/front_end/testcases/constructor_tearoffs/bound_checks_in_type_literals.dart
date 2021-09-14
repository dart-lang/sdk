// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T extends num> {}

test() => C<Object>;

test2([Type t = C<Object>]) {}

var test3 = (() => C<Object>)();

main() {}
