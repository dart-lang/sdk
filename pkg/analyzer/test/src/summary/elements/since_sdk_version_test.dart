// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../element_text.dart';
import '../elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SinceSdkVersionElementTest_keepLinking);
    defineReflectiveTests(SinceSdkVersionElementTest_fromBytes);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

abstract class SinceSdkVersionElementTest extends ElementsBaseTest {
  @override
  List<MockSdkLibrary> additionalMockSdkLibraries = [];

  test_sinceSdkVersion_class_constructor_inherits() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {
  A.named();
}

class B {
  B.named();
}
''');
    configuration
      ..forSinceSdkVersion()
      ..withConstructors = true;
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      classes
        #F1 class A (nameOffset:47) (firstTokenOffset:26) (offset:47)
          element: dart:foo::@class::A
          constructors
            #F2 named (nameOffset:55) (firstTokenOffset:53) (offset:55)
              element: dart:foo::@class::A::@constructor::named
              typeName: A
              typeNameOffset: 53
              periodOffset: 54
        #F3 class B (nameOffset:73) (firstTokenOffset:67) (offset:73)
          element: dart:foo::@class::B
          constructors
            #F4 named (nameOffset:81) (firstTokenOffset:79) (offset:81)
              element: dart:foo::@class::B::@constructor::named
              typeName: B
              typeNameOffset: 79
              periodOffset: 80
  classes
    class A
      reference: dart:foo::@class::A
      firstFragment: #F1
      sinceSdkVersion: 2.15.0
      constructors
        named
          reference: dart:foo::@class::A::@constructor::named
          firstFragment: #F2
          sinceSdkVersion: 2.15.0
    class B
      reference: dart:foo::@class::B
      firstFragment: #F3
      constructors
        named
          reference: dart:foo::@class::B::@constructor::named
          firstFragment: #F4
''');
  }

  test_sinceSdkVersion_class_field_inherits() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {
  int foo = 0;
}
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      classes
        #F1 class A (nameOffset:47) (firstTokenOffset:26) (offset:47)
          element: dart:foo::@class::A
          fields
            #F2 hasInitializer foo (nameOffset:57) (firstTokenOffset:57) (offset:57)
              element: dart:foo::@class::A::@field::foo
          getters
            #F3 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: dart:foo::@class::A::@getter::foo
          setters
            #F4 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
              element: dart:foo::@class::A::@setter::foo
              formalParameters
                #F5 value (nameOffset:<null>) (firstTokenOffset:<null>) (offset:57)
                  element: dart:foo::@class::A::@setter::foo::@formalParameter::value
  classes
    hasNonFinalField class A
      reference: dart:foo::@class::A
      firstFragment: #F1
      sinceSdkVersion: 2.15.0
      fields
        hasInitializer foo
          reference: dart:foo::@class::A::@field::foo
          firstFragment: #F2
          sinceSdkVersion: 2.15.0
          type: int
          getter: dart:foo::@class::A::@getter::foo
          setter: dart:foo::@class::A::@setter::foo
      getters
        synthetic foo
          reference: dart:foo::@class::A::@getter::foo
          firstFragment: #F3
          sinceSdkVersion: 2.15.0
          returnType: int
          variable: dart:foo::@class::A::@field::foo
      setters
        synthetic foo
          reference: dart:foo::@class::A::@setter::foo
          firstFragment: #F4
          sinceSdkVersion: 2.15.0
          formalParameters
            #E0 requiredPositional value
              firstFragment: #F5
              type: int
          returnType: void
          variable: dart:foo::@class::A::@field::foo
''');
  }

  test_sinceSdkVersion_class_getter_inherits() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {
  int get foo => 0;
}
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      classes
        #F1 class A (nameOffset:47) (firstTokenOffset:26) (offset:47)
          element: dart:foo::@class::A
          fields
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
              element: dart:foo::@class::A::@field::foo
          getters
            #F3 foo (nameOffset:61) (firstTokenOffset:53) (offset:61)
              element: dart:foo::@class::A::@getter::foo
  classes
    class A
      reference: dart:foo::@class::A
      firstFragment: #F1
      sinceSdkVersion: 2.15.0
      fields
        synthetic foo
          reference: dart:foo::@class::A::@field::foo
          firstFragment: #F2
          sinceSdkVersion: 2.15.0
          type: int
          getter: dart:foo::@class::A::@getter::foo
      getters
        foo
          reference: dart:foo::@class::A::@getter::foo
          firstFragment: #F3
          sinceSdkVersion: 2.15.0
          returnType: int
          variable: dart:foo::@class::A::@field::foo
''');
  }

  test_sinceSdkVersion_class_method_inherits() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {
  void foo() {}
}
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      classes
        #F1 class A (nameOffset:47) (firstTokenOffset:26) (offset:47)
          element: dart:foo::@class::A
          methods
            #F2 foo (nameOffset:58) (firstTokenOffset:53) (offset:58)
              element: dart:foo::@class::A::@method::foo
  classes
    class A
      reference: dart:foo::@class::A
      firstFragment: #F1
      sinceSdkVersion: 2.15.0
      methods
        foo
          reference: dart:foo::@class::A::@method::foo
          firstFragment: #F2
          sinceSdkVersion: 2.15.0
          returnType: void
