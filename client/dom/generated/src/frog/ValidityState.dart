
class ValidityState native "*ValidityState" {

  bool customError;

  bool patternMismatch;

  bool rangeOverflow;

  bool rangeUnderflow;

  bool stepMismatch;

  bool tooLong;

  bool typeMismatch;

  bool valid;

  bool valueMissing;

  var dartObjectLocalStorage;

  String get typeName() native;
}
