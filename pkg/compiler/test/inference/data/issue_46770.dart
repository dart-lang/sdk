// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class L {
  void m1();
}

/*member: L1.:[exact=L1]*/
class L1 implements L {
  @pragma('dart2js:noInline')
  /*member: L1.m1:[null]*/
  void m1() => print("L1");
}

/*member: L2.:[exact=L2]*/
class L2 implements L {
  @pragma('dart2js:noInline')
  /*member: L2.m1:[null]*/
  void m1() => print("L2");
}

/*member: L3.:[exact=L3]*/
class L3 implements L {
  @pragma('dart2js:noInline')
  /*member: L3.m1:[null]*/
  void m1() => print("L3");
}

/*member: cTrue:[exact=JSBool]*/
bool cTrue = confuse(true);
/*member: value:[exact=JSUInt31]*/
int value = confuse(1);

@pragma('dart2js:noInline')
/*member: confuse:Union([exact=JSBool], [exact=JSUInt31])*/
confuse(/*Union([exact=JSBool], [exact=JSUInt31])*/ x) => x;

/*member: test1:Union(null, [exact=L2], [exact=L3])*/
test1() {
  L? sourceInfo = L1();
  switch (value) {
    case 1:
      if (cTrue) {
        sourceInfo = L2();
        break;
      }
      sourceInfo = L3();
      break;
    default:
      return null;
  }

  sourceInfo. /*invoke: Union([exact=L2], [exact=L3])*/ m1();
  return sourceInfo;
}

/*member: test2:Union([exact=L1], [exact=L2], [exact=L3])*/
test2() {
  L? sourceInfo = L1();
  switch (value) {
    case 1:
      if (cTrue) {
        sourceInfo = L2();
        break;
      }
      sourceInfo = L3();
      break;
    default:
    // Do nothing
  }

  sourceInfo. /*invoke: Union([exact=L1], [exact=L2], [exact=L3])*/ m1();
  return sourceInfo;
}

/*member: test3:Union(null, [exact=L2], [exact=L3])*/
test3() {
  L? sourceInfo = L1();
  switchTarget:
  switch (value) {
    case 1:
      while (cTrue) {
        sourceInfo = L2();
        break switchTarget;
      }
      sourceInfo = L3();
      break;
    default:
      return null;
  }

  sourceInfo. /*invoke: Union([exact=L2], [exact=L3])*/ m1();
  return sourceInfo;
}

/*member: test4:Union(null, [exact=L1], [exact=L3])*/
test4() {
  L sourceInfo = L1();
  switch (value) {
    case 1:
      if (cTrue) {
        sourceInfo = L2();
        continue otherCase;
      }
      sourceInfo = L3();
      break;
    otherCase:
    case 2:
      sourceInfo. /*invoke: Union([exact=L1], [exact=L2])*/ m1();
      sourceInfo = L1();
      break;
    default:
      return null;
  }

  sourceInfo. /*invoke: Union([exact=L1], [exact=L3])*/ m1();
  return sourceInfo;
}

/*member: test5:Union(null, [exact=L1], [exact=L2], [exact=L3])*/
test5() {
  L sourceInfo = L1();
  switch (value) {
    case 1:
      if (cTrue) {
        sourceInfo = L2();
        continue otherCase;
      }
      sourceInfo = L3();
      break;
    otherCase:
    case 2:
      break;
    default:
      return null;
  }

  sourceInfo. /*invoke: Union([exact=L1], [exact=L2], [exact=L3])*/ m1();
  return sourceInfo;
}

/*member: test6:Union(null, [exact=L2], [exact=L3])*/
test6() {
  L sourceInfo = L1();
  switch (value) {
    case 1:
      if (cTrue) {
        sourceInfo = L2();
        continue otherCase;
      }
      sourceInfo = L3();
      break;
    otherCase:
    case 2:
      sourceInfo = L2();
      break;
    default:
      return null;
  }

  sourceInfo. /*invoke: Union([exact=L2], [exact=L3])*/ m1();
  return sourceInfo;
}

