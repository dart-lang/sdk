// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

class ImplementsBaseClass implements A {} /* Error */

class ImplementsBaseMixin implements M {} /* Error */

enum EnumImplementsBaseMixin implements M { x } /* Error */

mixin MixinOnA on A {} /* Ok */

mixin MixinOnM on M {} /* Ok */

mixin MixinOnAM on A, M {} /* Ok */
