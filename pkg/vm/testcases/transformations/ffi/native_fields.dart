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

final class MyStruct extends Struct {
  @Array.variable()
  external Array<Uint8> array;
}

final class MyStruct2 extends Struct {
  @Array.variableWithVariableDimension(1)
  external Array<Uint8> array;
}

final class MyStruct3 extends Struct {
  @Array.variableMulti([1, 2])
  external Array<Array<Array<Uint8>>> array;
}

final class MyStruct4 extends Struct {
  @Array.variableMulti(variableDimension: 1, [1, 2])
  external Array<Array<Array<Uint8>>> array;
}

final class MyUnion extends Union {
  external Vec2d vector;
  external Pointer<Vec2d> indirectVector;
}

@Native()
external final Vec2d vector;

@Native()
external MyUnion union;

@Native()
@Array(1, 2, 3)
external Array<Array<Array<Double>>> manyNumbers;

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

  final wholeArray = manyNumbers;
  wholeArray[0][1][2] = 123.45;
  manyNumbers = wholeArray;
  manyNumbers[0][0][0] = 54.321;
}
