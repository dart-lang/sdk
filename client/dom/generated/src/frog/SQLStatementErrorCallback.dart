
class SQLStatementErrorCallback native "SQLStatementErrorCallback" {

  bool handleEvent(SQLTransaction transaction, SQLError error) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
