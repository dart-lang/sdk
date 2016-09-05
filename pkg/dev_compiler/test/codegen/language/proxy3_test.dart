// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for static warnings for member access on classes with @proxy annotation.

const isFalse = identical(-0.0, 0);

const validProxy = isFalse ? null : proxy;
const invalidProxy = isFalse ? proxy : null;

@validProxy
class ValidProxy {}

@invalidProxy
class InvalidProxy {}

main() {
  try { new InvalidProxy().foo; } catch (e) {}  /// 01: static type warning
  try { new InvalidProxy().foo(); } catch (e) {}  /// 02: static type warning

  try { new ValidProxy().foo; } catch (e) {} /// 03: ok
  try { new ValidProxy().foo(); } catch (e) {} /// 04: ok
}
