
class SQLResultSetJs extends DOMTypeJs implements SQLResultSet native "*SQLResultSet" {

  int get insertId() native "return this.insertId;";

  SQLResultSetRowListJs get rows() native "return this.rows;";

  int get rowsAffected() native "return this.rowsAffected;";
}
