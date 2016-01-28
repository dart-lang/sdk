// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.src.index.store.codec;

import 'package:analysis_server/src/provisional/index/index_core.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/indexable_element.dart';
import 'package:analysis_server/src/services/index/store/codec.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../../abstract_single_unit.dart';
import '../../../mocks.dart';
import '../../../utils.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(_ContextCodecTest);
  defineReflectiveTests(_ElementCodecTest);
  defineReflectiveTests(_RelationshipCodecTest);
  defineReflectiveTests(_StringCodecTest);
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
    addSource(
        '/my_part.dart',
        '''
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
      IndexableObject indexable = new IndexableElement(element);
      int id1 = codec.encode1(indexable);
      int id2 = codec.encode2(indexable);
      int id3 = codec.encode3(indexable);
      expect(id1, isNonNegative);
      expect(id2, -1);
      expect(id3, IndexableElementKind.forElement(element).index);
      validateDecode(id1, id2, id3, element);
    }
    // part
    {
      Element element = testLibraryElement.parts[0];
      expect(element.source.fullName, '/my_part.dart');
      IndexableObject indexable = new IndexableElement(element);
      int id1 = codec.encode1(indexable);
      int id2 = codec.encode2(indexable);
      int id3 = codec.encode3(indexable);
      expect(id1, isNonNegative);
      expect(id2, -1);
      expect(id3, IndexableElementKind.forElement(element).index);
      validateDecode(id1, id2, id3, element);
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
    IndexableObject indexable = new IndexableElement(element);
    int id1 = codec.encode1(indexable);
    int id2 = codec.encode2(indexable);
    int id3 = codec.encode3(indexable);
    expect(id1, isNonNegative);
    expect(id2, classA.nameOffset);
    expect(id3, IndexableElementKind.forElement(element).index);
    validateDecode(id1, id2, id3, element);
  }

  void test_encode_ConstructorElement_default_synthetic() {
    resolveTestUnit('''
class A {
}
''');
    ClassElement classA = findElement('A');
    ConstructorElement element = classA.constructors[0];
    IndexableObject indexable = new IndexableElement(element);
    int id1 = codec.encode1(indexable);
    int id2 = codec.encode2(indexable);
    int id3 = codec.encode3(indexable);
    expect(id1, isNonNegative);
    expect(id2, classA.nameOffset);
    expect(id3, IndexableElementKind.forElement(element).index);
    validateDecode(id1, id2, id3, element);
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
      IndexableObject indexable = new IndexableElement(element);
      int id1 = codec.encode1(indexable);
      int id2 = codec.encode2(indexable);
      int id3 = codec.encode3(indexable);
      expect(id1, isNonNegative);
      expect(id2, classA.nameOffset);
      expect(id3, IndexableElementKind.forElement(element).index);
      validateDecode(id1, id2, id3, element);
    }
    // A.bbb()
    {
      ConstructorElement element = classA.getNamedConstructor('bbb');
      IndexableObject indexable = new IndexableElement(element);
      int id1 = codec.encode1(indexable);
      int id2 = codec.encode2(indexable);
      int id3 = codec.encode3(indexable);
      expect(id1, isNonNegative);
      expect(id2, classA.nameOffset);
      expect(id3, IndexableElementKind.forElement(element).index);
      validateDecode(id1, id2, id3, element);
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
      IndexableObject indexable = new IndexableElement(element);
      int id1 = codec.encode1(indexable);
      int id2 = codec.encode2(indexable);
      int id3 = codec.encode3(indexable);
      expect(id1, isNonNegative);
      expect(id2, classX.nameOffset);
      expect(id3, IndexableElementKind.forElement(element).index);
      validateDecode(id1, id2, id3, element);
    }
    // X.bbb()
    {
      ConstructorElement element = classX.getNamedConstructor('bbb');
      IndexableObject indexable = new IndexableElement(element);
      int id1 = codec.encode1(indexable);
      int id2 = codec.encode2(indexable);
      int id3 = codec.encode3(indexable);
      expect(id1, isNonNegative);
      expect(id2, classX.nameOffset);
      expect(id3, IndexableElementKind.forElement(element).index);
      validateDecode(id1, id2, id3, element);
    }
  }

  void test_encode_getter_real() {
    resolveTestUnit('''
class A {
  int get test => 42;
}
''');
    PropertyAccessorElement element = findElement('test', ElementKind.GETTER);
    IndexableObject indexable = new IndexableElement(element);
    int id1 = codec.encode1(indexable);
    int id2 = codec.encode2(indexable);
    int id3 = codec.encode3(indexable);
    expect(id1, isNonNegative);
    expect(id2, element.nameOffset);
    expect(id3, IndexableElementKind.forElement(element).index);
    validateDecode(id1, id2, id3, element);
  }

  void test_encode_getter_synthetic() {
    resolveTestUnit('''
class A {
  int test;
}
''');
    FieldElement field = findElement('test', ElementKind.FIELD);
    PropertyAccessorElement element = field.getter;
    IndexableObject indexable = new IndexableElement(element);
    int id1 = codec.encode1(indexable);
    int id2 = codec.encode2(indexable);
    int id3 = codec.encode3(indexable);
    expect(id1, isNonNegative);
    expect(id2, element.nameOffset);
    expect(id3, IndexableElementKind.forElement(element).index);
    validateDecode(id1, id2, id3, element);
  }

  void test_encode_IndexableName() {
    IndexableName indexable = new IndexableName('test');
    int id1 = codec.encode1(indexable);
    int id2 = codec.encode2(indexable);
    int id3 = codec.encode3(indexable);
    expect(id1, -1);
    expect(id2, isNonNegative);
    expect(id3, IndexableNameKind.INSTANCE.index);
    expect(codec.decode(context, id1, id2, id3), indexable);
  }

  void test_encode_LibraryElement() {
    resolveTestUnit('''
class A {
  test() {}
}
''');
    Element element = testLibraryElement;
    IndexableObject indexable = new IndexableElement(element);
    int id1 = codec.encode1(indexable);
    int id2 = codec.encode2(indexable);
    int id3 = codec.encode3(indexable);
    expect(id1, isNonNegative);
    expect(id2, -1);
    expect(id3, IndexableElementKind.forElement(element).index);
    validateDecode(id1, id2, id3, element);
  }

  void test_encode_MethodElement() {
    resolveTestUnit('''
class A {
  test() {}
}
''');
    Element element = findElement('test');
    IndexableObject indexable = new IndexableElement(element);
    int id1 = codec.encode1(indexable);
    int id2 = codec.encode2(indexable);
    int id3 = codec.encode3(indexable);
    expect(id1, isNonNegative);
    expect(id2, element.nameOffset);
    expect(id3, IndexableElementKind.forElement(element).index);
    validateDecode(id1, id2, id3, element);
  }

  void test_encode_nullLibraryElement() {
    resolveTestUnit('''
test() {}
''');
    Element element = findElement('test');
    IndexableObject indexable = new IndexableElement(element);
    int id1 = codec.encode1(indexable);
    int id2 = codec.encode2(indexable);
    int id3 = codec.encode3(indexable);
    context.setContents(testSource, '');
    IndexableObject object2 = codec.decode(context, id1, id2, id3);
    expect(object2, isNull);
  }

  void test_encode_setter_real() {
    resolveTestUnit('''
class A {
  void set test(x) {}
}
''');
    PropertyAccessorElement element = findElement('test=', ElementKind.SETTER);
    IndexableObject indexable = new IndexableElement(element);
    int id1 = codec.encode1(indexable);
    int id2 = codec.encode2(indexable);
    int id3 = codec.encode3(indexable);
    expect(id1, isNonNegative);
    expect(id2, element.nameOffset);
    expect(id3, IndexableElementKind.forElement(element).index);
    validateDecode(id1, id2, id3, element);
  }

  void test_encode_setter_synthetic() {
    resolveTestUnit('''
class A {
  int test;
}
''');
    FieldElement field = findElement('test', ElementKind.FIELD);
    PropertyAccessorElement element = field.setter;
    IndexableObject indexable = new IndexableElement(element);
    int id1 = codec.encode1(indexable);
    int id2 = codec.encode2(indexable);
    int id3 = codec.encode3(indexable);
    expect(id1, isNonNegative);
    expect(id2, element.nameOffset);
    expect(id3, IndexableElementKind.forElement(element).index);
    validateDecode(id1, id2, id3, element);
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
    int id_fooA = codec.encodeHash(new IndexableElement(fooA));
    int id_fooB = codec.encodeHash(new IndexableElement(fooB));
    int id_bar = codec.encodeHash(new IndexableElement(bar));
    expect(id_fooA == id_fooB, isTrue);
    expect(id_fooA == id_bar, isFalse);
  }

  void validateDecode(int id1, int id2, int id3, Element element) {
    IndexableObject object2 = codec.decode(context, id1, id2, id3);
    expect(object2, new isInstanceOf<IndexableElement>());
    Element element2 = (object2 as IndexableElement).element;
    expect(element2, element);
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
    RelationshipImpl relationship =
        RelationshipImpl.getRelationship('my-relationship');
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
