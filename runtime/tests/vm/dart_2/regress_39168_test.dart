// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/39168.
// Verifies that AOT compiler can handle synthetic code without line numbers
// (mixin application in regress_39168_part1.dart).

library regress_39168;

part 'regress_39168_part1.dart';
part 'regress_39168_part2.dart';
