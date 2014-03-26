// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for specifying test expectations, such as for unit tests.
 *
 * The matcher library provides a third-generation assertion mechanism, drawing
 * inspiration from [Hamcrest](http://code.google.com/p/hamcrest/).
 *
 * For more information, see
 * [Unit Testing with Dart]
 * (http://www.dartlang.org/articles/dart-unit-tests/).
 */
library matcher;

import 'dart:async';

import 'src/description.dart';
import 'src/interfaces.dart';

export 'src/description.dart';
export 'src/interfaces.dart';

part 'src/core_matchers.dart';
part 'src/expect.dart';
part 'src/future_matchers.dart';
part 'src/iterable_matchers.dart';
part 'src/map_matchers.dart';
part 'src/numeric_matchers.dart';
part 'src/operator_matchers.dart';
part 'src/string_matchers.dart';
