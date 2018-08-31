import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';
import 'task_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinDriverResolutionTest);
    defineReflectiveTests(MixinTaskResolutionTest);
  });
}

abstract class AssignmentResolutionMixin implements ResolutionTest {
  test_accessor_getter() async {
    addTestFile(r'''
mixin M {
  int get g => 0;
}
''');
    await resolveTestFile();

    var element = findElement.mixin('M');

    var accessors = element.accessors;
    expect(accessors, hasLength(1));

    var gElement = accessors[0];
    assertElementName(gElement, 'g', offset: 20);

    var gNode = findNode.methodDeclaration('g =>');
    assertElement(gNode.name, gElement);

    var fields = element.fields;
    expect(fields, hasLength(1));
    assertElementName(fields[0], 'g', isSynthetic: true);
  }

  test_accessor_method() async {
    addTestFile(r'''
mixin M {
  void foo() {}
}
''');
    await resolveTestFile();

    var element = findElement.mixin('M');

    var methods = element.methods;
    expect(methods, hasLength(1));

    var fooElement = methods[0];
    assertElementName(fooElement, 'foo', offset: 17);

    var fooNode = findNode.methodDeclaration('foo()');
    assertElement(fooNode.name, fooElement);
  }

  test_accessor_setter() async {
    addTestFile(r'''
mixin M {
  void set s(int _) {}
}
''');
    await resolveTestFile();

    var element = findElement.mixin('M');

    var accessors = element.accessors;
    expect(accessors, hasLength(1));

    var sElement = accessors[0];
    assertElementName(sElement, 's=', offset: 21);

    var gNode = findNode.methodDeclaration('s(int _)');
    assertElement(gNode.name, sElement);

    var fields = element.fields;
    expect(fields, hasLength(1));
    assertElementName(fields[0], 's', isSynthetic: true);
  }

  test_commentReference() async {
    addTestFile(r'''
const a = 0;

/// Reference [a] in documentation.
mixin M {}
''');
    await resolveTestFile();

    var aRef = findNode.commentReference('a]').identifier;
    assertElement(aRef, findElement.topGet('a'));
    assertTypeNull(aRef);
  }

  test_element() async {
    addTestFile(r'''
mixin M {}
''');
    await resolveTestFile();

    var mixin = findNode.mixin('mixin M');
    var element = findElement.mixin('M');
    assertElement(mixin, element);

    expect(element.typeParameters, isEmpty);
    assertElementTypes(element.superclassConstraints, [objectType]);
  }

  test_field() async {
    addTestFile(r'''
mixin M<T> {
  T f;
}
''');
    await resolveTestFile();

    var element = findElement.mixin('M');

    var typeParameters = element.typeParameters;
    expect(typeParameters, hasLength(1));

    var tElement = typeParameters.single;
    assertElementName(tElement, 'T', offset: 8);
    assertEnclosingElement(tElement, element);

    var tNode = findNode.typeParameter('T> {');
    assertElement(tNode.name, tElement);

    var fields = element.fields;
    expect(fields, hasLength(1));

    var fElement = fields[0];
    assertElementName(fElement, 'f', offset: 17);
    assertEnclosingElement(fElement, element);

    var fNode = findNode.variableDeclaration('f;');
    assertElement(fNode.name, fElement);

    assertTypeName(findNode.typeName('T f'), tElement, 'T');

    var accessors = element.accessors;
    expect(accessors, hasLength(2));
    assertElementName(accessors[0], 'f', isSynthetic: true);
    assertElementName(accessors[1], 'f=', isSynthetic: true);
  }

  test_implementsClause() async {
    addTestFile(r'''
class A {}
class B {}

mixin M implements A, B {} // M
''');
    await resolveTestFile();

    var element = findElement.mixin('M');
    assertElementTypes(element.interfaces, [
      findElement.interfaceType('A'),
      findElement.interfaceType('B'),
    ]);

    var aRef = findNode.typeName('A, ');
    assertTypeName(aRef, findElement.class_('A'), 'A');

    var bRef = findNode.typeName('B {} // M');
    assertTypeName(bRef, findElement.class_('B'), 'B');
  }

  test_metadata() async {
    addTestFile(r'''
const a = 0;

@a
mixin M {}
''');
    await resolveTestFile();

    var a = findElement.topGet('a');
    var element = findElement.mixin('M');

    var metadata = element.metadata;
    expect(metadata, hasLength(1));
    expect(metadata[0].element, same(a));

    var annotation = findNode.annotation('@a');
    assertElement(annotation, a);
    expect(annotation.elementAnnotation, same(metadata[0]));
  }

  test_onClause() async {
    addTestFile(r'''
class A {}
class B {}

mixin M on A, B {} // M
''');
    await resolveTestFile();

    var element = findElement.mixin('M');
    assertElementTypes(element.superclassConstraints, [
      findElement.interfaceType('A'),
      findElement.interfaceType('B'),
    ]);

    var aRef = findNode.typeName('A, ');
    assertTypeName(aRef, findElement.class_('A'), 'A');

    var bRef = findNode.typeName('B {} // M');
    assertTypeName(bRef, findElement.class_('B'), 'B');
  }
}

@reflectiveTest
class MixinDriverResolutionTest extends DriverResolutionTest
    with AssignmentResolutionMixin {}

@reflectiveTest
class MixinTaskResolutionTest extends TaskResolutionTest
    with AssignmentResolutionMixin {}
