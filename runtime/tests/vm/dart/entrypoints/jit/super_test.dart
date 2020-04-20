// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--enable-testing-pragmas --no-background-compilation --optimization-counter-threshold=5 -Denable_inlining=true --compilation-counter-threshold=5
// VMOptions=--enable-testing-pragmas --no-background-compilation --optimization-counter-threshold=5 --compilation-counter-threshold=5
// VMOptions=--enable-testing-pragmas --no-background-compilation --optimization-counter-threshold=-1 --compilation-counter-threshold=5

import "../super.dart";

main(args) => test(args);
