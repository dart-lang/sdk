// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

class ExtendsFinalClass extends A {}

class ImplementsFinalClass implements A {}

class ImplementsFinalMixin implements M {}

class MixInFinalMixin with M {}

enum EnumImplementsFinalMixin implements M { x }

enum EnumMixInFinalMixin with M { x }

mixin MixinOnA on A {}

mixin MixinOnM on M {}

mixin MixinOnAM on A, M {}
