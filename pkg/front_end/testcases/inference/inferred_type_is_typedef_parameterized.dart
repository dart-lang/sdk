// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

typedef T F<T>();
final /*@topType=Map<String, <int>() -> int>*/ x = <String, F<int>>{};
