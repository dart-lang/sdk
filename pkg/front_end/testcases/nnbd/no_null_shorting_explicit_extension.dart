// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

class Class {
  Class _field;
}

extension Extension on Class {
  Class get field => _field;
  void set field(Class value) {
    _field = value;
  }

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
  Extension(c)?.field;
  Extension(c)?.field = new Class();
  c = Extension(c)?.field = new Class();
  Extension(c)?.method();

  throws(() => Extension(c)?.field.field);
  Extension(c)?.field?.field;
  throws(() => Extension(c)?.field.field?.field);
  throws(() => Extension(c)?.field.field = new Class());
  Extension(c)?.field?.field = new Class();
  throws(() => Extension(c)?.field.field?.field = new Class());
  throws(() => (Extension(c)?.field).field);
  throws(() => (Extension(c)?.field = new Class()).field);
  throws(() => (Extension(c)?.method()).field);
  throws(() => c = Extension(c)?.field.field = new Class());
  c = Extension(c)?.field?.field = new Class();
  throws(() => c = Extension(c)?.field.field?.field = new Class());
  throws(() => Extension(c)?.field.method());
  Extension(c)?.field = new Class().field;
  c = Extension(c)?.field = new Class().field;
  Extension(c)?.field = new Class().field = new Class();
  c = Extension(c)?.field = new Class().field = new Class();
  Extension(c)?.field = new Class().method();
  c = Extension(c)?.field = new Class().method();
  throws(() => Extension(c)?.method().field);
  throws(() => Extension(c)?.method().field = new Class());
  throws(() => Extension(c)?.method().method());

  throws(() => Extension(c)?.field.field.field);
  throws(() => Extension(c)?.field.field.field = new Class());
  throws(() => c = Extension(c)?.field.field.field = new Class());
  throws(() => Extension(c)?.field.field.method());
  Extension(c)?.field = new Class().field.field;
  c = Extension(c)?.field = new Class().field.field;
  Extension(c)?.field = new Class().field.field = new Class();
  c = Extension(c)?.field = new Class().field.field = new Class();
  Extension(c)?.field = new Class().field.method();
  c = Extension(c)?.field = new Class().field.method();
  throws(() => Extension(c)?.method().field.field);
  throws(() => Extension(c)?.method().field.field = new Class());
  throws(() => Extension(c)?.method().field.method());

  throws(() => Extension(c)?.field.field = new Class().field);
  throws(() => c = Extension(c)?.field.field = new Class().field);
  throws(() => Extension(c)?.field.field = new Class().field = new Class());
  throws(() => c = Extension(c)?.field.field = new Class().field = new Class());
  throws(() => Extension(c)?.field.field = new Class().method());
  throws(() => c = Extension(c)?.field.field = new Class().method());
  Extension(c)?.field = new Class().field = new Class().field;
  c = Extension(c)?.field = new Class().field = new Class().field;
  Extension(c)?.field = new Class().field = new Class().field = new Class();
  c = Extension(c)?.field = new Class().field = new Class().field = new Class();
  Extension(c)?.field = new Class().field = new Class().method();
  c = Extension(c)?.field = new Class().field = new Class().method();
  throws(() => Extension(c)?.method().field = new Class().field);
  throws(() => c = Extension(c)?.method().field = new Class().field);
  throws(() => Extension(c)?.method().field = new Class().field = new Class());
  throws(
      () => c = Extension(c)?.method().field = new Class().field = new Class());
  throws(() => Extension(c)?.method().field = new Class().method());
  throws(() => c = Extension(c)?.method().field = new Class().method());

  throws(() => Extension(c)?.field.method().field);
  throws(() => Extension(c)?.field.method().field = new Class());
  throws(() => c = Extension(c)?.field.method().field = new Class());
  throws(() => Extension(c)?.field.method().method());
  Extension(c)?.field = new Class().method().field;
  c = Extension(c)?.field = new Class().method().field;
  Extension(c)?.field = new Class().method().field = new Class();
  c = Extension(c)?.field = new Class().method().field = new Class();
  Extension(c)?.field = new Class().method().method();
  c = Extension(c)?.field = new Class().method().method();
  throws(() => Extension(c)?.method().method().field);
  throws(() => Extension(c)?.method().method().field = new Class());
  throws(() => Extension(c)?.method().method().method());

  Extension(c)?.method()?.method();

  throws(() => Extension(c?.field).field);
  Extension(c?.field)?.field;
}

void indexAccess(Class c) {
  throws(() => Extension(c)?.field[c]);
  throws(() => Extension(c)?.field[c] = new Class());
  throws(() => c = Extension(c)?.field[c] = new Class());
  throws(() => Extension(c)?.field[c].method());
  throws(() => Extension(c)?.field[c] += 0);
  throws(() => c = Extension(c)?.field[c] += 0);
  throws(() => Extension(c)?.field[c]++);
  throws(() => c = Extension(c)?.field[c]++);
  throws(() => ++Extension(c)?.field[c]);
  throws(() => c = ++Extension(c)?.field[c]);

  throws(() => Extension(c)?.field[c][c]);
  throws(() => Extension(c)?.field[c][c] = new Class());
  throws(() => c = Extension(c)?.field[c][c] = new Class());
  throws(() => Extension(c)?.field[c][c].method());
  throws(() => Extension(c)?.field[c][c] += 0);
  throws(() => c = Extension(c)?.field[c][c] += 0);
  throws(() => Extension(c)?.field[c][c]++);
  throws(() => c = Extension(c)?.field[c][c]++);
  throws(() => ++Extension(c)?.field[c][c]);
  throws(() => c = ++Extension(c)?.field[c][c]);
}

void operatorAccess(Class c) {
  throws(() => Extension(c)?.field + 0);
  throws(() => -Extension(c)?.field);
  Extension(c)?.field += 0;
  c = Extension(c)?.field += 0;
  throws(() => Extension(c)?.field.field += 0);
  throws(() => c = Extension(c)?.field.field += 0);
  Extension(c)?.field++;
  c = Extension(c)?.field++;
  ++Extension(c)?.field;
  c = ++Extension(c)?.field;
}

void ifNull(Class c) {
  Extension(c)?.field ??= c;
  c = Extension(c)?.field ??= c;
  throws(() => Extension(c)?.field.field ??= c);
  throws(() => c = Extension(c)?.field.field ??= c);
  throws(() => Extension(c)?.field[c] ??= c);
  throws(() => c = Extension(c)?.field[c] ??= c);
}

void throws(void Function() f) {
  try {
    f();
  } catch (_) {
    return;
  }
  throw 'Expected exception.';
}
