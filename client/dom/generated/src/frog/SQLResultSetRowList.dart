
class SQLResultSetRowListJS implements SQLResultSetRowList native "*SQLResultSetRowList" {

  int get length() native "return this.length;";

  Object item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
