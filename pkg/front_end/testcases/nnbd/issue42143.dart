// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

void h1<T extends FutureOr<T?>?>(T? t) {}
void h2<S extends FutureOr<S?>>(S? s) {}

main() {}
