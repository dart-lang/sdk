// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
import 'infer_types_on_generic_instantiations_in_library_cycle.dart';

abstract class I<E> {
  A<E> m(a, String f(v, int e));
}

main() {}
