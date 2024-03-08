// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class B1 {}

mixin M1<T> {}

class SA1 extends B1 with M1<int> {}

class SA2 extends B1 with M1<int> {}

class SA3 extends B1 with M1<String> {}

class B2<T> {}

mixin M2 {}

class SB1 extends B2<int> with M2 {}

class SB2 extends B2<int> with M2 {}

class SB3 extends B2<String> with M2 {}

main() {}
