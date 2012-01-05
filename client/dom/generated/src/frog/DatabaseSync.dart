
class DatabaseSync native "*DatabaseSync" {

  String lastErrorMessage;

  String version;

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionSyncCallback callback = null]) native;

  void readTransaction(SQLTransactionSyncCallback callback) native;

  void transaction(SQLTransactionSyncCallback callback) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
