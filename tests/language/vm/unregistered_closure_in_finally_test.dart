// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--no-background-compilation

@pragma('vm:never-inline')
doSomething() {
  print("Hello!");
}

@pragma('vm:never-inline')
maybeThrow(bool doThrow) {
  if (doThrow) {
    throw new Exception();
  }
}

@pragma('vm:never-inline')
run(action) {
  try { action(); } catch(e) {}
}

test(bool doThrow) {
  try {
    maybeThrow(doThrow);
  } finally {
    run(() {
      doSomething();  // Should not crash here.
    });
  }
}

main() {
  try { test(true); } catch(e) {}
  try { test(false); } catch(e) {}
}
