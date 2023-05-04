// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

base class ImplementsBaseClass implements A {} /* Error */

base class ImplementsBaseMixin implements M {} /* Error */

enum EnumImplementsBaseMixin implements M { x } /* Error */

base mixin MixinOnA on A {} /* Ok */

base mixin MixinOnM on M {} /* Ok */

base mixin MixinOnAM on A, M {} /* Ok */
