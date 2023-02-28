extension IterableComparableExtensions<T extends Comparable> on Iterable<T> {
  /*
  * Returns the largest value in the iterable determined via
  * [Comparable.toCompare()].
  *
  * If any value is NaN or otherwise not equal to itself,
  * that element is treated as larger than any other.
  *
  * The iterable must have at least one element, otherwise
  * [IterableElementError] gets thrown.
  * If it has only one element, that element is returned.
  *
  * If multiple items are maximal, the function returns the first one
  * encountered.
  */
  T get max {
    final Iterator<T> iterator = this.iterator;
    if (!iterator.moveNext()) {
      throw IterableElementError.noElement();
    }
    T value = iterator.current;
    if (value != value) {
      return value;
    }

    while (iterator.moveNext()) {
      final current = iterator.current;
      if (current != current) {
        return current;
      } else if (current.compareTo(value) > 0) {
        value = current;
      }
    }
    return value;
  }

  /*
  * Returns the smallest value in the iterable determined via
  * [Comparable.toCompare()].
  *
  * If any value is NaN or otherwise not equal to itself,
  * that element is treated as smaller than any other.
  *
  * The iterable must have at least one element, otherwise
  * [IterableElementError] gets thrown.
  * If it has only one element, that element is returned.
  *
  * If multiple items are minimal, the function returns the first one
  * encountered.
  */
  T get min {
    final Iterator<T> iterator = this.iterator;
    if (!iterator.moveNext()) {
      throw IterableElementError.noElement();
    }
    T value = iterator.current;
    if (value != value) {
      return value;
    }

    while (iterator.moveNext()) {
      final current = iterator.current;
      if (current != current) {
        return current;
      } else if (current.compareTo(value) < 0) {
        value = current;
      }
    }
    return value;
  }
}
