// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib;

class _S {}

class _M {}

class _M2 {}

class MA extends _S with _M {}

class MA2 extends _S with _M, _M2 {}
