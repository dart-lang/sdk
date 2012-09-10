// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:uri");

#import("../../../lib/compiler/implementation/elements/elements.dart");
#import("../../../lib/compiler/implementation/js_backend/js_backend.dart");
#import("../../../lib/compiler/implementation/ssa/ssa.dart");
#import("../../../lib/compiler/implementation/scanner/scannerlib.dart");
#import("../../../lib/compiler/implementation/leg.dart");
#import("../../../lib/compiler/implementation/universe/universe.dart");

#import('compiler_helper.dart');
#import('parser_helper.dart');

// Source names used throughout the tests.
const SourceString x = const SourceString("x");
const SourceString p1 = const SourceString("p1");
const SourceString p2 = const SourceString("p2");
const SourceString p3 = const SourceString("p3");

// Lists of types.
List<HType> B;
List<HType> I;
List<HType> II;
List<HType> IBS;
List<HType> IIS;
List<HType> BII;
List<HType> IBI;
List<HType> IIB;
List<HType> III;

FunctionSignature compileAndFindSignature(String code,
                                          String className,
                                          String memberName) {
  Uri uri = new Uri.fromComponents(scheme: 'source');
  var compiler = compilerFor(code, uri);
  compiler.runCompiler(uri);
  var cls = findElement(compiler, className);
  var member = cls.lookupLocalMember(buildSourceString(memberName));
  var signature = member.computeSignature(compiler);
  return signature;
}

HTypeList createHTypeList(List<HType> types) {
  HTypeList result = new HTypeList(types.length);
  result.types.setRange(0, result.length, types);
  return result;
}

HTypeList createHTypeListWithNamed(List<HType> types,
                                   List<SourceString> namedArguments) {
  HTypeList result = new HTypeList.withNamedArguments(types.length,
                                                      namedArguments);
  result.types.setRange(0, result.length, types);
  return result;
}

void checkHTypeList(HTypeList types, List<HType> expected) {
  Expect.equals(expected.length, types.length);
  for (int i = 0; i < expected.length; i++) {
    Expect.equals(expected[i], types.types[i]);
  }
}

const String TEST_1 = @"""
  class A {
    x(p) => null;
  }
  main() {
    new A().x(1);
  }
""";

test1() {
  FunctionSignature signature = compileAndFindSignature(TEST_1, "A", "x");
  HTypeList types = createHTypeList(I);
  Selector s = new Selector.call(x, null, 1);
  types = types.unionWithOptionalParameters(s, signature, null);
  checkHTypeList(types, I);
}

const String TEST_2 = @"""
  class A {
    x(p1, [p2, p3]) => null;
  }
  main() {
    new A().x(1);
  }
""";

test2_1() {
  FunctionSignature signature = compileAndFindSignature(TEST_2, "A", "x");
  HTypeList types = createHTypeList(<HType>[HType.INTEGER]);
  Selector s = new Selector.call(x, null, 1);

  OptionalParameterTypes defaultTypes;
  defaultTypes = new OptionalParameterTypes(2);
  defaultTypes.update(0, p2, HType.BOOLEAN);
  defaultTypes.update(1, p3, HType.STRING);

  HTypeList t2 = types.unionWithOptionalParameters(s, signature, defaultTypes);
  checkHTypeList(t2, IBS);
}

test2_2() {
  FunctionSignature signature = compileAndFindSignature(TEST_2, "A", "x");
  HTypeList types = createHTypeList(II);
  Selector s = new Selector.call(x, null, 2);

  OptionalParameterTypes defaultTypes;
  defaultTypes = new OptionalParameterTypes(2);
  defaultTypes.update(0, p2, HType.BOOLEAN);
  defaultTypes.update(1, p3, HType.STRING);

  HTypeList t2 = types.unionWithOptionalParameters(s, signature, defaultTypes);
  checkHTypeList(t2, IIS);
}


test2_3() {
  FunctionSignature signature = compileAndFindSignature(TEST_2, "A", "x");
  HTypeList types = createHTypeList(III);
  Selector s = new Selector.call(x, null, 3);

  OptionalParameterTypes defaultTypes;
  defaultTypes = new OptionalParameterTypes(2);
  defaultTypes.update(0, p2, HType.BOOLEAN);
  defaultTypes.update(1, p3, HType.STRING);

  HTypeList t2 = types.unionWithOptionalParameters(s, signature, defaultTypes);
  checkHTypeList(t2, III);
}


