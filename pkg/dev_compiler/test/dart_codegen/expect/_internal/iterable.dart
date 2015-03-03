part of dart._internal;
 abstract class EfficientLength {int get length;
}
 abstract class ListIterable<E> extends IterableBase<E> implements EfficientLength {int get length;
 E elementAt(int i);
 const ListIterable();
 Iterator<E> get iterator => new ListIterator<E>(this);
 void forEach(void action(E element)) {
int length = this.length;
 for (int i = 0; i < length; i++) {
  action(elementAt(i));
   if (length != this.length) {
    throw new ConcurrentModificationError(this);
    }
  }
}
 bool get isEmpty => length == 0;
 E get first {
if (length == 0) throw IterableElementError.noElement();
 return elementAt(0);
}
 E get last {
if (length == 0) throw IterableElementError.noElement();
 return elementAt(length - 1);
}
 E get single {
if (length == 0) throw IterableElementError.noElement();
 if (length > 1) throw IterableElementError.tooMany();
 return elementAt(0);
}
 bool contains(Object element) {
int length = this.length;
 for (int i = 0; i < length; i++) {
  if (elementAt(i) == element) return true;
   if (length != this.length) {
    throw new ConcurrentModificationError(this);
    }
  }
 return false;
}
 bool every(bool test(E element)) {
int length = this.length;
 for (int i = 0; i < length; i++) {
  if (!test(elementAt(i))) return false;
   if (length != this.length) {
    throw new ConcurrentModificationError(this);
    }
  }
 return true;
}
 bool any(bool test(E element)) {
int length = this.length;
 for (int i = 0; i < length; i++) {
  if (test(elementAt(i))) return true;
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
 for (int i = 0; i < length; i++) {
  E element = elementAt(i);
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
 for (int i = length - 1; i >= 0; i--) {
  E element = elementAt(i);
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
 E match = null;
 bool matchFound = false;
 for (int i = 0; i < length; i++) {
  E element = elementAt(i);
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
int length = this.length;
 if (!separator.isEmpty) {
  if (length == 0) return "";
   String first = "${elementAt(0)}";
   if (length != this.length) {
    throw new ConcurrentModificationError(this);
    }
   StringBuffer buffer = new StringBuffer(first);
   for (int i = 1; i < length; i++) {
    buffer.write(separator);
     buffer.write(elementAt(i));
     if (length != this.length) {
      throw new ConcurrentModificationError(this);
      }
    }
   return buffer.toString();
  }
 else {
  StringBuffer buffer = new StringBuffer();
   for (int i = 0; i < length; i++) {
    buffer.write(elementAt(i));
     if (length != this.length) {
      throw new ConcurrentModificationError(this);
      }
    }
   return buffer.toString();
  }
}
 Iterable<E> where(bool test(E element)) => super.where(test);
 Iterable map(f(E element)) => new MappedListIterable(this, DDC$RT.wrap((dynamic f(E __u0)) {
dynamic c(E x0) => f(DDC$RT.cast(x0, dynamic, E, "CastParam", """line 175, column 62 of dart:_internal/iterable.dart: """, x0 is E, false));
 return f == null ? null : c;
}
, f, null, __t1, "Wrap", """line 175, column 62 of dart:_internal/iterable.dart: """, f is __t1));
 E reduce(E combine(var value, E element)) {
int length = this.length;
 if (length == 0) throw IterableElementError.noElement();
 E value = elementAt(0);
 for (int i = 1; i < length; i++) {
  value = combine(value, elementAt(i));
   if (length != this.length) {
    throw new ConcurrentModificationError(this);
    }
  }
 return value;
}
 fold(var initialValue, combine(var previousValue, E element)) {
var value = initialValue;
 int length = this.length;
 for (int i = 0; i < length; i++) {
  value = combine(value, elementAt(i));
   if (length != this.length) {
    throw new ConcurrentModificationError(this);
    }
  }
 return value;
}
 Iterable<E> skip(int count) => new SubListIterable<E>(this, count, null);
 Iterable<E> skipWhile(bool test(E element)) => super.skipWhile(test);
 Iterable<E> take(int count) => new SubListIterable<E>(this, 0, count);
 Iterable<E> takeWhile(bool test(E element)) => super.takeWhile(test);
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
 for (int i = 0; i < length; i++) {
  result[i] = elementAt(i);
  }
 return result;
}
 Set<E> toSet() {
Set<E> result = new Set<E>();
 for (int i = 0; i < length; i++) {
  result.add(elementAt(i));
  }
 return result;
}
}
 class SubListIterable<E> extends ListIterable<E> {final Iterable<E> _iterable;
 final int _start;
 final int _endOrLength;
 SubListIterable(this._iterable, this._start, this._endOrLength) {
RangeError.checkNotNegative(_start, "start");
 if (_endOrLength != null) {
RangeError.checkNotNegative(_endOrLength, "end");
 if (_start > _endOrLength) {
  throw new RangeError.range(_start, 0, _endOrLength, "start");
  }
}
}
 int get _endIndex {
int length = _iterable.length;
 if (_endOrLength == null || _endOrLength > length) return length;
 return _endOrLength;
}
 int get _startIndex {
int length = _iterable.length;
 if (_start > length) return length;
 return _start;
}
 int get length {
int length = _iterable.length;
 if (_start >= length) return 0;
 if (_endOrLength == null || _endOrLength >= length) {
return length - _start;
}
 return _endOrLength - _start;
}
 E elementAt(int index) {
int realIndex = _startIndex + index;
 if (index < 0 || realIndex >= _endIndex) {
throw new RangeError.index(index, this, "index");
}
 return _iterable.elementAt(realIndex);
}
 Iterable<E> skip(int count) {
RangeError.checkNotNegative(count, "count");
 int newStart = _start + count;
 if (_endOrLength != null && newStart >= _endOrLength) {
return new EmptyIterable<E>();
}
 return new SubListIterable<E>(_iterable, newStart, _endOrLength);
}
 Iterable<E> take(int count) {
RangeError.checkNotNegative(count, "count");
 if (_endOrLength == null) {
return new SubListIterable<E>(_iterable, _start, _start + count);
}
 else {
int newEnd = _start + count;
 if (_endOrLength < newEnd) return this;
 return new SubListIterable<E>(_iterable, _start, newEnd);
}
}
 List<E> toList({
bool growable : true}
) {
int start = _start;
 int end = _iterable.length;
 if (_endOrLength != null && _endOrLength < end) end = _endOrLength;
 int length = end - start;
 if (length < 0) length = 0;
 List result = growable ? (new List<E>()..length = length) : new List<E>(length);
 for (int i = 0; i < length; i++) {
result[i] = _iterable.elementAt(start + i);
 if (_iterable.length < end) throw new ConcurrentModificationError(this);
}
 return DDC$RT.cast(result, DDC$RT.type((List<dynamic> _) {
}
), DDC$RT.type((List<E> _) {
}
), "CastDynamic", """line 310, column 12 of dart:_internal/iterable.dart: """, result is List<E>, false);
}
}
 class ListIterator<E> implements Iterator<E> {final Iterable<E> _iterable;
 final int _length;
 int _index;
 E _current;
 ListIterator(Iterable<E> iterable) : _iterable = iterable, _length = iterable.length, _index = 0;
 E get current => _current;
 bool moveNext() {
int length = _iterable.length;
 if (_length != length) {
throw new ConcurrentModificationError(_iterable);
}
 if (_index >= length) {
_current = null;
 return false;
}
 _current = _iterable.elementAt(_index);
 _index++;
 return true;
}
}
 typedef T _Transformation<S, T>(S value);
 class MappedIterable<S, T> extends IterableBase<T> {final Iterable<S> _iterable;
 final _Transformation<S, T> _f;
 factory MappedIterable(Iterable iterable, T function(S value)) {
if (iterable is EfficientLength) {
return new EfficientLengthMappedIterable<S, T>(iterable, function);
}
 return new MappedIterable<S, T>._(DDC$RT.cast(iterable, DDC$RT.type((Iterable<dynamic> _) {
}
), DDC$RT.type((Iterable<S> _) {
}
), "CastDynamic", """line 357, column 39 of dart:_internal/iterable.dart: """, iterable is Iterable<S>, false), function);
}
 MappedIterable._(this._iterable, T this._f(S element));
 Iterator<T> get iterator => new MappedIterator<S, T>(_iterable.iterator, _f);
 int get length => _iterable.length;
 bool get isEmpty => _iterable.isEmpty;
 T get first => _f(_iterable.first);
 T get last => _f(_iterable.last);
 T get single => _f(_iterable.single);
 T elementAt(int index) => _f(_iterable.elementAt(index));
}
 class EfficientLengthMappedIterable<S, T> extends MappedIterable<S, T> implements EfficientLength {EfficientLengthMappedIterable(Iterable iterable, T function(S value)) : super._(DDC$RT.cast(iterable, DDC$RT.type((Iterable<dynamic> _) {
}
), DDC$RT.type((Iterable<S> _) {
}
), "CastDynamic", """line 378, column 17 of dart:_internal/iterable.dart: """, iterable is Iterable<S>, false), function);
}
 class MappedIterator<S, T> extends Iterator<T> {T _current;
 final Iterator<S> _iterator;
 final _Transformation<S, T> _f;
 MappedIterator(this._iterator, T this._f(S element));
 bool moveNext() {
if (_iterator.moveNext()) {
_current = _f(_iterator.current);
 return true;
}
 _current = null;
 return false;
}
 T get current => _current;
}
 class MappedListIterable<S, T> extends ListIterable<T> implements EfficientLength {final Iterable<S> _source;
 final _Transformation<S, T> _f;
 MappedListIterable(this._source, T this._f(S value));
 int get length => _source.length;
 T elementAt(int index) => _f(_source.elementAt(index));
}
 typedef bool _ElementPredicate<E>(E element);
 class WhereIterable<E> extends IterableBase<E> {final Iterable<E> _iterable;
 final _ElementPredicate _f;
 WhereIterable(this._iterable, bool this._f(E element));
 Iterator<E> get iterator => new WhereIterator<E>(_iterable.iterator, _f);
}
 class WhereIterator<E> extends Iterator<E> {final Iterator<E> _iterator;
 final _ElementPredicate _f;
 WhereIterator(this._iterator, bool this._f(E element));
 bool moveNext() {
while (_iterator.moveNext()) {
if (_f(_iterator.current)) {
return true;
}
}
 return false;
}
 E get current => _iterator.current;
}
 typedef Iterable<T> _ExpandFunction<S, T>(S sourceElement);
 class ExpandIterable<S, T> extends IterableBase<T> {final Iterable<S> _iterable;
 final _ExpandFunction _f;
 ExpandIterable(this._iterable, Iterable<T> this._f(S element));
 Iterator<T> get iterator => new ExpandIterator<S, T>(_iterable.iterator, DDC$RT.wrap((Iterable<dynamic> f(dynamic __u6)) {
Iterable<dynamic> c(dynamic x0) => ((__x5) => DDC$RT.cast(__x5, DDC$RT.type((Iterable<dynamic> _) {
}
), DDC$RT.type((Iterable<T> _) {
}
), "CastResult", """line 454, column 76 of dart:_internal/iterable.dart: """, __x5 is Iterable<T>, false))(f(x0));
 return f == null ? null : c;
}
, _f, null, DDC$RT.type((__t7<S, T> _) {
}
), "Wrap", """line 454, column 76 of dart:_internal/iterable.dart: """, _f is __t7<S, T>));
}
 class ExpandIterator<S, T> implements Iterator<T> {final Iterator<S> _iterator;
 final _ExpandFunction _f;
 Iterator<T> _currentExpansion = ((__x11) => DDC$RT.cast(__x11, null, DDC$RT.type((Iterator<T> _) {
}
), "CastExact", """line 463, column 35 of dart:_internal/iterable.dart: """, __x11 is Iterator<T>, false))(const EmptyIterator());
 T _current;
 ExpandIterator(this._iterator, Iterable<T> this._f(S element));
 void _nextExpansion() {
}
 T get current => _current;
 bool moveNext() {
if (_currentExpansion == null) return false;
 while (!_currentExpansion.moveNext()) {
_current = null;
 if (_iterator.moveNext()) {
_currentExpansion = null;
 _currentExpansion = ((__x12) => DDC$RT.cast(__x12, DDC$RT.type((Iterator<dynamic> _) {
}
), DDC$RT.type((Iterator<T> _) {
}
), "CastDynamic", """line 481, column 29 of dart:_internal/iterable.dart: """, __x12 is Iterator<T>, false))(_f(_iterator.current).iterator);
}
 else {
return false;
}
}
 _current = _currentExpansion.current;
 return true;
}
}
 class TakeIterable<E> extends IterableBase<E> {final Iterable<E> _iterable;
 final int _takeCount;
 factory TakeIterable(Iterable<E> iterable, int takeCount) {
if (takeCount is! int || takeCount < 0) {
throw new ArgumentError(takeCount);
}
 if (iterable is EfficientLength) {
return new EfficientLengthTakeIterable<E>(iterable, takeCount);
}
 return new TakeIterable<E>._(iterable, takeCount);
}
 TakeIterable._(this._iterable, this._takeCount);
 Iterator<E> get iterator {
return new TakeIterator<E>(_iterable.iterator, _takeCount);
}
}
 class EfficientLengthTakeIterable<E> extends TakeIterable<E> implements EfficientLength {EfficientLengthTakeIterable(Iterable<E> iterable, int takeCount) : super._(iterable, takeCount);
 int get length {
int iterableLength = _iterable.length;
 if (iterableLength > _takeCount) return _takeCount;
 return iterableLength;
}
}
 class TakeIterator<E> extends Iterator<E> {final Iterator<E> _iterator;
 int _remaining;
 TakeIterator(this._iterator, this._remaining) {
assert (_remaining is int && _remaining >= 0);}
 bool moveNext() {
_remaining--;
 if (_remaining >= 0) {
return _iterator.moveNext();
}
 _remaining = -1;
 return false;
}
 E get current {
if (_remaining < 0) return null;
 return _iterator.current;
}
}
 class TakeWhileIterable<E> extends IterableBase<E> {final Iterable<E> _iterable;
 final _ElementPredicate _f;
 TakeWhileIterable(this._iterable, bool this._f(E element));
 Iterator<E> get iterator {
return new TakeWhileIterator<E>(_iterable.iterator, _f);
}
}
 class TakeWhileIterator<E> extends Iterator<E> {final Iterator<E> _iterator;
 final _ElementPredicate _f;
 bool _isFinished = false;
 TakeWhileIterator(this._iterator, bool this._f(E element));
 bool moveNext() {
if (_isFinished) return false;
 if (!_iterator.moveNext() || !_f(_iterator.current)) {
_isFinished = true;
 return false;
}
 return true;
}
 E get current {
if (_isFinished) return null;
 return _iterator.current;
}
}
 class SkipIterable<E> extends IterableBase<E> {final Iterable<E> _iterable;
 final int _skipCount;
 factory SkipIterable(Iterable<E> iterable, int count) {
if (iterable is EfficientLength) {
return new EfficientLengthSkipIterable<E>(iterable, count);
}
 return new SkipIterable<E>._(iterable, count);
}
 SkipIterable._(this._iterable, this._skipCount) {
if (_skipCount is! int) {
throw new ArgumentError.value(_skipCount, "count is not an integer");
}
 RangeError.checkNotNegative(_skipCount, "count");
}
 Iterable<E> skip(int count) {
if (_skipCount is! int) {
throw new ArgumentError.value(_skipCount, "count is not an integer");
}
 RangeError.checkNotNegative(_skipCount, "count");
 return new SkipIterable<E>._(_iterable, _skipCount + count);
}
 Iterator<E> get iterator {
return new SkipIterator<E>(_iterable.iterator, _skipCount);
}
}
 class EfficientLengthSkipIterable<E> extends SkipIterable<E> implements EfficientLength {EfficientLengthSkipIterable(Iterable<E> iterable, int skipCount) : super._(iterable, skipCount);
 int get length {
int length = _iterable.length - _skipCount;
 if (length >= 0) return length;
 return 0;
}
}
 class SkipIterator<E> extends Iterator<E> {final Iterator<E> _iterator;
 int _skipCount;
 SkipIterator(this._iterator, this._skipCount) {
assert (_skipCount is int && _skipCount >= 0);}
 bool moveNext() {
for (int i = 0; i < _skipCount; i++) _iterator.moveNext();
 _skipCount = 0;
 return _iterator.moveNext();
}
 E get current => _iterator.current;
}
 class SkipWhileIterable<E> extends IterableBase<E> {final Iterable<E> _iterable;
 final _ElementPredicate _f;
 SkipWhileIterable(this._iterable, bool this._f(E element));
 Iterator<E> get iterator {
return new SkipWhileIterator<E>(_iterable.iterator, _f);
}
}
 class SkipWhileIterator<E> extends Iterator<E> {final Iterator<E> _iterator;
 final _ElementPredicate _f;
 bool _hasSkipped = false;
 SkipWhileIterator(this._iterator, bool this._f(E element));
 bool moveNext() {
if (!_hasSkipped) {
_hasSkipped = true;
 while (_iterator.moveNext()) {
if (!_f(_iterator.current)) return true;
}
}
 return _iterator.moveNext();
}
 E get current => _iterator.current;
}
 class EmptyIterable<E> extends IterableBase<E> implements EfficientLength {const EmptyIterable();
 Iterator<E> get iterator => ((__x13) => DDC$RT.cast(__x13, null, DDC$RT.type((Iterator<E> _) {
}
), "CastExact", """line 678, column 31 of dart:_internal/iterable.dart: """, __x13 is Iterator<E>, false))(const EmptyIterator());
 void forEach(void action(E element)) {
}
 bool get isEmpty => true;
 int get length => 0;
 E get first {
throw IterableElementError.noElement();
}
 E get last {
throw IterableElementError.noElement();
}
 E get single {
throw IterableElementError.noElement();
}
 E elementAt(int index) {
throw new RangeError.range(index, 0, 0, "index");
}
 bool contains(Object element) => false;
 bool every(bool test(E element)) => true;
 bool any(bool test(E element)) => false;
 E firstWhere(bool test(E element), {
E orElse()}
) {
if (orElse != null) return orElse();
 throw IterableElementError.noElement();
}
 E lastWhere(bool test(E element), {
E orElse()}
) {
if (orElse != null) return orElse();
 throw IterableElementError.noElement();
}
 E singleWhere(bool test(E element), {
E orElse()}
) {
if (orElse != null) return orElse();
 throw IterableElementError.noElement();
}
 String join([String separator = ""]) => "";
 Iterable<E> where(bool test(E element)) => this;
 Iterable map(f(E element)) => const EmptyIterable();
 E reduce(E combine(E value, E element)) {
throw IterableElementError.noElement();
}
 fold(var initialValue, combine(var previousValue, E element)) {
return initialValue;
}
 Iterable<E> skip(int count) {
RangeError.checkNotNegative(count, "count");
 return this;
}
 Iterable<E> skipWhile(bool test(E element)) => this;
 Iterable<E> take(int count) {
RangeError.checkNotNegative(count, "count");
 return this;
}
 Iterable<E> takeWhile(bool test(E element)) => this;
 List toList({
bool growable : true}
) => growable ? <E> [] : new List<E>(0);
 Set toSet() => new Set<E>();
}
 class EmptyIterator<E> implements Iterator<E> {const EmptyIterator();
 bool moveNext() => false;
 E get current => null;
}
 abstract class BidirectionalIterator<T> implements Iterator<T> {bool movePrevious();
}
 class IterableMixinWorkaround<T> {static bool contains(Iterable iterable, var element) {
for (final e in iterable) {
if (e == element) return true;
}
 return false;
}
 static void forEach(Iterable iterable, void f(o)) {
for (final e in iterable) {
f(e);
}
}
 static bool any(Iterable iterable, bool f(o)) {
for (final e in iterable) {
if (f(e)) return true;
}
 return false;
}
 static bool every(Iterable iterable, bool f(o)) {
for (final e in iterable) {
if (!f(e)) return false;
}
 return true;
}
 static dynamic reduce(Iterable iterable, dynamic combine(previousValue, element)) {
Iterator iterator = iterable.iterator;
 if (!iterator.moveNext()) throw IterableElementError.noElement();
 var value = iterator.current;
 while (iterator.moveNext()) {
value = combine(value, iterator.current);
}
 return value;
}
 static dynamic fold(Iterable iterable, dynamic initialValue, dynamic combine(dynamic previousValue, element)) {
for (final element in iterable) {
initialValue = combine(initialValue, element);
}
 return initialValue;
}
 static void removeWhereList(List list, bool test(var element)) {
List retained = [];
 int length = list.length;
 for (int i = 0; i < length; i++) {
var element = list[i];
 if (!test(element)) {
retained.add(element);
}
 if (length != list.length) {
throw new ConcurrentModificationError(list);
}
}
 if (retained.length == length) return; list.length = retained.length;
 for (int i = 0; i < retained.length; i++) {
list[i] = retained[i];
}
}
 static bool isEmpty(Iterable iterable) {
return !iterable.iterator.moveNext();
}
 static dynamic first(Iterable iterable) {
Iterator it = iterable.iterator;
 if (!it.moveNext()) {
throw IterableElementError.noElement();
}
 return it.current;
}
 static dynamic last(Iterable iterable) {
Iterator it = iterable.iterator;
 if (!it.moveNext()) {
throw IterableElementError.noElement();
}
 dynamic result;
 do {
result = it.current;
}
 while (it.moveNext()); return result;
}
 static dynamic single(Iterable iterable) {
Iterator it = iterable.iterator;
 if (!it.moveNext()) throw IterableElementError.noElement();
 dynamic result = it.current;
 if (it.moveNext()) throw IterableElementError.tooMany();
 return result;
}
 static dynamic firstWhere(Iterable iterable, bool test(dynamic value), dynamic orElse()) {
for (dynamic element in iterable) {
if (test(element)) return element;
}
 if (orElse != null) return orElse();
 throw IterableElementError.noElement();
}
 static dynamic lastWhere(Iterable iterable, bool test(dynamic value), dynamic orElse()) {
dynamic result = null;
 bool foundMatching = false;
 for (dynamic element in iterable) {
if (test(element)) {
result = element;
 foundMatching = true;
}
}
 if (foundMatching) return result;
 if (orElse != null) return orElse();
 throw IterableElementError.noElement();
}
 static dynamic lastWhereList(List list, bool test(dynamic value), dynamic orElse()) {
for (int i = list.length - 1; i >= 0; i--) {
dynamic element = list[i];
 if (test(element)) return element;
}
 if (orElse != null) return orElse();
 throw IterableElementError.noElement();
}
 static dynamic singleWhere(Iterable iterable, bool test(dynamic value)) {
dynamic result = null;
 bool foundMatching = false;
 for (dynamic element in iterable) {
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
 static elementAt(Iterable iterable, int index) {
if (index is! int) throw new ArgumentError.notNull("index");
 RangeError.checkNotNegative(index, "index");
 int elementIndex = 0;
 for (var element in iterable) {
if (index == elementIndex) return element;
 elementIndex++;
}
 throw new RangeError.index(index, iterable, "index", null, elementIndex);
}
 static String join(Iterable iterable, [String separator]) {
StringBuffer buffer = new StringBuffer();
 buffer.writeAll(iterable, separator);
 return buffer.toString();
}
 static String joinList(List list, [String separator]) {
if (list.isEmpty) return "";
 if (list.length == 1) return "${list[0]}";
 StringBuffer buffer = new StringBuffer();
 if (separator.isEmpty) {
for (int i = 0; i < list.length; i++) {
buffer.write(list[i]);
}
}
 else {
buffer.write(list[0]);
 for (int i = 1; i < list.length; i++) {
buffer.write(separator);
 buffer.write(list[i]);
}
}
 return buffer.toString();
}
 Iterable<T> where(Iterable iterable, bool f(var element)) {
return new WhereIterable<T>(DDC$RT.cast(iterable, DDC$RT.type((Iterable<dynamic> _) {
}
), DDC$RT.type((Iterable<T> _) {
}
), "CastDynamic", """line 961, column 33 of dart:_internal/iterable.dart: """, iterable is Iterable<T>, false), f);
}
 static Iterable map(Iterable iterable, f(var element)) {
return new MappedIterable(iterable, f);
}
 static Iterable mapList(List list, f(var element)) {
return new MappedListIterable(list, f);
}
 static Iterable expand(Iterable iterable, Iterable f(var element)) {
return new ExpandIterable(iterable, f);
}
 Iterable<T> takeList(List list, int n) {
return new SubListIterable<T>(DDC$RT.cast(list, DDC$RT.type((List<dynamic> _) {
}
), DDC$RT.type((Iterable<T> _) {
}
), "CastDynamic", """line 978, column 35 of dart:_internal/iterable.dart: """, list is Iterable<T>, false), 0, n);
}
 Iterable<T> takeWhile(Iterable iterable, bool test(var value)) {
return new TakeWhileIterable<T>(DDC$RT.cast(iterable, DDC$RT.type((Iterable<dynamic> _) {
}
), DDC$RT.type((Iterable<T> _) {
}
), "CastDynamic", """line 983, column 37 of dart:_internal/iterable.dart: """, iterable is Iterable<T>, false), test);
}
 Iterable<T> skipList(List list, int n) {
return new SubListIterable<T>(DDC$RT.cast(list, DDC$RT.type((List<dynamic> _) {
}
), DDC$RT.type((Iterable<T> _) {
}
), "CastDynamic", """line 988, column 35 of dart:_internal/iterable.dart: """, list is Iterable<T>, false), n, null);
}
 Iterable<T> skipWhile(Iterable iterable, bool test(var value)) {
return new SkipWhileIterable<T>(DDC$RT.cast(iterable, DDC$RT.type((Iterable<dynamic> _) {
}
), DDC$RT.type((Iterable<T> _) {
}
), "CastDynamic", """line 993, column 37 of dart:_internal/iterable.dart: """, iterable is Iterable<T>, false), test);
}
 Iterable<T> reversedList(List list) {
return new ReversedListIterable<T>(DDC$RT.cast(list, DDC$RT.type((List<dynamic> _) {
}
), DDC$RT.type((Iterable<T> _) {
}
), "CastDynamic", """line 997, column 40 of dart:_internal/iterable.dart: """, list is Iterable<T>, false));
}
 static void sortList(List list, int compare(a, b)) {
if (compare == null) compare = DDC$RT.wrap((int f(Comparable<dynamic> __u14, Comparable<dynamic> __u15)) {
int c(Comparable<dynamic> x0, Comparable<dynamic> x1) => f(DDC$RT.cast(x0, dynamic, DDC$RT.type((Comparable<dynamic> _) {
}
), "CastParam", """line 1001, column 36 of dart:_internal/iterable.dart: """, x0 is Comparable<dynamic>, true), DDC$RT.cast(x1, dynamic, DDC$RT.type((Comparable<dynamic> _) {
}
), "CastParam", """line 1001, column 36 of dart:_internal/iterable.dart: """, x1 is Comparable<dynamic>, true));
 return f == null ? null : c;
}
, Comparable.compare, __t19, __t16, "Wrap", """line 1001, column 36 of dart:_internal/iterable.dart: """, Comparable.compare is __t16);
 Sort.sort(list, compare);
}
 static void shuffleList(List list, Random random) {
if (random == null) random = new Random();
 int length = list.length;
 while (length > 1) {
int pos = random.nextInt(length);
 length -= 1;
 var tmp = list[length];
 list[length] = list[pos];
 list[pos] = tmp;
}
}
 static int indexOfList(List list, var element, int start) {
return Lists.indexOf(list, element, start, list.length);
}
 static int lastIndexOfList(List list, var element, int start) {
if (start == null) start = list.length - 1;
 return Lists.lastIndexOf(list, element, start);
}
 static void _rangeCheck(List list, int start, int end) {
RangeError.checkValidRange(start, end, list.length);
}
 Iterable<T> getRangeList(List list, int start, int end) {
_rangeCheck(list, start, end);
 return new SubListIterable<T>(DDC$RT.cast(list, DDC$RT.type((List<dynamic> _) {
}
), DDC$RT.type((Iterable<T> _) {
}
), "CastDynamic", """line 1033, column 35 of dart:_internal/iterable.dart: """, list is Iterable<T>, false), start, end);
}
 static void setRangeList(List list, int start, int end, Iterable from, int skipCount) {
_rangeCheck(list, start, end);
 int length = end - start;
 if (length == 0) return; if (skipCount < 0) throw new ArgumentError(skipCount);
 List otherList;
 int otherStart;
 if (from is List) {
otherList = from;
 otherStart = skipCount;
}
 else {
otherList = from.skip(skipCount).toList(growable: false);
 otherStart = 0;
}
 if (otherStart + length > otherList.length) {
throw IterableElementError.tooFew();
}
 Lists.copy(otherList, otherStart, list, start, length);
}
 static void replaceRangeList(List list, int start, int end, Iterable iterable) {
_rangeCheck(list, start, end);
 if (iterable is! EfficientLength) {
iterable = iterable.toList();
}
 int removeLength = end - start;
 int insertLength = iterable.length;
 if (removeLength >= insertLength) {
int delta = removeLength - insertLength;
 int insertEnd = start + insertLength;
 int newEnd = list.length - delta;
 list.setRange(start, insertEnd, iterable);
 if (delta != 0) {
list.setRange(insertEnd, newEnd, list, end);
 list.length = newEnd;
}
}
 else {
int delta = insertLength - removeLength;
 int newLength = list.length + delta;
 int insertEnd = start + insertLength;
 list.length = newLength;
 list.setRange(insertEnd, newLength, list, end);
 list.setRange(start, insertEnd, iterable);
}
}
 static void fillRangeList(List list, int start, int end, fillValue) {
_rangeCheck(list, start, end);
 for (int i = start; i < end; i++) {
list[i] = fillValue;
}
}
 static void insertAllList(List list, int index, Iterable iterable) {
RangeError.checkValueInInterval(index, 0, list.length, "index");
 if (iterable is! EfficientLength) {
iterable = iterable.toList(growable: false);
}
 int insertionLength = iterable.length;
 list.length += insertionLength;
 list.setRange(index + insertionLength, list.length, list, index);
 for (var element in iterable) {
list[index++] = element;
}
}
 static void setAllList(List list, int index, Iterable iterable) {
RangeError.checkValueInInterval(index, 0, list.length, "index");
 for (var element in iterable) {
list[index++] = element;
}
}
 Map<int, T> asMapList(List l) {
return new ListMapView<T>(DDC$RT.cast(l, DDC$RT.type((List<dynamic> _) {
}
), DDC$RT.type((List<T> _) {
}
), "CastDynamic", """line 1115, column 31 of dart:_internal/iterable.dart: """, l is List<T>, false));
}
 static bool setContainsAll(Set set, Iterable other) {
for (var element in other) {
if (!set.contains(element)) return false;
}
 return true;
}
 static Set setIntersection(Set set, Set other, Set result) {
Set smaller;
 Set larger;
 if (set.length < other.length) {
smaller = set;
 larger = other;
}
 else {
smaller = other;
 larger = set;
}
 for (var element in smaller) {
if (larger.contains(element)) {
result.add(element);
}
}
 return result;
}
 static Set setUnion(Set set, Set other, Set result) {
result.addAll(set);
 result.addAll(other);
 return result;
}
 static Set setDifference(Set set, Set other, Set result) {
for (var element in set) {
if (!other.contains(element)) {
result.add(element);
}
}
 return result;
}
}
 abstract class IterableElementError {static StateError noElement() => new StateError("No element");
 static StateError tooMany() => new StateError("Too many elements");
 static StateError tooFew() => new StateError("Too few elements");
}
 typedef dynamic __t1(dynamic __u2);
 typedef dynamic __t3<E>(E __u4);
 typedef Iterable<T> __t7<S, T>(S __u8);
 typedef Iterable<dynamic> __t9(dynamic __u10);
 typedef int __t16(dynamic __u17, dynamic __u18);
 typedef int __t19(Comparable<dynamic> __u20, Comparable<dynamic> __u21);
