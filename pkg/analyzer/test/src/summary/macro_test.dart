// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'element_text.dart';
import 'elements_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MacroElementsKeepLinkingTest);
    defineReflectiveTests(MacroElementsFromBytesTest);
  });
}

@reflectiveTest
class MacroElementsFromBytesTest extends MacroElementsTest {
  @override
  bool get keepLinkingLibraries => false;
}

@reflectiveTest
class MacroElementsKeepLinkingTest extends MacroElementsTest {
  @override
  bool get keepLinkingLibraries => true;
}

class MacroElementsTest extends ElementsBaseTest {
  @override
  bool get keepLinkingLibraries => false;

  test_class_macro() async {
    var library = await buildLibrary(r'''
macro class A {}
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      macro class A @12
        constructors
          synthetic @-1
''');
  }

  test_classAlias_macro() async {
    var library = await buildLibrary(r'''
mixin M {}
macro class A = Object with M;
''');
    checkElementText(library, r'''
library
  definingUnit
    classes
      macro class alias A @23
        supertype: Object
        mixins
          M
        constructors
          synthetic const @-1
            constantInitializers
              SuperConstructorInvocation
                superKeyword: super @0
                argumentList: ArgumentList
                  leftParenthesis: ( @0
                  rightParenthesis: ) @0
                staticElement: dart:core::@class::Object::@constructor::•
    mixins
      mixin M @6
        superclassConstraints
          Object
''');
  }
}
