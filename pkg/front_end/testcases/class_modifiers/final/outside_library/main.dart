// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

final class ExtendsFinalClass extends A {}

final class ImplementsFinalClass implements A {}

final class ImplementsFinalMixin implements M {}

final class MixInFinalMixin with M {}

enum EnumImplementsFinalMixin implements M { x }

enum EnumMixInFinalMixin with M { x }

final mixin MixinOnA on A {}

final mixin MixinOnM on M {}

final mixin MixinOnAM on A, M {}
