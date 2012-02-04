
class _DatabaseSyncJs extends _DOMTypeJs implements DatabaseSync native "*DatabaseSync" {

  final String lastErrorMessage;

  final String version;

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionSyncCallback callback = null]) native;

  void readTransaction(SQLTransactionSyncCallback callback) native;

  void transaction(SQLTransactionSyncCallback callback) native;
}
