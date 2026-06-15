// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from tests/language/why_not_promoted/assignment_error_test.dart

abstract class C {
  C? operator +(int i);
  int get cProperty => 0;
}

direct_assignment(int? i, int? j) {
  if (i == null) return;
  i = j;
  i.isEven;
}

compound_assignment(C? c, int i) {
  if (c == null) return;
  c += i;
  c.cProperty;
}

via_postfix_op(C? c) {
  if (c == null) return;
  c++;
  c.cProperty;
}

via_prefix_op(C? c) {
  if (c == null) return;
  ++c;
  c.cProperty;
}

via_for_each_statement(int? i, List<int?> list) {
  if (i == null) return;
  for (i in list) {
    i.isEven;
  }
}

via_for_each_list_element(int? i, List<int?> list) {
  if (i == null) return;
  [for (i in list) i.isEven];
}

via_for_each_set_element(int? i, List<int?> list) {
  if (i == null) return;
  ({for (i in list) i.isEven});
}

via_for_each_map_key(int? i, List<int?> list) {
  if (i == null) return;
  ({for (i in list) i.isEven: null});
}

via_for_each_map_value(int? i, List<int?> list) {
  if (i == null) return;
  ({for (i in list) null: i.isEven});
}
