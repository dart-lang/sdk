// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for static warnings for member access on classes with @proxy annotation.

import 'dart:core' as core;

class Fake {
  const Fake();
}

const proxy = const Fake();

@proxy
class WrongProxy {}

@core.proxy
class PrefixProxy {}

main() {
  try { new WrongProxy().foo; } catch (e) {}  /// 01: static type warning
  try { new WrongProxy().foo(); } catch (e) {}  /// 02: static type warning

  try { new PrefixProxy().foo; } catch (e) {} /// 03: ok
  try { new PrefixProxy().foo(); } catch (e) {} /// 04: ok
}
