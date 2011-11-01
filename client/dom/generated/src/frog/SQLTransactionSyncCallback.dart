
class SQLTransactionSyncCallback native "SQLTransactionSyncCallback" {

  bool handleEvent(SQLTransactionSync transaction) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