''');
  }

  test_sinceSdkVersion_class_method_max_greater() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {
  @Since('2.16')
  void foo() {}
}
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      classes
        #F1 class A (nameOffset:47) (firstTokenOffset:26) (offset:47)
          element: dart:foo::@class::A
          methods
            #F2 foo (nameOffset:75) (firstTokenOffset:53) (offset:75)
              element: dart:foo::@class::A::@method::foo
  classes
    class A
      reference: dart:foo::@class::A
      firstFragment: #F1
      sinceSdkVersion: 2.15.0
      methods
        foo
          reference: dart:foo::@class::A::@method::foo
          firstFragment: #F2
          sinceSdkVersion: 2.16.0
          returnType: void
''');
  }

  test_sinceSdkVersion_class_method_max_less() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {
  @Since('2.14')
  void foo() {}
}
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      classes
        #F1 class A (nameOffset:47) (firstTokenOffset:26) (offset:47)
          element: dart:foo::@class::A
          methods
            #F2 foo (nameOffset:75) (firstTokenOffset:53) (offset:75)
              element: dart:foo::@class::A::@method::foo
  classes
    class A
      reference: dart:foo::@class::A
      firstFragment: #F1
      sinceSdkVersion: 2.15.0
      methods
        foo
          reference: dart:foo::@class::A::@method::foo
          firstFragment: #F2
          sinceSdkVersion: 2.15.0
          returnType: void
''');
  }

  test_sinceSdkVersion_class_setter_inherits() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {
  set foo(int _) {}
}
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      classes
        #F1 class A (nameOffset:47) (firstTokenOffset:26) (offset:47)
          element: dart:foo::@class::A
          fields
            #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
              element: dart:foo::@class::A::@field::foo
          setters
            #F3 foo (nameOffset:57) (firstTokenOffset:53) (offset:57)
              element: dart:foo::@class::A::@setter::foo
              formalParameters
                #F4 _ (nameOffset:65) (firstTokenOffset:61) (offset:65)
                  element: dart:foo::@class::A::@setter::foo::@formalParameter::_
  classes
    class A
      reference: dart:foo::@class::A
      firstFragment: #F1
      sinceSdkVersion: 2.15.0
      fields
        synthetic foo
          reference: dart:foo::@class::A::@field::foo
          firstFragment: #F2
          sinceSdkVersion: 2.15.0
          type: int
          setter: dart:foo::@class::A::@setter::foo
      setters
        foo
          reference: dart:foo::@class::A::@setter::foo
          firstFragment: #F3
          sinceSdkVersion: 2.15.0
          formalParameters
            #E0 requiredPositional _
              firstFragment: #F4
              type: int
          returnType: void
          variable: dart:foo::@class::A::@field::foo
''');
  }

  test_sinceSdkVersion_enum_constant() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

