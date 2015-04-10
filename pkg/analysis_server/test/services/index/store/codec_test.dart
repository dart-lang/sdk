// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.src.index.store.codec;

import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/store/codec.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:unittest/unittest.dart';

import '../../../abstract_single_unit.dart';
import '../../../mocks.dart';
import '../../../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(_ContextCodecTest);
  runReflectiveTests(_ElementCodecTest);
  runReflectiveTests(_RelationshipCodecTest);
  runReflectiveTests(_StringCodecTest);
}

@reflectiveTest
class _ContextCodecTest {
  ContextCodec codec = new ContextCodec();

  void test_encode_decode() {
    AnalysisContext contextA = new MockAnalysisContext('contextA');
    AnalysisContext contextB = new MockAnalysisContext('contextB');
    int idA = codec.encode(contextA);
    int idB = codec.encode(contextB);
    expect(idA, codec.encode(contextA));
    expect(idB, codec.encode(contextB));
    expect(codec.decode(idA), contextA);
    expect(codec.decode(idB), contextB);
  }

  void test_remove() {
    // encode
    {
      AnalysisContext context = new MockAnalysisContext('context');
      // encode
      int id = codec.encode(context);
      expect(id, 0);
      expect(codec.decode(id), context);
      // remove
      codec.remove(context);
      expect(codec.decode(id), isNull);
    }
    // encode again
    {
      AnalysisContext context = new MockAnalysisContext('context');
      // encode
      int id = codec.encode(context);
      expect(id, 1);
      expect(codec.decode(id), context);
    }
  }
}

@reflectiveTest
class _ElementCodecTest extends AbstractSingleUnitTest {
  ElementCodec codec;
  AnalysisContext context = new MockAnalysisContext('context');
  StringCodec stringCodec = new StringCodec();

  void setUp() {
    super.setUp();
    codec = new ElementCodec(stringCodec);
  }

  void test_encode_CompilationUnitElement() {
    addSource('/my_part.dart', '''
part of my_lib;
''');
    resolveTestUnit('''
library my_lib;
part 'my_part.dart';
''');
    // defining unit
    {
      Element element = testLibraryElement.definingCompilationUnit;
      expect(element.source.fullName, '/test.dart');
      int id1 = codec.encode1(element);
      int id2 = codec.encode2(element);
      int id3 = codec.encode3(element);
      expect(id1, isNonNegative);
      expect(id2, element.nameOffset);
      expect(id3, ElementKind.COMPILATION_UNIT.ordinal);
      // decode
      Element element2 = codec.decode(context, id1, id2, id3);
      expect(element2, element);
    }
    // part
    {
      Element element = testLibraryElement.parts[0];
      expect(element.source.fullName, '/my_part.dart');
      int id1 = codec.encode1(element);
      int id2 = codec.encode2(element);
      int id3 = codec.encode3(element);
      expect(id1, isNonNegative);
      expect(id2, element.nameOffset);
      expect(id3, ElementKind.COMPILATION_UNIT.ordinal);
      // decode
      Element element2 = codec.decode(context, id1, id2, id3);
      expect(element2, element);
    }
  }

  void test_encode_ConstructorElement_default_real() {
    resolveTestUnit('''
class A {
  A();
}
''');
    ClassElement classA = findElement('A');
    ConstructorElement element = classA.constructors[0];
    int id1 = codec.encode1(element);
    int id2 = codec.encode2(element);
    int id3 = codec.encode3(element);
    expect(id1, isNonNegative);
    expect(id2, classA.nameOffset);
    expect(id3, -100);
    // decode
    Element element2 = codec.decode(context, id1, id2, id3);
    expect(element2, element);
  }

  void test_encode_ConstructorElement_default_synthetic() {
    resolveTestUnit('''
class A {
}
''');
    ClassElement classA = findElement('A');
    ConstructorElement element = classA.constructors[0];
    int id1 = codec.encode1(element);
    int id2 = codec.encode2(element);
    int id3 = codec.encode3(element);
    expect(id1, isNonNegative);
    expect(id2, classA.nameOffset);
    expect(id3, -100);
    // decode
    Element element2 = codec.decode(context, id1, id2, id3);
    expect(element2, element);
  }

