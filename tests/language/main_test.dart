// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main(

a         /// 01: ok
a, b      /// 02: ok
a, b, c   /// 03: static type warning, runtime error
a, b, {c} /// 04: ok
a, b, [c] /// 05: ok

[a]       /// 20: ok
a, [b]    /// 21: ok
[a, b]    /// 22: ok

{a}       /// 41: ok
a, {b}    /// 42: ok
{a, b}    /// 43: ok
[a, b, c] /// 44: ok
{a, b, c} /// 45: ok

) {
}
