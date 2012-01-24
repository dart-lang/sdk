
class IDBVersionChangeEventJS extends EventJS implements IDBVersionChangeEvent native "*IDBVersionChangeEvent" {

  String get version() native "return this.version;";
}
