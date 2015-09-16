// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for static warnings for member access on classes with @proxy annotation.

class NonProxy {}

@proxy
class Proxy {}

const alias = proxy;

@alias
class AliasProxy {}

main() {
  try { new NonProxy().foo; } catch (e) {} /// 01: static type warning
  try { new NonProxy().foo(); } catch (e) {} /// 02: static type warning

  try { new Proxy().foo; } catch (e) {} /// 03: ok
  try { new Proxy().foo(); } catch (e) {} /// 04: ok

  try { new AliasProxy().foo; } catch (e) {} /// 05: ok
  try { new AliasProxy().foo(); } catch (e) {} /// 06: ok
}