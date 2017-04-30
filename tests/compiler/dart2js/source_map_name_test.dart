// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_map_name_test;

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/io/source_information.dart';
import 'memory_compiler.dart';

const String SOURCE = '''

var toplevelField;
void toplevelMethod() {}
void toplevelAnonymous() {
  var foo = () {};
}
void toplevelLocal() {
  void localMethod() {}
}

class Class {
  Class() {
    var foo = () {};
  }
  Class.named() {
    void localMethod() {}
  }
  static var staticField;
  static staticMethod() {}
  static void staticAnonymous() {
    var foo = () {};
  }
  static void staticLocal() {
    void localMethod() {}
  }
  var instanceField;
  instanceMethod() {}
  void instanceAnonymous() {
    var foo = () {};
  }
  void instanceLocal() {
    void localMethod() {}
  }
  void instanceNestedLocal() {
    void localMethod() {
      var foo = () {};
      void nestedLocalMethod() {}
    }
  }
}

main() {
  toplevelField = toplevelMethod();
  toplevelAnonymous();
  toplevelLocal();

  Class.staticField = Class.staticMethod;
  Class.staticAnonymous();
  Class.staticLocal();

  var c = new Class();
  c = new Class.named();
  c.instanceField = c.instanceMethod();
  c.instanceAnonymous();
  c.instanceLocal();
  c.instanceNestedLocal();
}
''';

check(Element element, String expectedName) {
  String name = computeElementNameForSourceMaps(element);
  Expect.equals(expectedName, name,
      "Unexpected name '$name' for $element, expected '$expectedName'.");
}

main() {
  asyncTest(() async {
    CompilationResult result =
        await runCompiler(memorySourceFiles: {'main.dart': SOURCE});
    Compiler compiler = result.compiler;
    LibraryElement mainApp = compiler.mainApp;

    Element lookup(String name) {
      Element element;
      int dotPosition = name.indexOf('.');
      if (dotPosition != -1) {
        String clsName = name.substring(0, dotPosition);
        ClassElement cls = mainApp.find(clsName);
        Expect.isNotNull(cls, "Class '$clsName' not found.");
        element = cls.localLookup(name.substring(dotPosition + 1));
      } else {
        element = mainApp.find(name);
      }
      Expect.isNotNull(element, "Element '$name' not found.");
      return element;
    }

    void checkName(String expectedName,
        [List<String> expectedClosureNames, String lookupName]) {
      if (lookupName == null) {
        lookupName = expectedName;
      }
      var element = lookup(lookupName);
      check(element, expectedName);
      if (element.isConstructor) {
        var constructorBody =
            element.enclosingClass.lookupBackendMember(element.name);
        Expect.isNotNull(
            element, "Constructor body '${element.name}' not found.");
        check(constructorBody, expectedName);
      }

      if (expectedClosureNames != null) {
        int index = 0;
        for (var closure in element.nestedClosures) {
          String expectedName = expectedClosureNames[index];
          check(closure, expectedName);
          check(closure.expression, expectedName);
          check(closure.enclosingClass, expectedName);
          index++;
        }
      }
    }

    checkName('toplevelField');
    checkName('toplevelMethod');
    checkName('toplevelAnonymous', ['toplevelAnonymous.<anonymous function>']);
    checkName('toplevelLocal', ['toplevelLocal.localMethod']);
    checkName('Class');
    checkName('main');

    checkName('Class.staticField');
    checkName('Class.staticMethod');
    checkName('Class.staticAnonymous',
        ['Class.staticAnonymous.<anonymous function>']);
    checkName('Class.staticLocal', ['Class.staticLocal.localMethod']);

    checkName('Class', ['Class.<anonymous function>'], 'Class.');
    checkName('Class.named', ['Class.named.localMethod']);

    checkName('Class.instanceField');
    checkName('Class.instanceMethod');
    checkName('Class.instanceAnonymous',
        ['Class.instanceAnonymous.<anonymous function>']);
    checkName('Class.instanceLocal', ['Class.instanceLocal.localMethod']);
    checkName('Class.instanceNestedLocal', [
      'Class.instanceNestedLocal.localMethod',
      'Class.instanceNestedLocal.localMethod.<anonymous function>',
      'Class.instanceNestedLocal.localMethod.nestedLocalMethod'
    ]);
  });
}
