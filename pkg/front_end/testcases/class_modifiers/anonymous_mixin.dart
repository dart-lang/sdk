// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

base mixin M1 {}
base mixin M2 {}

base class S {}

final class C extends S with M1, M2 {}

final class D = S with M1, M2;
