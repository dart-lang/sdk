
class IDBVersionChangeRequestJs extends IDBRequestJs implements IDBVersionChangeRequest native "*IDBVersionChangeRequest" {

  EventListener get onblocked() native "return this.onblocked;";

  void set onblocked(EventListener value) native "this.onblocked = value;";
}
