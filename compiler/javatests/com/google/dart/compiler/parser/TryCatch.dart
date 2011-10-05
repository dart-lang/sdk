// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface TestException1 {
  int foo();
}

interface TestException2 {
  int bar();
}

a() {
  try {
  } catch (var e) {
  } finally {
  }
}

b() {
  try {
  } catch (var e) {
  }
}

c() {
  try {
  } finally {
  }
}

d() {
  try  {
  } catch (TestException1 e) {
  } catch (TestException2 e) {
  }
}

e() {
  try  {
  } catch (TestException1 e) {
  } catch (TestException2 e) {
  } finally {
  }
}

