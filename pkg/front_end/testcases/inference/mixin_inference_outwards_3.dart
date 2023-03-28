// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class I<X> {}

mixin class M0<T> extends Object implements I<T> {}

mixin M1<T> on I<T> {}

// M0 is inferred as M0<dynamic>
// Error since class hierarchy is inconsistent
class A extends Object with M0, M1<int> {}

main() {}
