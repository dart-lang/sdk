
class SQLResultSetRowList native "*SQLResultSetRowList" {

  int length;

  Object item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
