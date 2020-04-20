// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that same generic type passed as a type argument to itself
// doesn't cause issues in the mechanism for detection of non-simple bounds.

class Hest<TypeX> {}

class Fisk<TypeY extends Hest<Hest<Object>>> {}

main() {}