  void test_encode_ConstructorElement_named_real() {
    resolveTestUnit('''
class A {
  A.aaa();
  A.bbb();
}
''');
    ClassElement classA = findElement('A');
    // A.aaa()
    {
      ConstructorElement element = classA.getNamedConstructor('aaa');
      int id1 = codec.encode1(element);
      int id2 = codec.encode2(element);
      int id3 = codec.encode3(element);
      expect(id1, isNonNegative);
      expect(id2, classA.nameOffset);
      expect(id3, -100);
      // decode
      Element element2 = codec.decode(context, id1, id2, id3);
      expect(element2, element);
    }
    // A.bbb()
    {
      ConstructorElement element = classA.getNamedConstructor('bbb');
      int id1 = codec.encode1(element);
      int id2 = codec.encode2(element);
      int id3 = codec.encode3(element);
      expect(id1, isNonNegative);
      expect(id2, classA.nameOffset);
      expect(id3, -101);
      // decode
      Element element2 = codec.decode(context, id1, id2, id3);
      expect(element2, element);
    }
  }

  void test_encode_ConstructorElement_named_synthetic() {
    resolveTestUnit('''
class A {
  A.aaa();
  A.bbb();
}
class M {}
class X = A with M;
''');
    ClassElement classX = findElement('X');
    // X.aaa()
    {
      ConstructorElement element = classX.getNamedConstructor('aaa');
      int id1 = codec.encode1(element);
      int id2 = codec.encode2(element);
      int id3 = codec.encode3(element);
      expect(id1, isNonNegative);
      expect(id2, classX.nameOffset);
      expect(id3, -100);
      // decode
      Element element2 = codec.decode(context, id1, id2, id3);
      expect(element2, element);
    }
    // X.bbb()
    {
      ConstructorElement element = classX.getNamedConstructor('bbb');
      int id1 = codec.encode1(element);
      int id2 = codec.encode2(element);
      int id3 = codec.encode3(element);
      expect(id1, isNonNegative);
      expect(id2, classX.nameOffset);
      expect(id3, -101);
      // decode
      Element element2 = codec.decode(context, id1, id2, id3);
      expect(element2, element);
    }
  }

  void test_encode_getter_real() {
    resolveTestUnit('''
class A {
  int get test => 42;
}
''');
    PropertyAccessorElement element = findElement('test', ElementKind.GETTER);
    int id1 = codec.encode1(element);
    int id2 = codec.encode2(element);
    int id3 = codec.encode3(element);
    expect(id1, isNonNegative);
    expect(id2, element.nameOffset);
    expect(id3, ElementKind.GETTER.ordinal);
    // decode
    Element element2 = codec.decode(context, id1, id2, id3);
    expect(element2, element);
  }

  void test_encode_getter_synthetic() {
    resolveTestUnit('''
class A {
  int test;
}
''');
    FieldElement field = findElement('test', ElementKind.FIELD);
    PropertyAccessorElement element = field.getter;
    int id1 = codec.encode1(element);
    int id2 = codec.encode2(element);
    int id3 = codec.encode3(element);
    expect(id1, isNonNegative);
    expect(id2, element.nameOffset);
    expect(id3, ElementKind.GETTER.ordinal);
    // decode
    Element element2 = codec.decode(context, id1, id2, id3);
    expect(element2, element);
  }

  void test_encode_LibraryElement() {
    resolveTestUnit('''
class A {
  test() {}
}
''');
    Element element = testLibraryElement;
    int id1 = codec.encode1(element);
    int id2 = codec.encode2(element);
    int id3 = codec.encode3(element);
    expect(id1, isNonNegative);
    expect(id2, element.nameOffset);
    expect(id3, ElementKind.LIBRARY.ordinal);
    // decode
    Element element2 = codec.decode(context, id1, id2, id3);
    expect(element2, element);
  }

