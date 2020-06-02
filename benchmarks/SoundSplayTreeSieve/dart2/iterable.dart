/// Marker interface for [Iterable] subclasses that have an efficient
/// [length] implementation.
abstract class EfficientLengthIterable<T> extends Iterable<T> {
  const EfficientLengthIterable();

  /// Returns the number of elements in the iterable.
  ///
  /// This is an efficient operation that doesn't require iterating through
  /// the elements.
  int get length;
}

/// Creates errors throw by [Iterable] when the element count is wrong.
abstract class IterableElementError {
  /// Error thrown thrown by, e.g., [Iterable.first] when there is no result.
  static StateError noElement() => StateError("No element");

  /// Error thrown by, e.g., [Iterable.single] if there are too many results.
  static StateError tooMany() => StateError("Too many elements");

  /// Error thrown by, e.g., [List.setRange] if there are too few elements.
  static StateError tooFew() => StateError("Too few elements");
}
