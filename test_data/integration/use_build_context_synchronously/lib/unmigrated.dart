// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'package:flutter/foundation.dart';
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

void anonymousFunction(BuildContext context) async {
  final anon = () async {
    await Future<void>.delayed(Duration(seconds: 1));
  };
  await Navigator.of(context).pushNamed('routeName'); // OK
}

void anonymousExpressionFunction(BuildContext context) async {
  final anon = () async => await Future<void>.delayed(Duration());
  await Navigator.of(context).pushNamed('routeName'); // OK
}

void widgetCallbacks(BuildContext context) async {
  final widget = _Button(
    onTap: () async {
      await Future<void>.delayed(Duration());
    },
  );
  // Build complex widget piece by piece...
  f(context); // OK
}

class _Button extends StatelessWidget {
  const _Button({Key key, this.onTap}) : super(key: key);

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}