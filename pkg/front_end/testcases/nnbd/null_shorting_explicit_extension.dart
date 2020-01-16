// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  Class? _field;
}

extension Extension on Class {
  Class? get field => _field;
  void set field(Class? value) {
    _field = value;
  }

  Class method() => property;

  Class? operator [](Class? key) => field;
  void operator []=(Class? key, Class? value) {
    field = value;
  }

  Class? operator +(int value) => field;

  Class? operator -() => field;

  Class get property => this;
}

main() {
  propertyAccess(null);
  indexAccess(null);
  operatorAccess(null);
  ifNull(null);
}

void propertyAccess(Class? c) {
  Extension(c)?.field;
  Extension(c)?.field = new Class();
  c = Extension(c)?.field = new Class();
  Extension(c)?.method();

  Extension(c)?.property.field;
  Extension(c)?.field?.field;
  Extension(c)?.property.field?.field;
  Extension(c)?.property.field = new Class();
  Extension(c)?.field?.field = new Class();
  Extension(c)?.property.field?.field = new Class();
  (Extension(c)?.field)?.field;
  throws(() => (Extension(c)?.field = new Class()).field);
  throws(() => (Extension(c)?.method()).field);
  c = Extension(c)?.property.field = new Class();
  c = Extension(c)?.field?.field = new Class();
  c = Extension(c)?.property.field?.field = new Class();
  Extension(c)?.field?.method();
  Extension(c)?.field = new Class().field;
  c = Extension(c)?.field = new Class().field;
  Extension(c)?.field = new Class().field = new Class();
  c = Extension(c)?.field = new Class().field = new Class();
  Extension(c)?.field = new Class().method();
  c = Extension(c)?.field = new Class().method();
  Extension(c)?.method().field;
  Extension(c)?.method().field = new Class();
  Extension(c)?.method().method();

  Extension(c)?.property.property.field;
  Extension(c)?.property.property.field = new Class();
  c = Extension(c)?.property.property.field = new Class();
  Extension(c)?.property.property.method();
  Extension(c)?.field = new Class().property.field;
  c = Extension(c)?.field = new Class().property.field;
  Extension(c)?.field = new Class().property.field = new Class();
  c = Extension(c)?.field = new Class().property.field = new Class();
  Extension(c)?.field = new Class().property.method();
  c = Extension(c)?.field = new Class().property.method();
  Extension(c)?.method().property.field;
  Extension(c)?.method().property.field = new Class();
  Extension(c)?.method().field?.method();

  Extension(c)?.property.field = new Class().field;
  c = Extension(c)?.property.field = new Class().field;
  Extension(c)?.property.field = new Class().field = new Class();
  c = Extension(c)?.property.field = new Class().field = new Class();
  Extension(c)?.property.field = new Class().method();
  c = Extension(c)?.property.field = new Class().method();
  Extension(c)?.field = new Class().field = new Class().field;
  c = Extension(c)?.field = new Class().field = new Class().field;
  Extension(c)?.field = new Class().field = new Class().field = new Class();
  c = Extension(c)?.field = new Class().field = new Class().field = new Class();
  Extension(c)?.field = new Class().field = new Class().method();
  c = Extension(c)?.field = new Class().field = new Class().method();
  Extension(c)?.method().field = new Class().field;
  c = Extension(c)?.method().field = new Class().field;
  Extension(c)?.method().field = new Class().field = new Class();
  c = Extension(c)?.method().field = new Class().field = new Class();
  Extension(c)?.method().field = new Class().method();
  c = Extension(c)?.method().field = new Class().method();

  Extension(c)?.property.method().field;
  Extension(c)?.property.method().field = new Class();
  c = Extension(c)?.property.method().field = new Class();
  Extension(c)?.property.method().method();
  Extension(c)?.field = new Class().method().field;
  c = Extension(c)?.field = new Class().method().field;
  Extension(c)?.field = new Class().method().field = new Class();
  c = Extension(c)?.field = new Class().method().field = new Class();
  Extension(c)?.field = new Class().method().method();
  c = Extension(c)?.field = new Class().method().method();
  Extension(c)?.method().method().field;
  Extension(c)?.method().method().field = new Class();
  Extension(c)?.method().method().method();

  Extension(c)?.method()?.method();

  (Extension(c?.field)?.field)?.field;
  Extension(c?.field)?.field;
}

