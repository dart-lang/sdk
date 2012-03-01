
class _DatabaseImpl implements Database native "*Database" {

  final String version;

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionCallback callback = null, SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) native;

  void readTransaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) native;

  void transaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) native;
}