enum E {
  v1,
  @Since('2.15')
  v2
}
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      enums
        #F1 enum E (nameOffset:31) (firstTokenOffset:26) (offset:31)
          element: dart:foo::@enum::E
          fields
            #F2 hasInitializer v1 (nameOffset:37) (firstTokenOffset:37) (offset:37)
              element: dart:foo::@enum::E::@field::v1
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: dart:foo::@enum::E
                      type: E
                    element: dart:foo::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 hasInitializer v2 (nameOffset:60) (firstTokenOffset:43) (offset:60)
              element: dart:foo::@enum::E::@field::v2
              initializer: expression_1
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: dart:foo::@enum::E
                      type: E
                    element: dart:foo::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F4 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: dart:foo::@enum::E::@field::values
              initializer: expression_2
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v1 @-1
                      element: dart:foo::@enum::E::@getter::v1
                      staticType: E
                    SimpleIdentifier
                      token: v2 @-1
                      element: dart:foo::@enum::E::@getter::v2
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          getters
            #F5 synthetic v1 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:37)
              element: dart:foo::@enum::E::@getter::v1
            #F6 synthetic v2 (nameOffset:<null>) (firstTokenOffset:<null>) (offset:60)
              element: dart:foo::@enum::E::@getter::v2
            #F7 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:31)
              element: dart:foo::@enum::E::@getter::values
  enums
    enum E
      reference: dart:foo::@enum::E
      firstFragment: #F1
      supertype: Enum
      fields
        static const enumConstant hasInitializer v1
          reference: dart:foo::@enum::E::@field::v1
          firstFragment: #F2
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: dart:foo::@enum::E::@getter::v1
        static const enumConstant hasInitializer v2
          reference: dart:foo::@enum::E::@field::v2
          firstFragment: #F3
          sinceSdkVersion: 2.15.0
          type: E
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: dart:foo::@enum::E::@getter::v2
        synthetic static const values
          reference: dart:foo::@enum::E::@field::values
          firstFragment: #F4
          type: List<E>
          constantInitializer
            fragment: #F4
            expression: expression_2
          getter: dart:foo::@enum::E::@getter::values
      getters
        synthetic static v1
          reference: dart:foo::@enum::E::@getter::v1
          firstFragment: #F5
          returnType: E
          variable: dart:foo::@enum::E::@field::v1
        synthetic static v2
          reference: dart:foo::@enum::E::@getter::v2
          firstFragment: #F6
          sinceSdkVersion: 2.15.0
          returnType: E
          variable: dart:foo::@enum::E::@field::v2
        synthetic static values
          reference: dart:foo::@enum::E::@getter::values
          firstFragment: #F7
          returnType: List<E>
          variable: dart:foo::@enum::E::@field::values
''');
  }

  test_sinceSdkVersion_enum_method_inherits() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
enum E {
  v;
  void foo() {}
}
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      enums
        #F1 enum E (nameOffset:46) (firstTokenOffset:26) (offset:46)
          element: dart:foo::@enum::E
          fields
            #F2 hasInitializer v (nameOffset:52) (firstTokenOffset:52) (offset:52)
              element: dart:foo::@enum::E::@field::v
              initializer: expression_0
                InstanceCreationExpression
                  constructorName: ConstructorName
                    type: NamedType
                      name: E @-1
                      element2: dart:foo::@enum::E
                      type: E
                    element: dart:foo::@enum::E::@constructor::new
                  argumentList: ArgumentList
                    leftParenthesis: ( @0
                    rightParenthesis: ) @0
                  staticType: E
            #F3 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: dart:foo::@enum::E::@field::values
              initializer: expression_1
                ListLiteral
                  leftBracket: [ @0
                  elements
                    SimpleIdentifier
                      token: v @-1
                      element: dart:foo::@enum::E::@getter::v
                      staticType: E
                  rightBracket: ] @0
                  staticType: List<E>
          getters
            #F4 synthetic v (nameOffset:<null>) (firstTokenOffset:<null>) (offset:52)
              element: dart:foo::@enum::E::@getter::v
            #F5 synthetic values (nameOffset:<null>) (firstTokenOffset:<null>) (offset:46)
              element: dart:foo::@enum::E::@getter::values
          methods
            #F6 foo (nameOffset:62) (firstTokenOffset:57) (offset:62)
              element: dart:foo::@enum::E::@method::foo
  enums
    enum E
      reference: dart:foo::@enum::E
      firstFragment: #F1
      sinceSdkVersion: 2.15.0
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          reference: dart:foo::@enum::E::@field::v
          firstFragment: #F2
          sinceSdkVersion: 2.15.0
          type: E
          constantInitializer
            fragment: #F2
            expression: expression_0
          getter: dart:foo::@enum::E::@getter::v
        synthetic static const values
          reference: dart:foo::@enum::E::@field::values
          firstFragment: #F3
          sinceSdkVersion: 2.15.0
          type: List<E>
          constantInitializer
            fragment: #F3
            expression: expression_1
          getter: dart:foo::@enum::E::@getter::values
      getters
        synthetic static v
          reference: dart:foo::@enum::E::@getter::v
          firstFragment: #F4
          sinceSdkVersion: 2.15.0
          returnType: E
          variable: dart:foo::@enum::E::@field::v
        synthetic static values
          reference: dart:foo::@enum::E::@getter::values
          firstFragment: #F5
          sinceSdkVersion: 2.15.0
          returnType: List<E>
          variable: dart:foo::@enum::E::@field::values
      methods
        foo
          reference: dart:foo::@enum::E::@method::foo
          firstFragment: #F6
          sinceSdkVersion: 2.15.0
          returnType: void
''');
  }

  test_sinceSdkVersion_extension_method_inherits() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
