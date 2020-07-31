// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

defaultArg1() => 1;
defaultArg2() => 2;
myFunction1({argumentName1: defaultArg1, argumentName2: defaultArg2}) =>
    "${argumentName1()} - ${argumentName2()}";
