// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'package:flutter/widgets.dart';

import 'migrated.dart';

void nullableContext() async {
  f(contextOrNull);
  await Future<void>.delayed(Duration());
  f(contextOrNull); // OK
}

void topLevel(BuildContext context) async {
  Navigator.of(context).pushNamed('routeName'); // OK

  await Future<void>.delayed(Duration());
  Navigator.of(context).pushNamed('routeName'); // LINT
}
