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
import 'dart:_internal' hide deprecated;
import 'dart:html';
import 'dart:html_common';
import 'dart:_js_helper' show convertDartClosureToJS, Creates, JSName, Native;
import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show Interceptor;
// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
// Auto-generated dart:audio library.




// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('SQLStatementCallback')
// http://www.w3.org/TR/webdatabase/#sqlstatementcallback
@Experimental() // deprecated
typedef void SqlStatementCallback(SqlTransaction transaction, SqlResultSet resultSet);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('SQLStatementErrorCallback')
// http://www.w3.org/TR/webdatabase/#sqlstatementerrorcallback
@Experimental() // deprecated
typedef void SqlStatementErrorCallback(SqlTransaction transaction, SqlError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('SQLTransactionCallback')
// http://www.w3.org/TR/webdatabase/#sqltransactioncallback
@Experimental() // deprecated
typedef void SqlTransactionCallback(SqlTransaction transaction);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DomName('SQLTransactionErrorCallback')
// http://www.w3.org/TR/webdatabase/#sqltransactionerrorcallback
@Experimental() // deprecated
typedef void SqlTransactionErrorCallback(SqlError error);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('Database')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental()
// http://www.w3.org/TR/webdatabase/#asynchronous-database-api
@Experimental() // deprecated
@Native("Database")
class SqlDatabase extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory SqlDatabase._() { throw new UnsupportedError("Not supported"); }

  /// Checks if this type is supported on the current platform.
  static bool get supported => JS('bool', '!!(window.openDatabase)');

  @DomName('Database.version')
  @DocsEditable()
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
  @DocsEditable()
  void changeVersion(String oldVersion, String newVersion, [SqlTransactionCallback callback, SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) native;

  @DomName('Database.readTransaction')
  @DocsEditable()
  void readTransaction(SqlTransactionCallback callback, [SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) native;

  @DomName('Database.transaction')
  @DocsEditable()
  void transaction(SqlTransactionCallback callback, [SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SQLError')
// http://www.w3.org/TR/webdatabase/#sqlerror
@Experimental() // deprecated
@Native("SQLError")
class SqlError extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory SqlError._() { throw new UnsupportedError("Not supported"); }

  @DomName('SQLError.CONSTRAINT_ERR')
  @DocsEditable()
  static const int CONSTRAINT_ERR = 6;

  @DomName('SQLError.DATABASE_ERR')
  @DocsEditable()
  static const int DATABASE_ERR = 1;

  @DomName('SQLError.QUOTA_ERR')
  @DocsEditable()
  static const int QUOTA_ERR = 4;

  @DomName('SQLError.SYNTAX_ERR')
  @DocsEditable()
  static const int SYNTAX_ERR = 5;

  @DomName('SQLError.TIMEOUT_ERR')
  @DocsEditable()
  static const int TIMEOUT_ERR = 7;

  @DomName('SQLError.TOO_LARGE_ERR')
  @DocsEditable()
  static const int TOO_LARGE_ERR = 3;

  @DomName('SQLError.UNKNOWN_ERR')
  @DocsEditable()
  static const int UNKNOWN_ERR = 0;

  @DomName('SQLError.VERSION_ERR')
  @DocsEditable()
  static const int VERSION_ERR = 2;

  @DomName('SQLError.code')
  @DocsEditable()
  final int code;

  @DomName('SQLError.message')
  @DocsEditable()
  final String message;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SQLResultSet')
// http://www.w3.org/TR/webdatabase/#sqlresultset
@Experimental() // deprecated
@Native("SQLResultSet")
class SqlResultSet extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory SqlResultSet._() { throw new UnsupportedError("Not supported"); }

  @DomName('SQLResultSet.insertId')
  @DocsEditable()
  final int insertId;

  @DomName('SQLResultSet.rows')
  @DocsEditable()
  final SqlResultSetRowList rows;

  @DomName('SQLResultSet.rowsAffected')
  @DocsEditable()
  final int rowsAffected;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SQLResultSetRowList')
// http://www.w3.org/TR/webdatabase/#sqlresultsetrowlist
@Experimental() // deprecated
@Native("SQLResultSetRowList")
class SqlResultSetRowList extends Interceptor with ListMixin<Map>, ImmutableListMixin<Map> implements List<Map> {
  // To suppress missing implicit constructor warnings.
  factory SqlResultSetRowList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SQLResultSetRowList.length')
  @DocsEditable()
  int get length => JS("int", "#.length", this);

  Map operator[](int index) {
    if (JS("bool", "# >>> 0 !== # || # >= #", index,
        index, index, length))
      throw new RangeError.index(index, this);
    return this.item(index);
  }
  void operator[]=(int index, Map value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Map> mixins.
  // Map is the element type.


  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  Map get first {
    if (this.length > 0) {
      return JS('Map', '#[0]', this);
    }
    throw new StateError("No elements");
  }

  Map get last {
    int len = this.length;
    if (len > 0) {
      return JS('Map', '#[#]', this, len - 1);
    }
    throw new StateError("No elements");
  }

  Map get single {
    int len = this.length;
    if (len == 1) {
      return JS('Map', '#[0]', this);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Map elementAt(int index) => this[index];
  // -- end List<Map> mixins.

  @DomName('SQLResultSetRowList.item')
  @DocsEditable()
  @Creates('=Object')
  Map item(int index) {
    return convertNativeToDart_Dictionary(_item_1(index));
  }
  @JSName('item')
  @DomName('SQLResultSetRowList.item')
  @DocsEditable()
  @Creates('=Object')
  _item_1(index) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SQLTransaction')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental()
// http://www.w3.org/TR/webdatabase/#sqltransaction
@deprecated // deprecated
@Native("SQLTransaction")
class SqlTransaction extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory SqlTransaction._() { throw new UnsupportedError("Not supported"); }

  @DomName('SQLTransaction.executeSql')
  @DocsEditable()
  void executeSql(String sqlStatement, List<Object> arguments, [SqlStatementCallback callback, SqlStatementErrorCallback errorCallback]) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
@DomName('SQLTransactionSync')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental()
// http://www.w3.org/TR/webdatabase/#sqltransactionsync
@Experimental() // deprecated
@Native("SQLTransactionSync")
abstract class _SQLTransactionSync extends Interceptor {
  // To suppress missing implicit constructor warnings.
  factory _SQLTransactionSync._() { throw new UnsupportedError("Not supported"); }
}
