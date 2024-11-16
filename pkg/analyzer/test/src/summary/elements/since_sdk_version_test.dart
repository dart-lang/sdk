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
      enclosingElement3: <null>
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          enclosingElement3: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          constructors
            named @55
              reference: dart:foo::<fragment>::@class::A::@constructor::named
              enclosingElement3: dart:foo::<fragment>::@class::A
              sinceSdkVersion: 2.15.0
              periodOffset: 54
              nameEnd: 60
        class B @73
          reference: dart:foo::<fragment>::@class::B
          enclosingElement3: dart:foo::<fragment>
          constructors
            named @81
              reference: dart:foo::<fragment>::@class::B::@constructor::named
              enclosingElement3: dart:foo::<fragment>::@class::B
              periodOffset: 80
              nameEnd: 86
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      element: dart:foo
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          element: dart:foo::@class::A
          constructors
            named @55
              reference: dart:foo::<fragment>::@class::A::@constructor::named
              element: dart:foo::<fragment>::@class::A::@constructor::named#element
              sinceSdkVersion: 2.15.0
              typeName: A
              typeNameOffset: 53
              periodOffset: 54
        class B @73
          reference: dart:foo::<fragment>::@class::B
          element: dart:foo::@class::B
          constructors
            named @81
              reference: dart:foo::<fragment>::@class::B::@constructor::named
              element: dart:foo::<fragment>::@class::B::@constructor::named#element
              typeName: B
              typeNameOffset: 79
              periodOffset: 80
  classes
    class A
      reference: dart:foo::@class::A
      firstFragment: dart:foo::<fragment>::@class::A
      sinceSdkVersion: 2.15.0
      constructors
        named
          firstFragment: dart:foo::<fragment>::@class::A::@constructor::named
    class B
      reference: dart:foo::@class::B
      firstFragment: dart:foo::<fragment>::@class::B
      constructors
        named
          firstFragment: dart:foo::<fragment>::@class::B::@constructor::named
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
      enclosingElement3: <null>
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          enclosingElement3: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          fields
            foo @57
              reference: dart:foo::<fragment>::@class::A::@field::foo
              enclosingElement3: dart:foo::<fragment>::@class::A
              sinceSdkVersion: 2.15.0
              type: int
              shouldUseTypeForInitializerInference: true
          accessors
            synthetic get foo @-1
              reference: dart:foo::<fragment>::@class::A::@getter::foo
              enclosingElement3: dart:foo::<fragment>::@class::A
              sinceSdkVersion: 2.15.0
              returnType: int
            synthetic set foo= @-1
              reference: dart:foo::<fragment>::@class::A::@setter::foo
              enclosingElement3: dart:foo::<fragment>::@class::A
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
      element: dart:foo
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          element: dart:foo::@class::A
          fields
            hasInitializer foo @57
              reference: dart:foo::<fragment>::@class::A::@field::foo
              element: dart:foo::<fragment>::@class::A::@field::foo#element
              getter2: dart:foo::<fragment>::@class::A::@getter::foo
              setter2: dart:foo::<fragment>::@class::A::@setter::foo
          getters
            synthetic get foo
              reference: dart:foo::<fragment>::@class::A::@getter::foo
              element: dart:foo::<fragment>::@class::A::@getter::foo#element
              sinceSdkVersion: 2.15.0
          setters
            synthetic set foo
              reference: dart:foo::<fragment>::@class::A::@setter::foo
              element: dart:foo::<fragment>::@class::A::@setter::foo#element
              sinceSdkVersion: 2.15.0
              formalParameters
                <null-name>
                  element: dart:foo::<fragment>::@class::A::@setter::foo::@parameter::_foo#element
  classes
    class A
      reference: dart:foo::@class::A
      firstFragment: dart:foo::<fragment>::@class::A
      sinceSdkVersion: 2.15.0
      fields
        hasInitializer foo
          firstFragment: dart:foo::<fragment>::@class::A::@field::foo
          type: int
          getter: dart:foo::<fragment>::@class::A::@getter::foo#element
          setter: dart:foo::<fragment>::@class::A::@setter::foo#element
      getters
        synthetic get foo
          firstFragment: dart:foo::<fragment>::@class::A::@getter::foo
      setters
        synthetic set foo
          firstFragment: dart:foo::<fragment>::@class::A::@setter::foo
          formalParameters
            requiredPositional _foo
              type: int
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
      enclosingElement3: <null>
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          enclosingElement3: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          fields
            synthetic foo @-1
              reference: dart:foo::<fragment>::@class::A::@field::foo
              enclosingElement3: dart:foo::<fragment>::@class::A
              type: int
          accessors
            get foo @61
              reference: dart:foo::<fragment>::@class::A::@getter::foo
              enclosingElement3: dart:foo::<fragment>::@class::A
              sinceSdkVersion: 2.15.0
              returnType: int
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      element: dart:foo
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          element: dart:foo::@class::A
          fields
            synthetic foo
              reference: dart:foo::<fragment>::@class::A::@field::foo
              element: dart:foo::<fragment>::@class::A::@field::foo#element
              getter2: dart:foo::<fragment>::@class::A::@getter::foo
          getters
            get foo @61
              reference: dart:foo::<fragment>::@class::A::@getter::foo
              element: dart:foo::<fragment>::@class::A::@getter::foo#element
              sinceSdkVersion: 2.15.0
  classes
    class A
      reference: dart:foo::@class::A
      firstFragment: dart:foo::<fragment>::@class::A
      sinceSdkVersion: 2.15.0
      fields
        synthetic foo
          firstFragment: dart:foo::<fragment>::@class::A::@field::foo
          type: int
          getter: dart:foo::<fragment>::@class::A::@getter::foo#element
      getters
        get foo
          firstFragment: dart:foo::<fragment>::@class::A::@getter::foo
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
      enclosingElement3: <null>
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          enclosingElement3: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          methods
            foo @58
              reference: dart:foo::<fragment>::@class::A::@method::foo
              enclosingElement3: dart:foo::<fragment>::@class::A
              sinceSdkVersion: 2.15.0
              returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      element: dart:foo
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          element: dart:foo::@class::A
          methods
            foo @58
              reference: dart:foo::<fragment>::@class::A::@method::foo
              element: dart:foo::<fragment>::@class::A::@method::foo#element
              sinceSdkVersion: 2.15.0
  classes
    class A
      reference: dart:foo::@class::A
      firstFragment: dart:foo::<fragment>::@class::A
      sinceSdkVersion: 2.15.0
      methods
        foo
          reference: dart:foo::@class::A::@method::foo
          firstFragment: dart:foo::<fragment>::@class::A::@method::foo
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
      enclosingElement3: <null>
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          enclosingElement3: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          methods
            foo @75
              reference: dart:foo::<fragment>::@class::A::@method::foo
              enclosingElement3: dart:foo::<fragment>::@class::A
              sinceSdkVersion: 2.16.0
              returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      element: dart:foo
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          element: dart:foo::@class::A
          methods
            foo @75
              reference: dart:foo::<fragment>::@class::A::@method::foo
              element: dart:foo::<fragment>::@class::A::@method::foo#element
              sinceSdkVersion: 2.16.0
  classes
    class A
      reference: dart:foo::@class::A
      firstFragment: dart:foo::<fragment>::@class::A
      sinceSdkVersion: 2.15.0
      methods
        foo
          reference: dart:foo::@class::A::@method::foo
          firstFragment: dart:foo::<fragment>::@class::A::@method::foo
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
      enclosingElement3: <null>
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          enclosingElement3: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          methods
            foo @75
              reference: dart:foo::<fragment>::@class::A::@method::foo
              enclosingElement3: dart:foo::<fragment>::@class::A
              sinceSdkVersion: 2.15.0
              returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      element: dart:foo
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          element: dart:foo::@class::A
          methods
            foo @75
              reference: dart:foo::<fragment>::@class::A::@method::foo
              element: dart:foo::<fragment>::@class::A::@method::foo#element
              sinceSdkVersion: 2.15.0
  classes
    class A
      reference: dart:foo::@class::A
      firstFragment: dart:foo::<fragment>::@class::A
      sinceSdkVersion: 2.15.0
      methods
        foo
          reference: dart:foo::@class::A::@method::foo
          firstFragment: dart:foo::<fragment>::@class::A::@method::foo
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
      enclosingElement3: <null>
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          enclosingElement3: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          fields
            synthetic foo @-1
              reference: dart:foo::<fragment>::@class::A::@field::foo
              enclosingElement3: dart:foo::<fragment>::@class::A
              type: int
          accessors
            set foo= @57
              reference: dart:foo::<fragment>::@class::A::@setter::foo
              enclosingElement3: dart:foo::<fragment>::@class::A
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
      element: dart:foo
      classes
        class A @47
          reference: dart:foo::<fragment>::@class::A
          element: dart:foo::@class::A
          fields
            synthetic foo
              reference: dart:foo::<fragment>::@class::A::@field::foo
              element: dart:foo::<fragment>::@class::A::@field::foo#element
              setter2: dart:foo::<fragment>::@class::A::@setter::foo
          setters
            set foo @57
              reference: dart:foo::<fragment>::@class::A::@setter::foo
              element: dart:foo::<fragment>::@class::A::@setter::foo#element
              sinceSdkVersion: 2.15.0
              formalParameters
                _ @65
                  element: dart:foo::<fragment>::@class::A::@setter::foo::@parameter::_#element
  classes
    class A
      reference: dart:foo::@class::A
      firstFragment: dart:foo::<fragment>::@class::A
      sinceSdkVersion: 2.15.0
      fields
        synthetic foo
          firstFragment: dart:foo::<fragment>::@class::A::@field::foo
          type: int
          setter: dart:foo::<fragment>::@class::A::@setter::foo#element
      setters
        set foo
          firstFragment: dart:foo::<fragment>::@class::A::@setter::foo
          formalParameters
            requiredPositional _
              type: int
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
      enclosingElement3: <null>
      enums
        enum E @31
          reference: dart:foo::<fragment>::@enum::E
          enclosingElement3: dart:foo::<fragment>
          supertype: Enum
          fields
            static const enumConstant v1 @37
              reference: dart:foo::<fragment>::@enum::E::@field::v1
              enclosingElement3: dart:foo::<fragment>::@enum::E
              type: E
              shouldUseTypeForInitializerInference: false
            static const enumConstant v2 @60
              reference: dart:foo::<fragment>::@enum::E::@field::v2
              enclosingElement3: dart:foo::<fragment>::@enum::E
              sinceSdkVersion: 2.15.0
              type: E
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: dart:foo::<fragment>::@enum::E::@field::values
              enclosingElement3: dart:foo::<fragment>::@enum::E
              type: List<E>
          accessors
            synthetic static get v1 @-1
              reference: dart:foo::<fragment>::@enum::E::@getter::v1
              enclosingElement3: dart:foo::<fragment>::@enum::E
              returnType: E
            synthetic static get v2 @-1
              reference: dart:foo::<fragment>::@enum::E::@getter::v2
              enclosingElement3: dart:foo::<fragment>::@enum::E
              sinceSdkVersion: 2.15.0
              returnType: E
            synthetic static get values @-1
              reference: dart:foo::<fragment>::@enum::E::@getter::values
              enclosingElement3: dart:foo::<fragment>::@enum::E
              returnType: List<E>
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      element: dart:foo
      enums
        enum E @31
          reference: dart:foo::<fragment>::@enum::E
          element: dart:foo::@enum::E
          fields
            hasInitializer v1 @37
              reference: dart:foo::<fragment>::@enum::E::@field::v1
              element: dart:foo::<fragment>::@enum::E::@field::v1#element
              getter2: dart:foo::<fragment>::@enum::E::@getter::v1
            hasInitializer v2 @60
              reference: dart:foo::<fragment>::@enum::E::@field::v2
              element: dart:foo::<fragment>::@enum::E::@field::v2#element
              getter2: dart:foo::<fragment>::@enum::E::@getter::v2
            synthetic values
              reference: dart:foo::<fragment>::@enum::E::@field::values
              element: dart:foo::<fragment>::@enum::E::@field::values#element
              getter2: dart:foo::<fragment>::@enum::E::@getter::values
          getters
            synthetic get v1
              reference: dart:foo::<fragment>::@enum::E::@getter::v1
              element: dart:foo::<fragment>::@enum::E::@getter::v1#element
            synthetic get v2
              reference: dart:foo::<fragment>::@enum::E::@getter::v2
              element: dart:foo::<fragment>::@enum::E::@getter::v2#element
              sinceSdkVersion: 2.15.0
            synthetic get values
              reference: dart:foo::<fragment>::@enum::E::@getter::values
              element: dart:foo::<fragment>::@enum::E::@getter::values#element
  enums
    enum E
      reference: dart:foo::@enum::E
      firstFragment: dart:foo::<fragment>::@enum::E
      supertype: Enum
      fields
        static const enumConstant hasInitializer v1
          firstFragment: dart:foo::<fragment>::@enum::E::@field::v1
          type: E
          getter: dart:foo::<fragment>::@enum::E::@getter::v1#element
        static const enumConstant hasInitializer v2
          firstFragment: dart:foo::<fragment>::@enum::E::@field::v2
          type: E
          getter: dart:foo::<fragment>::@enum::E::@getter::v2#element
        synthetic static const values
          firstFragment: dart:foo::<fragment>::@enum::E::@field::values
          type: List<E>
          getter: dart:foo::<fragment>::@enum::E::@getter::values#element
      getters
        synthetic static get v1
          firstFragment: dart:foo::<fragment>::@enum::E::@getter::v1
        synthetic static get v2
          firstFragment: dart:foo::<fragment>::@enum::E::@getter::v2
        synthetic static get values
          firstFragment: dart:foo::<fragment>::@enum::E::@getter::values
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
      enclosingElement3: <null>
      enums
        enum E @46
          reference: dart:foo::<fragment>::@enum::E
          enclosingElement3: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          supertype: Enum
          fields
            static const enumConstant v @52
              reference: dart:foo::<fragment>::@enum::E::@field::v
              enclosingElement3: dart:foo::<fragment>::@enum::E
              sinceSdkVersion: 2.15.0
              type: E
              shouldUseTypeForInitializerInference: false
            synthetic static const values @-1
              reference: dart:foo::<fragment>::@enum::E::@field::values
              enclosingElement3: dart:foo::<fragment>::@enum::E
              type: List<E>
          accessors
            synthetic static get v @-1
              reference: dart:foo::<fragment>::@enum::E::@getter::v
              enclosingElement3: dart:foo::<fragment>::@enum::E
              sinceSdkVersion: 2.15.0
              returnType: E
            synthetic static get values @-1
              reference: dart:foo::<fragment>::@enum::E::@getter::values
              enclosingElement3: dart:foo::<fragment>::@enum::E
              returnType: List<E>
          methods
            foo @62
              reference: dart:foo::<fragment>::@enum::E::@method::foo
              enclosingElement3: dart:foo::<fragment>::@enum::E
              sinceSdkVersion: 2.15.0
              returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      element: dart:foo
      enums
        enum E @46
          reference: dart:foo::<fragment>::@enum::E
          element: dart:foo::@enum::E
          fields
            hasInitializer v @52
              reference: dart:foo::<fragment>::@enum::E::@field::v
              element: dart:foo::<fragment>::@enum::E::@field::v#element
              getter2: dart:foo::<fragment>::@enum::E::@getter::v
            synthetic values
              reference: dart:foo::<fragment>::@enum::E::@field::values
              element: dart:foo::<fragment>::@enum::E::@field::values#element
              getter2: dart:foo::<fragment>::@enum::E::@getter::values
          getters
            synthetic get v
              reference: dart:foo::<fragment>::@enum::E::@getter::v
              element: dart:foo::<fragment>::@enum::E::@getter::v#element
              sinceSdkVersion: 2.15.0
            synthetic get values
              reference: dart:foo::<fragment>::@enum::E::@getter::values
              element: dart:foo::<fragment>::@enum::E::@getter::values#element
          methods
            foo @62
              reference: dart:foo::<fragment>::@enum::E::@method::foo
              element: dart:foo::<fragment>::@enum::E::@method::foo#element
              sinceSdkVersion: 2.15.0
  enums
    enum E
      reference: dart:foo::@enum::E
      firstFragment: dart:foo::<fragment>::@enum::E
      sinceSdkVersion: 2.15.0
      supertype: Enum
      fields
        static const enumConstant hasInitializer v
          firstFragment: dart:foo::<fragment>::@enum::E::@field::v
          type: E
          getter: dart:foo::<fragment>::@enum::E::@getter::v#element
        synthetic static const values
          firstFragment: dart:foo::<fragment>::@enum::E::@field::values
          type: List<E>
          getter: dart:foo::<fragment>::@enum::E::@getter::values#element
      getters
        synthetic static get v
          firstFragment: dart:foo::<fragment>::@enum::E::@getter::v
        synthetic static get values
          firstFragment: dart:foo::<fragment>::@enum::E::@getter::values
      methods
        foo
          reference: dart:foo::@enum::E::@method::foo
          firstFragment: dart:foo::<fragment>::@enum::E::@method::foo
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
      enclosingElement3: <null>
      extensions
        E @51
          reference: dart:foo::<fragment>::@extension::E
          enclosingElement3: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          extendedType: int
          methods
            foo @69
              reference: dart:foo::<fragment>::@extension::E::@method::foo
              enclosingElement3: dart:foo::<fragment>::@extension::E
              sinceSdkVersion: 2.15.0
              returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      element: dart:foo
      extensions
        extension E @51
          reference: dart:foo::<fragment>::@extension::E
          element: dart:foo::@extension::E
          methods
            foo @69
              reference: dart:foo::<fragment>::@extension::E::@method::foo
              element: dart:foo::<fragment>::@extension::E::@method::foo#element
              sinceSdkVersion: 2.15.0
  extensions
    extension E
      reference: dart:foo::@extension::E
      firstFragment: dart:foo::<fragment>::@extension::E
      sinceSdkVersion: 2.15.0
      methods
        foo
          reference: dart:foo::@extension::E::@method::foo
          firstFragment: dart:foo::<fragment>::@extension::E::@method::foo
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
      enclosingElement3: <null>
      mixins
        mixin M @47
          reference: dart:foo::<fragment>::@mixin::M
          enclosingElement3: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          superclassConstraints
            Object
          methods
            foo @58
              reference: dart:foo::<fragment>::@mixin::M::@method::foo
              enclosingElement3: dart:foo::<fragment>::@mixin::M
              sinceSdkVersion: 2.15.0
              returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      element: dart:foo
      mixins
        mixin M @47
          reference: dart:foo::<fragment>::@mixin::M
          element: dart:foo::@mixin::M
          methods
            foo @58
              reference: dart:foo::<fragment>::@mixin::M::@method::foo
              element: dart:foo::<fragment>::@mixin::M::@method::foo#element
              sinceSdkVersion: 2.15.0
  mixins
    mixin M
      reference: dart:foo::@mixin::M
      firstFragment: dart:foo::<fragment>::@mixin::M
      sinceSdkVersion: 2.15.0
      superclassConstraints
        Object
      methods
        foo
          reference: dart:foo::@mixin::M::@method::foo
          firstFragment: dart:foo::<fragment>::@mixin::M::@method::foo
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
      enclosingElement3: <null>
      functions
        foo @46
          reference: dart:foo::<fragment>::@function::foo
          enclosingElement3: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          returnType: void
        bar @61
          reference: dart:foo::<fragment>::@function::bar
          enclosingElement3: dart:foo::<fragment>
          returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      element: dart:foo
      functions
        foo @46
          reference: dart:foo::<fragment>::@function::foo
          element: dart:foo::@function::foo
          sinceSdkVersion: 2.15.0
        bar @61
          reference: dart:foo::<fragment>::@function::bar
          element: dart:foo::@function::bar
  functions
    foo
      reference: dart:foo::@function::foo
      firstFragment: dart:foo::<fragment>::@function::foo
      returnType: void
    bar
      reference: dart:foo::@function::bar
      firstFragment: dart:foo::<fragment>::@function::bar
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement3: <null>
      functions
        foo @54
          reference: dart:foo::<fragment>::@function::foo
          enclosingElement3: dart:foo::<fragment>
          sinceSdkVersion: 2.15.3-dev.7
          returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      element: dart:foo
      functions
        foo @54
          reference: dart:foo::<fragment>::@function::foo
          element: dart:foo::@function::foo
          sinceSdkVersion: 2.15.3-dev.7
  functions
    foo
      reference: dart:foo::@function::foo
      firstFragment: dart:foo::<fragment>::@function::foo
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement3: <null>
      functions
        foo @48
          reference: dart:foo::<fragment>::@function::foo
          enclosingElement3: dart:foo::<fragment>
          sinceSdkVersion: 2.15.3
          returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      element: dart:foo
      functions
        foo @48
          reference: dart:foo::<fragment>::@function::foo
          element: dart:foo::@function::foo
          sinceSdkVersion: 2.15.3
  functions
    foo
      reference: dart:foo::@function::foo
      firstFragment: dart:foo::<fragment>::@function::foo
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement3: <null>
      functions
        foo @44
          reference: dart:foo::<fragment>::@function::foo
          enclosingElement3: dart:foo::<fragment>
          returnType: void
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      element: dart:foo
      functions
        foo @44
          reference: dart:foo::<fragment>::@function::foo
          element: dart:foo::@function::foo
  functions
    foo
      reference: dart:foo::@function::foo
      firstFragment: dart:foo::<fragment>::@function::foo
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement3: <null>
      functions
        foo @56
          reference: dart:foo::<fragment>::@function::foo
          enclosingElement3: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          returnType: void