extension E on int {
  void foo() {}
}
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      extensions
        #F1 extension E (nameOffset:51) (firstTokenOffset:26) (offset:51)
          element: dart:foo::@extension::E
          methods
            #F2 foo (nameOffset:69) (firstTokenOffset:64) (offset:69)
              element: dart:foo::@extension::E::@method::foo
  extensions
    extension E
      reference: dart:foo::@extension::E
      firstFragment: #F1
      sinceSdkVersion: 2.15.0
      extendedType: int
      methods
        foo
          reference: dart:foo::@extension::E::@method::foo
          firstFragment: #F2
          sinceSdkVersion: 2.15.0
          returnType: void
''');
  }

  test_sinceSdkVersion_mixin_method_inherits() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
mixin M {
  void foo() {}
}
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      mixins
        #F1 mixin M (nameOffset:47) (firstTokenOffset:26) (offset:47)
          element: dart:foo::@mixin::M
          methods
            #F2 foo (nameOffset:58) (firstTokenOffset:53) (offset:58)
              element: dart:foo::@mixin::M::@method::foo
  mixins
    mixin M
      reference: dart:foo::@mixin::M
      firstFragment: #F1
      sinceSdkVersion: 2.15.0
      superclassConstraints
        Object
      methods
        foo
          reference: dart:foo::@mixin::M::@method::foo
          firstFragment: #F2
          sinceSdkVersion: 2.15.0
          returnType: void
''');
  }

  test_sinceSdkVersion_unit_function() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
void foo() {}

void bar() {}
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      functions
        #F1 foo (nameOffset:46) (firstTokenOffset:26) (offset:46)
          element: dart:foo::@function::foo
        #F2 bar (nameOffset:61) (firstTokenOffset:56) (offset:61)
          element: dart:foo::@function::bar
  functions
    foo
      reference: dart:foo::@function::foo
      firstFragment: #F1
      sinceSdkVersion: 2.15.0
      returnType: void
    bar
      reference: dart:foo::@function::bar
      firstFragment: #F2
      returnType: void
''');
  }

  test_sinceSdkVersion_unit_function_format_extended() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15.3-dev.7')
void foo() {}
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      functions
        #F1 foo (nameOffset:54) (firstTokenOffset:26) (offset:54)
          element: dart:foo::@function::foo
  functions
    foo
      reference: dart:foo::@function::foo
      firstFragment: #F1
      sinceSdkVersion: 2.15.3-dev.7
      returnType: void
''');
  }

  test_sinceSdkVersion_unit_function_format_full() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15.3')
void foo() {}
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      functions
        #F1 foo (nameOffset:48) (firstTokenOffset:26) (offset:48)
          element: dart:foo::@function::foo
  functions
    foo
      reference: dart:foo::@function::foo
      firstFragment: #F1
      sinceSdkVersion: 2.15.3
      returnType: void
''');
  }

  test_sinceSdkVersion_unit_function_format_invalid() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

@Since('42')
void foo() {}
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      functions
        #F1 foo (nameOffset:44) (firstTokenOffset:26) (offset:44)
          element: dart:foo::@function::foo
  functions
    foo
      reference: dart:foo::@function::foo
      firstFragment: #F1
      returnType: void
''');
  }

  test_sinceSdkVersion_unit_function_inherits() async {
    var library = await _buildDartFooLibrary(r'''
@Since('2.15')
library;

import 'dart:_internal';

void foo() {}
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  sinceSdkVersion: 2.15.0
  fragments
    #F0 dart:foo
      element: dart:foo
      functions
        #F1 foo (nameOffset:56) (firstTokenOffset:51) (offset:56)
          element: dart:foo::@function::foo
  functions
    foo
      reference: dart:foo::@function::foo
      firstFragment: #F1
      sinceSdkVersion: 2.15.0
      returnType: void
''');
  }

  test_sinceSdkVersion_unit_function_parameters_optionalNamed() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

