// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:expect/expect.dart';

String log = 'uninitialized';

class Throwing extends Iterable<int> {
  final String path;
  Throwing(this.path) {
    log += '[$path]';
  }
  Iterator<int> get iterator => throw 'iterator@$path';

  // The following ensure these methods are not used to implement `yield*`.
  int get length => throw 'length';
  int elementAt(int i) => throw 'elementAt';
  void forEach(void Function(int) action) => throw 'forEach';
}

Iterable<int> f1(String path) sync* {
  final here = '$path.f1';
  yield* Throwing('$here.a');
  yield* Throwing('$here.b');
  log += '[f1.done]';
}

Iterable<int> f2(String path) sync* {
  final here = '$path.f2';
  try {
    final p = f1('$here.p');
    log += '[$here.p.y*1]';
    yield* p;
    log += '[$here.p.y*2]';

    yield* f1('$here.q');
  } catch (e) {
    log += '[$here.catch:$e]';
  }
  yield 100;
  log += '[$here.done]';
}

Iterable<int> f3(String path) sync* {
  final here = '$path.f3';
  try {
    yield* Throwing('$here.f');
    yield* Throwing('$here.g');
  } catch (e) {
    log += '[$here.catch:$e]';
  }
  log += '[$here.done]';
}

Iterable<int> f4(String path) sync* {
  final here = '$path.f4';
  try {
    final s = f3('$here.s');
    log += '[$here.s.y*1]';
    yield* s;
    log += '[$here.s.y*2]';

    yield* f3('$here.t');
  } catch (e) {
    log += '[$here.catch:$e]';
  }
  yield 200;
  log += '[$here.done]';
}

main() {
  // The spec dictates that `yield*` calls `iterator` on the operand. This
  // implies that any exception thrown by accessing the iterator should happen
  // as if at the yield* statement.

  {
    log = '';
    final iterator = f1('main').iterator;
    Expect.throws(() => iterator.moveNext());
    Expect.equals('[main.f1.a]', log);
    Expect.isFalse(iterator.moveNext());
    Expect.equals('[main.f1.a]', log);
  }

  {
    log = '';
    final iterator = f2('main').iterator;
    Expect.isTrue(iterator.moveNext());
    Expect.equals(100, iterator.current);
    Expect.equals(
        '[main.f2.p.y*1][main.f2.p.f1.a][main.f2.catch:iterator@main.f2.p.f1.a]',
        log);
    log = '';
    Expect.isFalse(iterator.moveNext());
    Expect.equals('[main.f2.done]', log);
  }

  {
    log = '';
    final iterator = f3('main').iterator;
    Expect.isFalse(iterator.moveNext());
    Expect.equals(
        '[main.f3.f][main.f3.catch:iterator@main.f3.f][main.f3.done]', log);
  }

  {
    log = '';
    final iterator = f4('M').iterator;
    Expect.isTrue(iterator.moveNext());
    Expect.equals(200, iterator.current);
    Expect.equals(
        '[M.f4.s.y*1]'
        '[M.f4.s.f3.f][M.f4.s.f3.catch:iterator@M.f4.s.f3.f][M.f4.s.f3.done]'
        '[M.f4.s.y*2]'
        '[M.f4.t.f3.f][M.f4.t.f3.catch:iterator@M.f4.t.f3.f][M.f4.t.f3.done]',
        log);
    log = '';
    Expect.isFalse(iterator.moveNext());
    Expect.equals('[M.f4.done]', log);
  }
}
