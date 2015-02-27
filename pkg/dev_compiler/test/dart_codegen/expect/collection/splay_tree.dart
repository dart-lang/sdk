part of dart.collection;
 typedef bool _Predicate<T>(T value);
 class _SplayTreeNode<K> {final K key;
 _SplayTreeNode<K> left;
 _SplayTreeNode<K> right;
 _SplayTreeNode(K this.key);
}
 class _SplayTreeMapNode<K, V> extends _SplayTreeNode<K> {V value;
 _SplayTreeMapNode(K key, V this.value) : super(key);
}
 abstract class _SplayTree<K> {_SplayTreeNode<K> _root;
 _SplayTreeNode<K> _dummy = new _SplayTreeNode<K>(((__x51) => DDC$RT.cast(__x51, Null, K, "CastLiteral", """line 46, column 52 of dart:collection/splay_tree.dart: """, __x51 is K, false))(null));
 int _count = 0;
 int _modificationCount = 0;
 int _splayCount = 0;
 int _compare(K key1, K key2);
 int _splay(K key) {
if (_root == null) return -1;
 _SplayTreeNode<K> left = _dummy;
 _SplayTreeNode<K> right = _dummy;
 _SplayTreeNode<K> current = _root;
 int comp;
 while (true) {
comp = _compare(current.key, key);
 if (comp > 0) {
  if (current.left == null) break;
   comp = _compare(current.left.key, key);
   if (comp > 0) {
    _SplayTreeNode<K> tmp = current.left;
     current.left = tmp.right;
     tmp.right = current;
     current = tmp;
     if (current.left == null) break;
    }
   right.left = current;
   right = current;
   current = current.left;
  }
 else if (comp < 0) {
  if (current.right == null) break;
   comp = _compare(current.right.key, key);
   if (comp < 0) {
    _SplayTreeNode<K> tmp = current.right;
     current.right = tmp.left;
     tmp.left = current;
     current = tmp;
     if (current.right == null) break;
    }
   left.right = current;
   left = current;
   current = current.right;
  }
 else {
  break;
  }
}
 left.right = current.left;
 right.left = current.right;
 current.left = _dummy.right;
 current.right = _dummy.left;
 _root = current;
 _dummy.right = null;
 _dummy.left = null;
 _splayCount++;
 return comp;
}
 _SplayTreeNode<K> _splayMin(_SplayTreeNode<K> node) {
_SplayTreeNode current = node;
 while (current.left != null) {
_SplayTreeNode left = current.left;
 current.left = left.right;
 left.right = current;
 current = left;
}
 return DDC$RT.cast(current, DDC$RT.type((_SplayTreeNode<dynamic> _) {
}
), DDC$RT.type((_SplayTreeNode<K> _) {
}
), "CastDynamic", """line 151, column 12 of dart:collection/splay_tree.dart: """, current is _SplayTreeNode<K>, false);
}
 _SplayTreeNode<K> _splayMax(_SplayTreeNode<K> node) {
_SplayTreeNode current = node;
 while (current.right != null) {
_SplayTreeNode right = current.right;
 current.right = right.left;
 right.left = current;
 current = right;
}
 return DDC$RT.cast(current, DDC$RT.type((_SplayTreeNode<dynamic> _) {
}
), DDC$RT.type((_SplayTreeNode<K> _) {
}
), "CastDynamic", """line 167, column 12 of dart:collection/splay_tree.dart: """, current is _SplayTreeNode<K>, false);
}
 _SplayTreeNode _remove(K key) {
if (_root == null) return null;
 int comp = _splay(key);
 if (comp != 0) return null;
 _SplayTreeNode result = _root;
 _count--;
 if (_root.left == null) {
_root = _root.right;
}
 else {
_SplayTreeNode<K> right = _root.right;
 _root = _splayMax(_root.left);
 _root.right = right;
}
 _modificationCount++;
 return result;
}
 void _addNewRoot(_SplayTreeNode<K> node, int comp) {
_count++;
 _modificationCount++;
 if (_root == null) {
_root = node;
 return;}
 if (comp < 0) {
node.left = _root;
 node.right = _root.right;
 _root.right = null;
}
 else {
node.right = _root;
 node.left = _root.left;
 _root.left = null;
}
 _root = node;
}
 _SplayTreeNode get _first {
if (_root == null) return null;
 _root = _splayMin(_root);
 return _root;
}
 _SplayTreeNode get _last {
if (_root == null) return null;
 _root = _splayMax(_root);
 return _root;
}
 void _clear() {
_root = null;
 _count = 0;
 _modificationCount++;
}
}
 class _TypeTest<T> {bool test(v) => v is T;
}
 class SplayTreeMap<K, V> extends _SplayTree<K> implements Map<K, V> {Comparator<K> _comparator;
 _Predicate _validKey;
 SplayTreeMap([int compare(K key1, K key2), bool isValidKey(potentialKey)]) : _comparator = ((__x55) => DDC$RT.cast(__x55, dynamic, DDC$RT.type((__t52<K> _) {
}
), "CastGeneral", """line 268, column 23 of dart:collection/splay_tree.dart: """, __x55 is __t52<K>, false))((compare == null) ? Comparable.compare : compare), _validKey = ((__x58) => DDC$RT.cast(__x58, dynamic, __t56, "CastGeneral", """line 269, column 21 of dart:collection/splay_tree.dart: """, __x58 is __t56, false))((isValidKey != null) ? isValidKey : ((v) => v is K));
 factory SplayTreeMap.from(Map other, [int compare(K key1, K key2), bool isValidKey(potentialKey)]) {
SplayTreeMap<K, V> result = new SplayTreeMap<K, V>();
 other.forEach((k, v) {
result[k] = DDC$RT.cast(v, dynamic, V, "CastGeneral", """line 278, column 40 of dart:collection/splay_tree.dart: """, v is V, false);
}
);
 return result;
}
 factory SplayTreeMap.fromIterable(Iterable iterable, {
K key(element), V value(element), int compare(K key1, K key2), bool isValidKey(potentialKey)}
) {
SplayTreeMap<K, V> map = new SplayTreeMap<K, V>(compare, isValidKey);
 Maps._fillMapWithMappedIterable(map, iterable, key, value);
 return map;
}
 factory SplayTreeMap.fromIterables(Iterable<K> keys, Iterable<V> values, [int compare(K key1, K key2), bool isValidKey(potentialKey)]) {
SplayTreeMap<K, V> map = new SplayTreeMap<K, V>(compare, isValidKey);
 Maps._fillMapWithIterables(map, keys, values);
 return map;
}
 int _compare(K key1, K key2) => _comparator(key1, key2);
 SplayTreeMap._internal();
 V operator [](Object key) {
if (key == null) throw new ArgumentError(key);
 if (!_validKey(key)) return ((__x59) => DDC$RT.cast(__x59, Null, V, "CastLiteral", """line 329, column 33 of dart:collection/splay_tree.dart: """, __x59 is V, false))(null);
 if (_root != null) {
int comp = _splay(DDC$RT.cast(key, Object, K, "CastGeneral", """line 331, column 25 of dart:collection/splay_tree.dart: """, key is K, false));
 if (comp == 0) {
_SplayTreeMapNode mapRoot = DDC$RT.cast(_root, DDC$RT.type((_SplayTreeNode<K> _) {
}
), DDC$RT.type((_SplayTreeMapNode<dynamic, dynamic> _) {
}
), "CastGeneral", """line 333, column 37 of dart:collection/splay_tree.dart: """, _root is _SplayTreeMapNode<dynamic, dynamic>, true);
 return DDC$RT.cast(mapRoot.value, dynamic, V, "CastGeneral", """line 334, column 16 of dart:collection/splay_tree.dart: """, mapRoot.value is V, false);
}
}
 return ((__x60) => DDC$RT.cast(__x60, Null, V, "CastLiteral", """line 337, column 12 of dart:collection/splay_tree.dart: """, __x60 is V, false))(null);
}
 V remove(Object key) {
if (!_validKey(key)) return ((__x61) => DDC$RT.cast(__x61, Null, V, "CastLiteral", """line 341, column 33 of dart:collection/splay_tree.dart: """, __x61 is V, false))(null);
 _SplayTreeMapNode mapRoot = ((__x62) => DDC$RT.cast(__x62, DDC$RT.type((_SplayTreeNode<dynamic> _) {
}
), DDC$RT.type((_SplayTreeMapNode<dynamic, dynamic> _) {
}
), "CastGeneral", """line 342, column 33 of dart:collection/splay_tree.dart: """, __x62 is _SplayTreeMapNode<dynamic, dynamic>, true))(_remove(DDC$RT.cast(key, Object, K, "CastGeneral", """line 342, column 41 of dart:collection/splay_tree.dart: """, key is K, false)));
 if (mapRoot != null) return DDC$RT.cast(mapRoot.value, dynamic, V, "CastGeneral", """line 343, column 33 of dart:collection/splay_tree.dart: """, mapRoot.value is V, false);
 return ((__x63) => DDC$RT.cast(__x63, Null, V, "CastLiteral", """line 344, column 12 of dart:collection/splay_tree.dart: """, __x63 is V, false))(null);
}
 void operator []=(K key, V value) {
if (key == null) throw new ArgumentError(key);
 int comp = _splay(key);
 if (comp == 0) {
_SplayTreeMapNode mapRoot = DDC$RT.cast(_root, DDC$RT.type((_SplayTreeNode<K> _) {
}
), DDC$RT.type((_SplayTreeMapNode<dynamic, dynamic> _) {
}
), "CastGeneral", """line 353, column 35 of dart:collection/splay_tree.dart: """, _root is _SplayTreeMapNode<dynamic, dynamic>, true);
 mapRoot.value = value;
 return;}
 _addNewRoot(((__x64) => DDC$RT.cast(__x64, DDC$RT.type((_SplayTreeMapNode<dynamic, dynamic> _) {
}
), DDC$RT.type((_SplayTreeNode<K> _) {
}
), "CastExact", """line 357, column 17 of dart:collection/splay_tree.dart: """, __x64 is _SplayTreeNode<K>, false))(new _SplayTreeMapNode(key, value)), comp);
}
 V putIfAbsent(K key, V ifAbsent()) {
if (key == null) throw new ArgumentError(key);
 int comp = _splay(key);
 if (comp == 0) {
_SplayTreeMapNode mapRoot = DDC$RT.cast(_root, DDC$RT.type((_SplayTreeNode<K> _) {
}
), DDC$RT.type((_SplayTreeMapNode<dynamic, dynamic> _) {
}
), "CastGeneral", """line 365, column 35 of dart:collection/splay_tree.dart: """, _root is _SplayTreeMapNode<dynamic, dynamic>, true);
 return DDC$RT.cast(mapRoot.value, dynamic, V, "CastGeneral", """line 366, column 14 of dart:collection/splay_tree.dart: """, mapRoot.value is V, false);
}
 int modificationCount = _modificationCount;
 int splayCount = _splayCount;
 V value = ifAbsent();
 if (modificationCount != _modificationCount) {
throw new ConcurrentModificationError(this);
}
 if (splayCount != _splayCount) {
comp = _splay(key);
 assert (comp != 0);}
 _addNewRoot(((__x65) => DDC$RT.cast(__x65, DDC$RT.type((_SplayTreeMapNode<dynamic, dynamic> _) {
}
), DDC$RT.type((_SplayTreeNode<K> _) {
}
), "CastExact", """line 379, column 17 of dart:collection/splay_tree.dart: """, __x65 is _SplayTreeNode<K>, false))(new _SplayTreeMapNode(key, value)), comp);
 return value;
}
 void addAll(Map<K, V> other) {
other.forEach((K key, V value) {
this[key] = value;
}
);
}
 bool get isEmpty {
return (_root == null);
}
 bool get isNotEmpty => !isEmpty;
 void forEach(void f(K key, V value)) {
Iterator<_SplayTreeNode<K>> nodes = new _SplayTreeNodeIterator<K>(this);
 while (nodes.moveNext()) {
_SplayTreeMapNode<K, V> node = DDC$RT.cast(nodes.current, DDC$RT.type((_SplayTreeNode<K> _) {
}
), DDC$RT.type((_SplayTreeMapNode<K, V> _) {
}
), "CastGeneral", """line 397, column 38 of dart:collection/splay_tree.dart: """, nodes.current is _SplayTreeMapNode<K, V>, false);
 f(node.key, node.value);
}
}
 int get length {
return _count;
}
 void clear() {
_clear();
}
 bool containsKey(Object key) {
return _validKey(key) && _splay(DDC$RT.cast(key, Object, K, "CastGeneral", """line 411, column 37 of dart:collection/splay_tree.dart: """, key is K, false)) == 0;
}
 bool containsValue(Object value) {
bool found = false;
 int initialSplayCount = _splayCount;
 bool visit(_SplayTreeMapNode node) {
while (node != null) {
if (node.value == value) return true;
 if (initialSplayCount != _splayCount) {
throw new ConcurrentModificationError(this);
}
 if (node.right != null && visit(DDC$RT.cast(node.right, DDC$RT.type((_SplayTreeNode<dynamic> _) {
}
), DDC$RT.type((_SplayTreeMapNode<dynamic, dynamic> _) {
}
), "CastGeneral", """line 423, column 41 of dart:collection/splay_tree.dart: """, node.right is _SplayTreeMapNode<dynamic, dynamic>, true))) return true;
 node = DDC$RT.cast(node.left, DDC$RT.type((_SplayTreeNode<dynamic> _) {
}
), DDC$RT.type((_SplayTreeMapNode<dynamic, dynamic> _) {
}
), "CastGeneral", """line 424, column 16 of dart:collection/splay_tree.dart: """, node.left is _SplayTreeMapNode<dynamic, dynamic>, true);
}
 return false;
}
 return visit(DDC$RT.cast(_root, DDC$RT.type((_SplayTreeNode<K> _) {
}
), DDC$RT.type((_SplayTreeMapNode<dynamic, dynamic> _) {
}
), "CastGeneral", """line 428, column 18 of dart:collection/splay_tree.dart: """, _root is _SplayTreeMapNode<dynamic, dynamic>, true));
}
 Iterable<K> get keys => new _SplayTreeKeyIterable<K>(this);
 Iterable<V> get values => new _SplayTreeValueIterable<K, V>(this);
 String toString() {
return Maps.mapToString(this);
}
 K firstKey() {
if (_root == null) return ((__x66) => DDC$RT.cast(__x66, Null, K, "CastLiteral", """line 443, column 31 of dart:collection/splay_tree.dart: """, __x66 is K, false))(null);
 return DDC$RT.cast(_first.key, dynamic, K, "CastGeneral", """line 444, column 12 of dart:collection/splay_tree.dart: """, _first.key is K, false);
}
 K lastKey() {
if (_root == null) return ((__x67) => DDC$RT.cast(__x67, Null, K, "CastLiteral", """line 451, column 31 of dart:collection/splay_tree.dart: """, __x67 is K, false))(null);
 return DDC$RT.cast(_last.key, dynamic, K, "CastGeneral", """line 452, column 12 of dart:collection/splay_tree.dart: """, _last.key is K, false);
}
 K lastKeyBefore(K key) {
if (key == null) throw new ArgumentError(key);
 if (_root == null) return ((__x68) => DDC$RT.cast(__x68, Null, K, "CastLiteral", """line 461, column 31 of dart:collection/splay_tree.dart: """, __x68 is K, false))(null);
 int comp = _splay(key);
 if (comp < 0) return _root.key;
 _SplayTreeNode<K> node = _root.left;
 if (node == null) return ((__x69) => DDC$RT.cast(__x69, Null, K, "CastLiteral", """line 465, column 30 of dart:collection/splay_tree.dart: """, __x69 is K, false))(null);
 while (node.right != null) {
node = node.right;
}
 return node.key;
}
 K firstKeyAfter(K key) {
if (key == null) throw new ArgumentError(key);
 if (_root == null) return ((__x70) => DDC$RT.cast(__x70, Null, K, "CastLiteral", """line 478, column 31 of dart:collection/splay_tree.dart: """, __x70 is K, false))(null);
 int comp = _splay(key);
 if (comp > 0) return _root.key;
 _SplayTreeNode<K> node = _root.right;
 if (node == null) return ((__x71) => DDC$RT.cast(__x71, Null, K, "CastLiteral", """line 482, column 30 of dart:collection/splay_tree.dart: """, __x71 is K, false))(null);
 while (node.left != null) {
node = node.left;
}
 return node.key;
}
}
 abstract class _SplayTreeIterator<T> implements Iterator<T> {final _SplayTree _tree;
 final List<_SplayTreeNode> _workList = <_SplayTreeNode> [];
 int _modificationCount;
 int _splayCount;
 _SplayTreeNode _currentNode;
 _SplayTreeIterator(_SplayTree tree) : _tree = tree, _modificationCount = tree._modificationCount, _splayCount = tree._splayCount {
_findLeftMostDescendent(tree._root);
}
 _SplayTreeIterator.startAt(_SplayTree tree, var startKey) : _tree = tree, _modificationCount = tree._modificationCount {
if (tree._root == null) return; int compare = tree._splay(startKey);
 _splayCount = tree._splayCount;
 if (compare < 0) {
_findLeftMostDescendent(tree._root.right);
}
 else {
_workList.add(tree._root);
}
}
 T get current {
if (_currentNode == null) return ((__x72) => DDC$RT.cast(__x72, Null, T, "CastLiteral", """line 547, column 38 of dart:collection/splay_tree.dart: """, __x72 is T, false))(null);
 return _getValue(_currentNode);
}
 void _findLeftMostDescendent(_SplayTreeNode node) {
while (node != null) {
_workList.add(node);
 node = node.left;
}
}
 void _rebuildWorkList(_SplayTreeNode currentNode) {
assert (!_workList.isEmpty); _workList.clear();
 if (currentNode == null) {
_findLeftMostDescendent(_tree._root);
}
 else {
_tree._splay(currentNode.key);
 _findLeftMostDescendent(_tree._root.right);
 assert (!_workList.isEmpty);}
}
 bool moveNext() {
if (_modificationCount != _tree._modificationCount) {
throw new ConcurrentModificationError(_tree);
}
 if (_workList.isEmpty) {
_currentNode = null;
 return false;
}
 if (_tree._splayCount != _splayCount && _currentNode != null) {
_rebuildWorkList(_currentNode);
}
 _currentNode = _workList.removeLast();
 _findLeftMostDescendent(_currentNode.right);
 return true;
}
 T _getValue(_SplayTreeNode node);
}
 class _SplayTreeKeyIterable<K> extends IterableBase<K> implements EfficientLength {_SplayTree<K> _tree;
 _SplayTreeKeyIterable(this._tree);
 int get length => _tree._count;
 bool get isEmpty => _tree._count == 0;
 Iterator<K> get iterator => new _SplayTreeKeyIterator<K>(_tree);
 Set<K> toSet() {
var setOrMap = _tree;
 SplayTreeSet<K> set = new SplayTreeSet<K>(DDC$RT.cast(setOrMap._comparator, dynamic, DDC$RT.type((__t73<K> _) {
}
), "CastGeneral", """line 613, column 29 of dart:collection/splay_tree.dart: """, setOrMap._comparator is __t73<K>, false), DDC$RT.cast(setOrMap._validKey, dynamic, __t56, "CastGeneral", """line 613, column 51 of dart:collection/splay_tree.dart: """, setOrMap._validKey is __t56, false));
 set._count = _tree._count;
 set._root = set._copyNode(_tree._root);
 return set;
}
}
 class _SplayTreeValueIterable<K, V> extends IterableBase<V> implements EfficientLength {SplayTreeMap<K, V> _map;
 _SplayTreeValueIterable(this._map);
 int get length => _map._count;
 bool get isEmpty => _map._count == 0;
 Iterator<V> get iterator => new _SplayTreeValueIterator<K, V>(_map);
}
 class _SplayTreeKeyIterator<K> extends _SplayTreeIterator<K> {_SplayTreeKeyIterator(_SplayTree<K> map) : super(map);
 K _getValue(_SplayTreeNode node) => DDC$RT.cast(node.key, dynamic, K, "CastGeneral", """line 631, column 39 of dart:collection/splay_tree.dart: """, node.key is K, false);
}
 class _SplayTreeValueIterator<K, V> extends _SplayTreeIterator<V> {_SplayTreeValueIterator(SplayTreeMap<K, V> map) : super(map);
 V _getValue(_SplayTreeMapNode node) => DDC$RT.cast(node.value, dynamic, V, "CastGeneral", """line 636, column 42 of dart:collection/splay_tree.dart: """, node.value is V, false);
}
 class _SplayTreeNodeIterator<K> extends _SplayTreeIterator<_SplayTreeNode<K>> {_SplayTreeNodeIterator(_SplayTree<K> tree) : super(tree);
 _SplayTreeNodeIterator.startAt(_SplayTree<K> tree, var startKey) : super.startAt(tree, startKey);
 _SplayTreeNode<K> _getValue(_SplayTreeNode node) => DDC$RT.cast(node, DDC$RT.type((_SplayTreeNode<dynamic> _) {
}
), DDC$RT.type((_SplayTreeNode<K> _) {
}
), "CastDynamic", """line 644, column 55 of dart:collection/splay_tree.dart: """, node is _SplayTreeNode<K>, false);
}
 class SplayTreeSet<E> extends _SplayTree<E> with IterableMixin<E>, SetMixin<E> {Comparator _comparator;
 _Predicate _validKey;
 SplayTreeSet([int compare(E key1, E key2), bool isValidKey(potentialKey)]) : _comparator = ((__x79) => DDC$RT.cast(__x79, dynamic, __t76, "CastGeneral", """line 693, column 23 of dart:collection/splay_tree.dart: """, __x79 is __t76, false))((compare == null) ? Comparable.compare : compare), _validKey = ((__x80) => DDC$RT.cast(__x80, dynamic, __t56, "CastGeneral", """line 694, column 21 of dart:collection/splay_tree.dart: """, __x80 is __t56, false))((isValidKey != null) ? isValidKey : ((v) => v is E));
 factory SplayTreeSet.from(Iterable elements, [int compare(E key1, E key2), bool isValidKey(potentialKey)]) {
SplayTreeSet<E> result = new SplayTreeSet<E>(compare, isValidKey);
 for (final E element in elements) {
result.add(element);
}
 return result;
}
 int _compare(E e1, E e2) => _comparator(e1, e2);
 Iterator<E> get iterator => new _SplayTreeKeyIterator<E>(this);
 int get length => _count;
 bool get isEmpty => _root == null;
 bool get isNotEmpty => _root != null;
 E get first {
if (_count == 0) throw IterableElementError.noElement();
 return DDC$RT.cast(_first.key, dynamic, E, "CastGeneral", """line 725, column 12 of dart:collection/splay_tree.dart: """, _first.key is E, false);
}
 E get last {
if (_count == 0) throw IterableElementError.noElement();
 return DDC$RT.cast(_last.key, dynamic, E, "CastGeneral", """line 730, column 12 of dart:collection/splay_tree.dart: """, _last.key is E, false);
}
 E get single {
if (_count == 0) throw IterableElementError.noElement();
 if (_count > 1) throw IterableElementError.tooMany();
 return _root.key;
}
 bool contains(Object object) {
return _validKey(object) && _splay(DDC$RT.cast(object, Object, E, "CastGeneral", """line 741, column 40 of dart:collection/splay_tree.dart: """, object is E, false)) == 0;
}
 bool add(E element) {
int compare = _splay(element);
 if (compare == 0) return false;
 _addNewRoot(((__x81) => DDC$RT.cast(__x81, DDC$RT.type((_SplayTreeNode<dynamic> _) {
}
), DDC$RT.type((_SplayTreeNode<E> _) {
}
), "CastExact", """line 747, column 17 of dart:collection/splay_tree.dart: """, __x81 is _SplayTreeNode<E>, false))(new _SplayTreeNode(element)), compare);
 return true;
}
 bool remove(Object object) {
if (!_validKey(object)) return false;
 return _remove(DDC$RT.cast(object, Object, E, "CastGeneral", """line 753, column 20 of dart:collection/splay_tree.dart: """, object is E, false)) != null;
}
 void addAll(Iterable<E> elements) {
for (E element in elements) {
int compare = _splay(element);
 if (compare != 0) {
_addNewRoot(((__x82) => DDC$RT.cast(__x82, DDC$RT.type((_SplayTreeNode<dynamic> _) {
}
), DDC$RT.type((_SplayTreeNode<E> _) {
}
), "CastExact", """line 760, column 21 of dart:collection/splay_tree.dart: """, __x82 is _SplayTreeNode<E>, false))(new _SplayTreeNode(element)), compare);
}
}
}
 void removeAll(Iterable<Object> elements) {
for (Object element in elements) {
if (_validKey(element)) _remove(DDC$RT.cast(element, Object, E, "CastGeneral", """line 767, column 39 of dart:collection/splay_tree.dart: """, element is E, false));
}
}
 void retainAll(Iterable<Object> elements) {
SplayTreeSet<E> retainSet = new SplayTreeSet<E>(_comparator, _validKey);
 int modificationCount = _modificationCount;
 for (Object object in elements) {
if (modificationCount != _modificationCount) {
throw new ConcurrentModificationError(this);
}
 if (_validKey(object) && _splay(DDC$RT.cast(object, Object, E, "CastGeneral", """line 781, column 39 of dart:collection/splay_tree.dart: """, object is E, false)) == 0) retainSet.add(_root.key);
}
 if (retainSet._count != _count) {
_root = retainSet._root;
 _count = retainSet._count;
 _modificationCount++;
}
}
 E lookup(Object object) {
if (!_validKey(object)) return ((__x83) => DDC$RT.cast(__x83, Null, E, "CastLiteral", """line 792, column 36 of dart:collection/splay_tree.dart: """, __x83 is E, false))(null);
 int comp = _splay(DDC$RT.cast(object, Object, E, "CastGeneral", """line 793, column 23 of dart:collection/splay_tree.dart: """, object is E, false));
 if (comp != 0) return ((__x84) => DDC$RT.cast(__x84, Null, E, "CastLiteral", """line 794, column 27 of dart:collection/splay_tree.dart: """, __x84 is E, false))(null);
 return _root.key;
}
 Set<E> intersection(Set<E> other) {
Set<E> result = new SplayTreeSet<E>(_comparator, _validKey);
 for (E element in this) {
if (other.contains(element)) result.add(element);
}
 return result;
}
 Set<E> difference(Set<E> other) {
Set<E> result = new SplayTreeSet<E>(_comparator, _validKey);
 for (E element in this) {
if (!other.contains(element)) result.add(element);
}
 return result;
}
 Set<E> union(Set<E> other) {
return _clone()..addAll(other);
}
 SplayTreeSet<E> _clone() {
var set = new SplayTreeSet<E>(_comparator, _validKey);
 set._count = _count;
 set._root = _copyNode(_root);
 return set;
}
 _SplayTreeNode<E> _copyNode(_SplayTreeNode<E> node) {
if (node == null) return null;
 return new _SplayTreeNode<E>(node.key)..left = _copyNode(node.left)..right = _copyNode(node.right);
}
 void clear() {
_clear();
}
 Set<E> toSet() => _clone();
 String toString() => IterableBase.iterableToFullString(this, '{', '}');
}
 typedef int __t52<K>(K __u53, K __u54);
 typedef bool __t56(dynamic __u57);
 typedef int __t73<K>(K __u74, K __u75);
 typedef int __t76(dynamic __u77, dynamic __u78);
