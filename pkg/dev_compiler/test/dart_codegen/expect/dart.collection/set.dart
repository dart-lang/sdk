part of dart.collection;

abstract class SetMixin<E> implements Set<E> {
  bool add(E element);
  bool contains(Object element);
  E lookup(E element);
  bool remove(Object element);
  Iterator<E> get iterator;
  Set<E> toSet();
  int get length;
  bool get isEmpty => length == 0;
  bool get isNotEmpty => length != 0;
  void clear() {
    removeAll(toList());
  }
  void addAll(Iterable<E> elements) {
    for (E element in elements) add(element);
  }
  void removeAll(Iterable<Object> elements) {
    for (Object element in elements) remove(element);
  }
  void retainAll(Iterable<Object> elements) {
    Set<E> toRemove = toSet();
    for (Object o in elements) {
      toRemove.remove(o);
    }
    removeAll(toRemove);
  }
  void removeWhere(bool test(E element)) {
    List toRemove = [];
    for (E element in this) {
      if (test(element)) toRemove.add(element);
    }
    removeAll(DDC$RT.cast(toRemove, DDC$RT.type((List<dynamic> _) {}),
        DDC$RT.type((Iterable<Object> _) {}), "CastDynamic",
        """line 77, column 15 of dart:collection/set.dart: """,
        toRemove is Iterable<Object>, false));
  }
  void retainWhere(bool test(E element)) {
    List toRemove = [];
    for (E element in this) {
      if (!test(element)) toRemove.add(element);
    }
    removeAll(DDC$RT.cast(toRemove, DDC$RT.type((List<dynamic> _) {}),
        DDC$RT.type((Iterable<Object> _) {}), "CastDynamic",
        """line 85, column 15 of dart:collection/set.dart: """,
        toRemove is Iterable<Object>, false));
  }
  bool containsAll(Iterable<Object> other) {
    for (Object o in other) {
      if (!contains(o)) return false;
    }
    return true;
  }
  Set<E> union(Set<E> other) {
    return toSet()..addAll(other);
  }
  Set<E> intersection(Set<Object> other) {
    Set<E> result = toSet();
    for (E element in this) {
      if (!other.contains(element)) result.remove(element);
    }
    return result;
  }
  Set<E> difference(Set<Object> other) {
    Set<E> result = toSet();
    for (E element in this) {
      if (other.contains(element)) result.remove(element);
    }
    return result;
  }
  List<E> toList({bool growable: true}) {
    List<E> result =
        growable ? (new List<E>()..length = length) : new List<E>(length);
    int i = 0;
    for (E element in this) result[i++] = element;
    return result;
  }
  Iterable map(f(E element)) =>
      new EfficientLengthMappedIterable<E, dynamic>(this, f);
  E get single {
    if (length > 1) throw IterableElementError.tooMany();
    Iterator it = iterator;
    if (!it.moveNext()) throw IterableElementError.noElement();
    E result = DDC$RT.cast(it.current, dynamic, E, "CastGeneral",
        """line 130, column 16 of dart:collection/set.dart: """,
        it.current is E, false);
    return result;
  }
  String toString() => IterableBase.iterableToFullString(this, '{', '}');
  Iterable<E> where(bool f(E element)) => new WhereIterable<E>(this, f);
  Iterable expand(Iterable f(E element)) =>
      new ExpandIterable<E, dynamic>(this, f);
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
  dynamic fold(
      var initialValue, dynamic combine(var previousValue, E element)) {
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
        buffer.write("${iterator.current}");
      } while (iterator.moveNext());
    } else {
      buffer.write("${iterator.current}");
      while (iterator.moveNext()) {
        buffer.write(separator);
        buffer.write("${iterator.current}");
      }
    }
    return buffer.toString();
  }
  bool any(bool test(E element)) {
    for (E element in this) {
      if (test(element)) return true;
    }
    return false;
  }
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
    return DDC$RT.cast(it.current, dynamic, E, "CastGeneral",
        """line 220, column 12 of dart:collection/set.dart: """,
        it.current is E, false);
  }
  E get last {
    Iterator it = iterator;
    if (!it.moveNext()) {
      throw IterableElementError.noElement();
    }
    E result;
    do {
      result = DDC$RT.cast(it.current, dynamic, E, "CastGeneral",
          """line 230, column 16 of dart:collection/set.dart: """,
          it.current is E, false);
    } while (it.moveNext());
    return result;
  }
  E firstWhere(bool test(E value), {E orElse()}) {
    for (E element in this) {
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }
  E lastWhere(bool test(E value), {E orElse()}) {
    E result = ((__x43) => DDC$RT.cast(__x43, Null, E, "CastLiteral",
        """line 244, column 16 of dart:collection/set.dart: """, __x43 is E,
        false))(null);
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
    E result = ((__x44) => DDC$RT.cast(__x44, Null, E, "CastLiteral",
        """line 258, column 16 of dart:collection/set.dart: """, __x44 is E,
        false))(null);
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
}
abstract class SetBase<E> extends SetMixin<E> {
  static String setToString(Set set) =>
      IterableBase.iterableToFullString(set, '{', '}');
}
