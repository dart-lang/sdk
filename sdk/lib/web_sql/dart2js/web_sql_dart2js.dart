library dart.dom.web_sql;

import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:html_common';
import 'dart:_js_helper' show convertDartClosureToJS, Creates, JavaScriptIndexingBehavior, JSName;
import 'dart:_foreign_helper' show JS;
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


@DocsEditable
@DomName('Database')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class SqlDatabase native "*Database" {

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.openDatabase)');

  @DomName('Database.version')
  @DocsEditable
  final String version;

  @DomName('Database.changeVersion')
  @DocsEditable
  void changeVersion(String oldVersion, String newVersion, [SqlTransactionCallback callback, SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) native;

  @DomName('Database.readTransaction')
  @DocsEditable
  void readTransaction(SqlTransactionCallback callback, [SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) native;

  @DomName('Database.transaction')
  @DocsEditable
  void transaction(SqlTransactionCallback callback, [SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('DatabaseSync')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class SqlDatabaseSync native "*DatabaseSync" {

  @DomName('DatabaseSync.lastErrorMessage')
  @DocsEditable
  final String lastErrorMessage;

  @DomName('DatabaseSync.version')
  @DocsEditable
  final String version;

  @DomName('DatabaseSync.changeVersion')
  @DocsEditable
  void changeVersion(String oldVersion, String newVersion, [SqlTransactionSyncCallback callback]) native;

  @DomName('DatabaseSync.readTransaction')
  @DocsEditable
  void readTransaction(SqlTransactionSyncCallback callback) native;

  @DomName('DatabaseSync.transaction')
  @DocsEditable
  void transaction(SqlTransactionSyncCallback callback) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SQLError')
class SqlError native "*SQLError" {

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
  final int code;

  @DomName('SQLError.message')
  @DocsEditable
  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SQLException')
class SqlException native "*SQLException" {

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
  final int code;

  @DomName('SQLException.message')
  @DocsEditable
  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SQLResultSet')
class SqlResultSet native "*SQLResultSet" {

  @DomName('SQLResultSet.insertId')
  @DocsEditable
  final int insertId;

  @DomName('SQLResultSet.rows')
  @DocsEditable
  final SqlResultSetRowList rows;

  @DomName('SQLResultSet.rowsAffected')
  @DocsEditable
  final int rowsAffected;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SQLResultSetRowList')
class SqlResultSetRowList implements JavaScriptIndexingBehavior, List<Map> native "*SQLResultSetRowList" {

  @DomName('SQLResultSetRowList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  Map operator[](int index) => this.item(index);

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

  List<Map> toList() => new List<Map>.from(this);
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

  Map firstMatching(bool test(Map value), { Map orElse() }) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  Map lastMatching(bool test(Map value), {Map orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  Map singleMatching(bool test(Map value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
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

  void removeMatching(bool test(Map element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainMatching(bool test(Map element)) {
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

  // -- end List<Map> mixins.

  @DomName('SQLResultSetRowList.item')
  @DocsEditable
  @Creates('=Object')
  Map item(int index) {
    return convertNativeToDart_Dictionary(_item_1(index));
  }
  @JSName('item')
  @DomName('SQLResultSetRowList.item')
  @DocsEditable
  @Creates('=Object')
  _item_1(index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SQLTransaction')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class SqlTransaction native "*SQLTransaction" {

  @DomName('SQLTransaction.executeSql')
  @DocsEditable
  void executeSql(String sqlStatement, List arguments, [SqlStatementCallback callback, SqlStatementErrorCallback errorCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('SQLTransactionSync')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class SqlTransactionSync native "*SQLTransactionSync" {

  @DomName('SQLTransactionSync.executeSql')
  @DocsEditable
  SqlResultSet executeSql(String sqlStatement, List arguments) native;
}
