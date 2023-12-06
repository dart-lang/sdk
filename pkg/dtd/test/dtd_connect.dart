// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dtd/dtd.dart';

void main() {
  // ignore: unused_local_variable
  final dtdConnection = DartToolingDaemon.connect(
    Uri.parse(
      'wss://127.0.0.1:51906',
    ),
  );
}