  void test_encode_MethodElement() {
    resolveTestUnit('''
class A {
  test() {}
}
''');
    Element element = findElement('test');
    int id1 = codec.encode1(element);
    int id2 = codec.encode2(element);
    int id3 = codec.encode3(element);
    expect(id1, isNonNegative);
    expect(id2, element.nameOffset);
    expect(id3, ElementKind.METHOD.ordinal);
    // decode
    Element element2 = codec.decode(context, id1, id2, id3);
    expect(element2, element);
  }

  void test_encode_NameElement() {
    Element element = new NameElement('test');
    int id1 = codec.encode1(element);
    int id2 = codec.encode2(element);
    int id3 = codec.encode3(element);
    expect(id1, -1);
    expect(id2, isNonNegative);
    expect(id3, ElementKind.NAME.ordinal);
  }

  void test_encode_nullLibraryElement() {
    resolveTestUnit('''
test() {}
''');
    Element element = findElement('test');
    int id1 = codec.encode1(element);
    int id2 = codec.encode2(element);
    int id3 = codec.encode3(element);
    context.setContents(testSource, '');
    // decode
    Element element2 = codec.decode(context, id1, id2, id3);
    expect(element2, isNull);
  }

  void test_encode_setter_real() {
    resolveTestUnit('''
class A {
  void set test(x) {}
}
''');
    PropertyAccessorElement element = findElement('test=', ElementKind.SETTER);
    int id1 = codec.encode1(element);
    int id2 = codec.encode2(element);
    int id3 = codec.encode3(element);
    expect(id1, isNonNegative);
    expect(id2, element.nameOffset);
    expect(id3, ElementKind.SETTER.ordinal);
    // decode
    Element element2 = codec.decode(context, id1, id2, id3);
    expect(element2, element);
  }

  void test_encode_setter_synthetic() {
    resolveTestUnit('''
class A {
  int test;
}
''');
    FieldElement field = findElement('test', ElementKind.FIELD);
    PropertyAccessorElement element = field.setter;
    int id1 = codec.encode1(element);
    int id2 = codec.encode2(element);
    int id3 = codec.encode3(element);
    expect(id1, isNonNegative);
    expect(id2, element.nameOffset);
    expect(id3, ElementKind.SETTER.ordinal);
    // decode
    Element element2 = codec.decode(context, id1, id2, id3);
    expect(element2, element);
  }

  void test_encodeHash_notLocal() {
    resolveTestUnit('''
class A {
  void mainA() {
    int foo; // A
  }
  void mainB() {
    int foo; // B
    int bar;
  }
}
''');
    MethodElement mainA = findElement('mainA');
    MethodElement mainB = findElement('mainB');
    Element fooA = mainA.localVariables[0];
    Element fooB = mainB.localVariables[0];
    Element bar = mainB.localVariables[1];
    int id_fooA = codec.encodeHash(fooA);
    int id_fooB = codec.encodeHash(fooB);
    int id_bar = codec.encodeHash(bar);
    expect(id_fooA == id_fooB, isTrue);
    expect(id_fooA == id_bar, isFalse);
  }
}

@reflectiveTest
class _RelationshipCodecTest {
  StringCodec stringCodec = new StringCodec();
  RelationshipCodec codec;

  void setUp() {
    codec = new RelationshipCodec(stringCodec);
  }

  void test_all() {
    Relationship relationship = Relationship.getRelationship('my-relationship');
    int id = codec.encode(relationship);
    expect(codec.decode(id), relationship);
  }
}

@reflectiveTest
class _StringCodecTest {
  StringCodec codec = new StringCodec();

  void test_all() {
    int idA = codec.encode('aaa');
    int idB = codec.encode('bbb');
    expect(codec.decode(idA), 'aaa');
    expect(codec.decode(idB), 'bbb');
  }
}
