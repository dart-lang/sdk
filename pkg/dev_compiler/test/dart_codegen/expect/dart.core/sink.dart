part of dart.core;

abstract class Sink<T> {
  void add(T data);
  void close();
}