/*member: test7:[null|exact=L3]*/
test7() {
  L? sourceInfo = L1();
  switch (value) {
    case 1:
      if (cTrue) {
        sourceInfo = L2();
        return null;
      }
      sourceInfo = L3();
      break;
    default:
      return null;
  }

  sourceInfo. /*invoke: [exact=L3]*/ m1();
  return sourceInfo;
}

/*member: test8:[null|exact=L3]*/
test8() {
  L? sourceInfo = L1();
  switch (value) {
    case 1:
      while (cTrue) {
        sourceInfo = L2();
        break;
      }
      sourceInfo = L3();
      break;
    default:
      return null;
  }

  sourceInfo. /*invoke: [exact=L3]*/ m1();
  return sourceInfo;
}

/*member: test9:[null|exact=L3]*/
test9() {
  L? sourceInfo = L1();
  switch (value) {
    case 1:
      while (cTrue) {
        sourceInfo = L2();
        return null;
      }
      sourceInfo = L3();
      break;
    default:
      return null;
  }

  sourceInfo. /*invoke: [exact=L3]*/ m1();
  return sourceInfo;
}

/*member: test10:Union(null, [exact=L1], [exact=L2], [exact=L3])*/
test10() {
  L sourceInfo = L1();
  try {
    switch (value) {
      case 1:
        if (cTrue) {
          sourceInfo = L2();
          throw Exception();
        }
        sourceInfo = L3();
        break;
      default:
        return null;
    }
  } catch (e) {
    // Do nothing
  }

  sourceInfo. /*invoke: Union([exact=L1], [exact=L2], [exact=L3])*/ m1();
  return sourceInfo;
}

/*member: test11:[null|exact=L3]*/
test11() {
  L sourceInfo = L1();
  switch (value) {
    case 1:
      if (cTrue) {
        sourceInfo = L2();
        throw Exception();
      }
      sourceInfo = L3();
      break;
    default:
      return null;
  }
  sourceInfo. /*invoke: [exact=L3]*/ m1();
  return sourceInfo;
}

/*member: test12:Union(null, [exact=L1], [exact=L3])*/
test12() {
  L? sourceInfo = L1();
  switch (value) {
    case 1:
      if (cTrue) {
        sourceInfo = L2();
        return null;
      }
      sourceInfo = L3();
      break;
    default:
    // Do nothing
  }

  sourceInfo. /*invoke: Union([exact=L1], [exact=L3])*/ m1();
  return sourceInfo;
}

/*member: test13:Union(null, [exact=L2], [exact=L3])*/
test13() {
  L? sourceInfo = L1();
  switch (value) {
    case 1:
      if (cTrue) {
        sourceInfo = L2();
        return null;
      }
      sourceInfo = L3();
      break;
    default:
      sourceInfo = L2();
  }

  sourceInfo. /*invoke: Union([exact=L2], [exact=L3])*/ m1();
  return sourceInfo;
}

/*member: test14:Union(null, [exact=L1], [exact=L2], [exact=L3])*/
test14() {
  L sourceInfo = L1();
  whileLabel:
  while (true) {
    switch (value) {
      case 1:
        if (cTrue) {
          sourceInfo = L2();
          break whileLabel;
        }
        sourceInfo = L3();
        break;
      default:
        return null;
    }
    sourceInfo. /*invoke: [exact=L3]*/ m1();
    break;
  }
  sourceInfo. /*invoke: Union([exact=L1], [exact=L2], [exact=L3])*/ m1();
  return sourceInfo;
}

/*member: test15:[null|exact=L3]*/
test15() {
  L sourceInfo = L1();
  switch (value) {
    case 1:
      if (cTrue) {
        sourceInfo = L2();
        continue otherCase;
      }
      sourceInfo = L3();
      break;
    otherCase:
    case 2:
      return null;
    default:
      return null;
  }

  sourceInfo. /*invoke: [exact=L3]*/ m1();
  return sourceInfo;
}

/*member: main:[null]*/
main() {
  test1();
  test2();
  test3();
  test4();
  test5();
  test6();
  test7();
  test8();
  test9();
  test10();
  test11();
  test12();
  test13();
  test14();
  test15();
}
