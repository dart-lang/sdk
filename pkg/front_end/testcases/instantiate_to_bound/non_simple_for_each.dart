// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that an error is reported on all type variables that have a
// raw generic type in their bounds in case this generic type has non-simple
// bounds.

class Hest<TypeX extends Hest<TypeX>> {}

class Fisk<TypeY extends Hest, TypeZ extends Hest> {}

main() {}
