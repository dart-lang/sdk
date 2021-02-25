// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'typedef_from_opt_in_lib.dart';

Handler method1() => (Request r) async => new Response();

Typedef method2() => (r) => 0;

main() {}
