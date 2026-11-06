// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that TFA does not reuse state of variables between different
// exits from a try/finally block.
// Regression test for b/581840537.

@pragma('vm:never-inline')
Object init(List<String> a) => int.parse(a[0]);

@pragma('vm:never-inline')
bool flag(List<String> a) => a.length > 1;

@pragma('vm:never-inline')
int probe(List<String> a) {
  Object x = init(a);
  L:
  {
    try {
      if (flag(a)) break L;
    } finally {
      print('cleanup');
    }
    x = 'ok';
  }
  return (x as String).length; // Should not be eliminated.
}

void main(List<String> a) {
  print(probe(a));
}
