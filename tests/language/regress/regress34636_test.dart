// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class /*@compile-error=unspecified*/ A<X extends B> {}

class /*@compile-error=unspecified*/ B<X extends C> {}

class /*@compile-error=unspecified*/ C<X extends A<B>> {}

main() {}
