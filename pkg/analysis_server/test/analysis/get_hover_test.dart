// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.analysis.hover;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import '../analysis_abstract.dart';
import '../reflective_tests.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(AnalysisHoverTest);
}


@ReflectiveTestCase()
class AnalysisHoverTest extends AbstractAnalysisTest {
  Future<HoverInformation> prepareHover(String search) {
    int offset = findOffset(search);
    return prepareHoverAt(offset);
  }

  Future<HoverInformation> prepareHoverAt(int offset) {
    return waitForTasksFinished().then((_) {
      Request request =
          new AnalysisGetHoverParams(testFile, offset).toRequest('0');
      Response response = handleSuccessfulRequest(request);
      var result = new AnalysisGetHoverResult.fromResponse(response);
      List<HoverInformation> hovers = result.hovers;
      return hovers.isNotEmpty ? hovers.first : null;
    });
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
  }

  test_dartdoc_clunky() {
    addTestFile('''
library my.library;
/**
 * doc aaa
 * doc bbb
 */
main() {
}
''');
    return prepareHover('main() {').then((HoverInformation hover) {
      expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    });
  }

  test_dartdoc_elegant() {
    addTestFile('''
library my.library;
/// doc aaa
/// doc bbb
main() {
}
''');
    return prepareHover('main() {').then((HoverInformation hover) {
      expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
    });
  }

  test_expression_function() {
    addTestFile('''
library my.library;
/// doc aaa
/// doc bbb
List<String> fff(int a, String b) {
}
''');
    return prepareHover('fff(int a').then((HoverInformation hover) {
      // element
      expect(hover.containingLibraryName, 'my.library');
      expect(hover.containingLibraryPath, testFile);
      expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
      expect(hover.elementDescription, 'fff(int a, String b) → List<String>');
      expect(hover.elementKind, 'function');
      // types
      expect(hover.staticType, '(int, String) → List<String>');
      expect(hover.propagatedType, isNull);
      // no parameter
      expect(hover.parameter, isNull);
    });
  }

  test_expression_literal_noElement() {
    addTestFile('''
main() {
  foo(123);
}
foo(Object myParameter) {}
''');
    return prepareHover('123').then((HoverInformation hover) {
      // literal, no Element
      expect(hover.elementDescription, isNull);
      expect(hover.elementKind, isNull);
      // types
      expect(hover.staticType, 'int');
      expect(hover.propagatedType, isNull);
      // parameter
      expect(hover.parameter, 'Object myParameter');
    });
  }

  test_expression_method() {
    addTestFile('''
library my.library;
class A {
  /// doc aaa
  /// doc bbb
  List<String> mmm(int a, String b) {
  }
}
''');
    return prepareHover('mmm(int a').then((HoverInformation hover) {
      // element
      expect(hover.containingLibraryName, 'my.library');
      expect(hover.containingLibraryPath, testFile);
      expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
      expect(hover.elementDescription, 'A.mmm(int a, String b) → List<String>');
      expect(hover.elementKind, 'method');
      // types
      expect(hover.staticType, '(int, String) → List<String>');
      expect(hover.propagatedType, isNull);
      // no parameter
      expect(hover.parameter, isNull);
    });
  }

  test_expression_method_invocation() {
    addTestFile('''
library my.library;
class A {
  List<String> mmm(int a, String b) {
  }
}
main(A a) {
  a.mmm(42, 'foo');
}
''');
    return prepareHover('mm(42, ').then((HoverInformation hover) {
      // range
      expect(hover.offset, findOffset('mmm(42, '));
      expect(hover.length, 'mmm'.length);
      // element
      expect(hover.containingLibraryName, 'my.library');
      expect(hover.containingLibraryPath, testFile);
      expect(hover.elementDescription, 'A.mmm(int a, String b) → List<String>');
      expect(hover.elementKind, 'method');
      // types
      expect(hover.staticType, isNull);
      expect(hover.propagatedType, isNull);
      // no parameter
      expect(hover.parameter, isNull);
    });
  }

