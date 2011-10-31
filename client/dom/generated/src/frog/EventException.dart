
class EventException native "EventException" {

  int code;

  String message;

  String name;

  var dartObjectLocalStorage;

  String get typeName() native;
}
