// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X1 extends G<num>> {}
typedef G<X1> = void Function<Y1 extends X1>();

class B<X2 extends H<num>> {}
typedef H<X2> = (void Function<Y2 extends X2>(), int);

class C<X3 extends I<num>> {}
typedef I<X3> = ({void Function<Y3 extends X3>() a, int b});

main() {}
