// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

// Tests that it is an error to mix in regular classes from a post 3.0 non-core
// library.

import 'main_lib.dart';

class AWith with A {}

class BWith with B {}

class CWith with C {}

class MultipleWithMixin with A, M {}

class MultipleWithAnotherClass with A, B {}
