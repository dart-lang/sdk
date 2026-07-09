// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test is ensuring that the flag for --async-igoto-threshold is handled.
// - -1 means igoto-based async is disabled.
// - All other values sets the threshold for after how many continuations we
//   used the igoto-based async.

// VMOptions=--async-igoto-threshold=-1
// VMOptions=--async-igoto-threshold=0
// VMOptions=--async-igoto-threshold=1
// VMOptions=--async-igoto-threshold=10
// VMOptions=--async-igoto-threshold=1000

import '../../../../benchmarks/Calls/dart/Calls.dart' as calls;

main() async => calls.main();