----------------------------------------
library
  reference: dart:foo
  sinceSdkVersion: 2.15.0
  fragments
    dart:foo::<fragment>
      element: dart:foo
      functions
        foo @56
          reference: dart:foo::<fragment>::@function::foo
          element: dart:foo::@function::foo
          sinceSdkVersion: 2.15.0
  functions
    foo
      reference: dart:foo::@function::foo
      firstFragment: dart:foo::<fragment>::@function::foo
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement3: <null>
      functions
        f @31
          reference: dart:foo::<fragment>::@function::f
          enclosingElement3: dart:foo::<fragment>
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
      element: dart:foo
      functions
        f @31
          reference: dart:foo::<fragment>::@function::f
          element: dart:foo::@function::f
          formalParameters
            p1 @37
              element: dart:foo::<fragment>::@function::f::@parameter::p1#element
            default p2 @67
              reference: dart:foo::<fragment>::@function::f::@parameter::p2
              element: dart:foo::<fragment>::@function::f::@parameter::p2#element
              sinceSdkVersion: 2.15.0
  functions
    f
      reference: dart:foo::@function::f
      firstFragment: dart:foo::<fragment>::@function::f
      formalParameters
        requiredPositional p1
          type: int
        optionalNamed p2
          firstFragment: dart:foo::<fragment>::@function::f::@parameter::p2
          type: int?
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement3: <null>
      functions
        f @31
          reference: dart:foo::<fragment>::@function::f
          enclosingElement3: dart:foo::<fragment>
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
      element: dart:foo
      functions
        f @31
          reference: dart:foo::<fragment>::@function::f
          element: dart:foo::@function::f
          formalParameters
            p1 @37
              element: dart:foo::<fragment>::@function::f::@parameter::p1#element
            default p2 @67
              element: dart:foo::<fragment>::@function::f::@parameter::p2#element
              sinceSdkVersion: 2.15.0
  functions
    f
      reference: dart:foo::@function::f
      firstFragment: dart:foo::<fragment>::@function::f
      formalParameters
        requiredPositional p1
          type: int
        optionalPositional p2
          type: int?
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement3: <null>
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
      element: dart:foo
      typeAliases
        A @49
          reference: dart:foo::<fragment>::@typeAlias::A
          element: dart:foo::@typeAlias::A
          sinceSdkVersion: 2.15.0
  typeAliases
    A
      firstFragment: dart:foo::<fragment>::@typeAlias::A
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
  definingUnit: dart:foo::<fragment>
  units
    dart:foo::<fragment>
      enclosingElement3: <null>
      topLevelVariables
        static final foo @47
          reference: dart:foo::<fragment>::@topLevelVariable::foo
          enclosingElement3: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          type: int
          shouldUseTypeForInitializerInference: false
      accessors
        synthetic static get foo @-1
          reference: dart:foo::<fragment>::@getter::foo
          enclosingElement3: dart:foo::<fragment>
          sinceSdkVersion: 2.15.0
          returnType: int
----------------------------------------
library
  reference: dart:foo
  fragments
    dart:foo::<fragment>
      element: dart:foo
      topLevelVariables
        hasInitializer foo @47
          reference: dart:foo::<fragment>::@topLevelVariable::foo
          element: dart:foo::@topLevelVariable::foo
          sinceSdkVersion: 2.15.0
          getter2: dart:foo::<fragment>::@getter::foo
      getters
        synthetic get foo
          reference: dart:foo::<fragment>::@getter::foo
          element: dart:foo::<fragment>::@getter::foo#element
          sinceSdkVersion: 2.15.0
  topLevelVariables
    final hasInitializer foo
      reference: dart:foo::@topLevelVariable::foo
      firstFragment: dart:foo::<fragment>::@topLevelVariable::foo
      type: int
      getter: dart:foo::<fragment>::@getter::foo#element
  getters
    synthetic static get foo
      firstFragment: dart:foo::<fragment>::@getter::foo
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