void indexAccess(Class? c) {
  Extension(c)?.[c];
  Extension(c)?.[c] = new Class();
  Extension(c)?.[c]?.method();
  Extension(c)?.field[c];
  Extension(c)?.field[c] = new Class();
  c = Extension(c)?.field[c] = new Class();
  Extension(c)?.field[c]?.method();
  Extension(c)?.field[c] += 0;
  c = Extension(c)?.field[c] += 0;
  Extension(c)?.[c] ??= c;
  c = Extension(c)?.[c] ??= c;
  Extension(c)?.[c] += 0;
  c = Extension(c)?.[c] += 0;
  Extension(c)?.[c] += 0;
  c = Extension(c)?.[c] += 0;
  // TODO(johnniwinther): ++ should probably not be null-shorted, awaiting spec
  // update.
  Extension(c)?.[c]++;
  c = Extension(c)?.[c]++;
  Extension(c)?.[c];
  c = ++Extension(c)?.[c];
  Extension(c)?.field[c]++;
  c = Extension(c)?.field[c]++;
  ++Extension(c)?.field[c];
  c = ++Extension(c)?.field[c];

  Extension(c)?.field[c][c];
  Extension(c)?.field[c][c] = new Class();
  c = Extension(c)?.field[c][c] = new Class();
  Extension(c)?.field[c][c]?.method();
  Extension(c)?.field[c][c] += 0;
  c = Extension(c)?.field[c][c] += 0;
  // TODO(johnniwinther): ++ should probably not be null-shorted, awaiting spec
  //  update.
  Extension(c)?.field[c][c]++;
  c = Extension(c)?.field[c][c]++;
  ++Extension(c)?.field[c][c];
  c = ++Extension(c)?.field[c][c];

  Extension(c)?.[c]?.[c];
  Extension(c)?.[c]?.[c] = new Class();
  c = Extension(c)?.[c]?.[c] = new Class();
  Extension(c)?.[c]?.[c]?.method();
  c = Extension(c)?.[c]?.[c]?.method();
  Extension(c)?.[c]?.[c] ??= c;
  c = Extension(c)?.[c]?.[c] ??= c;
  Extension(c)?.[c]?.[c] += 0;
  c = Extension(c)?.[c]?.[c] += 0;
  // TODO(johnniwinther): ++ should probably not be null-shorted, awaiting spec
  //  update.
  Extension(c)?.[c]?.[c]++;
  c = Extension(c)?.[c]?.[c]++;
  ++Extension(c)?.[c]?.[c];
  c = ++Extension(c)?.[c]?.[c];
}

void operatorAccess(Class? c) {
  throws(() => Extension(c)?.field + 0);
  throws(() => -Extension(c)?.field);
  Extension(c)?.field += 0;
  c = Extension(c)?.field += 0;
  Extension(c)?.property.field += 0;
  c = Extension(c)?.property.field += 0;
  // TODO(johnniwinther): ++ should probably not be null-shorted, awaiting spec
  // update.
  Extension(c)?.field++;
  c = Extension(c)?.field++;
  ++Extension(c)?.field;
  c = ++Extension(c)?.field;
}

void ifNull(Class? c) {
  Extension(c)?.field ??= c;
  c = Extension(c)?.field ??= c;
  Extension(c)?.property.field ??= c;
  c = Extension(c)?.property.field ??= c;
  Extension(c)?.field[c] ??= c;
  c = Extension(c)?.field[c] ??= c;
}

void throws(void Function() f) {
  try {
    f();
  } catch (_) {
    return;
  }
  throw 'Expected exception.';
}
