// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class TableContext {}

class Column {}

class TableSchema<F extends Column, C extends TableContext> {
  factory TableSchema({required Iterable<F> fields, C? context}) =>
      new TableSchema._();

  TableSchema._();
}

var schema = TableSchema(fields: []);

void method() {
  var schema = TableSchema(fields: []);
}
