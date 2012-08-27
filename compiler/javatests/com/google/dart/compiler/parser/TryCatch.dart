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
  } catch (e) {
  } finally {
  }
}

b() {
  try {
  } catch (e) {
  }
}

c() {
  try {
  } finally {
  }
}

d() {
  try  {
  } on TestException1 catch (e) {
  } on TestException2 catch (e) {
  }
}

e() {
  try  {
  } on TestException1 catch (e) {
  } on TestException2 catch (e) {
  } finally {
  }
}

