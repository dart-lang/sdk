// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  negate(1);
  negateNum(1);
  negateNum(1.5);
  negateNull(1);
  negateNull(null);
  negateString(1);
  negateString('');

  add(1, 2);
  addNumInt(1, 2);
  addNumInt(1.5, 2);
  addIntNum(2, 1);
  addIntNum(2, 1.5);
  addNumNum(1, 1.5);
  addNumNum(1.5, 1);
  addIntNull(2, 1);
  addIntNull(2, null);
  addNullInt(1, 2);
  addNullInt(null, 2);
  addStringInt(1, 2);
  addStringInt('', 2);
  addIntString(2, 1);
  addIntString(2, '');

  subtract(1, 2);
  subtractNumInt(1, 2);
  subtractNumInt(1.5, 2);
  subtractIntNum(2, 1);
  subtractIntNum(2, 1.5);
  subtractNumNum(1, 1.5);
  subtractNumNum(1.5, 1);
  subtractIntNull(2, 1);
  subtractIntNull(2, null);
  subtractNullInt(1, 2);
  subtractNullInt(null, 2);
  subtractStringInt(1, 2);
  subtractStringInt('', 2);
  subtractIntString(2, 1);
  subtractIntString(2, '');

  multiply(1, 2);
  multiplyNumInt(1, 2);
  multiplyNumInt(1.5, 2);
  multiplyIntNum(2, 1);
  multiplyIntNum(2, 1.5);
  multiplyNumNum(1, 1.5);
  multiplyNumNum(1.5, 1);
  multiplyIntNull(2, 1);
  multiplyIntNull(2, null);
  multiplyNullInt(1, 2);
  multiplyNullInt(null, 2);
  multiplyStringInt(1, 2);
  multiplyStringInt('', 2);
  multiplyIntString(2, 1);
  multiplyIntString(2, '');

  divide(1, 2);
  divideZero(1);
  divideNumInt(1, 2);
  divideNumInt(1.5, 2);
  divideIntNum(2, 1);
  divideIntNum(2, 1.5);
  divideNumNum(1, 1.5);
  divideNumNum(1.5, 1);
  divideIntNull(2, 1);
  divideIntNull(2, null);
  divideNullInt(1, 2);
  divideNullInt(null, 2);
  divideStringInt(1, 2);
  divideStringInt('', 2);
  divideIntString(2, 1);
  divideIntString(2, '');

  truncatingDivide(1, 2);
  truncatingDivideZero(1);
  truncatingDivideIntNonZero1(1);
  truncatingDivideIntNonZero2(2);
  truncatingDivideNumInt(1, 2);
  truncatingDivideNumInt(1.5, 2);
  truncatingDivideNumNonZero(1);
  truncatingDivideNumNonZero(1.5);
  truncatingDivideIntNum(2, 1);
  truncatingDivideIntNum(2, 1.5);
  truncatingDivideNumNum(1, 1.5);
  truncatingDivideNumNum(1.5, 1);
  truncatingDivideIntNull(2, 1);
  truncatingDivideIntNull(2, null);
  truncatingDivideNullInt(1, 2);
  truncatingDivideNullInt(null, 2);
  truncatingDivideStringInt(1, 2);
  truncatingDivideStringInt('', 2);
  truncatingDivideIntString(2, 1);
  truncatingDivideIntString(2, '');

  abs(1);
  absNum(1);
  absNum(1.5);
  absNull(1);
  absNull(null);
  absString(1);
  absString('');

  round(1);
  roundNum(1);
  roundNum(1.5);
  roundNull(1);
  roundNull(null);
  roundString(1);
  roundString('');
}

////////////////////////////////////////////////////////////////////////////////
// Negation
////////////////////////////////////////////////////////////////////////////////

/*element: negate:Specializer=[Negate],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
negate(o) {
  return -o;
}

/*element: negateNum:Specializer=[Negate],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
negateNum(o) {
  return -o;
}

/*element: negateNull:Specializer=[Negate],PrimitiveCheck=[kind=receiver&type=num]*/
@pragma('dart2js:noInline')
negateNull(o) {
  return -o;
}

/*element: negateString:Specializer=[!Negate]*/
@pragma('dart2js:noInline')
negateString(o) {
  return -o;
}

////////////////////////////////////////////////////////////////////////////////
// Addition
////////////////////////////////////////////////////////////////////////////////

