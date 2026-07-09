import 'dart:ffi';

final class Coordinate extends Struct {
  @Int64()
  external int x;

  @Int64()
  external int y;

  void copyInto(Pointer<Coordinate> ptr) {
    ptr.ref = this;
  }

  void getRefWithFinalizer(
    Pointer<Coordinate> ptr,
    Pointer<NativeFinalizerFunction> finalizer, {
    Pointer<Void>? token,
  }) {
    ptr.refWithFinalizer(finalizer, token: token);
  }
}

final class SomeUnion extends Union {
  external Coordinate coordinate;
  @Int64()
  external int id;

  void copyIntoAtIndex(Pointer<SomeUnion> ptr, int index) {
    ptr[index] = this;
  }

  void getRefWithFinalizer(
    Pointer<SomeUnion> ptr,
    Pointer<NativeFinalizerFunction> finalizer, {
    Pointer<Void>? token,
  }) {
    ptr.refWithFinalizer(finalizer, token: token);
  }
}

void main() {}
