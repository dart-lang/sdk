
class EventExceptionJs extends DOMTypeJs implements EventException native "*EventException" {

  static final int DISPATCH_REQUEST_ERR = 1;

  static final int UNSPECIFIED_EVENT_TYPE_ERR = 0;

  int get code() native "return this.code;";

  String get message() native "return this.message;";

  String get name() native "return this.name;";

  String toString() native;
}
