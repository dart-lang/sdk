import 'dart:ffi';

final class Coordinate extends Struct {
  @Int64()
  external int x;

  @Int64()
  external int y;

  void copyInto(Pointer<Coordinate> ptr) {
    ptr.ref = this;
  }
}

final class SomeUnion extends Union {
  external Coordinate coordinate;
  @Int64()
  external int id;

  void copyIntoAtIndex(Pointer<SomeUnion> ptr, int index) {
    ptr[index] = this;
  }
}

void main() {}
