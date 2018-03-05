// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=error*/

class I<X> {}

class M0<T> extends Object implements I<T> {}

class M1<T> extends I<T> {}

// M0 is inferred as M0<dynamic> (unconstrained)
// M1 is inferred as M1<dynamic> (constrained by inferred argument to M0)
// Error since class hierarchy is inconsistent
class /*@error=AmbiguousSupertypes*/ A extends Object
    with M0, M1
    implements I<int> {}

main() {}
