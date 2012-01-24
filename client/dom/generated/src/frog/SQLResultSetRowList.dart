
class SQLResultSetRowListJs extends DOMTypeJs implements SQLResultSetRowList native "*SQLResultSetRowList" {

  int get length() native "return this.length;";

  Object item(int index) native;
}
