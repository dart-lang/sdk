// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

var x = () => y;
//  ^
// [analyzer] COMPILE_TIME_ERROR.TOP_LEVEL_CYCLE
// [cfe] Can't infer the type of 'x': circularity found during type inference.
var y = () => x;
//  ^
// [analyzer] COMPILE_TIME_ERROR.TOP_LEVEL_CYCLE

void main() {
  x;
  y;
}
