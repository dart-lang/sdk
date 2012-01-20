
class StyleMedia native "*StyleMedia" {

  String get type() native "return this.type;";

  bool matchMedium(String mediaquery) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
