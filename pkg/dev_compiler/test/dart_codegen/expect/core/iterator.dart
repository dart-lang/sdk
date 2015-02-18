part of dart.core;

abstract class Iterator<E> {
  bool moveNext();
  E get current;
}
