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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          enclosingElement: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          constructors
            named @55
              reference: dart:foo::<fragment>::@class::A::@constructor::named
              enclosingElement: dart:foo::<fragment>::@class::A
              sinceSdkVersion: 2.15.0
              periodOffset: 54
              nameEnd: 60
        class B @73
          reference: dart:foo::<fragment>::@class::B
          enclosingElement: dart:foo::<fragment>
          constructors
            named @81
              reference: dart:foo::<fragment>::@class::B::@constructor::named
              enclosingElement: dart:foo::<fragment>::@class::B
              periodOffset: 80
              nameEnd: 86
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
        class B @73
          reference: dart:foo::<fragment>::@class::B
  classes
    class A
      reference: dart:foo::<fragment>::@class::A
      enclosingElement2: dart:foo
      sinceSdkVersion: 2.15.0
      firstFragment: dart:foo::<fragment>::@class::A
    class B
      reference: dart:foo::<fragment>::@class::B
      enclosingElement2: dart:foo
      firstFragment: dart:foo::<fragment>::@class::B
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          enclosingElement: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          fields
            foo @57
              reference: dart:foo::<fragment>::@class::A::@field::foo
              enclosingElement: dart:foo::<fragment>::@class::A
              sinceSdkVersion: 2.15.0
              type: int
              shouldUseTypeForInitializerInference: true
          accessors
            synthetic get foo @-1
              reference: dart:foo::<fragment>::@class::A::@getter::foo
              enclosingElement: dart:foo::<fragment>::@class::A
              sinceSdkVersion: 2.15.0
              returnType: int
            synthetic set foo= @-1
              reference: dart:foo::<fragment>::@class::A::@setter::foo
              enclosingElement: dart:foo::<fragment>::@class::A
              sinceSdkVersion: 2.15.0
              parameters
                requiredPositional _foo @-1
                  type: int
              returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
  classes
    class A
      reference: dart:foo::<fragment>::@class::A
      enclosingElement2: dart:foo
      sinceSdkVersion: 2.15.0
      firstFragment: dart:foo::<fragment>::@class::A
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          enclosingElement: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          fields
            synthetic foo @-1
              reference: dart:foo::<fragment>::@class::A::@field::foo
              enclosingElement: dart:foo::<fragment>::@class::A
              type: int
          accessors
            get foo @61
              reference: dart:foo::<fragment>::@class::A::@getter::foo
              enclosingElement: dart:foo::<fragment>::@class::A
              sinceSdkVersion: 2.15.0
              returnType: int
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
  classes
    class A
      reference: dart:foo::<fragment>::@class::A
      enclosingElement2: dart:foo
      sinceSdkVersion: 2.15.0
      firstFragment: dart:foo::<fragment>::@class::A
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          enclosingElement: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          methods
            foo @58
              reference: dart:foo::<fragment>::@class::A::@method::foo
              enclosingElement: dart:foo::<fragment>::@class::A
              sinceSdkVersion: 2.15.0
              returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
  classes
    class A
      reference: dart:foo::<fragment>::@class::A
      enclosingElement2: dart:foo
      sinceSdkVersion: 2.15.0
      firstFragment: dart:foo::<fragment>::@class::A
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          enclosingElement: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          methods
            foo @75
              reference: dart:foo::<fragment>::@class::A::@method::foo
              enclosingElement: dart:foo::<fragment>::@class::A
              sinceSdkVersion: 2.16.0
              returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
  classes
    class A
      reference: dart:foo::<fragment>::@class::A
      enclosingElement2: dart:foo
      sinceSdkVersion: 2.15.0
      firstFragment: dart:foo::<fragment>::@class::A
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          enclosingElement: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          methods
            foo @75
              reference: dart:foo::<fragment>::@class::A::@method::foo
              enclosingElement: dart:foo::<fragment>::@class::A
              sinceSdkVersion: 2.15.0
              returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
  classes
    class A
      reference: dart:foo::<fragment>::@class::A
      enclosingElement2: dart:foo
      sinceSdkVersion: 2.15.0
      firstFragment: dart:foo::<fragment>::@class::A
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          enclosingElement: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          fields
            synthetic foo @-1
              reference: dart:foo::<fragment>::@class::A::@field::foo
              enclosingElement: dart:foo::<fragment>::@class::A
              type: int
          accessors
            set foo= @57
              reference: dart:foo::<fragment>::@class::A::@setter::foo
              enclosingElement: dart:foo::<fragment>::@class::A
              sinceSdkVersion: 2.15.0
              parameters
                requiredPositional _ @65
                  type: int
              returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
  classes
    class A
      reference: dart:foo::<fragment>::@class::A
      enclosingElement2: dart:foo
      sinceSdkVersion: 2.15.0
      firstFragment: dart:foo::<fragment>::@class::A
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      enums
        enum E @31
          reference: dart:foo::<fragment>::@enum::E
          enclosingElement: dart:foo::<fragment>
          supertype: Enum
          fields
            static const enumConstant v1 @37
              reference: dart:foo::<fragment>::@enum::E::@field::v1
              enclosingElement: dart:foo::<fragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
            static const enumConstant v2 @60
              reference: dart:foo::<fragment>::@enum::E::@field::v2
              enclosingElement: dart:foo::<fragment>::@enum::E
              sinceSdkVersion: 2.15.0
              type: E
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: dart:foo::<fragment>::@enum::E::@field::values
              enclosingElement: dart:foo::<fragment>::@enum::E
              type: List<E>
          accessors
            synthetic static get v1 @-1
              reference: dart:foo::<fragment>::@enum::E::@getter::v1
              enclosingElement: dart:foo::<fragment>::@enum::E
              returnType: E
            synthetic static get v2 @-1
              reference: dart:foo::<fragment>::@enum::E::@getter::v2
              enclosingElement: dart:foo::<fragment>::@enum::E
              sinceSdkVersion: 2.15.0
              returnType: E
            synthetic static get values @-1
              reference: dart:foo::<fragment>::@enum::E::@getter::values
              enclosingElement: dart:foo::<fragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      enums
        enum E @31
          reference: dart:foo::<fragment>::@enum::E
  enums
    enum E
      reference: dart:foo::<fragment>::@enum::E
      enclosingElement2: dart:foo
      firstFragment: dart:foo::<fragment>::@enum::E
      supertype: Enum
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      enums
        enum E @46
          reference: dart:foo::<fragment>::@enum::E
          enclosingElement: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          supertype: Enum
          fields
            static const enumConstant v @52
              reference: dart:foo::<fragment>::@enum::E::@field::v
              enclosingElement: dart:foo::<fragment>::@enum::E
              sinceSdkVersion: 2.15.0
              type: E
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: dart:foo::<fragment>::@enum::E::@field::values
              enclosingElement: dart:foo::<fragment>::@enum::E
              type: List<E>
          accessors
            synthetic static get v @-1
              reference: dart:foo::<fragment>::@enum::E::@getter::v
              enclosingElement: dart:foo::<fragment>::@enum::E
              sinceSdkVersion: 2.15.0
              returnType: E
            synthetic static get values @-1
              reference: dart:foo::<fragment>::@enum::E::@getter::values
              enclosingElement: dart:foo::<fragment>::@enum::E
              returnType: List<E>
          methods
            foo @62
              reference: dart:foo::<fragment>::@enum::E::@method::foo
              enclosingElement: dart:foo::<fragment>::@enum::E
              sinceSdkVersion: 2.15.0
              returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      enums
        enum E @46
          reference: dart:foo::<fragment>::@enum::E
  enums
    enum E
      reference: dart:foo::<fragment>::@enum::E
      enclosingElement2: dart:foo
      sinceSdkVersion: 2.15.0
      firstFragment: dart:foo::<fragment>::@enum::E
      supertype: Enum
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      extensions
        E @51
          reference: dart:foo::<fragment>::@extension::E
          enclosingElement: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          extendedType: int
          methods
            foo @69
              reference: dart:foo::<fragment>::@extension::E::@method::foo
              enclosingElement: dart:foo::<fragment>::@extension::E
              sinceSdkVersion: 2.15.0
              returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      extensions
        extension E @51
          reference: dart:foo::<fragment>::@extension::E
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      mixins
        mixin M @47
          reference: dart:foo::<fragment>::@mixin::M
          enclosingElement: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          superclassConstraints
            Object
          methods
            foo @58
              reference: dart:foo::<fragment>::@mixin::M::@method::foo
              enclosingElement: dart:foo::<fragment>::@mixin::M
              sinceSdkVersion: 2.15.0
              returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      mixins
        mixin M @47
          reference: dart:foo::<fragment>::@mixin::M
  mixins
    mixin M
      reference: dart:foo::<fragment>::@mixin::M
      enclosingElement2: dart:foo
      sinceSdkVersion: 2.15.0
      firstFragment: dart:foo::<fragment>::@mixin::M
      superclassConstraints
        Object
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      functions
        foo @46
          reference: dart:foo::<fragment>::@function::foo
          enclosingElement: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          returnType: void
        bar @61
          reference: dart:foo::<fragment>::@function::bar
          enclosingElement: dart:foo::<fragment>
          returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      functions
        foo @54
          reference: dart:foo::<fragment>::@function::foo
          enclosingElement: dart:foo::<fragment>
          sinceSdkVersion: 2.15.3-dev.7
          returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      functions
        foo @48
          reference: dart:foo::<fragment>::@function::foo
          enclosingElement: dart:foo::<fragment>
          sinceSdkVersion: 2.15.3
          returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      functions
        foo @44
          reference: dart:foo::<fragment>::@function::foo
          enclosingElement: dart:foo::<fragment>
          returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      functions
        foo @56
          reference: dart:foo::<fragment>::@function::foo
          enclosingElement: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          returnType: void
