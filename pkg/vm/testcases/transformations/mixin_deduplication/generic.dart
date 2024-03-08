// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class B1 {}

mixin M1<T> {}

class SA1<T> extends B1 with M1<T> {}

class SA2<T> extends B1 with M1<T> {}

class SA3<T> extends B1 with M1<T?> {}

class B2<T> {}

mixin M2 {}

class SB1<T> extends B2<T> with M2 {}

class SB2<T> extends B2<T> with M2 {}

class SB3<T> extends B2<T?> with M2 {}

class B3<T> {}

mixin M3 {}

class SC1<T extends Object> extends B3<T> with M2 {}

class SC2<T extends Object> extends B3<T> with M2 {}

class SC3<T extends Object?> extends B3<T> with M2 {}

main() {}
