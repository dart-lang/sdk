// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Opt out of Null Safety:
// @dart = 2.6

import 'type_casts_null_safe_library.dart';

class A<T> {
  @pragma('vm:never-inline')
  asT(arg) => arg as T;

  @pragma('vm:never-inline')
  asBT(arg) => arg as B<T>;
}

class B<T> {}

class C {}

class D extends C {}

newAOfLegacyC() => new A<C>();
newAOfLegacyBOfLegacyC() => new A<B<C>>();
newWOfLegacyC() => new W<C>();
newWOfLegacyBOfLegacyC() => new W<B<C>>();
newXOfLegacyY() => new X<Y>();
