import "package:expect/expect.dart";

void main() {
  testIteratorFactory();
  testIteratorEquality();
}

void testIteratorFactory() {
  Iterator<Object?>? returnedIterator;
  Object? thrownError;
  int calls = 0;
  Iterator<T> f<T>() {
    calls++;
    if (thrownError case var error?) throw error;
    return returnedIterator as Iterator<T>;
  }

  var ints = Iterable.withIterator(f<int>);
  var intIterator = <int>[].iterator;
  returnedIterator = intIterator;
  Expect.identical(intIterator, ints.iterator, "First iterator should match");
  Expect.equals(1, calls, "First call count");
  Expect.identical(intIterator, ints.iterator, "Second iterator should match");
  Expect.equals(2, calls, "Second call count");

  var intIterator2 = <int>[].iterator;
  Expect.notIdentical(intIterator, intIterator2, "Different iterators should not be identical");
  returnedIterator = intIterator2;
  Expect.identical(intIterator2, ints.iterator, "Third iterator should match");
  Expect.equals(3, calls, "Third call count");
  Expect.identical(intIterator2, ints.iterator, "Fourth iterator should match");
  Expect.equals(4, calls, "Fourth call count");

  var error = StateError("quo");
  thrownError = error;
  Expect.identical(error, Expect.throws(() => ints.iterator), "Should throw first error");
  Expect.equals(5, calls, "Fifth call count");
  Expect.identical(error, Expect.throws(() => ints.iterator), "Should throw second error");
  Expect.equals(6, calls, "Sixth call count");

  thrownError = null;
  Expect.identical(intIterator2, ints.iterator, "Fifth iterator should match");
  Expect.equals(7, calls, "Seventh call count");

  var objectqs = Iterable.withIterator(f<Object?>);
  Expect.identical(intIterator2, objectqs.iterator, "Object iterator should match");
  Expect.equals(8, calls, "Eighth call count");

  var nulls = Iterable.withIterator(f<Null>);
  var nullIterator = <Null>[].iterator;
  returnedIterator = nullIterator;
  Expect.identical(nullIterator, nulls.iterator, "Null iterator should match");
  Expect.equals(9, calls, "Ninth call count");

  var nevers = Iterable.withIterator(f<Never>);
  thrownError = error;
  Expect.identical(error, Expect.throws(() => nevers.iterator), "Should throw third error");
  Expect.equals(10, calls, "Tenth call count");
  Expect.identical(error, Expect.throws(() => nevers.iterator), "Should throw fourth error");
  Expect.equals(11, calls, "Eleventh call count");
}

void testIteratorEquality() {
  var iterable1 = Iterable.withIterator(() => [1, 2, 3].iterator);
  var iterable2 = Iterable.withIterator(() => [1, 2, 3].iterator);
  Expect.listEquals(iterable1.toList(), iterable2.toList(), "Iterator contents should be equal");
}
