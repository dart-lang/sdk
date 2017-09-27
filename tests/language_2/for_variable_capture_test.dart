// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

run(callback) => callback();

initializer() {
  var closure;
  for (var i = 0, fn = () => i; i < 3; i++) {
    i += 1;
    closure = fn;
  }
  Expect.equals(1, closure());
}

condition() {
  var closures = [];
  check(callback) {
    closures.add(callback);
    return callback();
  }

  var values = [];
  for (var i = 0; check(() => ++i) < 8; ++i) {
    values.add(i);
  }
  Expect.listEquals([1, 3, 5, 7], values);
  Expect.listEquals([2, 4, 6, 8, 10], closures.map(run).toList());
}

body() {
  var closures = [];
  for (var i = 0, j = 0; i < 3; i++) {
    j++;
    closures.add(() => i);
    closures.add(() => j);
  }
  Expect.listEquals([0, 1, 1, 2, 2, 3], closures.map(run).toList());
}

update() {
  var closures = [];
  check(callback) {
    closures.add(callback);
    return callback();
  }

  var values = [];
  for (var i = 0; i < 4; check(() => ++i)) {
    values.add(i);
  }
  Expect.listEquals([0, 1, 2, 3], values);
  Expect.listEquals([2, 3, 4, 5], closures.map(run).toList());
}

initializer_condition() {
  var values = [];
  for (var i = 0, fn = () => i; run(() => ++i) < 3;) {
    values.add(i);
    values.add(fn());
  }
  Expect.listEquals([1, 1, 2, 1], values);
}

initializer_update() {
  var update_closures = [];
  update(callback) {
    update_closures.add(callback);
    return callback();
  }

  var init_closure;
  for (var i = 0, fn = () => i; i < 4; update(() => ++i)) {
    init_closure = fn;
    if (i == 0) {
      ++i; // Mutate copy of 'i' from first iteration.
    }
  }
  Expect.equals(1, init_closure());
  Expect.listEquals([3, 4, 5], update_closures.map(run).toList());
  Expect.equals(1, init_closure());
}

initializer_body() {
  var closures = [];
  for (var i = 0, fn = () => i; i < 3; i++) {
    closures.add(() => i);
    closures.add(fn);
    fn = () => i;
  }
  Expect.listEquals([0, 0, 1, 0, 2, 1], closures.map(run).toList());
}

condition_update() {
  var cond_closures = [];
  check(callback) {
    cond_closures.add(callback);
    return callback();
  }

  var update_closures = [];
  update(callback) {
    update_closures.add(callback);
    return callback();
  }

  var values = [];
  for (var i = 0; check(() => i) < 4; update(() => ++i)) {
    values.add(i);
  }
  Expect.listEquals([0, 1, 2, 3], values);

  Expect.listEquals([0, 1, 2, 3, 4], cond_closures.map(run).toList());
  Expect.listEquals([2, 3, 4, 5], update_closures.map(run).toList());
  Expect.listEquals([0, 2, 3, 4, 5], cond_closures.map(run).toList());
}

condition_body() {
  var cond_closures = [];
  check(callback) {
    cond_closures.add(callback);
    return callback();
  }

  var body_closures = [];
  do_body(callback) {
    body_closures.add(callback);
    return callback();
  }

  for (var i = 0; check(() => i) < 4; ++i) {
    do_body(() => i);
  }
  Expect.listEquals([0, 1, 2, 3, 4], cond_closures.map(run).toList());
  Expect.listEquals([0, 1, 2, 3], body_closures.map(run).toList());
}

initializer_condition_update() {
  var init;
  var cond_closures = [];
  check(callback) {
    cond_closures.add(callback);
    return callback();
  }

  var update_closures = [];
  update(callback) {
    update_closures.add(callback);
    return callback();
  }

  var values = [];
  for (var i = 0, fn = () => i; check(() => ++i) < 8; update(() => ++i)) {
    init = fn;
    values.add(i);
  }
  Expect.listEquals([1, 3, 5, 7], values);
  Expect.equals(1, init());

  Expect.listEquals([2, 4, 6, 8, 10], cond_closures.map(run).toList());
  Expect.listEquals([5, 7, 9, 11], update_closures.map(run).toList());
}

