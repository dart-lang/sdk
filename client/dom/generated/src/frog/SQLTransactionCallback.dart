
class SQLTransactionCallback native "*SQLTransactionCallback" {

  bool handleEvent(SQLTransaction transaction) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
