
class SQLTransactionErrorCallback native "SQLTransactionErrorCallback" {

  bool handleEvent(SQLError error) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
