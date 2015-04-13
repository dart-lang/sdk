part of dart.core;
 @SupportJsExtensionMethods() abstract class Iterable<E> {const Iterable();
 factory Iterable.generate(int count, [E generator(int index)]) {
  if (count <= 0) return new EmptyIterable<E>();
   return new _GeneratorIterable<E>(count, generator);
  }
 Iterator<E> get iterator;
 Iterable map(f(E element));
 Iterable<E> where(bool test(E element));
 Iterable expand(Iterable f(E element));
 bool contains(Object element);
 void forEach(void f(E element));
 E reduce(E combine(E value, E element));
 dynamic fold(var initialValue, dynamic combine(var previousValue, E element));
 bool every(bool test(E element));
 String join([String separator = ""]) {
  StringBuffer buffer = new StringBuffer();
   buffer.writeAll(this, separator);
   return buffer.toString();
  }
 bool any(bool test(E element));
 List<E> toList({
  bool growable : true}
);
 Set<E> toSet();
 int get length;
 bool get isEmpty;
 bool get isNotEmpty;
 Iterable<E> take(int count);
 Iterable<E> takeWhile(bool test(E value));
 Iterable<E> skip(int count);
 Iterable<E> skipWhile(bool test(E value));
 E get first;
 E get last;
 E get single;
 E firstWhere(bool test(E element), {
  E orElse()}
);
 E lastWhere(bool test(E element), {
  E orElse()}
);
 E singleWhere(bool test(E element));
 E elementAt(int index);
}
 typedef E _Generator<E>(int index);
 class _GeneratorIterable<E> extends IterableBase<E> implements EfficientLength {final int _start;
 final int _end;
 final _Generator<E> _generator;
 _GeneratorIterable(this._end, E generator(int n)) : _start = 0, _generator = ((__x8) => DEVC$RT.cast(__x8, dynamic, DEVC$RT.type((_Generator<E> _) {
}
), "CompositeCast", """line 320, column 22 of dart:core/iterable.dart: """, __x8 is _Generator<E>, false))((generator != null) ? generator : _id);
 _GeneratorIterable.slice(this._start, this._end, this._generator);
 Iterator<E> get iterator => new _GeneratorIterator<E>(_start, _end, _generator);
 int get length => _end - _start;
 Iterable<E> skip(int count) {
RangeError.checkNotNegative(count, "count");
 if (count == 0) return this;
 int newStart = _start + count;
 if (newStart >= _end) return new EmptyIterable<E>();
 return new _GeneratorIterable<E>.slice(newStart, _end, _generator);
}
 Iterable<E> take(int count) {
RangeError.checkNotNegative(count, "count");
 if (count == 0) return new EmptyIterable<E>();
 int newEnd = _start + count;
 if (newEnd >= _end) return this;
 return new _GeneratorIterable<E>.slice(_start, newEnd, _generator);
}
 static int _id(int n) => n;
}
 class _GeneratorIterator<E> implements Iterator<E> {final int _end;
 final _Generator<E> _generator;
 int _index;
 E _current;
 _GeneratorIterator(this._index, this._end, this._generator);
 bool moveNext() {
if (_index < _end) {
_current = _generator(_index);
 _index++;
 return true;
}
 else {
_current = null;
 return false;
}
}
 E get current => _current;
}
 abstract class BidirectionalIterator<E> implements Iterator<E> {bool movePrevious();
}
