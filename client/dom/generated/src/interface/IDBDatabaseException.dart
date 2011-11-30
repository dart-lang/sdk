// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface IDBDatabaseException {

  static final int ABORT_ERR = 13;

  static final int CONSTRAINT_ERR = 4;

  static final int DATA_ERR = 5;

  static final int DEADLOCK_ERR = 11;

  static final int NON_TRANSIENT_ERR = 2;

  static final int NOT_ALLOWED_ERR = 6;

  static final int NOT_FOUND_ERR = 3;

  static final int NO_ERR = 0;

  static final int READ_ONLY_ERR = 12;

  static final int RECOVERABLE_ERR = 8;

  static final int SERIAL_ERR = 7;

  static final int TIMEOUT_ERR = 10;

  static final int TRANSIENT_ERR = 9;

  static final int UNKNOWN_ERR = 1;

  int get code();

  String get message();

  String get name();

  String toString();
}
