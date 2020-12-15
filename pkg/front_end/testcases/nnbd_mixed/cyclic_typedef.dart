// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from
// instantiate_to_bound/non_simple_class_parameterized_typedef_cycle

import 'cyclic_typedef_lib.dart';

class Hest2<TypeX extends Fisk2> {}

typedef Fisk1 = void Function<TypeY extends Hest1>();

main() {}
