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

void unawaited(Future<void> future) {}

void methodWithBuildContextParameter2f(BuildContext context) async {
  try {
    await Future<void>.delayed(Duration());
    f(context); // LINT
  } on Exception {
    f(context); // TODO: LINT
  }
}

class WidgetStateContext {
  bool get mounted => false;
}

void f(BuildContext context) {}

void func(Function f) {}

class MyWidget extends StatefulWidget {
  @override
  State createState() => _MyState();
}

void directAccess(BuildContext context) async {
  await Future<void>.delayed(Duration());

  var renderObject = context.findRenderObject(); // LINT
}

Future<bool> binaryExpression(BuildContext context) async {
  bool f2(BuildContext context) => true;

  f2(context);

  await Future<void>.delayed(Duration());

  return true || f2(context); // LINT
}

class C {
  BuildContext context;
  C(this.context);
}

class _MyState extends State<MyWidget> {
  void methodUsingStateContext1() async {
    // Uses context from State.
    Navigator.of(context).pushNamed('routeName'); // OK

    await Future<void>.delayed(Duration());

    // Not ok. Used after an async gap without checking mounted.
    Navigator.of(context).pushNamed('routeName'); // LINT
  }

  void methodUsingStateContext2() async {
    // Uses context from State.
    Navigator.of(context).pushNamed('routeName'); // OK

    await Future<void>.delayed(Duration());

    if (!mounted) return;

    // OK. mounted checked first.
    Navigator.of(context).pushNamed('routeName'); // OK
  }

  void methodUsingStateContext2a() async {
    await Future<void>.delayed(Duration());
    if (!mounted) print('oops');

    // Need a return after the mounted check.
    Navigator.of(context).pushNamed('routeName'); // LINT
  }

  void methodUsingStateContext2b() async {
    await Future<void>.delayed(Duration());
    if (!mounted) {
      print('ok');
      return;
    }

    // Mounted check does return.
    Navigator.of(context).pushNamed('routeName'); //OK
  }

  void methodUsingStateContext3() async {
    f(context);

    await Future<void>.delayed(Duration());

    f(context); // LINT
  }

  void methodUsingStateContext4() async {
    void f(BuildContext context) {}

    f(context);

    await Future<void>.delayed(Duration());

    f(context); // LINT
  }

  void methodUsingStateContext5() async {
    C(context);

    await Future<void>.delayed(Duration());

    C(context); // LINT
  }

  void methodUsingStateContext6() async {
    Future<int> f() async => Future.value(10);

    print(await f());

    C(context); // LINT
  }

  // Method given a build context to use.
  void methodWithBuildContextParameter1(BuildContext context) async {
    Navigator.of(context).pushNamed('routeName'); // OK

    await Future<void>.delayed(Duration());
    Navigator.of(context).pushNamed('routeName'); // LINT
  }