----------------------------------------
library
  reference: dart:foo
  sinceSdkVersion: 2.15.0
  fragments
    dart:foo::<fragment>
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      functions
        f @31
          reference: dart:foo::<fragment>::@function::f
          enclosingElement: dart:foo::<fragment>
          parameters
            requiredPositional p1 @37
              type: int
            optionalNamed default p2 @67
              reference: dart:foo::<fragment>::@function::f::@parameter::p2
              type: int?
              sinceSdkVersion: 2.15.0
          returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      functions
        f @31
          reference: dart:foo::<fragment>::@function::f
          enclosingElement: dart:foo::<fragment>
          parameters
            requiredPositional p1 @37
              type: int
            optionalPositional default p2 @67
              type: int?
              sinceSdkVersion: 2.15.0
          returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      typeAliases
        A @49
          reference: dart:foo::<fragment>::@typeAlias::A
          sinceSdkVersion: 2.15.0
          aliasedType: List<int>
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement: dart:foo
      topLevelVariables
        static final foo @47
          reference: dart:foo::<fragment>::@topLevelVariable::foo
          enclosingElement: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get foo @-1
          reference: dart:foo::<fragment>::@getter::foo
          enclosingElement: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          returnType: int
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
''');
  }

  Future<LibraryElementImpl> _buildDartFooLibrary(String content) async {
    additionalMockSdkLibraries.add(
      MockSdkLibrary('foo', [
        MockSdkLibraryUnit('foo/foo.dart', content),
      ]),
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
