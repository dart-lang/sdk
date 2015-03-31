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
 _SplayTreeNode<K> _dummy = new _SplayTreeNode<K>(null);
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
 return DEVC$RT.cast(current, DEVC$RT.type((_SplayTreeNode<dynamic> _) {
}
), DEVC$RT.type((_SplayTreeNode<K> _) {
}
), "CompositeCast", """line 151, column 12 of dart:collection/splay_tree.dart: """, current is _SplayTreeNode<K>, false);
}
 _SplayTreeNode<K> _splayMax(_SplayTreeNode<K> node) {
_SplayTreeNode current = node;
 while (current.right != null) {
_SplayTreeNode right = current.right;
 current.right = right.left;
 right.left = current;
 current = right;
}
 return DEVC$RT.cast(current, DEVC$RT.type((_SplayTreeNode<dynamic> _) {
}
), DEVC$RT.type((_SplayTreeNode<K> _) {
}
), "CompositeCast", """line 167, column 12 of dart:collection/splay_tree.dart: """, current is _SplayTreeNode<K>, false);
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
 SplayTreeMap([int compare(K key1, K key2), bool isValidKey(potentialKey)]) : _comparator = ((__x21) => DEVC$RT.cast(__x21, dynamic, DEVC$RT.type((__t18<K> _) {
}
), "CompositeCast", """line 268, column 23 of dart:collection/splay_tree.dart: """, __x21 is __t18<K>, false))((compare == null) ? Comparable.compare : compare), _validKey = ((__x24) => DEVC$RT.cast(__x24, dynamic, __t22, "CompositeCast", """line 269, column 21 of dart:collection/splay_tree.dart: """, __x24 is __t22, false))((isValidKey != null) ? isValidKey : ((v) => v is K));
 factory SplayTreeMap.from(Map other, [int compare(K key1, K key2), bool isValidKey(potentialKey)]) {
SplayTreeMap<K, V> result = new SplayTreeMap<K, V>();
 other.forEach((k, v) {
result[k] = DEVC$RT.cast(v, dynamic, V, "CompositeCast", """line 278, column 40 of dart:collection/splay_tree.dart: """, v is V, false);
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
 if (!_validKey(key)) return null;
 if (_root != null) {
int comp = _splay(DEVC$RT.cast(key, Object, K, "CompositeCast", """line 331, column 25 of dart:collection/splay_tree.dart: """, key is K, false));
 if (comp == 0) {
_SplayTreeMapNode mapRoot = DEVC$RT.cast(_root, DEVC$RT.type((_SplayTreeNode<K> _) {
}
), DEVC$RT.type((_SplayTreeMapNode<dynamic, dynamic> _) {
}
), "AssignmentCast", """line 333, column 37 of dart:collection/splay_tree.dart: """, _root is _SplayTreeMapNode<dynamic, dynamic>, true);
 return DEVC$RT.cast(mapRoot.value, dynamic, V, "CompositeCast", """line 334, column 16 of dart:collection/splay_tree.dart: """, mapRoot.value is V, false);
}
}
 return null;
}
 V remove(Object key) {
if (!_validKey(key)) return null;
 _SplayTreeMapNode mapRoot = ((__x25) => DEVC$RT.cast(__x25, DEVC$RT.type((_SplayTreeNode<dynamic> _) {
}
), DEVC$RT.type((_SplayTreeMapNode<dynamic, dynamic> _) {
}
), "AssignmentCast", """line 342, column 33 of dart:collection/splay_tree.dart: """, __x25 is _SplayTreeMapNode<dynamic, dynamic>, true))(_remove(DEVC$RT.cast(key, Object, K, "CompositeCast", """line 342, column 41 of dart:collection/splay_tree.dart: """, key is K, false)));
 if (mapRoot != null) return DEVC$RT.cast(mapRoot.value, dynamic, V, "CompositeCast", """line 343, column 33 of dart:collection/splay_tree.dart: """, mapRoot.value is V, false);
 return null;
}
 void operator []=(K key, V value) {
if (key == null) throw new ArgumentError(key);
 int comp = _splay(key);
 if (comp == 0) {
_SplayTreeMapNode mapRoot = DEVC$RT.cast(_root, DEVC$RT.type((_SplayTreeNode<K> _) {
}
), DEVC$RT.type((_SplayTreeMapNode<dynamic, dynamic> _) {
}
), "AssignmentCast", """line 353, column 35 of dart:collection/splay_tree.dart: """, _root is _SplayTreeMapNode<dynamic, dynamic>, true);
 mapRoot.value = value;
 return;}
 _addNewRoot(new _SplayTreeMapNode<K, dynamic>(key, value), comp);
}
 V putIfAbsent(K key, V ifAbsent()) {
if (key == null) throw new ArgumentError(key);
 int comp = _splay(key);
 if (comp == 0) {
_SplayTreeMapNode mapRoot = DEVC$RT.cast(_root, DEVC$RT.type((_SplayTreeNode<K> _) {
}
), DEVC$RT.type((_SplayTreeMapNode<dynamic, dynamic> _) {
}
), "AssignmentCast", """line 365, column 35 of dart:collection/splay_tree.dart: """, _root is _SplayTreeMapNode<dynamic, dynamic>, true);
 return DEVC$RT.cast(mapRoot.value, dynamic, V, "CompositeCast", """line 366, column 14 of dart:collection/splay_tree.dart: """, mapRoot.value is V, false);
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
 _addNewRoot(new _SplayTreeMapNode<K, dynamic>(key, value), comp);
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
_SplayTreeMapNode<K, V> node = DEVC$RT.cast(nodes.current, DEVC$RT.type((_SplayTreeNode<K> _) {
}
), DEVC$RT.type((_SplayTreeMapNode<K, V> _) {
}
), "CompositeCast", """line 397, column 38 of dart:collection/splay_tree.dart: """, nodes.current is _SplayTreeMapNode<K, V>, false);
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
return _validKey(key) && _splay(DEVC$RT.cast(key, Object, K, "CompositeCast", """line 411, column 37 of dart:collection/splay_tree.dart: """, key is K, false)) == 0;
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
 if (node.right != null && visit(DEVC$RT.cast(node.right, DEVC$RT.type((_SplayTreeNode<dynamic> _) {
}
), DEVC$RT.type((_SplayTreeMapNode<dynamic, dynamic> _) {
}
), "ImplicitCast", """line 423, column 41 of dart:collection/splay_tree.dart: """, node.right is _SplayTreeMapNode<dynamic, dynamic>, true))) return true;
 node = DEVC$RT.cast(node.left, DEVC$RT.type((_SplayTreeNode<dynamic> _) {
}
), DEVC$RT.type((_SplayTreeMapNode<dynamic, dynamic> _) {
}
), "ImplicitCast", """line 424, column 16 of dart:collection/splay_tree.dart: """, node.left is _SplayTreeMapNode<dynamic, dynamic>, true);
}
 return false;
}
 return visit(DEVC$RT.cast(_root, DEVC$RT.type((_SplayTreeNode<K> _) {
}
), DEVC$RT.type((_SplayTreeMapNode<dynamic, dynamic> _) {
}
), "ImplicitCast", """line 428, column 18 of dart:collection/splay_tree.dart: """, _root is _SplayTreeMapNode<dynamic, dynamic>, true));
}
 Iterable<K> get keys => new _SplayTreeKeyIterable<K>(this);
 Iterable<V> get values => new _SplayTreeValueIterable<K, V>(this);
 String toString() {
return Maps.mapToString(this);
}
 K firstKey() {
if (_root == null) return null;
 return DEVC$RT.cast(_first.key, dynamic, K, "CompositeCast", """line 444, column 12 of dart:collection/splay_tree.dart: """, _first.key is K, false);
}
 K lastKey() {
if (_root == null) return null;
 return DEVC$RT.cast(_last.key, dynamic, K, "CompositeCast", """line 452, column 12 of dart:collection/splay_tree.dart: """, _last.key is K, false);
}
 K lastKeyBefore(K key) {
if (key == null) throw new ArgumentError(key);
 if (_root == null) return null;
 int comp = _splay(key);
 if (comp < 0) return _root.key;
 _SplayTreeNode<K> node = _root.left;
 if (node == null) return null;
 while (node.right != null) {
node = node.right;
}
 return node.key;
}
 K firstKeyAfter(K key) {
if (key == null) throw new ArgumentError(key);
 if (_root == null) return null;
 int comp = _splay(key);
 if (comp > 0) return _root.key;
 _SplayTreeNode<K> node = _root.right;
 if (node == null) return null;
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
if (_currentNode == null) return null;
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
 SplayTreeSet<K> set = new SplayTreeSet<K>(DEVC$RT.cast(setOrMap._comparator, dynamic, DEVC$RT.type((__t26<K> _) {
}
), "CompositeCast", """line 613, column 29 of dart:collection/splay_tree.dart: """, setOrMap._comparator is __t26<K>, false), DEVC$RT.cast(setOrMap._validKey, dynamic, __t22, "CompositeCast", """line 613, column 51 of dart:collection/splay_tree.dart: """, setOrMap._validKey is __t22, false));
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
 K _getValue(_SplayTreeNode node) => DEVC$RT.cast(node.key, dynamic, K, "CompositeCast", """line 631, column 39 of dart:collection/splay_tree.dart: """, node.key is K, false);
}
 class _SplayTreeValueIterator<K, V> extends _SplayTreeIterator<V> {_SplayTreeValueIterator(SplayTreeMap<K, V> map) : super(map);
 V _getValue(_SplayTreeMapNode node) => DEVC$RT.cast(node.value, dynamic, V, "CompositeCast", """line 636, column 42 of dart:collection/splay_tree.dart: """, node.value is V, false);
}
 class _SplayTreeNodeIterator<K> extends _SplayTreeIterator<_SplayTreeNode<K>> {_SplayTreeNodeIterator(_SplayTree<K> tree) : super(tree);
 _SplayTreeNodeIterator.startAt(_SplayTree<K> tree, var startKey) : super.startAt(tree, startKey);
 _SplayTreeNode<K> _getValue(_SplayTreeNode node) => DEVC$RT.cast(node, DEVC$RT.type((_SplayTreeNode<dynamic> _) {
}
), DEVC$RT.type((_SplayTreeNode<K> _) {
}
), "CompositeCast", """line 644, column 55 of dart:collection/splay_tree.dart: """, node is _SplayTreeNode<K>, false);
}
 class SplayTreeSet<E> extends _SplayTree<E> with IterableMixin<E>, SetMixin<E> {Comparator _comparator;
 _Predicate _validKey;
 SplayTreeSet([int compare(E key1, E key2), bool isValidKey(potentialKey)]) : _comparator = ((__x32) => DEVC$RT.cast(__x32, dynamic, __t29, "CompositeCast", """line 693, column 23 of dart:collection/splay_tree.dart: """, __x32 is __t29, false))((compare == null) ? Comparable.compare : compare), _validKey = ((__x33) => DEVC$RT.cast(__x33, dynamic, __t22, "CompositeCast", """line 694, column 21 of dart:collection/splay_tree.dart: """, __x33 is __t22, false))((isValidKey != null) ? isValidKey : ((v) => v is E));
 factory SplayTreeSet.from(Iterable elements, [int compare(E key1, E key2), bool isValidKey(potentialKey)]) {
SplayTreeSet<E> result = new SplayTreeSet<E>(compare, isValidKey);
 for (final E element in DEVC$RT.cast(elements, DEVC$RT.type((Iterable<dynamic> _) {
}
), DEVC$RT.type((Iterable<E> _) {
}
), "CompositeCast", """line 707, column 29 of dart:collection/splay_tree.dart: """, elements is Iterable<E>, false)) {
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
 return DEVC$RT.cast(_first.key, dynamic, E, "CompositeCast", """line 725, column 12 of dart:collection/splay_tree.dart: """, _first.key is E, false);
}
 E get last {
if (_count == 0) throw IterableElementError.noElement();
 return DEVC$RT.cast(_last.key, dynamic, E, "CompositeCast", """line 730, column 12 of dart:collection/splay_tree.dart: """, _last.key is E, false);
}
 E get single {
if (_count == 0) throw IterableElementError.noElement();
 if (_count > 1) throw IterableElementError.tooMany();
 return _root.key;
}
 bool contains(Object object) {
return _validKey(object) && _splay(DEVC$RT.cast(object, Object, E, "CompositeCast", """line 741, column 40 of dart:collection/splay_tree.dart: """, object is E, false)) == 0;
}
 bool add(E element) {
int compare = _splay(element);
 if (compare == 0) return false;
 _addNewRoot(new _SplayTreeNode<E>(element), compare);
 return true;
}
 bool remove(Object object) {
if (!_validKey(object)) return false;
 return _remove(DEVC$RT.cast(object, Object, E, "CompositeCast", """line 753, column 20 of dart:collection/splay_tree.dart: """, object is E, false)) != null;
}
 void addAll(Iterable<E> elements) {
for (E element in elements) {
int compare = _splay(element);
 if (compare != 0) {
_addNewRoot(new _SplayTreeNode<E>(element), compare);
}
}
}
 void removeAll(Iterable<Object> elements) {
for (Object element in elements) {
if (_validKey(element)) _remove(DEVC$RT.cast(element, Object, E, "CompositeCast", """line 767, column 39 of dart:collection/splay_tree.dart: """, element is E, false));
}
}
 void retainAll(Iterable<Object> elements) {
SplayTreeSet<E> retainSet = new SplayTreeSet<E>(DEVC$RT.wrap((int f(dynamic __u34, dynamic __u35)) {
int c(dynamic x0, dynamic x1) => f(x0, x1);
 return f == null ? null : c;
}
, _comparator, __t29, DEVC$RT.type((__t36<E> _) {
}
), "Wrap", """line 773, column 53 of dart:collection/splay_tree.dart: """, _comparator is __t36<E>), _validKey);
 int modificationCount = _modificationCount;
 for (Object object in elements) {
if (modificationCount != _modificationCount) {
throw new ConcurrentModificationError(this);
}
 if (_validKey(object) && _splay(DEVC$RT.cast(object, Object, E, "CompositeCast", """line 781, column 39 of dart:collection/splay_tree.dart: """, object is E, false)) == 0) retainSet.add(_root.key);
}
 if (retainSet._count != _count) {
_root = retainSet._root;
 _count = retainSet._count;
 _modificationCount++;
}
}
 E lookup(Object object) {
if (!_validKey(object)) return null;
 int comp = _splay(DEVC$RT.cast(object, Object, E, "CompositeCast", """line 793, column 23 of dart:collection/splay_tree.dart: """, object is E, false));
 if (comp != 0) return null;
 return _root.key;
}
 Set<E> intersection(Set<E> other) {
Set<E> result = new SplayTreeSet<E>(DEVC$RT.wrap((int f(dynamic __u39, dynamic __u40)) {
int c(dynamic x0, dynamic x1) => f(x0, x1);
 return f == null ? null : c;
}
, _comparator, __t29, DEVC$RT.type((__t36<E> _) {
}
), "Wrap", """line 799, column 41 of dart:collection/splay_tree.dart: """, _comparator is __t36<E>), _validKey);
 for (E element in this) {
if (other.contains(element)) result.add(element);
}
 return result;
}
 Set<E> difference(Set<E> other) {
Set<E> result = new SplayTreeSet<E>(DEVC$RT.wrap((int f(dynamic __u41, dynamic __u42)) {
int c(dynamic x0, dynamic x1) => f(x0, x1);
 return f == null ? null : c;
}
, _comparator, __t29, DEVC$RT.type((__t36<E> _) {
}
), "Wrap", """line 807, column 41 of dart:collection/splay_tree.dart: """, _comparator is __t36<E>), _validKey);
 for (E element in this) {
if (!other.contains(element)) result.add(element);
}
 return result;
}
 Set<E> union(Set<E> other) {
return _clone()..addAll(other);
}
 SplayTreeSet<E> _clone() {
var set = new SplayTreeSet<E>(DEVC$RT.wrap((int f(dynamic __u43, dynamic __u44)) {
int c(dynamic x0, dynamic x1) => f(x0, x1);
 return f == null ? null : c;
}
, _comparator, __t29, DEVC$RT.type((__t36<E> _) {
}
), "Wrap", """line 819, column 35 of dart:collection/splay_tree.dart: """, _comparator is __t36<E>), _validKey);
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
 typedef int __t18<K>(K __u19, K __u20);
 typedef bool __t22(dynamic __u23);
 typedef int __t26<K>(K __u27, K __u28);
 typedef int __t29(dynamic __u30, dynamic __u31);
 typedef int __t36<E>(E __u37, E __u38);
