// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

class ExtendsFinalClass extends A {} /* Error */

class ImplementsFinalClass implements A {} /* Error */

// Produces only a superclass constraint out of library error, and not a
// final or base subtyping error.

mixin MixinOnA on A {} /* Error */

mixin MixinOnAB on A, B {} /* Error */
