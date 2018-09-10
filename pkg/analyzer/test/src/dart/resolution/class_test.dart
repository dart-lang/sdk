import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';
import 'resolution.dart';
import 'task_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDriverResolutionTest);
    defineReflectiveTests(ClassTaskResolutionTest);
  });
}

@reflectiveTest
class ClassDriverResolutionTest extends DriverResolutionTest
    with ClassResolutionMixin {}

abstract class ClassResolutionMixin implements ResolutionTest {
  test_error_conflictingConstructorAndStaticField_field() async {
    addTestFile(r'''
class C {
  C.foo();
  static int foo;
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD,
    ]);
  }

  test_error_conflictingConstructorAndStaticField_getter() async {
    addTestFile(r'''
class C {
  C.foo();
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD,
    ]);
  }

  test_error_conflictingConstructorAndStaticField_OK_notSameClass() async {
    addTestFile(r'''
class A {
  static int foo;
}
class B extends A {
  B.foo();
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_conflictingConstructorAndStaticField_OK_notStatic() async {
    addTestFile(r'''
class C {
  C.foo();
  int foo;
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_conflictingConstructorAndStaticField_setter() async {
    addTestFile(r'''
class C {
  C.foo();
  static void set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD,
    ]);
  }

  test_error_conflictingConstructorAndStaticMethod() async {
    addTestFile(r'''
class C {
  C.foo();
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD,
    ]);
  }

  test_error_conflictingConstructorAndStaticMethod_OK_notSameClass() async {
    addTestFile(r'''
class A {
  static void foo() {}
}
class B extends A {
  B.foo();
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_conflictingConstructorAndStaticMethod_OK_notStatic() async {
    addTestFile(r'''
class C {
  C.foo();
  void foo() {}
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_conflictingFieldAndMethod_inSuper_field() async {
    addTestFile(r'''
class A {
  foo() {}
}
class B extends A {
  int foo;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD]);
  }

  test_error_conflictingFieldAndMethod_inSuper_getter() async {
    addTestFile(r'''
class A {
  foo() {}
}
class B extends A {
  get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD]);
  }

  test_error_conflictingFieldAndMethod_inSuper_setter() async {
    addTestFile(r'''
class A {
  foo() {}
}
class B extends A {
  set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD]);
  }

  test_error_conflictingMethodAndField_inSuper_field() async {
    addTestFile(r'''
class A {
  int foo;
}
class B extends A {
  foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD]);
  }

  test_error_conflictingMethodAndField_inSuper_getter() async {
    addTestFile(r'''
class A {
  get foo => 0;
}
class B extends A {
  foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD]);
  }

  test_error_conflictingMethodAndField_inSuper_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
class B extends A {
  foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD]);
  }

  test_error_conflictingStaticAndInstance_inClass_getter_getter() async {
    addTestFile(r'''
class C {
  static int get foo => 0;
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_getter_method() async {
    addTestFile(r'''
class C {
  static int get foo => 0;
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_getter_setter() async {
    addTestFile(r'''
class C {
  static int get foo => 0;
  set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_method_getter() async {
    addTestFile(r'''
class C {
  static void foo() {}
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_method_method() async {
    addTestFile(r'''
class C {
  static void foo() {}
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_method_setter() async {
    addTestFile(r'''
class C {
  static void foo() {}
  set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_setter_getter() async {
    addTestFile(r'''
class C {
  static set foo(_) {}
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_setter_method() async {
    addTestFile(r'''
class C {
  static set foo(_) {}
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inClass_setter_setter() async {
    addTestFile(r'''
class C {
  static set foo(_) {}
  set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_getter_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
abstract class B implements A {
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_getter_method() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
abstract class B implements A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_getter_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_method_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
abstract class B implements A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_method_method() async {
    addTestFile(r'''
class A {
  void foo() {}
}
abstract class B implements A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_method_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_setter_method() async {
    addTestFile(r'''
class A {
  void foo() {}
}
abstract class B implements A {
  static set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inInterface_setter_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inMixin_getter_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
class B extends Object with A {
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inMixin_getter_method() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
class B extends Object with A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inMixin_getter_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
class B extends Object with A {
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inMixin_method_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
class B extends Object with A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inMixin_method_method() async {
    addTestFile(r'''
class A {
  void foo() {}
}
class B extends Object with A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inMixin_method_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
class B extends Object with A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inMixin_setter_method() async {
    addTestFile(r'''
class A {
  void foo() {}
}
class B extends Object with A {
  static set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inMixin_setter_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
class B extends Object with A {
  static set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inSuper_getter_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
class B extends A {
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inSuper_getter_method() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
class B extends A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inSuper_getter_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
class B extends A {
  static int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inSuper_method_getter() async {
    addTestFile(r'''
class A {
  int get foo => 0;
}
class B extends A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inSuper_method_method() async {
    addTestFile(r'''
class A {
  void foo() {}
}
class B extends A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inSuper_method_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
class B extends A {
  static void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inSuper_setter_method() async {
    addTestFile(r'''
class A {
  void foo() {}
}
class B extends A {
  static set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_conflictingStaticAndInstance_inSuper_setter_setter() async {
    addTestFile(r'''
class A {
  set foo(_) {}
}
class B extends A {
  static set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE]);
  }

  test_error_duplicateConstructorDefault() async {
    addTestFile(r'''
class C {
  C();
  C();
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT,
    ]);
  }

  test_error_duplicateConstructorName() async {
    addTestFile(r'''
class C {
  C.foo();
  C.foo();
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME,
    ]);
  }

  test_error_duplicateDefinition_field_field() async {
    addTestFile(r'''
class C {
  int foo;
  int foo;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_field_field_static() async {
    addTestFile(r'''
class C {
  static int foo;
  static int foo;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_field_getter() async {
    addTestFile(r'''
class C {
  int foo;
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_field_method() async {
    addTestFile(r'''
class C {
  int foo;
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_getter_getter() async {
    addTestFile(r'''
class C {
  int get foo => 0;
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_getter_method() async {
    addTestFile(r'''
class C {
  int get foo => 0;
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_method_getter() async {
    addTestFile(r'''
class C {
  void foo() {}
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_method_method() async {
    addTestFile(r'''
class C {
  void foo() {}
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_method_setter() async {
    addTestFile(r'''
class C {
  void foo() {}
  set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_OK_fieldFinal_setter() async {
    addTestFile(r'''
class C {
  final int foo = 0;
  set foo(int x) {}
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_duplicateDefinition_OK_getter_setter() async {
    addTestFile(r'''
class C {
  int get foo => 0;
  set foo(_) {}
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_duplicateDefinition_OK_setter_getter() async {
    addTestFile(r'''
class C {
  set foo(_) {}
  int get foo => 0;
}
''');
    await resolveTestFile();
    assertNoTestErrors();
  }

  test_error_duplicateDefinition_setter_method() async {
    addTestFile(r'''
class C {
  set foo(_) {}
  void foo() {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_duplicateDefinition_setter_setter() async {
    addTestFile(r'''
class C {
  void set foo(_) {}
  void set foo(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_error_extendsNonClass_dynamic() async {
    addTestFile(r'''
class A extends dynamic {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.EXTENDS_NON_CLASS,
    ]);

    var a = findElement.class_('A');
    assertElementType(a.supertype, objectType);
  }

  test_error_extendsNonClass_enum() async {
    addTestFile(r'''
enum E { ONE }
class A extends E {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.EXTENDS_NON_CLASS,
    ]);

    var a = findElement.class_('A');
    assertElementType(a.supertype, objectType);

    var eRef = findNode.typeName('E {}');
    assertTypeName(eRef, findElement.enum_('E'), 'E');
  }

  test_error_extendsNonClass_mixin() async {
    addTestFile(r'''
mixin M {}
class A extends M {} // ref
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.EXTENDS_NON_CLASS,
    ]);

    var a = findElement.class_('A');
    assertElementType(a.supertype, objectType);

    var mRef = findNode.typeName('M {} // ref');
    assertTypeName(mRef, findElement.mixin('M'), 'M');
  }

  test_error_extendsNonClass_variable() async {
    addTestFile(r'''
int v;
class A extends v {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.EXTENDS_NON_CLASS,
    ]);

    var a = findElement.class_('A');
    assertElementType(a.supertype, objectType);
  }

  test_error_memberWithClassName_getter() async {
    addTestFile(r'''
class C {
  int get C => null;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
  }

  test_error_memberWithClassName_getter_static() async {
    addTestFile(r'''
class C {
  static int get C => null;
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);

    var method = findNode.methodDeclaration('C =>');
    expect(method.isGetter, isTrue);
    expect(method.isStatic, isTrue);
    assertElement(method, findElement.getter('C'));
  }

  test_error_memberWithClassName_setter() async {
    addTestFile(r'''
class C {
  set C(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
  }

  test_error_memberWithClassName_setter_static() async {
    addTestFile(r'''
class C {
  static set C(_) {}
}
''');
    await resolveTestFile();
    assertTestErrors([CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);

    var method = findNode.methodDeclaration('C(_)');
    expect(method.isSetter, isTrue);
    expect(method.isStatic, isTrue);
  }

  test_recursiveInterfaceInheritance_extends() async {
    addTestFile(r'''
class A extends B {}
class B extends A {}''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_extends_implements() async {
    addTestFile(r'''
class A extends B {}
class B implements A {}''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_implements() async {
    addTestFile(r'''
class A implements B {}
class B implements A {}''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_mixin() async {
    addTestFile(r'''
class M1 = Object with M2;
class M2 = Object with M1;''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_mixin_superclass() async {
    // Make sure we don't get CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS in
    // addition--that would just be confusing.
    addTestFile('''
class C = D with M;
class D = C with M;
class M {}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_tail() async {
    addTestFile(r'''
abstract class A implements A {}
class B implements A {}''');
    await resolveTestFile();
    assertTestErrors(
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS]);
  }

  test_recursiveInterfaceInheritance_tail2() async {
    addTestFile(r'''
abstract class A implements B {}
abstract class B implements A {}
class C implements A {}''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritance_tail3() async {
    addTestFile(r'''
abstract class A implements B {}
abstract class B implements C {}
abstract class C implements A {}
class D implements A {}''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveInterfaceInheritanceExtends() async {
    addTestFile("class A extends A {}");
    await resolveTestFile();
    assertTestErrors(
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS]);
  }

  test_recursiveInterfaceInheritanceExtends_abstract() async {
    addTestFile(r'''
class C extends C {
  var bar = 0;
  m();
}
''');
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS,
      StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER,
      StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE
    ]);
  }

  test_recursiveInterfaceInheritanceImplements() async {
    addTestFile("class A implements A {}");
    await resolveTestFile();
    assertTestErrors(
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS]);
  }

  test_recursiveInterfaceInheritanceImplements_typeAlias() async {
    addTestFile(r'''
class A {}
class M {}
class B = A with M implements B;''');
    await resolveTestFile();
    assertTestErrors(
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS]);
  }

  test_recursiveInterfaceInheritanceWith() async {
    addTestFile("class M = Object with M;");
    await resolveTestFile();
    assertTestErrors([
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_WITH,
    ]);
  }
}

@reflectiveTest
class ClassTaskResolutionTest extends TaskResolutionTest
    with ClassResolutionMixin {}
