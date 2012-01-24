
class IDBVersionChangeEventJs extends EventJs implements IDBVersionChangeEvent native "*IDBVersionChangeEvent" {

  String get version() native "return this.version;";
}
