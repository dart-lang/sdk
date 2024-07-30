// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that formals named `_` in function types don't use the non-binding type
// parameter `_`.

// SharedOptions=--enable-experiment=wildcard-variables

void genericFunction<_ extends void Function<_>(_, _), _>() {}
//                                              ^
// [analyzer] unspecified
// [cfe] unspecified
