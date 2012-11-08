// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
/**
 * The matcher library provides a 3rd generation assertion mechanism, drawing
 * inspiration from [Hamcrest] and Ladislav Thon's [dart-matchers]
 * library.
 *
 * See [Hamcrest] http://en.wikipedia.org/wiki/Hamcrest
 *     [Hamcrest] http://code.google.com/p/hamcrest/
 *     [dart-matchers] https://github.com/Ladicek/dart-matchers
 */
library matcher;

part 'src/basematcher.dart';
part 'src/collection_matchers.dart';
part 'src/core_matchers.dart';
part 'src/description.dart';
part 'src/expect.dart';
part 'src/future_matchers.dart';
part 'src/interfaces.dart';
part 'src/map_matchers.dart';
part 'src/numeric_matchers.dart';
part 'src/operator_matchers.dart';
part 'src/string_matchers.dart';
