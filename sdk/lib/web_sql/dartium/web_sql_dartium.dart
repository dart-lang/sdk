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
import 'dart:_internal';
import 'dart:html';
import 'dart:html_common';
import 'dart:nativewrappers';
import 'dart:_blink' as _blink;
import 'dart:js' as js;

// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
// Auto-generated dart:audio library.




// FIXME: Can we make this private?
@Deprecated("Internal Use Only")
final web_sqlBlinkMap = {
  'Database': () => SqlDatabase,
  'SQLError': () => SqlError,
  'SQLResultSet': () => SqlResultSet,
  'SQLResultSetRowList': () => SqlResultSetRowList,
  'SQLTransaction': () => SqlTransaction,

};

// FIXME: Can we make this private?
@Deprecated("Internal Use Only")
final web_sqlBlinkFunctionMap = {
  'Database': () => SqlDatabase.internalCreateSqlDatabase,
  'SQLError': () => SqlError.internalCreateSqlError,
  'SQLResultSet': () => SqlResultSet.internalCreateSqlResultSet,
  'SQLResultSetRowList': () => SqlResultSetRowList.internalCreateSqlResultSetRowList,
  'SQLTransaction': () => SqlTransaction.internalCreateSqlTransaction,

};
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

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('Database')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental()
// http://www.w3.org/TR/webdatabase/#asynchronous-database-api
@Experimental() // deprecated
class SqlDatabase extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory SqlDatabase._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static SqlDatabase internalCreateSqlDatabase() {
    return new SqlDatabase._internalWrap();
  }

  factory SqlDatabase._internalWrap() {
    return new SqlDatabase.internal_();
  }

  @Deprecated("Internal Use Only")
  SqlDatabase.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('Database.version')
  @DocsEditable()
  String get version => _blink.BlinkDatabase.instance.version_Getter_(unwrap_jso(this));
  
  void changeVersion(String oldVersion, String newVersion, [SqlTransactionCallback callback, SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) {
    if (successCallback != null) {
      _blink.BlinkDatabase.instance.changeVersion_Callback_5_(unwrap_jso(this), oldVersion, newVersion, unwrap_jso((transaction) => callback(wrap_jso(transaction))), unwrap_jso((error) => errorCallback(wrap_jso(error))), unwrap_jso(() => successCallback()));
      return;
    }
    if (errorCallback != null) {
      _blink.BlinkDatabase.instance.changeVersion_Callback_4_(unwrap_jso(this), oldVersion, newVersion, unwrap_jso((transaction) => callback(wrap_jso(transaction))), unwrap_jso((error) => errorCallback(wrap_jso(error))));
      return;
    }
    if (callback != null) {
      _blink.BlinkDatabase.instance.changeVersion_Callback_3_(unwrap_jso(this), oldVersion, newVersion, unwrap_jso((transaction) => callback(wrap_jso(transaction))));
      return;
    }
    _blink.BlinkDatabase.instance.changeVersion_Callback_2_(unwrap_jso(this), oldVersion, newVersion);
    return;
  }

  void readTransaction(SqlTransactionCallback callback, [SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) {
    if (successCallback != null) {
      _blink.BlinkDatabase.instance.readTransaction_Callback_3_(unwrap_jso(this), unwrap_jso((transaction) => callback(wrap_jso(transaction))), unwrap_jso((error) => errorCallback(wrap_jso(error))), unwrap_jso(() => successCallback()));
      return;
    }
    if (errorCallback != null) {
      _blink.BlinkDatabase.instance.readTransaction_Callback_2_(unwrap_jso(this), unwrap_jso((transaction) => callback(wrap_jso(transaction))), unwrap_jso((error) => errorCallback(wrap_jso(error))));
      return;
    }
    _blink.BlinkDatabase.instance.readTransaction_Callback_1_(unwrap_jso(this), unwrap_jso((transaction) => callback(wrap_jso(transaction))));
    return;
  }

  void transaction(SqlTransactionCallback callback, [SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) {
    if (successCallback != null) {
      _blink.BlinkDatabase.instance.transaction_Callback_3_(unwrap_jso(this), unwrap_jso((transaction) => callback(wrap_jso(transaction))), unwrap_jso((error) => errorCallback(wrap_jso(error))), unwrap_jso(() => successCallback()));
      return;
    }
    if (errorCallback != null) {
      _blink.BlinkDatabase.instance.transaction_Callback_2_(unwrap_jso(this), unwrap_jso((transaction) => callback(wrap_jso(transaction))), unwrap_jso((error) => errorCallback(wrap_jso(error))));
      return;
    }
    _blink.BlinkDatabase.instance.transaction_Callback_1_(unwrap_jso(this), unwrap_jso((transaction) => callback(wrap_jso(transaction))));
    return;
  }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SQLError')
// http://www.w3.org/TR/webdatabase/#sqlerror
@Experimental() // deprecated
class SqlError extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory SqlError._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static SqlError internalCreateSqlError() {
    return new SqlError._internalWrap();
  }

  factory SqlError._internalWrap() {
    return new SqlError.internal_();
  }

  @Deprecated("Internal Use Only")
  SqlError.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

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
  int get code => _blink.BlinkSQLError.instance.code_Getter_(unwrap_jso(this));
  
  @DomName('SQLError.message')
  @DocsEditable()
  String get message => _blink.BlinkSQLError.instance.message_Getter_(unwrap_jso(this));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SQLResultSet')
// http://www.w3.org/TR/webdatabase/#sqlresultset
@Experimental() // deprecated
class SqlResultSet extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory SqlResultSet._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static SqlResultSet internalCreateSqlResultSet() {
    return new SqlResultSet._internalWrap();
  }

  factory SqlResultSet._internalWrap() {
    return new SqlResultSet.internal_();
  }

  @Deprecated("Internal Use Only")
  SqlResultSet.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SQLResultSet.insertId')
  @DocsEditable()
  int get insertId => _blink.BlinkSQLResultSet.instance.insertId_Getter_(unwrap_jso(this));
  
  @DomName('SQLResultSet.rows')
  @DocsEditable()
  SqlResultSetRowList get rows => wrap_jso(_blink.BlinkSQLResultSet.instance.rows_Getter_(unwrap_jso(this)));
  
  @DomName('SQLResultSet.rowsAffected')
  @DocsEditable()
  int get rowsAffected => _blink.BlinkSQLResultSet.instance.rowsAffected_Getter_(unwrap_jso(this));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SQLResultSetRowList')
// http://www.w3.org/TR/webdatabase/#sqlresultsetrowlist
@Experimental() // deprecated
class SqlResultSetRowList extends DartHtmlDomObject with ListMixin<Map>, ImmutableListMixin<Map> implements List<Map> {
  // To suppress missing implicit constructor warnings.
  factory SqlResultSetRowList._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static SqlResultSetRowList internalCreateSqlResultSetRowList() {
    return new SqlResultSetRowList._internalWrap();
  }

  factory SqlResultSetRowList._internalWrap() {
    return new SqlResultSetRowList.internal_();
  }

  @Deprecated("Internal Use Only")
  SqlResultSetRowList.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('SQLResultSetRowList.length')
  @DocsEditable()
  int get length => _blink.BlinkSQLResultSetRowList.instance.length_Getter_(unwrap_jso(this));
  
  Map operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.index(index, this);
    return wrap_jso(_blink.BlinkSQLResultSetRowList.instance.item_Callback_1_(unwrap_jso(this), index));
  }

  Map _nativeIndexedGetter(int index) => wrap_jso(_blink.BlinkSQLResultSetRowList.instance.item_Callback_1_(unwrap_jso(this), index));

  void operator[]=(int index, Map value) {
    throw new UnsupportedError("Cannot assign element of immutable List.");
  }
  // -- start List<Map> mixins.
  // Map is the element type.


  set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  Map get first {
    if (this.length > 0) {
      return _nativeIndexedGetter(0);
    }
    throw new StateError("No elements");
  }

  Map get last {
    int len = this.length;
    if (len > 0) {
      return _nativeIndexedGetter(len - 1);
    }
    throw new StateError("No elements");
  }

  Map get single {
    int len = this.length;
    if (len == 1) {
      return _nativeIndexedGetter(0);
    }
    if (len == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  Map elementAt(int index) => this[index];
  // -- end List<Map> mixins.

  @DomName('SQLResultSetRowList.item')
  @DocsEditable()
  Object item(int index) => wrap_jso(_blink.BlinkSQLResultSetRowList.instance.item_Callback_1_(unwrap_jso(this), index));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SQLTransaction')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental()
// http://www.w3.org/TR/webdatabase/#sqltransaction
@deprecated // deprecated
class SqlTransaction extends DartHtmlDomObject {
  // To suppress missing implicit constructor warnings.
  factory SqlTransaction._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static SqlTransaction internalCreateSqlTransaction() {
    return new SqlTransaction._internalWrap();
  }

  factory SqlTransaction._internalWrap() {
    return new SqlTransaction.internal_();
  }

  @Deprecated("Internal Use Only")
  SqlTransaction.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  void executeSql(String sqlStatement, [List arguments, SqlStatementCallback callback, SqlStatementErrorCallback errorCallback]) {
    if (errorCallback != null) {
      _blink.BlinkSQLTransaction.instance.executeSql_Callback_4_(unwrap_jso(this), sqlStatement, arguments, unwrap_jso((transaction, resultSet) => callback(wrap_jso(transaction), wrap_jso(resultSet))), unwrap_jso((transaction, error) => errorCallback(wrap_jso(transaction), wrap_jso(error))));
      return;
    }
    if (callback != null) {
      _blink.BlinkSQLTransaction.instance.executeSql_Callback_3_(unwrap_jso(this), sqlStatement, arguments, unwrap_jso((transaction, resultSet) => callback(wrap_jso(transaction), wrap_jso(resultSet))));
      return;
    }
    if (arguments != null) {
      _blink.BlinkSQLTransaction.instance.executeSql_Callback_2_(unwrap_jso(this), sqlStatement, arguments);
      return;
    }
    _blink.BlinkSQLTransaction.instance.executeSql_Callback_1_(unwrap_jso(this), sqlStatement);
    return;
  }

}
