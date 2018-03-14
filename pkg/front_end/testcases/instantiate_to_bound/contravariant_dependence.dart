// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that contravariant occurrences of a type variable in the
// bounds of the other type variables from the same declaration that are not
// being transitively depended on by that variable are replaced with Null.

class C<X extends num, Y extends void Function(X)> {}

C c;

main() {}
