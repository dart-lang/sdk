part of dart.collection;
 class LinkedList<E extends LinkedListEntry<E>> extends IterableBase<E> implements _LinkedListLink {int _modificationCount = 0;
 int _length = 0;
 _LinkedListLink _next;
 _LinkedListLink _previous;
 LinkedList() {
  _next = _previous = this;
  }
 void addFirst(E entry) {
  _insertAfter(this, entry);
  }
 void add(E entry) {
  _insertAfter(_previous, entry);
  }
 void addAll(Iterable<E> entries) {
  entries.forEach((entry) => _insertAfter(_previous, DEVC$RT.cast(entry, dynamic, E, "CompositeCast", """line 65, column 56 of dart:collection/linked_list.dart: """, entry is E, false)));
  }
 bool remove(E entry) {
  if (entry._list != this) return false;
   _unlink(entry);
   return true;
  }
 Iterator<E> get iterator => new _LinkedListIterator<E>(this);
 int get length => _length;
 void clear() {
  _modificationCount++;
   _LinkedListLink next = _next;
   while (!identical(next, this)) {
    E entry = DEVC$RT.cast(next, _LinkedListLink, E, "CompositeCast", """line 93, column 17 of dart:collection/linked_list.dart: """, next is E, false);
     next = entry._next;
     entry._next = entry._previous = entry._list = null;
    }
   _next = _previous = this;
   _length = 0;
  }
 E get first {
  if (identical(_next, this)) {
    throw new StateError('No such element');
    }
   return DEVC$RT.cast(_next, _LinkedListLink, E, "CompositeCast", """line 105, column 12 of dart:collection/linked_list.dart: """, _next is E, false);
  }
 E get last {
  if (identical(_previous, this)) {
    throw new StateError('No such element');
    }
   return DEVC$RT.cast(_previous, _LinkedListLink, E, "CompositeCast", """line 112, column 12 of dart:collection/linked_list.dart: """, _previous is E, false);
  }
 E get single {
  if (identical(_previous, this)) {
    throw new StateError('No such element');
    }
   if (!identical(_previous, _next)) {
    throw new StateError('Too many elements');
    }
   return DEVC$RT.cast(_next, _LinkedListLink, E, "CompositeCast", """line 122, column 12 of dart:collection/linked_list.dart: """, _next is E, false);
  }
 void forEach(void action(E entry)) {
  int modificationCount = _modificationCount;
   _LinkedListLink current = _next;
   while (!identical(current, this)) {
    action(DEVC$RT.cast(current, _LinkedListLink, E, "CompositeCast", """line 134, column 14 of dart:collection/linked_list.dart: """, current is E, false));
     if (modificationCount != _modificationCount) {
      throw new ConcurrentModificationError(this);
      }
     current = current._next;
    }
  }
 bool get isEmpty => _length == 0;
 void _insertAfter(_LinkedListLink entry, E newEntry) {
  if (newEntry.list != null) {
    throw new StateError('LinkedListEntry is already in a LinkedList');
    }
   _modificationCount++;
   newEntry._list = this;
   var predecessor = entry;
   var successor = entry._next;
   successor._previous = newEntry;
   newEntry._previous = predecessor;
   newEntry._next = successor;
   predecessor._next = newEntry;
   _length++;
  }
 void _unlink(LinkedListEntry<E> entry) {
  _modificationCount++;
   entry._next._previous = entry._previous;
   entry._previous._next = entry._next;
   _length--;
   entry._list = entry._next = entry._previous = null;
  }
}
 class _LinkedListIterator<E extends LinkedListEntry<E>> implements Iterator<E> {final LinkedList<E> _list;
 final int _modificationCount;
 E _current;
 _LinkedListLink _next;
 _LinkedListIterator(LinkedList<E> list) : _list = list, _modificationCount = list._modificationCount, _next = list._next;
 E get current => _current;
 bool moveNext() {
if (identical(_next, _list)) {
  _current = null;
   return false;
  }
 if (_modificationCount != _list._modificationCount) {
  throw new ConcurrentModificationError(this);
  }
 _current = DEVC$RT.cast(_next, _LinkedListLink, E, "CompositeCast", """line 192, column 16 of dart:collection/linked_list.dart: """, _next is E, false);
 _next = _next._next;
 return true;
}
}
 class _LinkedListLink {_LinkedListLink _next;
 _LinkedListLink _previous;
}
 abstract class LinkedListEntry<E extends LinkedListEntry<E>> implements _LinkedListLink {LinkedList<E> _list;
 _LinkedListLink _next;
 _LinkedListLink _previous;
 LinkedList<E> get list => _list;
 void unlink() {
_list._unlink(this);
}
 E get next {
if (identical(_next, _list)) return null;
 E result = DEVC$RT.cast(_next, _LinkedListLink, E, "CompositeCast", """line 249, column 16 of dart:collection/linked_list.dart: """, _next is E, false);
 return result;
}
 E get previous {
if (identical(_previous, _list)) return null;
 return DEVC$RT.cast(_previous, _LinkedListLink, E, "CastUser", """line 261, column 12 of dart:collection/linked_list.dart: """, _previous is E, false);
}
 void insertAfter(E entry) {
_list._insertAfter(this, entry);
}
 void insertBefore(E entry) {
_list._insertAfter(_previous, entry);
}
}
