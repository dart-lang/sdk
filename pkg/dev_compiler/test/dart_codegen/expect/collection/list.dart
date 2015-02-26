part of dart.collection;
 abstract class ListBase<E> extends Object with ListMixin<E> {static String listToString(List list) => IterableBase.iterableToFullString(list, '[', ']');
}
 abstract class ListMixin<E> implements List<E> {Iterator<E> get iterator => new ListIterator<E>(this);
 E elementAt(int index) => this[index];
 void forEach(void action(E element)) {
int length = this.length;
 for (int i = 0;
 i < length;
 i++) {
  action(this[i]);
   if (length != this.length) {
    throw new ConcurrentModificationError(this);
    }
  }
}
 bool get isEmpty => length == 0;
 bool get isNotEmpty => !isEmpty;
 E get first {
if (length == 0) throw IterableElementError.noElement();
 return this[0];
}
 E get last {
if (length == 0) throw IterableElementError.noElement();
 return this[length - 1];
}
 E get single {
if (length == 0) throw IterableElementError.noElement();
 if (length > 1) throw IterableElementError.tooMany();
 return this[0];
}
 bool contains(Object element) {
int length = this.length;
 for (int i = 0;
 i < this.length;
 i++) {
  if (this[i] == element) return true;
   if (length != this.length) {
    throw new ConcurrentModificationError(this);
    }
  }
 return false;
}
 bool every(bool test(E element)) {
int length = this.length;
 for (int i = 0;
 i < length;
 i++) {
  if (!test(this[i])) return false;
   if (length != this.length) {
    throw new ConcurrentModificationError(this);
    }
  }
 return true;
}
 bool any(bool test(E element)) {
int length = this.length;
 for (int i = 0;
 i < length;
 i++) {
  if (test(this[i])) return true;
   if (length != this.length) {
    throw new ConcurrentModificationError(this);
    }
  }
 return false;
}
 E firstWhere(bool test(E element), {
E orElse()}
) {
int length = this.length;
 for (int i = 0;
 i < length;
 i++) {
  E element = this[i];
   if (test(element)) return element;
   if (length != this.length) {
    throw new ConcurrentModificationError(this);
    }
  }
 if (orElse != null) return orElse();
 throw IterableElementError.noElement();
}
 E lastWhere(bool test(E element), {
E orElse()}
) {
int length = this.length;
 for (int i = length - 1;
 i >= 0;
 i--) {
  E element = this[i];
   if (test(element)) return element;
   if (length != this.length) {
    throw new ConcurrentModificationError(this);
    }
  }
 if (orElse != null) return orElse();
 throw IterableElementError.noElement();
}
 E singleWhere(bool test(E element)) {
int length = this.length;
 E match = ((__x9) => DDC$RT.cast(__x9, Null, E, "CastLiteral", """line 151, column 15 of dart:collection/list.dart: """, __x9 is E, false))(null);
 bool matchFound = false;
 for (int i = 0;
 i < length;
 i++) {
  E element = this[i];
   if (test(element)) {
    if (matchFound) {
      throw IterableElementError.tooMany();
      }
     matchFound = true;
     match = element;
    }
   if (length != this.length) {
    throw new ConcurrentModificationError(this);
    }
  }
 if (matchFound) return match;
 throw IterableElementError.noElement();
}
 String join([String separator = ""]) {
if (length == 0) return "";
 StringBuffer buffer = new StringBuffer()..writeAll(this, separator);
 return buffer.toString();
}
 Iterable<E> where(bool test(E element)) => new WhereIterable<E>(this, test);
 Iterable map(f(E element)) => new MappedListIterable(this, f);
 Iterable expand(Iterable f(E element)) => new ExpandIterable<E, dynamic>(this, f);
 E reduce(E combine(E previousValue, E element)) {
int length = this.length;
 if (length == 0) throw IterableElementError.noElement();
 E value = this[0];
 for (int i = 1;
 i < length;
 i++) {
  value = combine(value, this[i]);
   if (length != this.length) {
    throw new ConcurrentModificationError(this);
    }
  }
 return value;
}
 fold(var initialValue, combine(var previousValue, E element)) {
var value = initialValue;
 int length = this.length;
 for (int i = 0;
 i < length;
 i++) {
  value = combine(value, this[i]);
   if (length != this.length) {
    throw new ConcurrentModificationError(this);
    }
  }
 return value;
}
 Iterable<E> skip(int count) => new SubListIterable<E>(this, count, null);
 Iterable<E> skipWhile(bool test(E element)) {
return new SkipWhileIterable<E>(this, test);
}
 Iterable<E> take(int count) => new SubListIterable<E>(this, 0, count);
 Iterable<E> takeWhile(bool test(E element)) {
return new TakeWhileIterable<E>(this, test);
}
 List<E> toList({
bool growable : true}
) {
List<E> result;
 if (growable) {
  result = new List<E>()..length = length;
  }
 else {
  result = new List<E>(length);
  }
 for (int i = 0;
 i < length;
 i++) {
  result[i] = this[i];
  }
 return result;
}
 Set<E> toSet() {
Set<E> result = new Set<E>();
 for (int i = 0;
 i < length;
 i++) {
  result.add(this[i]);
  }
 return result;
}
 void add(E element) {
this[this.length++] = element;
}
 void addAll(Iterable<E> iterable) {
for (E element in iterable) {
  this[this.length++] = element;
  }
}
 bool remove(Object element) {
for (int i = 0;
 i < this.length;
 i++) {
  if (this[i] == element) {
    this.setRange(i, this.length - 1, this, i + 1);
     this.length -= 1;
     return true;
    }
  }
 return false;
}
 void removeWhere(bool test(E element)) {
_filter(this, DDC$RT.wrap((bool f(E __u10)) {
  bool c(E x0) => f(DDC$RT.cast(x0, dynamic, E, "CastParam", """line 264, column 19 of dart:collection/list.dart: """, x0 is E, false));
   return f == null ? null : c;
  }
, test, DDC$RT.type((__t13<E> _) {
  }
), __t11, "Wrap", """line 264, column 19 of dart:collection/list.dart: """, test is __t11), false);
}
 void retainWhere(bool test(E element)) {
_filter(this, DDC$RT.wrap((bool f(E __u15)) {
  bool c(E x0) => f(DDC$RT.cast(x0, dynamic, E, "CastParam", """line 268, column 19 of dart:collection/list.dart: """, x0 is E, false));
   return f == null ? null : c;
  }
, test, DDC$RT.type((__t13<E> _) {
  }
), __t11, "Wrap", """line 268, column 19 of dart:collection/list.dart: """, test is __t11), true);
}
 static void _filter(List source, bool test(var element), bool retainMatching) {
List retained = [];
 int length = source.length;
 for (int i = 0;
 i < length;
 i++) {
  var element = source[i];
   if (test(element) == retainMatching) {
    retained.add(element);
    }
   if (length != source.length) {
    throw new ConcurrentModificationError(source);
    }
  }
 if (retained.length != source.length) {
  source.setRange(0, retained.length, retained);
   source.length = retained.length;
  }
}
 void clear() {
this.length = 0;
}
 E removeLast() {
if (length == 0) {
  throw IterableElementError.noElement();
  }
 E result = this[length - 1];
 length--;
 return result;
}
 void sort([int compare(E a, E b)]) {
if (compare == null) {
  var defaultCompare = Comparable.compare;
   compare = defaultCompare;
  }
 Sort.sort(this, DDC$RT.wrap((int f(E __u16, E __u17)) {
  int c(E x0, E x1) => f(DDC$RT.cast(x0, dynamic, E, "CastParam", """line 309, column 21 of dart:collection/list.dart: """, x0 is E, false), DDC$RT.cast(x1, dynamic, E, "CastParam", """line 309, column 21 of dart:collection/list.dart: """, x1 is E, false));
   return f == null ? null : c;
  }
, compare, DDC$RT.type((__t21<E> _) {
  }
), __t18, "Wrap", """line 309, column 21 of dart:collection/list.dart: """, compare is __t18));
}
 void shuffle([Random random]) {
if (random == null) random = new Random();
 int length = this.length;
 while (length > 1) {
  int pos = random.nextInt(length);
   length -= 1;
   var tmp = this[length];
   this[length] = this[pos];
   this[pos] = tmp;
  }
}
 Map<int, E> asMap() {
return new ListMapView<E>(this);
}
 List<E> sublist(int start, [int end]) {
int listLength = this.length;
 if (end == null) end = listLength;
 RangeError.checkValidRange(start, end, listLength);
 int length = end - start;
 List<E> result = new List<E>()..length = length;
 for (int i = 0;
 i < length;
 i++) {
  result[i] = this[start + i];
  }
 return result;
}
 Iterable<E> getRange(int start, int end) {
RangeError.checkValidRange(start, end, this.length);
 return new SubListIterable<E>(this, start, end);
}
 void removeRange(int start, int end) {
RangeError.checkValidRange(start, end, this.length);
 int length = end - start;
 setRange(start, this.length - length, this, end);
 this.length -= length;
}
 void fillRange(int start, int end, [E fill]) {
RangeError.checkValidRange(start, end, this.length);
 for (int i = start;
 i < end;
 i++) {
  this[i] = fill;
  }
}
 void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
RangeError.checkValidRange(start, end, this.length);
 int length = end - start;
 if (length == 0) return; RangeError.checkNotNegative(skipCount, "skipCount");
 List otherList;
 int otherStart;
 if (iterable is List) {
  otherList = DDC$RT.cast(iterable, DDC$RT.type((Iterable<E> _) {
    }
  ), DDC$RT.type((List<dynamic> _) {
    }
  ), "CastGeneral", """line 369, column 19 of dart:collection/list.dart: """, iterable is List<dynamic>, true);
   otherStart = skipCount;
  }
 else {
  otherList = iterable.skip(skipCount).toList(growable: false);
   otherStart = 0;
  }
 if (otherStart + length > otherList.length) {
  throw IterableElementError.tooFew();
  }
 if (otherStart < start) {
  for (int i = length - 1;
   i >= 0;
   i--) {
    this[start + i] = ((__x24) => DDC$RT.cast(__x24, dynamic, E, "CastGeneral", """line 381, column 27 of dart:collection/list.dart: """, __x24 is E, false))(otherList[otherStart + i]);
    }
  }
 else {
  for (int i = 0;
   i < length;
   i++) {
    this[start + i] = ((__x25) => DDC$RT.cast(__x25, dynamic, E, "CastGeneral", """line 385, column 27 of dart:collection/list.dart: """, __x25 is E, false))(otherList[otherStart + i]);
    }
  }
}
 void replaceRange(int start, int end, Iterable<E> newContents) {
RangeError.checkValidRange(start, end, this.length);
 if (newContents is! EfficientLength) {
  newContents = newContents.toList();
  }
 int removeLength = end - start;
 int insertLength = newContents.length;
 if (removeLength >= insertLength) {
  int delta = removeLength - insertLength;
   int insertEnd = start + insertLength;
   int newLength = this.length - delta;
   this.setRange(start, insertEnd, newContents);
   if (delta != 0) {
    this.setRange(insertEnd, newLength, this, end);
     this.length = newLength;
    }
  }
 else {
  int delta = insertLength - removeLength;
   int newLength = this.length + delta;
   int insertEnd = start + insertLength;
   this.length = newLength;
   this.setRange(insertEnd, newLength, this, end);
   this.setRange(start, insertEnd, newContents);
  }
}
 int indexOf(Object element, [int startIndex = 0]) {
if (startIndex >= this.length) {
  return -1;
  }
 if (startIndex < 0) {
  startIndex = 0;
  }
 for (int i = startIndex;
 i < this.length;
 i++) {
  if (this[i] == element) {
    return i;
    }
  }
 return -1;
}
 int lastIndexOf(Object element, [int startIndex]) {
if (startIndex == null) {
  startIndex = this.length - 1;
  }
 else {
  if (startIndex < 0) {
    return -1;
    }
   if (startIndex >= this.length) {
    startIndex = this.length - 1;
    }
  }
 for (int i = startIndex;
 i >= 0;
 i--) {
  if (this[i] == element) {
    return i;
    }
  }
 return -1;
}
 void insert(int index, E element) {
RangeError.checkValueInInterval(index, 0, length, "index");
 if (index == this.length) {
  add(element);
   return;}
 if (index is! int) throw new ArgumentError(index);
 this.length++;
 setRange(index + 1, this.length, this, index);
 this[index] = element;
}
 E removeAt(int index) {
E result = this[index];
 setRange(index, this.length - 1, this, index + 1);
 length--;
 return result;
}
 void insertAll(int index, Iterable<E> iterable) {
RangeError.checkValueInInterval(index, 0, length, "index");
 if (iterable is EfficientLength) {
  iterable = iterable.toList();
  }
 int insertionLength = iterable.length;
 this.length += insertionLength;
 setRange(index + insertionLength, this.length, this, index);
 setAll(index, iterable);
}
 void setAll(int index, Iterable<E> iterable) {
if (iterable is List) {
  setRange(index, index + iterable.length, iterable);
  }
 else {
  for (E element in iterable) {
    this[index++] = element;
    }
  }
}
 Iterable<E> get reversed => new ReversedListIterable<E>(this);
 String toString() => IterableBase.iterableToFullString(this, '[', ']');
}
 typedef bool __t11(dynamic __u12);
 typedef bool __t13<E>(E __u14);
 typedef int __t18(dynamic __u19, dynamic __u20);
 typedef int __t21<E>(E __u22, E __u23);
