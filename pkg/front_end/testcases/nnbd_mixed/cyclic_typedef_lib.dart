// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from
// instantiate_to_bound/non_simple_class_parameterized_typedef_cycle

import 'cyclic_typedef.dart';

class Hest1<TypeX extends Fisk1> {}

typedef Fisk2 = void Function<TypeY extends Hest2>();
