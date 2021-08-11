// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final foo = [() => const [], () => bar()];

final foo2 = [(dynamic x) => const [], (Bar x) => const []];

final foo3 = [(List<dynamic> x) => const [], (List<Bar> x) => const []];

final foo4 = [(Function(dynamic) x) => const [], (Function(Bar) x) => const []];

main() {}