initializer_condition_body() {
  var init;
  var cond_closures = [];
  check(callback) {
    cond_closures.add(callback);
    return callback();
  }

  var body_closures = [];
  do_body(callback) {
    body_closures.add(callback);
    return callback();
  }

  var values = [];
  for (var i = 0, fn = () => i; check(() => ++i) < 8;) {
    init = fn;
    do_body(() => ++i);
    values.add(i);
  }
  Expect.listEquals([2, 4, 6, 8], values);
  Expect.equals(2, init());

  Expect.listEquals([3, 5, 7, 9, 10], cond_closures.map(run).toList());
  Expect.listEquals([4, 6, 8, 10], body_closures.map(run).toList());
}

initializer_update_body() {
  var init;
  var update_closures = [];
  update(callback) {
    update_closures.add(callback);
    return callback();
  }

  var body_closures = [];
  do_body(callback) {
    body_closures.add(callback);
    return callback();
  }

  var values = [];
  for (var i = 0, fn = () => i; i < 8; update(() => ++i)) {
    init = fn;
    do_body(() => ++i);
    values.add(i);
  }
  Expect.listEquals([1, 3, 5, 7], values);
  Expect.equals(1, init());

  Expect.listEquals([4, 6, 8, 9], update_closures.map(run).toList());
  Expect.listEquals([2, 5, 7, 9], body_closures.map(run).toList());
}

condition_update_body() {
  var cond_closures = [];
  check(callback) {
    cond_closures.add(callback);
    return callback();
  }

  var update_closures = [];
  update(callback) {
    update_closures.add(callback);
    return callback();
  }

  var body_closures = [];
  do_body(callback) {
    body_closures.add(callback);
    return callback();
  }

  var values = [];
  for (var i = 0; check(() => i) < 8; update(() => ++i)) {
    do_body(() => ++i);
    values.add(i);
  }
  Expect.listEquals([1, 3, 5, 7], values);

  Expect.listEquals([1, 3, 5, 7, 8], cond_closures.map(run).toList());
  Expect.listEquals([4, 6, 8, 9], update_closures.map(run).toList());
  Expect.listEquals([2, 5, 7, 9], body_closures.map(run).toList());
  Expect.listEquals([2, 5, 7, 9, 9], cond_closures.map(run).toList());
}

initializer_condition_update_body() {
  var init;
  var cond_closures = [];
  check(callback) {
    cond_closures.add(callback);
    return callback();
  }

  var update_closures = [];
  update(callback) {
    update_closures.add(callback);
    return callback();
  }

  var body_closures = [];
  do_body(callback) {
    body_closures.add(callback);
    return callback();
  }

  var values = [];
  for (var i = 0, fn = () => i; check(() => i) < 8; update(() => ++i)) {
    init = fn;
    do_body(() => ++i);
    values.add(i);
  }
  Expect.listEquals([1, 3, 5, 7], values);
  Expect.equals(1, init());

  Expect.listEquals([1, 3, 5, 7, 8], cond_closures.map(run).toList());
  Expect.listEquals([4, 6, 8, 9], update_closures.map(run).toList());
  Expect.listEquals([2, 5, 7, 9], body_closures.map(run).toList());
  Expect.listEquals([2, 5, 7, 9, 9], cond_closures.map(run).toList());
}

main() {
  initializer();
  condition();
  update();
  body();
  initializer_condition();
  initializer_update();
  initializer_body();
  condition_update();
  condition_body();
  initializer_condition_update();
  initializer_condition_body();
  initializer_update_body();
  condition_update_body();
  initializer_condition_update_body();
}
