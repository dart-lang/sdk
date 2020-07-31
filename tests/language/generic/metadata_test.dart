// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that annotations cannot use type arguments, but can be raw.

class C<T> {
  const C();
}

@C()
@C<dynamic>()
//^
// [analyzer] SYNTACTIC_ERROR.ANNOTATION_WITH_TYPE_ARGUMENTS
// [cfe] An annotation (metadata) can't use type arguments.
@C<int>()
//^
// [analyzer] SYNTACTIC_ERROR.ANNOTATION_WITH_TYPE_ARGUMENTS
// [cfe] An annotation (metadata) can't use type arguments.
main() {}
