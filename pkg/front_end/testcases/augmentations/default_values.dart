// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int topLevelMethod1a([int x]);
augment int topLevelMethod1a([int x = 0]) => x;

int topLevelMethod1b([int x = 0]);
augment int topLevelMethod1b([int x]) => x;

int topLevelMethod1c([int x]);
augment int topLevelMethod1c([int x]) => x;
augment int topLevelMethod1c([int x = 0]);

int topLevelMethod1d([int x]);
augment int topLevelMethod1d([int x = 0]);
augment int topLevelMethod1d([int x]) => x;

int topLevelMethod1e([int x = 0]);
augment int topLevelMethod1e([int x = 0]) => x; // Error

int topLevelMethod1f([int x]);
augment int topLevelMethod1f([int x]) => x; // Error

int topLevelMethod2a([int x, int y]);
augment int topLevelMethod2a([int x = 0, int y = 0]) => x + y;

int topLevelMethod2b([int x = 0, int y = 0]);
augment int topLevelMethod2b([int x, int y]) => x + y;

int topLevelMethod2c([int x = 0, int y]);
augment int topLevelMethod2c([int x, int y = 0]) => x + y;

class Class {
  final int result;

  new([this.result = -1]);

  new generative1a([int x]);
  augment new generative1a([int x = 0]) : result = x;

  new generative1b([int x = 0]);
  augment new generative1b([int x]) : result = x;

  new generative1c([int x]);
  augment new generative1c([int x]) : result = x;
  augment new generative1c([int x = 0]);

  new generative1d([int x]);
  augment new generative1d([int x = 0]);
  augment new generative1d([int x]) : result = x;

  new generative1e([int x = 0]);
  augment new generative1e([int x = 0]) : result = x; // Error

  new generative1f([int x]);
  augment new generative1f([int x]) : result = x; // Error

  new generative2a([int x, int y]);
  augment new generative2a([int x = 0, int y = 0]) : result = x + y;

  new generative2b([int x = 0, int y = 0]);
  augment new generative2b([int x, int y]) : result = x + y;

  new generative2c([int x = 0, int y]);
  augment new generative2c([int x, int y = 0]) : result = x + y;
  
  int instanceMethod1a([int x]);
  augment int instanceMethod1a([int x = 0]) => x;

  int instanceMethod1b([int x = 0]);
  augment int instanceMethod1b([int x]) => x;

  int instanceMethod1c([int x]);
  augment int instanceMethod1c([int x]) => x;
  augment int instanceMethod1c([int x = 0]);

  int instanceMethod1d([int x]);
  augment int instanceMethod1d([int x = 0]);
  augment int instanceMethod1d([int x]) => x;

  int instanceMethod1e([int x = 0]);
  augment int instanceMethod1e([int x = 0]) => x; // Error

  int instanceMethod1f([int x]);
  augment int instanceMethod1f([int x]) => x; // Error

  int instanceMethod2a([int x, int y]);
  augment int instanceMethod2a([int x = 0, int y = 0]) => x + y;

  int instanceMethod2b([int x = 0, int y = 0]);
  augment int instanceMethod2b([int x, int y]) => x + y;

  int instanceMethod2c([int x = 0, int y]);
  augment int instanceMethod2c([int x, int y = 0]) => x + y;

  static int staticMethod1a([int x]);
  augment static int staticMethod1a([int x = 0]) => x;

  static int staticMethod1b([int x = 0]);
  augment static int staticMethod1b([int x]) => x;

  static int staticMethod1c([int x]);
  augment static int staticMethod1c([int x]) => x;
  augment static int staticMethod1c([int x = 0]);

  static int staticMethod1d([int x]);
  augment static int staticMethod1d([int x = 0]);
  augment static int staticMethod1d([int x]) => x;

  static int staticMethod1e([int x = 0]);
  augment static int staticMethod1e([int x = 0]) => x; // Error

  static int staticMethod1f([int x]);
  augment static int staticMethod1f([int x]) => x; // Error

  static int staticMethod2a([int x, int y]);
  augment static int staticMethod2a([int x = 0, int y = 0]) => x + y;

  static int staticMethod2b([int x = 0, int y = 0]);
  augment static int staticMethod2b([int x, int y]) => x + y;

  static int staticMethod2c([int x = 0, int y]);
  augment static int staticMethod2c([int x, int y = 0]) => x + y;
}

main() {
  expect(0, topLevelMethod1a());
  expect(1, topLevelMethod1a(1));
  expect(0, topLevelMethod1b());
  expect(1, topLevelMethod1b(1));
  expect(0, topLevelMethod1c());
  expect(1, topLevelMethod1c(1));
  expect(0, topLevelMethod1d());
  expect(1, topLevelMethod1d(1));

  expect(0, topLevelMethod2a());
  expect(3, topLevelMethod2a(1, 2));
  expect(0, topLevelMethod2b());
  expect(3, topLevelMethod2b(1, 2));
  expect(0, topLevelMethod2c());
  expect(3, topLevelMethod2c(1, 2));

  expect(0, Class.generative1a().result);
  expect(1, Class.generative1a(1).result);
  expect(0, Class.generative1b().result);
  expect(1, Class.generative1b(1).result);
  expect(0, Class.generative1c().result);
  expect(1, Class.generative1c(1).result);
  expect(0, Class.generative1d().result);
  expect(1, Class.generative1d(1).result);

  expect(0, Class.generative2a().result);
  expect(3, Class.generative2a(1, 2).result);
  expect(0, Class.generative2b().result);
  expect(3, Class.generative2b(1, 2).result);
  expect(0, Class.generative2c().result);
  expect(3, Class.generative2c(1, 2).result);

  var c = Class();
  expect(0, c.instanceMethod1a());
  expect(1, c.instanceMethod1a(1));
  expect(0, c.instanceMethod1b());
  expect(1, c.instanceMethod1b(1));
  expect(0, c.instanceMethod1c());
  expect(1, c.instanceMethod1c(1));
  expect(0, c.instanceMethod1d());
  expect(1, c.instanceMethod1d(1));

  expect(0, c.instanceMethod2a());
  expect(3, c.instanceMethod2a(1, 2));
  expect(0, c.instanceMethod2b());
  expect(3, c.instanceMethod2b(1, 2));
  expect(0, c.instanceMethod2c());
  expect(3, c.instanceMethod2c(1, 2));
  
  expect(0, Class.staticMethod1a());
  expect(1, Class.staticMethod1a(1));
  expect(0, Class.staticMethod1b());
  expect(1, Class.staticMethod1b(1));
  expect(0, Class.staticMethod1c());
  expect(1, Class.staticMethod1c(1));
  expect(0, Class.staticMethod1d());
  expect(1, Class.staticMethod1d(1));

  expect(0, Class.staticMethod2a());
  expect(3, Class.staticMethod2a(1, 2));
  expect(0, Class.staticMethod2b());
  expect(3, Class.staticMethod2b(1, 2));
  expect(0, Class.staticMethod2c());
  expect(3, Class.staticMethod2c(1, 2));
}


expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual.';
}