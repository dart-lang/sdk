
class _SQLResultSetJs extends _DOMTypeJs implements SQLResultSet native "*SQLResultSet" {

  int get insertId() native "return this.insertId;";

  _SQLResultSetRowListJs get rows() native "return this.rows;";

  int get rowsAffected() native "return this.rowsAffected;";
}
