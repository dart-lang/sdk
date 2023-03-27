// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

final class ExtendsFinalClass extends A {}

final class ImplementsFinalClass implements A {}

enum EnumImplementsFinalMixin implements A { x }

base mixin MixinOnA on A {}

base mixin MixinOnAB on A, B {}
