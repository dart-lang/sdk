part of dart.core;
 @SupportJsExtensionMethod() @JsPeerInterface(name: 'Array') abstract class List<E> implements Iterable<E>, EfficientLength {external factory List([int length]);
 external factory List.filled(int length, E fill);
 external factory List.from(Iterable elements, {
  bool growable : true}
);
 factory List.generate(int length, E generator(int index), {
  bool growable : true}
) {
  List<E> result;
   if (growable) {
    result = <E> []..length = length;
    }
   else {
    result = new List<E>(length);
    }
   for (int i = 0; i < length; i++) {
    result[i] = generator(i);
    }
   return result;
  }
 checkMutable(reason) {
  }
 checkGrowable(reason) {
  }
 Iterable<E> where(bool f(E element)) {
  return new IterableMixinWorkaround<E>().where(this, f);
  }
 Iterable expand(Iterable f(E element)) {
  return IterableMixinWorkaround.expand(this, f);
  }
 void forEach(void f(E element)) {
  int length = this.length;
   for (int i = 0; i < length; i++) {
    f(((__x8) => DEVC$RT.cast(__x8, dynamic, E, "CompositeCast", """line 153, column 9 of dart:core/list.dart: """, __x8 is E, false))(JS('', '#[#]', this, i)));
     if (length != this.length) {
      throw new ConcurrentModificationError(this);
      }
    }
  }
 Iterable map(f(E element)) {
  return IterableMixinWorkaround.mapList(this, f);
  }
 String join([String separator = ""]) {
  var list = new List(this.length);
   for (int i = 0; i < this.length; i++) {
    list[i] = "${this[i]}";
    }
   return ((__x9) => DEVC$RT.cast(__x9, dynamic, String, "DynamicCast", """line 169, column 12 of dart:core/list.dart: """, __x9 is String, true))(JS('String', "#.join(#)", list, separator));
  }
 Iterable<E> take(int n) {
  return new IterableMixinWorkaround<E>().takeList(this, n);
  }
 Iterable<E> takeWhile(bool test(E value)) {
  return new IterableMixinWorkaround<E>().takeWhile(this, test);
  }
 Iterable<E> skip(int n) {
  return new IterableMixinWorkaround<E>().skipList(this, n);
  }
 Iterable<E> skipWhile(bool test(E value)) {
  return new IterableMixinWorkaround<E>().skipWhile(this, test);
  }
 E reduce(E combine(E value, E element)) {
  return ((__x10) => DEVC$RT.cast(__x10, dynamic, E, "CompositeCast", """line 189, column 12 of dart:core/list.dart: """, __x10 is E, false))(IterableMixinWorkaround.reduce(this, combine));
  }
 fold(initialValue, combine(previousValue, E element)) {
  return IterableMixinWorkaround.fold(this, initialValue, combine);
  }
 E firstWhere(bool test(E value), {
  E orElse()}
) {
  return ((__x11) => DEVC$RT.cast(__x11, dynamic, E, "CompositeCast", """line 197, column 12 of dart:core/list.dart: """, __x11 is E, false))(IterableMixinWorkaround.firstWhere(this, test, orElse));
  }
 E lastWhere(bool test(E value), {
  E orElse()}
) {
  return ((__x12) => DEVC$RT.cast(__x12, dynamic, E, "CompositeCast", """line 201, column 12 of dart:core/list.dart: """, __x12 is E, false))(IterableMixinWorkaround.lastWhereList(this, test, orElse));
  }
 E singleWhere(bool test(E value)) {
  return ((__x13) => DEVC$RT.cast(__x13, dynamic, E, "CompositeCast", """line 205, column 12 of dart:core/list.dart: """, __x13 is E, false))(IterableMixinWorkaround.singleWhere(this, test));
  }
 E elementAt(int index) {
  return this[index];
  }
 E get first {
  if (length > 0) return this[0];
   throw new StateError("No elements");
  }
 E get last {
  if (length > 0) return this[length - 1];
   throw new StateError("No elements");
  }
 E get single {
  if (length == 1) return this[0];
   if (length == 0) throw new StateError("No elements");
   throw new StateError("More than one element");
  }
 bool any(bool f(E element)) => IterableMixinWorkaround.any(this, f);
 bool every(bool f(E element)) => IterableMixinWorkaround.every(this, f);
 bool contains(Object other) {
  for (int i = 0; i < length; i++) {
    if (this[i] == other) return true;
    }
   return false;
  }
 bool get isEmpty => length == 0;
 bool get isNotEmpty => !isEmpty;
 String toString() => ListBase.listToString(this);
 List<E> toList({
  bool growable : true}
) {
  return ((__x14) => DEVC$RT.cast(__x14, dynamic, DEVC$RT.type((List<E> _) {
    }
  ), "CompositeCast", """line 248, column 12 of dart:core/list.dart: """, __x14 is List<E>, false))(JS('', 'dart.setType(#.slice(), core.List\$(#))', this, E));
  }
 Set<E> toSet() => new Set<E>.from(this);
 Iterator<E> get iterator => new ListIterator<E>(this);
 int get hashCode => ((__x15) => DEVC$RT.cast(__x15, dynamic, int, "DynamicCast", """line 255, column 23 of dart:core/list.dart: """, __x15 is int, true))(Primitives.objectHashCode(this));
 E operator [](int index) {
  if (index is! int) throw new ArgumentError(index);
   if (index >= length || index < 0) throw new RangeError.value(index);
   return ((__x16) => DEVC$RT.cast(__x16, dynamic, E, "CompositeCast", """line 266, column 12 of dart:core/list.dart: """, __x16 is E, false))(JS('var', '#[#]', this, index));
  }
 void operator []=(int index, E value) {
  checkMutable('indexed set');
   if (index is! int) throw new ArgumentError(index);
   if (index >= length || index < 0) throw new RangeError.value(index);
   JS('void', r'#[#] = #', this, index, value);
  }
 int get length => ((__x17) => DEVC$RT.cast(__x17, dynamic, int, "DynamicCast", """line 285, column 21 of dart:core/list.dart: """, __x17 is int, true))(JS('JSUInt32', r'#.length', this));
 void set length(int newLength) {
  if (newLength is! int) throw new ArgumentError(newLength);
   if (newLength < 0) throw new RangeError.value(newLength);
   checkGrowable('set length');
   JS('void', r'#.length = #', this, newLength);
  }
 void add(E value) {
  checkGrowable('add');
   JS('void', r'#.push(#)', this, value);
  }
 void addAll(Iterable<E> iterable) {
  for (E e in iterable) {
    this.add(e);
    }
  }
 Iterable<E> get reversed => new IterableMixinWorkaround<E>().reversedList(this);
 void sort([int compare(E a, E b)]) {
  checkMutable('sort');
   IterableMixinWorkaround.sortList(this, compare);
  }
 void shuffle([Random random]) {
  IterableMixinWorkaround.shuffleList(this, random);
  }
 int indexOf(E element, [int start = 0]) {
  return IterableMixinWorkaround.indexOfList(this, element, start);
  }
 int lastIndexOf(E element, [int start]) {
  return IterableMixinWorkaround.lastIndexOfList(this, element, start);
  }
 void clear() {
  length = 0;
  }
 void insert(int index, E element) {
  if (index is! int) throw new ArgumentError(index);
   if (index < 0 || index > length) {
    throw new RangeError.value(index);
    }
   checkGrowable('insert');
   JS('void', r'#.splice(#, 0, #)', this, index, element);
  }
 void insertAll(int index, Iterable<E> iterable) {
  checkGrowable('insertAll');
   IterableMixinWorkaround.insertAllList(this, index, iterable);
  }
 void setAll(int index, Iterable<E> iterable) {
  checkMutable('setAll');
   IterableMixinWorkaround.setAllList(this, index, iterable);
  }
 bool remove(Object element) {
  checkGrowable('remove');
   for (int i = 0; i < this.length; i++) {
    if (this[i] == value) {
      JS('var', r'#.splice(#, 1)', this, i);
       return true;
      }
    }
   return false;
  }
 E removeAt(int index) {
  if (index is! int) throw new ArgumentError(index);
   if (index < 0 || index >= length) {
    throw new RangeError.value(index);
    }
   checkGrowable('removeAt');
   return ((__x18) => DEVC$RT.cast(__x18, dynamic, E, "CompositeCast", """line 517, column 12 of dart:core/list.dart: """, __x18 is E, false))(JS('var', r'#.splice(#, 1)[0]', this, index));
  }
 E removeLast() {
  checkGrowable('removeLast');
   if (length == 0) throw new RangeError.value(-1);
   return ((__x19) => DEVC$RT.cast(__x19, dynamic, E, "CompositeCast", """line 528, column 12 of dart:core/list.dart: """, __x19 is E, false))(JS('var', r'#.pop()', this));
  }
 void removeWhere(bool test(E element)) {
  IterableMixinWorkaround.removeWhereList(this, test);
  }
 void retainWhere(bool test(E element)) {
  IterableMixinWorkaround.removeWhereList(this, (E element) => !test(element));
  }
 List<E> sublist(int start, [int end]) {
  checkNull(start);
   if (start is! int) throw new ArgumentError(start);
   if (start < 0 || start > length) {
    throw new RangeError.range(start, 0, length);
    }
   if (end == null) {
    end = length;
    }
   else {
    if (end is! int) throw new ArgumentError(end);
     if (end < start || end > length) {
      throw new RangeError.range(end, start, length);
      }
    }
   if (start == end) return <E> [];
   return new JSArray<E>.markGrowable(JS('', r'#.slice(#, #)', this, start, end));
  }
 Iterable<E> getRange(int start, int end) {
  return new IterableMixinWorkaround<E>().getRangeList(this, start, end);
  }
 void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
  checkMutable('set range');
   IterableMixinWorkaround.setRangeList(this, start, end, iterable, skipCount);
  }
 void removeRange(int start, int end) {
  checkGrowable('removeRange');
   int receiverLength = this.length;
   if (start < 0 || start > receiverLength) {
    throw new RangeError.range(start, 0, receiverLength);
    }
   if (end < start || end > receiverLength) {
    throw new RangeError.range(end, start, receiverLength);
    }
   Lists.copy(this, end, this, start, receiverLength - end);
   this.length = receiverLength - (end - start);
  }
 void fillRange(int start, int end, [E fillValue]) {
  checkMutable('fill range');
   IterableMixinWorkaround.fillRangeList(this, start, end, fillValue);
  }
 void replaceRange(int start, int end, Iterable<E> replacement) {
  checkGrowable('removeRange');
   IterableMixinWorkaround.replaceRangeList(this, start, end, replacement);
  }
 Map<int, E> asMap() {
  return new IterableMixinWorkaround<E>().asMapList(this);
  }
}
