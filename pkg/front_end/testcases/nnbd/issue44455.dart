// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef F<Y extends num> = Y Function();
class A<X extends F<X>> {}

class A2<X extends F2<X>> {}
typedef F2<Y extends num> = Y Function();

main() {}
