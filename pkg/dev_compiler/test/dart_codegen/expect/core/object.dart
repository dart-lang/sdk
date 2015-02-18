part of dart.core;

class Object {
  const Object();
  bool operator ==(other) => identical(this, other);
  external int get hashCode;
  external String toString();
  external dynamic noSuchMethod(Invocation invocation);
  external Type get runtimeType;
}
