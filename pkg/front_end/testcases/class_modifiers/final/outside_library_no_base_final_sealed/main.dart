// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

class ExtendsFinalClass extends A {} /* Error */

class ImplementsFinalClass implements A {} /* Error */

class ImplementsFinalMixin implements M {} /* Error */

class MixInFinalMixin with M {} /* Error */

mixin MixinOnA on A {} /* Error */

mixin MixinOnM on M {} /* Error */

mixin MixinOnAM on A, M {} /* Error */
