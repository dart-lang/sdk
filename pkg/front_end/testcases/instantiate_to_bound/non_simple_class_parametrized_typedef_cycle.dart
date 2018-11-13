// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the cyclic non-simplicity issues are detected in case
// when both class declaration and a parametrized typedef participate in the
// cycle.

class Hest<TypeX extends Fisk> {}

typedef Fisk = void Function<TypeY extends Hest>();

main() {}
