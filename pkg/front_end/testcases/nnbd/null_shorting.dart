// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  Class? field;
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
  c?.field;
  c?.field = new Class();
  c = c?.field = new Class();
  c?.method();

  c?.property.field;
  c?.field?.field;
  c?.property.field?.field;
  c?.property.field = new Class();
  c?.field?.field = new Class();
  c?.property.field?.field = new Class();
  (c?.field)?.field;
  throws(() => (c?.field = new Class()).field);
  throws(() => (c?.method()).field);
  c = c?.property.field = new Class();
  c = c?.field?.field = new Class();
  c = c?.property.field?.field = new Class();
  c?.field?.method();
  c?.field = new Class().field;
  c = c?.field = new Class().field;
  c?.field = new Class().field = new Class();
  c = c?.field = new Class().field = new Class();
  c?.field = new Class().method();
  c = c?.field = new Class().method();
  c?.method().field;
  c?.method().field = new Class();
  c?.method().method();

  c?.property.property.field;
  c?.property.property.field = new Class();
  c = c?.property.property.field = new Class();
  c?.property.field?.method();
  c?.field = new Class().property.field;
  c = c?.field = new Class().property.field;
  c?.field = new Class().property.field = new Class();
  c = c?.field = new Class().property.field = new Class();
  c?.field = new Class().property.method();
  c = c?.field = new Class().property.method();
  c?.method().property.field;
  c?.method().property.field = new Class();
  c?.method().property.method();

  c?.property.field = new Class().field;
  c = c?.property.field = new Class().field;
  c?.property.field = new Class().field = new Class();
  c = c?.property.field = new Class().field = new Class();
  c?.property.field = new Class().method();
  c = c?.property.field = new Class().method();
  c?.field = new Class().field = new Class().field;
  c = c?.field = new Class().field = new Class().field;
  c?.field = new Class().field = new Class().field = new Class();
  c = c?.field = new Class().field = new Class().field = new Class();
  c?.field = new Class().field = new Class().method();
  c = c?.field = new Class().field = new Class().method();
  c?.method().field = new Class().field;
  c = c?.method().field = new Class().field;
  c?.method().field = new Class().field = new Class();
  c = c?.method().field = new Class().field = new Class();
  c?.method().field = new Class().method();
  c = c?.method().field = new Class().method();

  c?.property.method().field;
  c?.property.method().field = new Class();
  c = c?.property.method().field = new Class();
  c?.property.method().method();
  c?.field = new Class().method().field;
  c = c?.field = new Class().method().field;
  c?.field = new Class().method().field = new Class();
  c = c?.field = new Class().method().field = new Class();
  c?.field = new Class().method().method();
  c = c?.field = new Class().method().method();
  c?.method().method().field;
  c?.method().method().field = new Class();
  c?.method().method().method();

  c?.method()?.method();
}

void indexAccess(Class? c) {
  c?.[c];
  c?.[c] = new Class();
  c?.[c]?.method();
  c?.field[c];
  c?.field[c] = new Class();
  c = c?.field[c] = new Class();
  c?.field[c]?.method();
  c?.field[c] += 0;
  c = c?.field[c] += 0;
  c?.[c] ??= c;
  c = c?.[c] ??= c;
  c?.[c] += 0;
  c = c?.[c] += 0;
  c?.[c] += 0;
  c = c?.[c] += 0;
  // TODO(johnniwinther): ++ should probably not be null-shorted, awaiting spec
  //  update.
  c?.[c]++;
  c = c?.[c]++;
  ++c?.[c];
  c = ++c?.[c];
  c?.field[c]++;
  c = c?.field[c]++;
  ++c?.field[c];
  c = ++c?.field[c];

  c?.field[c][c];
  c?.field[c][c] = new Class();
  c = c?.field[c][c] = new Class();
  c?.field[c][c]?.method();
  c?.field[c][c] += 0;
  c = c?.field[c][c] += 0;
  // TODO(johnniwinther): ++ should probably not be null-shorted, awaiting spec
  //  update.
  c?.field[c][c]++;
  c = c?.field[c][c]++;
  ++c?.field[c][c];
  c = ++c?.field[c][c];

  c?.[c]?.[c];
  c?.[c]?.[c] = new Class();
  c = c?.[c]?.[c] = new Class();
  c?.[c]?.[c]?.method();
  c = c?.[c]?.[c]?.method();
  c?.[c]?.[c] ??= c;
  c = c?.[c]?.[c] ??= c;
  c?.[c]?.[c] += 0;
  c = c?.[c]?.[c] += 0;
  // TODO(johnniwinther): ++ should probably not be null-shorted, awaiting spec
  //  update.
  c?.[c]?.[c]++;
  c = c?.[c]?.[c]++;
  ++c?.[c]?.[c];
  c = ++c?.[c]?.[c];
}

void operatorAccess(Class? c) {
  throws(() => c?.field + 0);
  throws(() => -c?.field);
  c?.field += 0;
  c = c?.field += 0;
  c?.property.field += 0;
  c = c?.property.field += 0;
  // TODO(johnniwinther): ++ should probably not be null-shorted, awaiting spec
  //  update.
  c?.field++;
  c = c?.field++;
  ++c?.field;
  c = ++c?.field;
}

void ifNull(Class? c) {
  c?.field ??= c;
  c = c?.field ??= c;
  c?.property.field ??= c;
  c = c?.property.field ??= c;
  c?.field[c] ??= c;
  c = c?.field[c] ??= c;
}

void throws(void Function() f) {
  try {
    f();
  } catch (_) {
    return;
  }
  throw 'Expected exception.';
}
