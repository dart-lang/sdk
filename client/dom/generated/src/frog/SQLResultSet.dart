
class SQLResultSet native "SQLResultSet" {

  int insertId;

  SQLResultSetRowList rows;

  int rowsAffected;

  var dartObjectLocalStorage;

  String get typeName() native;
}
