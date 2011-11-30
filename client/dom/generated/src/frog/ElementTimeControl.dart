
class ElementTimeControl native "*ElementTimeControl" {

  void beginElement() native;

  void beginElementAt(num offset) native;

  void endElement() native;

  void endElementAt(num offset) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
