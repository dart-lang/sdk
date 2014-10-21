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
import 'dart:nativewrappers';
import 'dart:_blink' as _blink;
// DO NOT EDIT - unless you are editing documentation as per:
// https://code.google.com/p/dart/wiki/ContributingHTMLDocumentation
// Auto-generated dart:audio library.




// FIXME: Can we make this private?
final web_sqlBlinkMap = {
  'Database': () => SqlDatabase,
  'SQLError': () => SqlError,
  'SQLResultSet': () => SqlResultSet,
  'SQLResultSetRowList': () => SqlResultSetRowList,
  'SQLTransaction': () => SqlTransaction,
  'SQLTransactionSync': () => _SQLTransactionSync,

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
class SqlDatabase extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory SqlDatabase._() { throw new UnsupportedError("Not supported"); }

  /// Checks if this type is supported on the current platform.
  static bool get supported => true;

  @DomName('Database.version')
  @DocsEditable()
  String get version => _blink.BlinkDatabase.version_Getter(this);

  void changeVersion(String oldVersion, String newVersion, [SqlTransactionCallback callback, SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) {
    if (successCallback != null) {
      _blink.BlinkDatabase.changeVersion_Callback_5(this, oldVersion, newVersion, callback, errorCallback, successCallback);
      return;
    }
    if (errorCallback != null) {
      _blink.BlinkDatabase.changeVersion_Callback_4(this, oldVersion, newVersion, callback, errorCallback);
      return;
    }
    if (callback != null) {
      _blink.BlinkDatabase.changeVersion_Callback_3(this, oldVersion, newVersion, callback);
      return;
    }
    _blink.BlinkDatabase.changeVersion_Callback_2(this, oldVersion, newVersion);
    return;
  }

  void readTransaction(SqlTransactionCallback callback, [SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) {
    if (successCallback != null) {
      _blink.BlinkDatabase.readTransaction_Callback_3(this, callback, errorCallback, successCallback);
      return;
    }
    if (errorCallback != null) {
      _blink.BlinkDatabase.readTransaction_Callback_2(this, callback, errorCallback);
      return;
    }
    _blink.BlinkDatabase.readTransaction_Callback_1(this, callback);
    return;
  }

  void transaction(SqlTransactionCallback callback, [SqlTransactionErrorCallback errorCallback, VoidCallback successCallback]) {
    if (successCallback != null) {
      _blink.BlinkDatabase.transaction_Callback_3(this, callback, errorCallback, successCallback);
      return;
    }
    if (errorCallback != null) {
      _blink.BlinkDatabase.transaction_Callback_2(this, callback, errorCallback);
      return;
    }
    _blink.BlinkDatabase.transaction_Callback_1(this, callback);
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
class SqlError extends NativeFieldWrapperClass2 {
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
  int get code => _blink.BlinkSQLError.code_Getter(this);

  @DomName('SQLError.message')
  @DocsEditable()
  String get message => _blink.BlinkSQLError.message_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SQLResultSet')
// http://www.w3.org/TR/webdatabase/#sqlresultset
@Experimental() // deprecated
class SqlResultSet extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory SqlResultSet._() { throw new UnsupportedError("Not supported"); }

  @DomName('SQLResultSet.insertId')
  @DocsEditable()
  int get insertId => _blink.BlinkSQLResultSet.insertId_Getter(this);

  @DomName('SQLResultSet.rows')
  @DocsEditable()
  SqlResultSetRowList get rows => _blink.BlinkSQLResultSet.rows_Getter(this);

  @DomName('SQLResultSet.rowsAffected')
  @DocsEditable()
  int get rowsAffected => _blink.BlinkSQLResultSet.rowsAffected_Getter(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SQLResultSetRowList')
// http://www.w3.org/TR/webdatabase/#sqlresultsetrowlist
@Experimental() // deprecated
class SqlResultSetRowList extends NativeFieldWrapperClass2 with ListMixin<Map>, ImmutableListMixin<Map> implements List<Map> {
  // To suppress missing implicit constructor warnings.
  factory SqlResultSetRowList._() { throw new UnsupportedError("Not supported"); }

  @DomName('SQLResultSetRowList.length')
  @DocsEditable()
  int get length => _blink.BlinkSQLResultSetRowList.length_Getter(this);

  Map operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.range(index, 0, length);
    return _blink.BlinkSQLResultSetRowList.item_Callback_1(this, index);
  }

  Map _nativeIndexedGetter(int index) => _blink.BlinkSQLResultSetRowList.item_Callback_1(this, index);

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
  Map item(int index) => _blink.BlinkSQLResultSetRowList.item_Callback_1(this, index);

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
class SqlTransaction extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory SqlTransaction._() { throw new UnsupportedError("Not supported"); }

  @DomName('SQLTransaction.executeSql')
  @DocsEditable()
  void executeSql(String sqlStatement, List<Object> arguments, [SqlStatementCallback callback, SqlStatementErrorCallback errorCallback]) => _blink.BlinkSQLTransaction.executeSql_Callback_4(this, sqlStatement, arguments, callback, errorCallback);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('SQLTransactionSync')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.SAFARI)
@Experimental()
// http://www.w3.org/TR/webdatabase/#sqltransactionsync
@Experimental() // deprecated
abstract class _SQLTransactionSync extends NativeFieldWrapperClass2 {
  // To suppress missing implicit constructor warnings.
  factory _SQLTransactionSync._() { throw new UnsupportedError("Not supported"); }

}