void f(int p1, {
  @Since('2.15')
  int? p2,
}) {}
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      functions
        #F1 f (nameOffset:31) (firstTokenOffset:26) (offset:31)
          element: dart:foo::@function::f
          formalParameters
            #F2 p1 (nameOffset:37) (firstTokenOffset:33) (offset:37)
              element: dart:foo::@function::f::@formalParameter::p1
            #F3 p2 (nameOffset:67) (firstTokenOffset:45) (offset:67)
              element: dart:foo::@function::f::@formalParameter::p2
  functions
    f
      reference: dart:foo::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional p1
          firstFragment: #F2
          type: int
        #E1 optionalNamed p2
          firstFragment: #F3
          type: int?
          sinceSdkVersion: 2.15.0
      returnType: void
''');
  }

  test_sinceSdkVersion_unit_function_parameters_optionalPositional() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

void f(int p1, [
  @Since('2.15')
  int? p2,
]) {}
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      functions
        #F1 f (nameOffset:31) (firstTokenOffset:26) (offset:31)
          element: dart:foo::@function::f
          formalParameters
            #F2 p1 (nameOffset:37) (firstTokenOffset:33) (offset:37)
              element: dart:foo::@function::f::@formalParameter::p1
            #F3 p2 (nameOffset:67) (firstTokenOffset:45) (offset:67)
              element: dart:foo::@function::f::@formalParameter::p2
  functions
    f
      reference: dart:foo::@function::f
      firstFragment: #F1
      formalParameters
        #E0 requiredPositional p1
          firstFragment: #F2
          type: int
        #E1 optionalPositional p2
          firstFragment: #F3
          type: int?
          sinceSdkVersion: 2.15.0
      returnType: void
''');
  }

  test_sinceSdkVersion_unit_typeAlias() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
typedef A = List<int>;
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      typeAliases
        #F1 A (nameOffset:49) (firstTokenOffset:26) (offset:49)
          element: dart:foo::@typeAlias::A
  typeAliases
    A
      reference: dart:foo::@typeAlias::A
      firstFragment: #F1
      sinceSdkVersion: 2.15.0
      aliasedType: List<int>
''');
  }

  test_sinceSdkVersion_unit_variable() async {
    var library = await _buildDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
final foo = 0;
''');
    configuration.forSinceSdkVersion();
    checkElementText(library, r'''
library
  reference: dart:foo
  fragments
    #F0 dart:foo
      element: dart:foo
      topLevelVariables
        #F1 hasInitializer foo (nameOffset:47) (firstTokenOffset:47) (offset:47)
          element: dart:foo::@topLevelVariable::foo
      getters
        #F2 synthetic foo (nameOffset:<null>) (firstTokenOffset:<null>) (offset:47)
          element: dart:foo::@getter::foo
  topLevelVariables
    final hasInitializer foo
      reference: dart:foo::@topLevelVariable::foo
      firstFragment: #F1
      sinceSdkVersion: 2.15.0
      type: int
      getter: dart:foo::@getter::foo
  getters
    synthetic static foo
      reference: dart:foo::@getter::foo
      firstFragment: #F2
      sinceSdkVersion: 2.15.0
      returnType: int
      variable: dart:foo::@topLevelVariable::foo
''');
  }

  Future<LibraryElementImpl> _buildDartFooLibrary(String content) async {
    additionalMockSdkLibraries.add(
      MockSdkLibrary('foo', [MockSdkLibraryUnit('foo/foo.dart', content)]),
    );

    return await _libraryByUriFromTest('dart:foo');
  }

  /// Returns the library for [uriStr] from the context of [testFile].
  Future<LibraryElementImpl> _libraryByUriFromTest(String uriStr) async {
    var analysisContext = contextFor(testFile);
    var analysisSession = analysisContext.currentSession;

    var libraryResult = await analysisSession.getLibraryByUri(uriStr);
    libraryResult as LibraryElementResult;
    return libraryResult.element as LibraryElementImpl;
  }
}

@reflectiveTest
class SinceSdkVersionElementTest_fromBytes extends SinceSdkVersionElementTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class SinceSdkVersionElementTest_keepLinking
    extends SinceSdkVersionElementTest {
  @override
  bool get keepLinkingLibraries => true;
}

extension on ElementTextConfiguration {
  void forSinceSdkVersion() {
    withConstantInitializers = false;
    withConstructors = false;
    withImports = false;
    withMetadata = false;
  }
}