  test_expression_syntheticGetter() {
    addTestFile('''
library my.library;
class A {
  /// doc aaa
  /// doc bbb
  String fff;
}
main(A a) {
  print(a.fff);
}
''');
    return prepareHover('fff);').then((HoverInformation hover) {
      // element
      expect(hover.containingLibraryName, 'my.library');
      expect(hover.containingLibraryPath, testFile);
      expect(hover.dartdoc, '''doc aaa\ndoc bbb''');
      expect(hover.elementDescription, 'String fff');
      expect(hover.elementKind, 'field');
      // types
      expect(hover.staticType, 'String');
      expect(hover.propagatedType, isNull);
    });
  }

  test_expression_variable_hasPropagatedType() {
    addTestFile('''
library my.library;
main() {
  var vvv = 123;
  print(vvv);
}
''');
    return prepareHover('vvv);').then((HoverInformation hover) {
      // element
      expect(hover.containingLibraryName, 'my.library');
      expect(hover.containingLibraryPath, testFile);
      expect(hover.dartdoc, isNull);
      expect(hover.elementDescription, 'dynamic vvv');
      expect(hover.elementKind, 'local variable');
      // types
      expect(hover.staticType, 'dynamic');
      expect(hover.propagatedType, 'int');
    });
  }

  test_instanceCreation_implicit() {
    addTestFile('''
library my.library;
class A {
}
main() {
  new A();
}
''');
    return prepareHover('new A').then((HoverInformation hover) {
      // range
      expect(hover.offset, findOffset('new A'));
      expect(hover.length, 'new A()'.length);
      // element
      expect(hover.containingLibraryName, 'my.library');
      expect(hover.containingLibraryPath, testFile);
      expect(hover.dartdoc, isNull);
      expect(hover.elementDescription, 'A() → A');
      expect(hover.elementKind, 'constructor');
      // types
      expect(hover.staticType, 'A');
      expect(hover.propagatedType, isNull);
      // no parameter
      expect(hover.parameter, isNull);
    });
  }

  test_instanceCreation_implicit_withTypeArgument() {
    addTestFile('''
library my.library;
class A<T> {}
main() {
  new A<String>();
}
''');
    Function onConstructor = (HoverInformation hover) {
      // range
      expect(hover.offset, findOffset('new A<String>'));
      expect(hover.length, 'new A<String>()'.length);
      // element
      expect(hover.containingLibraryName, 'my.library');
      expect(hover.containingLibraryPath, testFile);
      expect(hover.dartdoc, isNull);
      expect(hover.elementDescription, 'A() → A<String>');
      expect(hover.elementKind, 'constructor');
      // types
      expect(hover.staticType, 'A<String>');
      expect(hover.propagatedType, isNull);
      // no parameter
      expect(hover.parameter, isNull);
    };
    var futureNewA = prepareHover('new A').then(onConstructor);
    var futureA = prepareHover('A<String>()').then(onConstructor);
    var futureString = prepareHover('String>').then((HoverInformation hover) {
      expect(hover.offset, findOffset('String>'));
      expect(hover.length, 'String'.length);
      expect(hover.elementKind, 'class');
    });
    return Future.wait([futureNewA, futureA, futureString]);
  }

  test_instanceCreation_named() {
    addTestFile('''
library my.library;
class A {
  /// my doc
  A.named() {}
}
main() {
  new A.named();
}
''');
    var onConstructor = (HoverInformation hover) {
      // range
      expect(hover.offset, findOffset('new A'));
      expect(hover.length, 'new A.named()'.length);
      // element
      expect(hover.dartdoc, 'my doc');
      expect(hover.elementDescription, 'A.named() → A');
      expect(hover.elementKind, 'constructor');
    };
    var futureCreation = prepareHover('new A').then(onConstructor);
    var futureName = prepareHover('named();').then(onConstructor);
    return Future.wait([futureCreation, futureName]);
  }

  test_noHoverInfo() {
    addTestFile('''
library my.library;
main() {
  // nothing
}
''');
    return prepareHover('nothing').then((HoverInformation hover) {
      expect(hover, isNull);
    });
  }
}
