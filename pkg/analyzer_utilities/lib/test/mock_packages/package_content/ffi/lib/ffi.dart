import 'dart:ffi';

const Allocator calloc = _CallocAllocator();

abstract class Allocator {
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment});

  void free(Pointer pointer);
}

final class Utf8 extends Opaque {}

class _CallocAllocator implements Allocator {
  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) =>
      throw '';

  @override
  void free(Pointer pointer) => throw '';
}
