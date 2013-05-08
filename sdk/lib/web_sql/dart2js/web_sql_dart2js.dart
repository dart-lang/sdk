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
import 'dart:_collection-dev';
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


@DocsEditable
@DomName('Database')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental
class SqlDatabase native "Database" {

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.openDatabase)');

  @DomName('Database.version')
  @DocsEditable
  final String version;

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
@DomName('SQLError')
class SqlError native "SQLError" {

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
class SqlException native "SQLException" {

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
class SqlResultSet native "SQLResultSet" {

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
class SqlResultSetRowList extends Object with ListMixin<Map>, ImmutableListMixin<Map> implements JavaScriptIndexingBehavior, List<Map> native "SQLResultSetRowList" {

  @DomName('SQLResultSetRowList.length')
  @DocsEditable
  int get length => JS("int", "#.length", this);

  Map operator[](int index) => this.item(index);

  void operator[]=(int index, Map value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Map> mixins.
  // Map is the element type.


  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

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
class SqlTransaction native "SQLTransaction" {

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
abstract class _SQLTransactionSync native "SQLTransactionSync" {
}
