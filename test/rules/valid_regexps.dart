// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N valid_regexps`

RegExp bad = new RegExp('('); //LINT
RegExp good = new RegExp('[(]'); //OK
String interpolated = '';
RegExp skipped = new RegExp('( $interpolated'); //OK -- skipped
