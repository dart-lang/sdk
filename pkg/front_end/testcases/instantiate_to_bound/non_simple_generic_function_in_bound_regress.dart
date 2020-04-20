// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the use of generic function types in the bound of a
// type variable is detected early and doesn't cause issues to the mechanism for
// detection of non-simple bounds.

class Hest<TypeX extends Hest<TypeX>> {}

class Fisk<TypeY extends Function<TypeZ extends Hest<Null>>(TypeZ)> {}

main() {}
