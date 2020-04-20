// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See http://dartbug.com/34511 for details.

class A<X> {}

class B<Z> extends Object with A<Z Function()> {}

main() {}
