
class SQLResultSet native "*SQLResultSet" {

  int get insertId() native "return this.insertId;";

  SQLResultSetRowList get rows() native "return this.rows;";

  int get rowsAffected() native "return this.rowsAffected;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
