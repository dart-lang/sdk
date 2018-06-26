// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that an error is reported on all raw generic types with
// non-simple bounds used in the bound of the same type variable.

class Hest<TypeX extends Hest<TypeX>> {}

class Fisk<TypeY extends Fisk<TypeY>> {}

class Naebdyr<TypeZ extends Map<Hest, Fisk>> {}

main() {}
