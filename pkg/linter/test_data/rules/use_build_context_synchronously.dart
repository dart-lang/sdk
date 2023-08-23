// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N use_build_context_synchronously`

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

void awaitInSwitchCase(BuildContext context) async {
  await Future<void>.delayed(Duration());
  switch (1) {
    case 1:
      await Navigator.of(context).pushNamed('routeName'); // LINT
      break;
  }
}

void awaitInSwitchCase_mountedCheckBeforeSwitch(BuildContext context) async {
  await Future<void>.delayed(Duration());
  if (!mounted) return;
  switch (1) {
    case 1:
      await Navigator.of(context).pushNamed('routeName'); // OK
      break;
  }
}

bool get mounted => true;

BuildContext? get contextOrNull => null;

class ContextHolder {
  BuildContext? get contextOrNull => null;
}

void f2(BuildContext? contextOrNull) {}

void nullableContext() async {
  f2(contextOrNull);
  await Future<void>.delayed(Duration());
  f2(contextOrNull); // OK
}

void nullableContext2(ContextHolder holder) async {
  f2(holder.contextOrNull);
  await Future<void>.delayed(Duration());
  f2(holder.contextOrNull); // OK
}

void nullableContext3() async {
  f2(contextOrNull);
  await Future<void>.delayed(Duration());
  var renderObject = contextOrNull?.findRenderObject(); // OK
}

void f(BuildContext context) {}

class MyWidget extends StatefulWidget {
  @override
  State createState() => _MyState();
}

void directAccess(BuildContext context) async {
  await Future<void>.delayed(Duration());

  var renderObject = context.findRenderObject(); // LINT
}

class _MyState extends State<MyWidget> {
  // Same as above, but using a conditional path.
  void methodWithBuildContextParameter2(BuildContext context) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await Future<void>.delayed(Duration());
    }
    Navigator.of(context).pushNamed('routeName'); // LINT
  }

  void methodWithBuildContextParameter2g(BuildContext context) async {
    await Future<void>.delayed(Duration());
    switch (1) {
      case 1:
        if (!mounted) return;
        await Navigator.of(context).pushNamed('routeName'); // OK
        break;
    }
  }

  @override
  Widget build(BuildContext context) => Placeholder();
}

void topLevel2(BuildContext context) async {
  Navigator.of(context).pushNamed('routeName'); // OK

  await Future<void>.delayed(Duration());
  // todo (pq): consider other conditionals (for, while, do, ...)
  if (true) {
    Navigator.of(context).pushNamed('routeName'); // LINT
  }
}
