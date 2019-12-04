// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

class Class {
  Class field;
  Class method() => field;

  Class operator [](Class key) => field;
  void operator []=(Class key, Class value) {
    field = value;
  }

  Class operator +(int value) => field;

  Class operator -() => field;
}

main() {
  propertyAccess(null);
  indexAccess(null);
  operatorAccess(null);
  ifNull(null);
}

void propertyAccess(Class c) {
  c?.field;
  c?.field = new Class();
  c = c?.field = new Class();
  c?.method();

  throws(() => c?.field.field);
  c?.field?.field;
  throws(() => c?.field.field?.field);
  throws(() => c?.field.field = new Class());
  c?.field?.field = new Class();
  throws(() => c?.field.field?.field = new Class());
  throws(() => (c?.field).field);
  throws(() => (c?.field = new Class()).field);
  throws(() => (c?.method()).field);
  throws(() => c = c?.field.field = new Class());
  c = c?.field?.field = new Class();
  throws(() => c = c?.field.field?.field = new Class());
  throws(() => c?.field.method());
  c?.field = new Class().field;
  c = c?.field = new Class().field;
  c?.field = new Class().field = new Class();
  c = c?.field = new Class().field = new Class();
  c?.field = new Class().method();
  c = c?.field = new Class().method();
  throws(() => c?.method().field);
  throws(() => c?.method().field = new Class());
  throws(() => c?.method().method());

  throws(() => c?.field.field.field);
  throws(() => c?.field.field.field = new Class());
  throws(() => c = c?.field.field.field = new Class());
  throws(() => c?.field.field.method());
  c?.field = new Class().field.field;
  c = c?.field = new Class().field.field;
  c?.field = new Class().field.field = new Class();
  c = c?.field = new Class().field.field = new Class();
  c?.field = new Class().field.method();
  c = c?.field = new Class().field.method();
  throws(() => c?.method().field.field);
  throws(() => c?.method().field.field = new Class());
  throws(() => c?.method().field.method());

  throws(() => c?.field.field = new Class().field);
  throws(() => c = c?.field.field = new Class().field);
  throws(() => c?.field.field = new Class().field = new Class());
  throws(() => c = c?.field.field = new Class().field = new Class());
  throws(() => c?.field.field = new Class().method());
  throws(() => c = c?.field.field = new Class().method());
  c?.field = new Class().field = new Class().field;
  c = c?.field = new Class().field = new Class().field;
  c?.field = new Class().field = new Class().field = new Class();
  c = c?.field = new Class().field = new Class().field = new Class();
  c?.field = new Class().field = new Class().method();
  c = c?.field = new Class().field = new Class().method();
  throws(() => c?.method().field = new Class().field);
  throws(() => c = c?.method().field = new Class().field);
  throws(() => c?.method().field = new Class().field = new Class());
  throws(() => c = c?.method().field = new Class().field = new Class());
  throws(() => c?.method().field = new Class().method());
  throws(() => c = c?.method().field = new Class().method());

  throws(() => c?.field.method().field);
  throws(() => c?.field.method().field = new Class());
  throws(() => c = c?.field.method().field = new Class());
  throws(() => c?.field.method().method());
  c?.field = new Class().method().field;
  c = c?.field = new Class().method().field;
  c?.field = new Class().method().field = new Class();
  c = c?.field = new Class().method().field = new Class();
  c?.field = new Class().method().method();
  c = c?.field = new Class().method().method();
  throws(() => c?.method().method().field);
  throws(() => c?.method().method().field = new Class());
  throws(() => c?.method().method().method());

  c?.method()?.method();
}

void indexAccess(Class c) {
  throws(() => c?.field[c]);
  throws(() => c?.field[c] = new Class());
  throws(() => c = c?.field[c] = new Class());
  throws(() => c?.field[c].method());
  throws(() => c?.field[c] += 0);
  throws(() => c = c?.field[c] += 0);
  throws(() => c?.field[c]++);
  throws(() => c = c?.field[c]++);
  throws(() => ++c?.field[c]);
  throws(() => c = ++c?.field[c]);

  throws(() => c?.field[c][c]);
  throws(() => c?.field[c][c] = new Class());
  throws(() => c = c?.field[c][c] = new Class());
  throws(() => c?.field[c][c].method());
  throws(() => c?.field[c][c] += 0);
  throws(() => c = c?.field[c][c] += 0);
  throws(() => c?.field[c][c]++);
  throws(() => c = c?.field[c][c]++);
  throws(() => ++c?.field[c][c]);
  throws(() => c = ++c?.field[c][c]);
}

void operatorAccess(Class c) {
  throws(() => c?.field + 0);
  throws(() => -c?.field);
  c?.field += 0;
  c = c?.field += 0;
  throws(() => c?.field.field += 0);
  throws(() => c = c?.field.field += 0);
  c?.field++;
  c = c?.field++;
  ++c?.field;
  c = ++c?.field;
}

void ifNull(Class c) {
  c?.field ??= c;
  c = c?.field ??= c;
  throws(() => c?.field.field ??= c);
  throws(() => c = c?.field.field ??= c);
  throws(() => c?.field[c] ??= c);
  throws(() => c = c?.field[c] ??= c);
}

void throws(void Function() f) {
  try {
    f();
  } catch (_) {
    return;
  }
  throw 'Expected exception.';
}
