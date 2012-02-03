
class _IDBVersionChangeEventJs extends _EventJs implements IDBVersionChangeEvent native "*IDBVersionChangeEvent" {

  String get version() native "return this.version;";
}
