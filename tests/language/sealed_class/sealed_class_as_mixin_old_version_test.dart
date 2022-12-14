// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Allow mixing in a sealed class outside of library when the version of the
// library of the class being mixed-in is older than the version that
// `sealed-class` is being shipped in.

import 'sealed_class_as_mixin_old_version_lib.dart';

abstract class OutsideA with Class {}

class OutsideB with Class {}

class OutsideC = Object with Class;

abstract class OutsideD with Class, Mixin {}

class OutsideE with Class, Mixin {}

sealed class OutsideF with Class {}

sealed class OutsideG with Class, Mixin {}

sealed class OutsideH = Object with Class;