  // Same as above, but using a conditional path.
  void methodWithBuildContextParameter2(BuildContext context) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await Future<void>.delayed(Duration());
    }
    Navigator.of(context).pushNamed('routeName'); // LINT
  }

  // Another conditional path.
  void methodWithBuildContextParameter2a(BuildContext context) async {
    bool f() => true;
    while (f()) {
      await Future<void>.delayed(Duration());
    }
    Navigator.of(context).pushNamed('routeName'); // LINT
  }

  // And another.
  void methodWithBuildContextParameter2b(BuildContext context) async {
    for (var i = 0; i < 1; ++i) {
      await Future<void>.delayed(Duration());
    }
    Navigator.of(context).pushNamed('routeName'); // LINT
  }

  // And another.
  void methodWithBuildContextParameter2c(BuildContext context) async {
    for (var i in [1]) {
      await Future<void>.delayed(Duration());
    }
    Navigator.of(context).pushNamed('routeName'); // LINT
  }

  // And another.
  void methodWithBuildContextParameter2d(BuildContext context) async {
    bool f() => true;
    do {
      await Future<void>.delayed(Duration());
    } while (f());
    Navigator.of(context).pushNamed('routeName'); // LINT
  }

  Future<void> methodWithBuildContextParameter2e(BuildContext context) async {
    await Future<void>.delayed(Duration());
    if (!mounted) return;
    unawaited(methodWithBuildContextParameter2e(context)); //OK
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

  void methodWithBuildContextParameter2h(BuildContext context) async {
    try {
      await Future<void>.delayed(Duration());
    } finally {
      // ...
    }

    try {
      // ...
    } on Exception catch (e) {
      if (!mounted) return;
      f(context); // OK
      return;
    }

    if (!mounted) return;
    f(context); // OK
  }

  void methodWithBuildContextParameter2i(BuildContext context) async {
    try {
      await Future<void>.delayed(Duration());
    } finally {
      if (!mounted) return;
    }

    f(context); // OK
  }

  // Mounted checks are deliberately naive.
  void methodWithBuildContextParameter3(BuildContext context) async {
    Navigator.of(context).pushNamed('routeName'); // OK

    await Future<void>.delayed(Duration());

    if (!mounted) return;

    // Mounted doesn't cover provided context but that's by design.
    Navigator.of(context).pushNamed('routeName'); // OK
  }

  void methodWithMountedFieldCheck(
      BuildContext context, WidgetStateContext stateContext) async {
    await Future<void>.delayed(Duration());
    if (!stateContext.mounted) return;
    f(context); // OK
  }

  @override
  Widget build(BuildContext context) => const Placeholder();
}

void topLevel(BuildContext context) async {
  Navigator.of(context).pushNamed('routeName'); // OK

  await Future<void>.delayed(Duration());
  Navigator.of(context).pushNamed('routeName'); // LINT
}

void topLevel2(BuildContext context) async {
  Navigator.of(context).pushNamed('routeName'); // OK

  await Future<void>.delayed(Duration());
  // todo (pq): consider other conditionals (for, while, do, ...)
  if (true) {
    Navigator.of(context).pushNamed('routeName'); // LINT
  }
}

void topLevel3(BuildContext context) async {
  while (true) {
    // OK the first time only!
    Navigator.of(context).pushNamed('routeName'); // TODO: LINT
    await Future<void>.delayed(Duration());
  }
}

void topLevel4(BuildContext context) async {
  Navigator.of(context).pushNamed('routeName');
  await Future<void>.delayed(Duration());
  if (mounted) {
    Navigator.of(context).pushNamed('routeName'); // OK
  }
}

void topLevel5(BuildContext context) async {
  Navigator.of(context).pushNamed('routeName');
  await Future<void>.delayed(Duration());

  switch ('') {
    case 'a':
      if (!mounted) {
        break;
      }
      Navigator.of(context).pushNamed('routeName2'); // OK
      break;
    default: //nothing.
  }
}

void topLevel6(BuildContext context) async {
  Navigator.of(context).pushNamed('route1'); // OK
  if (true) {
    await Future<void>.delayed(Duration());
    return;
  }
  Navigator.of(context).pushNamed('route2'); // OK
}

void topLevel7(BuildContext context) async {
  Navigator.of(context).pushNamed('route1'); // OK
  if (true) {
    await Future<void>.delayed(Duration());
    return;
  } else {
    await Future<void>.delayed(Duration());
    return;
  }
  Navigator.of(context).pushNamed('route2'); // OK
}

void topLevel8(BuildContext context) async {
  Navigator.of(context).pushNamed('route1'); // OK
  if (true) {
    await Future<void>.delayed(Duration());
  } else {
    await Future<void>.delayed(Duration());
    return;
  }
  Navigator.of(context).pushNamed('route2'); // LINT
}

void topLevel9(BuildContext context) async {
  Navigator.of(context).pushNamed('route1'); // OK
  while (true) {
    await Future<void>.delayed(Duration());
    break;
  }
  Navigator.of(context).pushNamed('route2'); // LINT
}

void closure(BuildContext context) async {
  await Future<void>.delayed(Duration());

  // todo (pq): what about closures?
  func(() {
    f(context); // TODO: LINT
  });
}
