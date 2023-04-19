// @dart = 2.19

class B {
  /*member: B.x:
   static=[
    Rti._bind(1),
    Rti._eval(1),
    _arrayInstanceType(1),
    _asBool(1),
    _asBoolQ(1),
    _asBoolS(1),
    _asDouble(1),
    _asDoubleQ(1),
    _asDoubleS(1),
    _asInt(1),
    _asIntQ(1),
    _asIntS(1),
    _asNum(1),
    _asNumQ(1),
    _asNumS(1),
    _asObject(1),
    _asString(1),
    _asStringQ(1),
    _asStringS(1),
    _asTop(1),
    _generalAsCheckImplementation(1),
    _generalIsTestImplementation(1),
    _generalNullableAsCheckImplementation(1),
    _generalNullableIsTestImplementation(1),
    _installSpecializedAsCheck(1),
    _installSpecializedIsTest(1),
    _instanceType(1),
    _isBool(1),
    _isInt(1),
    _isNum(1),
    _isObject(1),
    _isString(1),
    _isTop(1),
    findType(1),
    instanceType(1)],
   type=[
    inst:Closure,
    inst:JSBool,
    inst:JSNull,
    param:int]
  */
  final int x;
  const B(this.x);
}

/*member: case3:
 static=[B.x=IntConstant(1)],
 type=[
  const:B,
  inst:JSInt,
  inst:JSNull,
  inst:JSNumNotInt,
  inst:JSNumber,
  inst:JSPositiveInt,
  inst:JSUInt31,
  inst:JSUInt32]
*/
int case3() {
  switch (null as dynamic) {
    case B(const bool.fromEnvironment('x') ? 0 : 1):
      return 1;
    default:
      return 2;
  }
}

/*member: main:static=[
  case3(0),
  print(1)]*/
void main() {
  print(case3());
}
