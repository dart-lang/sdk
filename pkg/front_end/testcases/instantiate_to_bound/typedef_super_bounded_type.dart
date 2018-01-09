// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that instantiate to bound produces correct super-bounded
// types from raw typedef types that refer to F-bounded typedefs.

typedef A<T>(T p);

typedef B<S extends A<S>>(S p);

B b;

main() {}
