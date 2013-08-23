// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Signed 32- and 64-bit integer support.
 *
 * The integer implementations in this library are designed to work
 * identically whether executed on the Dart VM or compiled to JavaScript.
 *
 * For information on installing and importing this library, see the
 * [fixnum package on pub.dartlang.org]
 * (http://pub.dartlang.org/packages/fixnum).
 */
library fixnum;

part 'src/intx.dart';
part 'src/int32.dart';
part 'src/int64.dart';