const String TEST_3 = @"""
  class A {
    x(p1, [p2, p3]) => null;
  }
  main() {
    new A().x(1);
  }
""";

test3_1() {
  FunctionSignature signature = compileAndFindSignature(TEST_3, "A", "x");

  OptionalParameterTypes defaultTypes;
  defaultTypes = new OptionalParameterTypes(2);
  defaultTypes.update(0, p2, HType.BOOLEAN);
  defaultTypes.update(1, p3, HType.STRING);

  HTypeList types;
  Selector s;
  HTypeList result;

  s = new Selector.call(x, null, 2, <SourceString>[p2]);
  types = createHTypeListWithNamed(II, <SourceString>[p2]);
  result = types.unionWithOptionalParameters(s, signature, defaultTypes);
  checkHTypeList(result, IIS);

  s = new Selector.call(x, null, 2, <SourceString>[p3]);
  types = createHTypeListWithNamed(II, <SourceString>[p3]);
  result = types.unionWithOptionalParameters(s, signature, defaultTypes);
  checkHTypeList(result, IBI);
}

test3_2() {
  FunctionSignature signature = compileAndFindSignature(TEST_2, "A", "x");

  OptionalParameterTypes defaultTypes;
  defaultTypes = new OptionalParameterTypes(2);
  defaultTypes.update(0, p2, HType.BOOLEAN);
  defaultTypes.update(1, p3, HType.STRING);

  HTypeList types
  Selector s;
  HTypeList result;

  s = new Selector.call(x, null, 2, <SourceString>[p2, p3]);
  types = createHTypeListWithNamed(III, <SourceString>[p2, p3]);
  result = types.unionWithOptionalParameters(s1, signature, defaultTypes);
  checkHTypeList(result, III);

  s = new Selector.call(x, null, 2, <SourceString>[p3, p3]);
  types = createHTypeListWithNamed(III, <SourceString>[p2, p3]);
  result = types.unionWithOptionalParameters(s2, signature, defaultTypes);
  checkHTypeList(result, III);
}


const String TEST_4 = @"""
  class A {
    x([p1, p2, p3]) => null;
  }
  main() {
    new A().x();
  }
""";

test4() {
  FunctionSignature signature = compileAndFindSignature(TEST_4, "A", "x");

  OptionalParameterTypes defaultTypes;
  defaultTypes = new OptionalParameterTypes(3);
  defaultTypes.update(0, p1, HType.INTEGER);
  defaultTypes.update(1, p2, HType.INTEGER);
  defaultTypes.update(2, p3, HType.INTEGER);

  HTypeList types;
  Selector s;
  HTypeList result;

  s = new Selector.call(x, null, 1, <SourceString>[p1]);
  types = createHTypeListWithNamed(B, <SourceString>[p1]);
  result = types.unionWithOptionalParameters(s, signature, defaultTypes);
  checkHTypeList(result, BII);

  s = new Selector.call(x, null, 1, <SourceString>[p2]);
  types = createHTypeListWithNamed(B, <SourceString>[p2]);
  result = types.unionWithOptionalParameters(s, signature, defaultTypes);
  checkHTypeList(result, IBI);

  s = new Selector.call(x, null, 1, <SourceString>[p3]);
  types = createHTypeListWithNamed(B, <SourceString>[p3]);
  result = types.unionWithOptionalParameters(s, signature, defaultTypes);
  checkHTypeList(result, IIB);
}

main() {
  B = <HType>[HType.BOOLEAN];
  I = <HType>[HType.INTEGER];
  II = <HType>[HType.INTEGER, HType.INTEGER];
  IBS = <HType>[HType.INTEGER, HType.BOOLEAN, HType.STRING];
  IIS = <HType>[HType.INTEGER, HType.INTEGER, HType.STRING];
  BII = <HType>[HType.BOOLEAN, HType.INTEGER, HType.INTEGER];
  IBI = <HType>[HType.INTEGER, HType.BOOLEAN, HType.INTEGER];
  IIB = <HType>[HType.INTEGER, HType.INTEGER, HType.BOOLEAN];
  III = <HType>[HType.INTEGER, HType.INTEGER, HType.INTEGER];

  test1();
  test2_1();
  test2_2();
  test2_3();
  test3_1();
  test4();
}
