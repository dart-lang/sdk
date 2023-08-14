// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma('origin-library')
library;

@pragma('origin-class')
class Class<@pragma('origin-class-type-variable') T> {
  @pragma('origin-constructor')
  external Class();

  @pragma('origin-procedure')
  external void method<@pragma('origin-method-type-variable') S>();
}
