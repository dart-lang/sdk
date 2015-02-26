part of dart.collection;
 abstract class IterableMixin<E> implements Iterable<E> {Iterable map(f(E element)) => new MappedIterable<E, dynamic>(this, f);
 Iterable<E> where(bool f(E element)) => new WhereIterable<E>(this, f);
 Iterable expand(Iterable f(E element)) => new ExpandIterable<E, dynamic>(this, f);
 bool contains(Object element) {
  for (E e in this) {
    if (e == element) return true;
    }
   return false;
  }
 void forEach(void f(E element)) {
  for (E element in this) f(element);
  }
 E reduce(E combine(E value, E element)) {
  Iterator<E> iterator = this.iterator;
   if (!iterator.moveNext()) {
    throw IterableElementError.noElement();
    }
   E value = iterator.current;
   while (iterator.moveNext()) {
    value = combine(value, iterator.current);
    }
   return value;
  }
 dynamic fold(var initialValue, dynamic combine(var previousValue, E element)) {
  var value = initialValue;
   for (E element in this) value = combine(value, element);
   return value;
  }
 bool every(bool f(E element)) {
  for (E element in this) {
    if (!f(element)) return false;
    }
   return true;
  }
 String join([String separator = ""]) {
  Iterator<E> iterator = this.iterator;
   if (!iterator.moveNext()) return "";
   StringBuffer buffer = new StringBuffer();
   if (separator == null || separator == "") {
    do {
      buffer.write("${iterator.current}
    ");
    }
   while (iterator.moveNext());}
 else {
  buffer.write("${iterator.current}
");
 while (iterator.moveNext()) {
  buffer.write(separator);
   buffer.write("${iterator.current}
");
}
}
 return buffer.toString();
}
 bool any(bool f(E element)) {
for (E element in this) {
if (f(element)) return true;
}
 return false;
}
 List<E> toList({
bool growable : true}
) => new List<E>.from(this, growable: growable);
 Set<E> toSet() => new Set<E>.from(this);
 int get length {
assert (this is! EfficientLength); int count = 0;
 Iterator it = iterator;
 while (it.moveNext()) {
count++;
}
 return count;
}
 bool get isEmpty => !iterator.moveNext();
 bool get isNotEmpty => !isEmpty;
 Iterable<E> take(int n) {
return new TakeIterable<E>(this, n);
}
 Iterable<E> takeWhile(bool test(E value)) {
return new TakeWhileIterable<E>(this, test);
}
 Iterable<E> skip(int n) {
return new SkipIterable<E>(this, n);
}
 Iterable<E> skipWhile(bool test(E value)) {
return new SkipWhileIterable<E>(this, test);
}
 E get first {
Iterator it = iterator;
 if (!it.moveNext()) {
throw IterableElementError.noElement();
}
 return DDC$RT.cast(it.current, dynamic, E, "CastGeneral", """line 127, column 12 of dart:collection/iterable.dart: """, it.current is E, false);
}
 E get last {
Iterator it = iterator;
 if (!it.moveNext()) {
throw IterableElementError.noElement();
}
 E result;
 do {
result = DDC$RT.cast(it.current, dynamic, E, "CastGeneral", """line 137, column 16 of dart:collection/iterable.dart: """, it.current is E, false);
}
 while (it.moveNext()); return result;
}
 E get single {
Iterator it = iterator;
 if (!it.moveNext()) throw IterableElementError.noElement();
 E result = DDC$RT.cast(it.current, dynamic, E, "CastGeneral", """line 145, column 16 of dart:collection/iterable.dart: """, it.current is E, false);
 if (it.moveNext()) throw IterableElementError.tooMany();
 return result;
}
 E firstWhere(bool test(E value), {
E orElse()}
) {
for (E element in this) {
if (test(element)) return element;
}
 if (orElse != null) return orElse();
 throw IterableElementError.noElement();
}
 E lastWhere(bool test(E value), {
E orElse()}
) {
E result = ((__x0) => DDC$RT.cast(__x0, Null, E, "CastLiteral", """line 159, column 16 of dart:collection/iterable.dart: """, __x0 is E, false))(null);
 bool foundMatching = false;
 for (E element in this) {
if (test(element)) {
result = element;
 foundMatching = true;
}
}
 if (foundMatching) return result;
 if (orElse != null) return orElse();
 throw IterableElementError.noElement();
}
 E singleWhere(bool test(E value)) {
E result = ((__x1) => DDC$RT.cast(__x1, Null, E, "CastLiteral", """line 173, column 16 of dart:collection/iterable.dart: """, __x1 is E, false))(null);
 bool foundMatching = false;
 for (E element in this) {
if (test(element)) {
if (foundMatching) {
  throw IterableElementError.tooMany();
  }
 result = element;
 foundMatching = true;
}
}
 if (foundMatching) return result;
 throw IterableElementError.noElement();
}
 E elementAt(int index) {
if (index is! int) throw new ArgumentError.notNull("index");
 RangeError.checkNotNegative(index, "index");
 int elementIndex = 0;
 for (E element in this) {
if (index == elementIndex) return element;
 elementIndex++;
}
 throw new RangeError.index(index, this, "index", null, elementIndex);
}
 String toString() => IterableBase.iterableToShortString(this, '(', ')');
}
 abstract class IterableBase<E> implements Iterable<E> {const IterableBase();
 Iterable map(f(E element)) => new MappedIterable<E, dynamic>(this, f);
 Iterable<E> where(bool f(E element)) => new WhereIterable<E>(this, f);
 Iterable expand(Iterable f(E element)) => new ExpandIterable<E, dynamic>(this, f);
 bool contains(Object element) {
for (E e in this) {
if (e == element) return true;
}
 return false;
}
 void forEach(void f(E element)) {
for (E element in this) f(element);
}
 E reduce(E combine(E value, E element)) {
Iterator<E> iterator = this.iterator;
 if (!iterator.moveNext()) {
throw IterableElementError.noElement();
}
 E value = iterator.current;
 while (iterator.moveNext()) {
value = combine(value, iterator.current);
}
 return value;
}
 dynamic fold(var initialValue, dynamic combine(var previousValue, E element)) {
var value = initialValue;
 for (E element in this) value = combine(value, element);
 return value;
}
 bool every(bool f(E element)) {
for (E element in this) {
if (!f(element)) return false;
}
 return true;
}
 String join([String separator = ""]) {
Iterator<E> iterator = this.iterator;
 if (!iterator.moveNext()) return "";
 StringBuffer buffer = new StringBuffer();
 if (separator == null || separator == "") {
do {
buffer.write("${iterator.current}
");
}
 while (iterator.moveNext());}
 else {
buffer.write("${iterator.current}
");
 while (iterator.moveNext()) {
buffer.write(separator);
 buffer.write("${iterator.current}
");
}
}
 return buffer.toString();
}
 bool any(bool f(E element)) {
for (E element in this) {
if (f(element)) return true;
}
 return false;
}
 List<E> toList({
bool growable : true}
) => new List<E>.from(this, growable: growable);
 Set<E> toSet() => new Set<E>.from(this);
 int get length {
assert (this is! EfficientLength); int count = 0;
 Iterator it = iterator;
 while (it.moveNext()) {
count++;
}
 return count;
}
 bool get isEmpty => !iterator.moveNext();
 bool get isNotEmpty => !isEmpty;
 Iterable<E> take(int n) {
return new TakeIterable<E>(this, n);
}
 Iterable<E> takeWhile(bool test(E value)) {
return new TakeWhileIterable<E>(this, test);
}
 Iterable<E> skip(int n) {
return new SkipIterable<E>(this, n);
}
 Iterable<E> skipWhile(bool test(E value)) {
return new SkipWhileIterable<E>(this, test);
}
 E get first {
Iterator it = iterator;
 if (!it.moveNext()) {
throw IterableElementError.noElement();
}
 return DDC$RT.cast(it.current, dynamic, E, "CastGeneral", """line 323, column 12 of dart:collection/iterable.dart: """, it.current is E, false);
}
 E get last {
Iterator it = iterator;
 if (!it.moveNext()) {
throw IterableElementError.noElement();
}
 E result;
 do {
result = DDC$RT.cast(it.current, dynamic, E, "CastGeneral", """line 333, column 16 of dart:collection/iterable.dart: """, it.current is E, false);
}
 while (it.moveNext()); return result;
}
 E get single {
Iterator it = iterator;
 if (!it.moveNext()) throw IterableElementError.noElement();
 E result = DDC$RT.cast(it.current, dynamic, E, "CastGeneral", """line 341, column 16 of dart:collection/iterable.dart: """, it.current is E, false);
 if (it.moveNext()) throw IterableElementError.tooMany();
 return result;
}
 E firstWhere(bool test(E value), {
E orElse()}
) {
for (E element in this) {
if (test(element)) return element;
}
 if (orElse != null) return orElse();
 throw IterableElementError.noElement();
}
 E lastWhere(bool test(E value), {
E orElse()}
) {
E result = ((__x2) => DDC$RT.cast(__x2, Null, E, "CastLiteral", """line 355, column 16 of dart:collection/iterable.dart: """, __x2 is E, false))(null);
 bool foundMatching = false;
 for (E element in this) {
if (test(element)) {
result = element;
 foundMatching = true;
}
}
 if (foundMatching) return result;
 if (orElse != null) return orElse();
 throw IterableElementError.noElement();
}
 E singleWhere(bool test(E value)) {
E result = ((__x3) => DDC$RT.cast(__x3, Null, E, "CastLiteral", """line 369, column 16 of dart:collection/iterable.dart: """, __x3 is E, false))(null);
 bool foundMatching = false;
 for (E element in this) {
if (test(element)) {
if (foundMatching) {
throw IterableElementError.tooMany();
}
 result = element;
 foundMatching = true;
}
}
 if (foundMatching) return result;
 throw IterableElementError.noElement();
}
 E elementAt(int index) {
if (index is! int) throw new ArgumentError.notNull("index");
 RangeError.checkNotNegative(index, "index");
 int elementIndex = 0;
 for (E element in this) {
if (index == elementIndex) return element;
 elementIndex++;
}
 throw new RangeError.index(index, this, "index", null, elementIndex);
}
 String toString() => iterableToShortString(this, '(', ')');
 static String iterableToShortString(Iterable iterable, [String leftDelimiter = '(', String rightDelimiter = ')']) {
if (_isToStringVisiting(iterable)) {
if (leftDelimiter == "(" && rightDelimiter == ")") {
return "(...)";
}
 return "$leftDelimiter...$rightDelimiter";
}
 List parts = [];
 _toStringVisiting.add(iterable);
 try {
_iterablePartsToStrings(iterable, parts);
}
 finally {
assert (identical(_toStringVisiting.last, iterable)); _toStringVisiting.removeLast();
}
 return (new StringBuffer(leftDelimiter)..writeAll(parts, ", ")..write(rightDelimiter)).toString();
}
 static String iterableToFullString(Iterable iterable, [String leftDelimiter = '(', String rightDelimiter = ')']) {
if (_isToStringVisiting(iterable)) {
return "$leftDelimiter...$rightDelimiter";
}
 StringBuffer buffer = new StringBuffer(leftDelimiter);
 _toStringVisiting.add(iterable);
 try {
buffer.writeAll(iterable, ", ");
}
 finally {
assert (identical(_toStringVisiting.last, iterable)); _toStringVisiting.removeLast();
}
 buffer.write(rightDelimiter);
 return buffer.toString();
}
 static final List _toStringVisiting = [];
 static bool _isToStringVisiting(Object o) {
for (int i = 0;
 i < _toStringVisiting.length;
 i++) {
if (identical(o, _toStringVisiting[i])) return true;
}
 return false;
}
 static void _iterablePartsToStrings(Iterable iterable, List parts) {
const int LENGTH_LIMIT = 80;
 const int HEAD_COUNT = 3;
 const int TAIL_COUNT = 2;
 const int MAX_COUNT = 100;
 const int OVERHEAD = 2;
 const int ELLIPSIS_SIZE = 3;
 int length = 0;
 int count = 0;
 Iterator it = iterable.iterator;
 while (length < LENGTH_LIMIT || count < HEAD_COUNT) {
if (!it.moveNext()) return; String next = "${it.current}
";
 parts.add(next);
 length += next.length + OVERHEAD;
 count++;
}
 String penultimateString;
 String ultimateString;
 var penultimate = null;
 var ultimate = null;
 if (!it.moveNext()) {
if (count <= HEAD_COUNT + TAIL_COUNT) return; ultimateString = ((__x4) => DDC$RT.cast(__x4, dynamic, String, "CastGeneral", """line 530, column 24 of dart:collection/iterable.dart: """, __x4 is String, true))(parts.removeLast());
 penultimateString = ((__x5) => DDC$RT.cast(__x5, dynamic, String, "CastGeneral", """line 531, column 27 of dart:collection/iterable.dart: """, __x5 is String, true))(parts.removeLast());
}
 else {
penultimate = it.current;
 count++;
 if (!it.moveNext()) {
if (count <= HEAD_COUNT + 1) {
parts.add("$penultimate");
 return;}
 ultimateString = "$penultimate";
 penultimateString = ((__x6) => DDC$RT.cast(__x6, dynamic, String, "CastGeneral", """line 541, column 29 of dart:collection/iterable.dart: """, __x6 is String, true))(parts.removeLast());
 length += ultimateString.length + OVERHEAD;
}
 else {
ultimate = it.current;
 count++;
 assert (count < MAX_COUNT); while (it.moveNext()) {
penultimate = ultimate;
 ultimate = it.current;
 count++;
 if (count > MAX_COUNT) {
while (length > LENGTH_LIMIT - ELLIPSIS_SIZE - OVERHEAD && count > HEAD_COUNT) {
length -= ((__x7) => DDC$RT.cast(__x7, dynamic, int, "CastGeneral", """line 562, column 25 of dart:collection/iterable.dart: """, __x7 is int, true))(parts.removeLast().length + OVERHEAD);
 count--;
}
 parts.add("...");
 return;}
}
 penultimateString = "$penultimate";
 ultimateString = "$ultimate";
 length += ultimateString.length + penultimateString.length + 2 * OVERHEAD;
}
}
 String elision = null;
 if (count > parts.length + TAIL_COUNT) {
elision = "...";
 length += ELLIPSIS_SIZE + OVERHEAD;
}
 while (length > LENGTH_LIMIT && parts.length > HEAD_COUNT) {
length -= ((__x8) => DDC$RT.cast(__x8, dynamic, int, "CastGeneral", """line 588, column 17 of dart:collection/iterable.dart: """, __x8 is int, true))(parts.removeLast().length + OVERHEAD);
 if (elision == null) {
elision = "...";
 length += ELLIPSIS_SIZE + OVERHEAD;
}
}
 if (elision != null) {
parts.add(elision);
}
 parts.add(penultimateString);
 parts.add(ultimateString);
}
}
