// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DatabaseSync {

  final String lastErrorMessage;

  final String version;

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionSyncCallback callback]);

  void readTransaction(SQLTransactionSyncCallback callback);

  void transaction(SQLTransactionSyncCallback callback);
}
