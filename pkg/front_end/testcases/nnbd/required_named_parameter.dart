// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Should be a compile-time error / warning.
foo({required int parameter = 42}) {}
foo2({int parameter}) {}
foo3([int parameter]) {}

// Should be ok.
bar({required int parameter}) {}
bar2({int parameter = 42}) {}
bar3([int parameter = 42]) {}

main() {}
