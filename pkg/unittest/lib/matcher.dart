// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
/**
 * The matcher library provides a 3rd generation assertion mechanism, drawing
 * inspiration from [Hamcrest](http://code.google.com/p/hamcrest/).
 *
 * ## Installing ##
 *
 * Use [pub][] to install this package. Add the following to your `pubspec.yaml`
 * file.
 *
 *     dependencies:
 *       matcher: any
 *
 * Then run `pub install`.
 *
 * For more information, see the
 * [matcher package on pub.dartlang.org][pkg].
 *
 * [pub]: http://pub.dartlang.org
 * [pkg]: http://pub.dartlang.org/packages/matcher
 */
library matcher;

import 'dart:async';

part 'src/basematcher.dart';
part 'src/iterable_matchers.dart';
part 'src/core_matchers.dart';
part 'src/description.dart';
part 'src/expect.dart';
part 'src/future_matchers.dart';
part 'src/interfaces.dart';
part 'src/map_matchers.dart';
part 'src/numeric_matchers.dart';
part 'src/operator_matchers.dart';
part 'src/string_matchers.dart';
