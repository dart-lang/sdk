/**
 * An API for storing data in the browser that can be queried with SQL.
 *
 * **Caution:** this specification is no longer actively maintained by the Web
 * Applications Working Group and may be removed at any time.
 * See [the W3C Web SQL Database specification](http://www.w3.org/TR/webdatabase/)
 * for more information.
 *
 * The [dart:indexed_db] APIs is a recommended alternatives.
 */
library dart.dom.web_sql;

import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:html_common';
import 'dart:nativewrappers';
// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
// Auto-generated dart:audio library.




// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void DatabaseCallback(database);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SqlStatementCallback(SqlTransaction transaction, SqlResultSet resultSet);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SqlStatementErrorCallback(SqlTransaction transaction, SqlError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SqlTransactionCallback(SqlTransaction transaction);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SqlTransactionErrorCallback(SqlError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


typedef void SqlTransactionSyncCallback(SqlTransactionSync transaction);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('Database')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class SqlDatabase extends NativeFieldWrapperClass1 {
  SqlDatabase.internal();

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('Database.version')
  @DocsEditable
  String get version native "Database_version_Getter";

  /**
   * Atomically update the database version to [newVersion], asynchronously
   * running [callback] on the [SqlTransaction] representing this
   * [changeVersion] transaction.
   *
   * If [callback] runs successfully, then [successCallback] is called.
   * Otherwise, [errorCallback] is called.
   *
   * [oldVersion] should match the database's current [version] exactly.
   *
   * * [Database.changeVersion](http://www.w3.org/TR/webdatabase/#dom-database-changeversion) from W3C.
   */
  @DomName('Database.changeVersion')
  @DocsEditable
  void changeVersion(String oldVersion, String newVersion, [SqlTransactionCallback callback, SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) native "Database_changeVersion_Callback";

  @DomName('Database.readTransaction')
  @DocsEditable
  void readTransaction(SqlTransactionCallback callback, [SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) native "Database_readTransaction_Callback";

  @DomName('Database.transaction')
  @DocsEditable
  void transaction(SqlTransactionCallback callback, [SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) native "Database_transaction_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('DatabaseSync')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class SqlDatabaseSync extends NativeFieldWrapperClass1 {
  SqlDatabaseSync.internal();

  @DomName('DatabaseSync.lastErrorMessage')
  @DocsEditable
  String get lastErrorMessage native "DatabaseSync_lastErrorMessage_Getter";

  @DomName('DatabaseSync.version')
  @DocsEditable
  String get version native "DatabaseSync_version_Getter";

  @DomName('DatabaseSync.changeVersion')
  @DocsEditable
  void changeVersion(String oldVersion, String newVersion, [SqlTransactionSyncCallback callback]) native "DatabaseSync_changeVersion_Callback";

  @DomName('DatabaseSync.readTransaction')
  @DocsEditable
  void readTransaction(SqlTransactionSyncCallback callback) native "DatabaseSync_readTransaction_Callback";

  @DomName('DatabaseSync.transaction')
  @DocsEditable
  void transaction(SqlTransactionSyncCallback callback) native "DatabaseSync_transaction_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SQLError')
class SqlError extends NativeFieldWrapperClass1 {
  SqlError.internal();

  static const int CONSTRAINT_ERR = 6;

  static const int DATABASE_ERR = 1;

  static const int QUOTA_ERR = 4;

  static const int SYNTAX_ERR = 5;

  static const int TIMEOUT_ERR = 7;

  static const int TOO_LARGE_ERR = 3;

  static const int UNKNOWN_ERR = 0;

  static const int VERSION_ERR = 2;

  @DomName('SQLError.code')
  @DocsEditable
  int get code native "SQLError_code_Getter";

  @DomName('SQLError.message')
  @DocsEditable
  String get message native "SQLError_message_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SQLException')
class SqlException extends NativeFieldWrapperClass1 {
  SqlException.internal();

  static const int CONSTRAINT_ERR = 6;

  static const int DATABASE_ERR = 1;

  static const int QUOTA_ERR = 4;

  static const int SYNTAX_ERR = 5;

  static const int TIMEOUT_ERR = 7;

  static const int TOO_LARGE_ERR = 3;

  static const int UNKNOWN_ERR = 0;

  static const int VERSION_ERR = 2;

  @DomName('SQLException.code')
  @DocsEditable
  int get code native "SQLException_code_Getter";

  @DomName('SQLException.message')
  @DocsEditable
  String get message native "SQLException_message_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SQLResultSet')
class SqlResultSet extends NativeFieldWrapperClass1 {
  SqlResultSet.internal();

  @DomName('SQLResultSet.insertId')
  @DocsEditable
  int get insertId native "SQLResultSet_insertId_Getter";

  @DomName('SQLResultSet.rows')
  @DocsEditable
  SqlResultSetRowList get rows native "SQLResultSet_rows_Getter";

  @DomName('SQLResultSet.rowsAffected')
  @DocsEditable
  int get rowsAffected native "SQLResultSet_rowsAffected_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SQLResultSetRowList')
class SqlResultSetRowList extends NativeFieldWrapperClass1 implements List<Map> {
  SqlResultSetRowList.internal();

  @DomName('SQLResultSetRowList.length')
  @DocsEditable
  int get length native "SQLResultSetRowList_length_Getter";

  Map operator[](int index) native "SQLResultSetRowList_item_Callback";

  void operator[]=(int index, Map value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Map> mixins.
  // Map is the element type.

  // From Iterable<Map>:

  Iterator<Map> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<Map>(this);
  }

  dynamic reduce(dynamic initialValue, dynamic combine(dynamic, Map)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  bool contains(Map element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(Map element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator]) =>
      IterableMixinWorkaround.joinList(this, separator);

  Iterable map(f(Map element)) =>
      IterableMixinWorkaround.mapList(this, f);

  Iterable<Map> where(bool f(Map element)) =>
      IterableMixinWorkaround.where(this, f);

  Iterable expand(Iterable f(Map element)) =>
      IterableMixinWorkaround.expand(this, f);

  bool every(bool f(Map element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(Map element)) => IterableMixinWorkaround.any(this, f);

  List<Map> toList({ bool growable: true }) =>
      new List<Map>.from(this, growable: growable);

  Set<Map> toSet() => new Set<Map>.from(this);

  bool get isEmpty => this.length == 0;

  Iterable<Map> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<Map> takeWhile(bool test(Map value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<Map> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<Map> skipWhile(bool test(Map value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  Map firstWhere(bool test(Map value), { Map orElse() }) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  Map lastWhere(bool test(Map value), {Map orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  Map singleWhere(bool test(Map value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  Map elementAt(int index) {
    return this[index];
  }

  // From Collection<Map>:

  void add(Map value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addLast(Map value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<Map> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<Map>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  Iterable<Map> get reversed {
    return IterableMixinWorkaround.reversedList(this);
  }

  void sort([int compare(Map a, Map b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(Map element, [int start = 0]) =>
      Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(Map element, [int start]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  Map get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  Map get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  Map get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Map min([int compare(Map a, Map b)]) =>
      IterableMixinWorkaround.min(this, compare);

  Map max([int compare(Map a, Map b)]) =>
      IterableMixinWorkaround.max(this, compare);

  void insert(int index, Map element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  Map removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  Map removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(Map element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(Map element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int rangeLength, List<Map> from, [int startFrom]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int rangeLength) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int rangeLength, [Map initialValue]) {
    throw new UnsupportedError("Cannot insertRange on immutable List.");
  }

  List<Map> getRange(int start, int rangeLength) =>
      Lists.getRange(this, start, rangeLength, <Map>[]);

  Map<int, Map> asMap() =>
    IterableMixinWorkaround.asMapList(this);

  // -- end List<Map> mixins.

  @DomName('SQLResultSetRowList.item')
  @DocsEditable
  Map item(int index) native "SQLResultSetRowList_item_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SQLTransaction')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class SqlTransaction extends NativeFieldWrapperClass1 {
  SqlTransaction.internal();

  @DomName('SQLTransaction.executeSql')
  @DocsEditable
  void executeSql(String sqlStatement, List arguments, [SqlStatementCallback callback, SqlStatementErrorCallback errorCallback]) native "SQLTransaction_executeSql_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('SQLTransactionSync')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class SqlTransactionSync extends NativeFieldWrapperClass1 {
  SqlTransactionSync.internal();

  @DomName('SQLTransactionSync.executeSql')
  @DocsEditable
  SqlResultSet executeSql(String sqlStatement, List arguments) native "SQLTransactionSync_executeSql_Callback";

}
