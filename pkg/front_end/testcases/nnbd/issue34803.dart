// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.13

class A<X extends G<num>> {}
typedef G<X> = void Function<Y extends X>();

main() {}
