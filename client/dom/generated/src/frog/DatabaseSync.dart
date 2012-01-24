
class DatabaseSyncJS implements DatabaseSync native "*DatabaseSync" {

  String get lastErrorMessage() native "return this.lastErrorMessage;";

  String get version() native "return this.version;";

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionSyncCallback callback = null]) native;

  void readTransaction(SQLTransactionSyncCallback callback) native;

  void transaction(SQLTransactionSyncCallback callback) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
