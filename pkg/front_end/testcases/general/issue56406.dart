// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A { A(); }
class B1 { B1(super.foo); }
class B2 { B2({super.foo}); }
class B3 { B3(super.foo, {super.bar}); }
class B4 { B4(super.foo, super.bar); }
class B5 { B5({super.foo, super.bar}); }
