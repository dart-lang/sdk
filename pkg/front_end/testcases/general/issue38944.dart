// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin A<Q> {}

class B<X> extends Object with A<void Function<Y extends X>()> {}
