
class _IDBCursorJs extends _DOMTypeJs implements IDBCursor native "*IDBCursor" {

  static final int NEXT = 0;

  static final int NEXT_NO_DUPLICATE = 1;

  static final int PREV = 2;

  static final int PREV_NO_DUPLICATE = 3;

  final int direction;

  final _IDBKeyJs key;

  final _IDBKeyJs primaryKey;

  final _IDBAnyJs source;

  void continueFunction([_IDBKeyJs key = null]) native '''
if (key == null) return this['continue']();
return this['continue'](key);
''';

  _IDBRequestJs delete() native;

  _IDBRequestJs update(Dynamic value) native;
}
