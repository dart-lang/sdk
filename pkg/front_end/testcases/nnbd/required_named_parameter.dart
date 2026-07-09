// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo({required int parameter = 42}) {} // error
foo2({int parameter}) {} // error
foo3([int parameter]) {} // error

bar({required int parameter}) {} // ok
bar2({int parameter = 42}) {} // ok
bar3([int parameter = 42]) {} // ok

main() {}
