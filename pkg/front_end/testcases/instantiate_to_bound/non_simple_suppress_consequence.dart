// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that in the case of an error on a class related to
// non-simple bounds, the implied errors on other classes that reference the
// erroneous one in the bounds of their type variables is not reported.

class Hest<TypeX extends Hest<TypeX>> {}

class Fisk<TypeY extends Hest> {}

class Naebdyr<TypeZ extends Fisk> {}

main() {}
