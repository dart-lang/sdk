
class SQLStatementCallback native "*SQLStatementCallback" {

  bool handleEvent(SQLTransaction transaction, SQLResultSet resultSet) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
