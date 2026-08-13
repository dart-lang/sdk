// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that tracing debugging stacktraces with frames involving an implicit
// instance method (here, _AsyncStarStreamController.runBody which is in the
// stacktrace for _Future._runError when run with --dart-dynamic-modules)
// doesn't crash.

// VMOptions=--stacktrace-filter=_hasError --trace-debugger-stacktrace

Stream<int> foobar() async* {
  yield 1;
  yield 2;
}

Future<void> helper() async {
  await for (var i in foobar()) {
    print(i);
  }
  return;
}

Future<void> main() async {
  await helper();
}
