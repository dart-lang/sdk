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

  Class? method() => field;

  Class? operator [](Class? key) => field;
  void operator []=(Class? key, Class? value) {
    field = value;
  }

  Class? operator +(int value) => field;
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

  c?.field.field;
  c?.field.field = new Class();
  c = c?.field.field = new Class();
  c?.field.method();
  c?.field = new Class().field;
  c = c?.field = new Class().field;
  c?.field = new Class().field = new Class();
  c = c?.field = new Class().field = new Class();
  c?.field = new Class().method();
  c = c?.field = new Class().method();
  c?.method().field;
  c?.method().field = new Class();
  c?.method().method();

  c?.field.field.field;
  c?.field.field.field = new Class();
  c = c?.field.field.field = new Class();
  c?.field.field.method();
  c?.field = new Class().field.field;
  c = c?.field = new Class().field.field;
  c?.field = new Class().field.field = new Class();
  c = c?.field = new Class().field.field = new Class();
  c?.field = new Class().field.method();
  c = c?.field = new Class().field.method();
  c?.method().field.field;
  c?.method().field.field = new Class();
  c?.method().field.method();

  c?.field.field = new Class().field;
  c = c?.field.field = new Class().field;
  c?.field.field = new Class().field = new Class();
  c = c?.field.field = new Class().field = new Class();
  c?.field.field = new Class().method();
  c = c?.field.field = new Class().method();
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

  c?.field.method().field;
  c?.field.method().field = new Class();
  c = c?.field.method().field = new Class();
  c?.field.method().method();
  c?.field = new Class().method().field;
  c = c?.field = new Class().method().field;
  c?.field = new Class().method().field = new Class();
  c = c?.field = new Class().method().field = new Class();
  c?.field = new Class().method().method();
  c = c?.field = new Class().method().method();
  c?.method().method().field;
  c?.method().method().field = new Class();
  c?.method().method().method();
}

void indexAccess(Class? c) {
  // TODO(johnniwinther): Handle null aware index access.
  //c?.[c];
  //c?.[c] = new Class();
  //c?.[c].method();
  c?.field[c];
  c?.field[c] = new Class();
  c = c?.field[c] = new Class();
  c?.field[c].method();
  c?.field[c] += 0;
  c = c?.field[c] += 0;
  // TODO(johnniwinther): ++ should probably not be null-shorted, awaiting spec
  // update.
  c?.field[c]++;
  c = c?.field[c]++;
  ++c?.field[c];
  c = ++c?.field[c];
}

void operatorAccess(Class? c) {
  // TODO(johnniwinther): + should _not_ be null-shortened.
  c?.field + 0;
  c?.field += 0;
  c = c?.field += 0;
  c?.field.field += 0;
  c = c?.field.field += 0;
  // TODO(johnniwinther): ++ should probably not be null-shorted, awaiting spec
  // update.
  c?.field++;
  c = c?.field++;
  ++c?.field;
  c = ++c?.field;
}

void ifNull(Class? c) {
  c?.field ??= c;
  c = c?.field ??= c;
  c?.field[c] ??= c;
}
