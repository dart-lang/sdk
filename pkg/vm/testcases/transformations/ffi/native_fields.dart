import 'dart:ffi';

@Native()
external Pointer<Char> aString;

@Native<Int32>()
external int anInt;

@Native<Int>()
external int anotherInt;

final class Vec2d extends Struct {
  @Double()
  external double x;
  @Double()
  external double y;
}

final class MyUnion extends Union {
  external Vec2d vector;
  external Pointer<Vec2d> indirectVector;
}

@Native()
external final Vec2d vector;

@Native()
external MyUnion union;

void main() {
  print('first char of string: ${aString.value}');
  print('global int: {$anInt}');

  aString = nullptr;
  anInt++;

  final vec = vector;
  print('(${vec.x}, ${vec.y})');

  union.indirectVector = Native.addressOf(vector);

  print(Native.addressOf<Int>(anotherInt));
  print(Native.addressOf<Vec2d>(vector));
  print(Native.addressOf<MyUnion>(union));
}
