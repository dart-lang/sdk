// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';

@pragma('vm:entry-point')
void main(List<String>? args) {
  final greetee = args?.singleOrNull ?? 'world';
  print('Hello, $greetee!');
}
