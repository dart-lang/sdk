
class _SQLResultSetImpl extends _DOMTypeBase implements SQLResultSet {
  _SQLResultSetImpl._wrap(ptr) : super._wrap(ptr);

  int get insertId() => _wrap(_ptr.insertId);

  SQLResultSetRowList get rows() => _wrap(_ptr.rows);

  int get rowsAffected() => _wrap(_ptr.rowsAffected);
}