/*element: add:Specializer=[Add],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
add(a, b) {
  return a + b;
}

/*element: addNumInt:Specializer=[Add],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
addNumInt(a, b) {
  return a + b;
}

/*element: addIntNum:Specializer=[Add],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
addIntNum(a, b) {
  return a + b;
}

/*element: addNumNum:Specializer=[Add],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
addNumNum(a, b) {
  return a + b;
}

/*element: addNullInt:Specializer=[Add],PrimitiveCheck=[kind=receiver&type=num]*/
@pragma('dart2js:noInline')
addNullInt(a, b) {
  return a + b;
}

/*element: addIntNull:Specializer=[Add],PrimitiveCheck=[kind=argument&type=num]*/
@pragma('dart2js:noInline')
addIntNull(a, b) {
  return a + b;
}

/*element: addStringInt:Specializer=[!Add]*/
@pragma('dart2js:noInline')
addStringInt(a, b) {
  return a + b;
}

/*element: addIntString:Specializer=[Add],PrimitiveCheck=[kind=argument&type=num]*/
@pragma('dart2js:noInline')
addIntString(a, b) {
  return a + b;
}

////////////////////////////////////////////////////////////////////////////////
// Subtraction
////////////////////////////////////////////////////////////////////////////////

/*element: subtract:Specializer=[Subtract],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
subtract(a, b) {
  return a - b;
}

/*element: subtractNumInt:Specializer=[Subtract],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
subtractNumInt(a, b) {
  return a - b;
}

/*element: subtractIntNum:Specializer=[Subtract],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
subtractIntNum(a, b) {
  return a - b;
}

/*element: subtractNumNum:Specializer=[Subtract],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
subtractNumNum(a, b) {
  return a - b;
}

/*element: subtractNullInt:Specializer=[Subtract],PrimitiveCheck=[kind=receiver&type=num]*/
@pragma('dart2js:noInline')
subtractNullInt(a, b) {
  return a - b;
}

/*element: subtractIntNull:Specializer=[Subtract],PrimitiveCheck=[kind=argument&type=num]*/
@pragma('dart2js:noInline')
subtractIntNull(a, b) {
  return a - b;
}

/*element: subtractStringInt:Specializer=[Subtract],PrimitiveCheck=[kind=receiver&type=num]*/
@pragma('dart2js:noInline')
subtractStringInt(a, b) {
  return a - b;
}

/*element: subtractIntString:Specializer=[Subtract],PrimitiveCheck=[kind=argument&type=num]*/
@pragma('dart2js:noInline')
subtractIntString(a, b) {
  return a - b;
}

////////////////////////////////////////////////////////////////////////////////
// Multiplication
////////////////////////////////////////////////////////////////////////////////

/*element: multiply:Specializer=[Multiply],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
multiply(a, b) {
  return a * b;
}

/*element: multiplyNumInt:Specializer=[Multiply],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
multiplyNumInt(a, b) {
  return a * b;
}

/*element: multiplyIntNum:Specializer=[Multiply],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
multiplyIntNum(a, b) {
  return a * b;
}

/*element: multiplyNumNum:Specializer=[Multiply],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
multiplyNumNum(a, b) {
  return a * b;
}

/*element: multiplyNullInt:Specializer=[Multiply],PrimitiveCheck=[kind=receiver&type=num]*/
@pragma('dart2js:noInline')
multiplyNullInt(a, b) {
  return a * b;
}

/*element: multiplyIntNull:Specializer=[Multiply],PrimitiveCheck=[kind=argument&type=num]*/
@pragma('dart2js:noInline')
multiplyIntNull(a, b) {
  return a * b;
}

/*element: multiplyStringInt:Specializer=[!Multiply]*/
@pragma('dart2js:noInline')
multiplyStringInt(a, b) {
  return a * b;
}

/*element: multiplyIntString:Specializer=[Multiply],PrimitiveCheck=[kind=argument&type=num]*/
@pragma('dart2js:noInline')
multiplyIntString(a, b) {
  return a * b;
}

////////////////////////////////////////////////////////////////////////////////
// Division
////////////////////////////////////////////////////////////////////////////////

/*element: divide:Specializer=[Divide],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
divide(a, b) {
  return a / b;
}

/*element: divideZero:Specializer=[Divide],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
divideZero(a) {
  return a / 0;
}

/*element: divideNumInt:Specializer=[Divide],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
divideNumInt(a, b) {
  return a / b;
}

/*element: divideIntNum:Specializer=[Divide],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
divideIntNum(a, b) {
  return a / b;
}

/*element: divideNumNum:Specializer=[Divide],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
divideNumNum(a, b) {
  return a / b;
}

/*element: divideNullInt:Specializer=[Divide],PrimitiveCheck=[kind=receiver&type=num]*/
@pragma('dart2js:noInline')
divideNullInt(a, b) {
  return a / b;
}

