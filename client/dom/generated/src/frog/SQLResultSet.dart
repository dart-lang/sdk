
class SQLResultSetJS implements SQLResultSet native "*SQLResultSet" {

  int get insertId() native "return this.insertId;";

  SQLResultSetRowListJS get rows() native "return this.rows;";

  int get rowsAffected() native "return this.rowsAffected;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