/*element: divideIntNull:Specializer=[Divide],PrimitiveCheck=[kind=argument&type=num]*/
@pragma('dart2js:noInline')
divideIntNull(a, b) {
  return a / b;
}

/*element: divideStringInt:Specializer=[Divide],PrimitiveCheck=[kind=receiver&type=num]*/
@pragma('dart2js:noInline')
divideStringInt(a, b) {
  return a / b;
}

/*element: divideIntString:Specializer=[Divide],PrimitiveCheck=[kind=argument&type=num]*/
@pragma('dart2js:noInline')
divideIntString(a, b) {
  return a / b;
}

////////////////////////////////////////////////////////////////////////////////
// Truncating division
////////////////////////////////////////////////////////////////////////////////

/*element: truncatingDivide:Specializer=[TruncatingDivide],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
truncatingDivide(a, b) {
  return a ~/ 2;
}

/*element: truncatingDivideZero:Specializer=[!TruncatingDivide]*/
@pragma('dart2js:noInline')
truncatingDivideZero(a) {
  return a ~/ 0;
}

/*element: truncatingDivideIntNonZero1:Specializer=[TruncatingDivide],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
truncatingDivideIntNonZero1(a) {
  return a ~/ 1;
}

/*element: truncatingDivideIntNonZero2:Specializer=[TruncatingDivide],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
truncatingDivideIntNonZero2(a) {
  return a ~/ 2;
}

/*element: truncatingDivideNumInt:Specializer=[!TruncatingDivide]*/
@pragma('dart2js:noInline')
truncatingDivideNumInt(a, b) {
  return a ~/ b;
}

/*element: truncatingDivideNumNonZero:Specializer=[TruncatingDivide._tdivFast],PrimitiveCheck=[]*/
@pragma('dart2js:noInline')
truncatingDivideNumNonZero(a) {
  return a ~/ 2;
}

/*element: truncatingDivideIntNum:Specializer=[!TruncatingDivide]*/
@pragma('dart2js:noInline')
truncatingDivideIntNum(a, b) {
  return a ~/ b;
}

/*element: truncatingDivideNumNum:Specializer=[!TruncatingDivide]*/
@pragma('dart2js:noInline')
truncatingDivideNumNum(a, b) {
  return a ~/ b;
}

/*element: truncatingDivideNullInt:Specializer=[!TruncatingDivide],PrimitiveCheck=[kind=receiver&type=num]*/
@pragma('dart2js:noInline')
truncatingDivideNullInt(a, b) {
  return a ~/ b;
}

/*element: truncatingDivideIntNull:Specializer=[!TruncatingDivide],PrimitiveCheck=[kind=argument&type=num]*/
@pragma('dart2js:noInline')
truncatingDivideIntNull(a, b) {
  return a ~/ b;
}

/*element: truncatingDivideStringInt:Specializer=[!TruncatingDivide],PrimitiveCheck=[kind=receiver&type=num]*/
@pragma('dart2js:noInline')
truncatingDivideStringInt(a, b) {
  return a ~/ b;
}

/*element: truncatingDivideIntString:Specializer=[!TruncatingDivide],PrimitiveCheck=[kind=argument&type=num]*/
@pragma('dart2js:noInline')
truncatingDivideIntString(a, b) {
  return a ~/ b;
}

////////////////////////////////////////////////////////////////////////////////
// .abs()
////////////////////////////////////////////////////////////////////////////////

/*element: abs:Specializer=[Abs]*/
@pragma('dart2js:noInline')
abs(o) {
  return o.abs();
}

/*element: absNum:Specializer=[Abs]*/
@pragma('dart2js:noInline')
absNum(o) {
  return o.abs();
}

/*element: absNull:Specializer=[Abs]*/
@pragma('dart2js:noInline')
absNull(o) {
  return o.abs();
}

/*element: absString:Specializer=[!Abs]*/
@pragma('dart2js:noInline')
absString(o) {
  return o.abs();
}

////////////////////////////////////////////////////////////////////////////////
// .round()
////////////////////////////////////////////////////////////////////////////////

/*element: round:Specializer=[Round]*/
@pragma('dart2js:noInline')
round(o) {
  return o.round();
}

/*element: roundNum:Specializer=[Round]*/
@pragma('dart2js:noInline')
roundNum(o) {
  return o.round();
}

/*element: roundNull:Specializer=[Round]*/
@pragma('dart2js:noInline')
roundNull(o) {
  return o.round();
}

/*element: roundString:Specializer=[!Round]*/
@pragma('dart2js:noInline')
roundString(o) {
  return o.round();
}
