// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_map_name_test;

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/io/source_information.dart';
import '../memory_compiler.dart';

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

check(Entity element, String expectedName) {
  String name = computeElementNameForSourceMaps(element);
  Expect.equals(expectedName, name,
      "Unexpected name '$name' for $element, expected '$expectedName'.");
}

main() {
  asyncTest(() async {
    CompilationResult result =
        await runCompiler(memorySourceFiles: {'main.dart': SOURCE});
    Compiler compiler = result.compiler;
    var env = compiler.backendClosedWorldForTesting.elementEnvironment;
    LibraryEntity mainApp = env.mainLibrary;

    Entity lookup(String name) {
      Entity element;
      int dotPosition = name.indexOf('.');
      if (dotPosition != -1) {
        String clsName = name.substring(0, dotPosition);
        ClassEntity cls = env.lookupClass(mainApp, clsName);
        Expect.isNotNull(cls, "Class '$clsName' not found.");
        var subname = name.substring(dotPosition + 1);
        element = env.lookupLocalClassMember(cls, subname) ??
            env.lookupConstructor(cls, subname);
      } else if (name.substring(0, 1) == name.substring(0, 1).toUpperCase()) {
        element = env.lookupClass(mainApp, name);
      } else {
        element = env.lookupLibraryMember(mainApp, name);
      }
      Expect.isNotNull(element, "Element '$name' not found.");
      return element;
    }

    void checkName(String expectedName,
        [List<String> expectedClosureNames, String lookupName]) {
      if (lookupName == null) {
        lookupName = expectedName;
      }
      dynamic element = lookup(lookupName);
      check(element, expectedName);
      if (element is ConstructorEntity) {
        env.forEachConstructorBody(element.enclosingClass, (body) {
          if (body.name != element.name) return;
          Expect.isNotNull(
              body, "Constructor body '${element.name}' not found.");
          check(body, expectedName);
        });
      }

      if (expectedClosureNames != null) {
        int index = 0;
        env.forEachNestedClosure(element, (closure) {
          String expectedName = expectedClosureNames[index];
          check(closure, expectedName);
          check(closure.enclosingClass, expectedName);
          index++;
        });
      }
    }

    checkName('toplevelField');
    checkName('toplevelMethod');
    // TODO(johnniwinther): improve closure names.
    checkName('toplevelAnonymous', ['toplevelAnonymous_closure']);
    checkName('toplevelLocal', ['toplevelLocal_localMethod']);
    checkName('Class');
    checkName('main');

    checkName('Class.staticField');
    checkName('Class.staticMethod');
    checkName('Class.staticAnonymous', ['Class_staticAnonymous_closure']);
    checkName('Class.staticLocal', ['Class_staticLocal_localMethod']);

    checkName('Class', ['Class_closure'], 'Class.');
    checkName('Class.named', ['Class\$named_localMethod']);

    checkName('Class.instanceField');
    checkName('Class.instanceMethod');
    checkName('Class.instanceAnonymous', ['Class_instanceAnonymous_closure']);
    checkName('Class.instanceLocal', ['Class_instanceLocal_localMethod']);
    checkName('Class.instanceNestedLocal', [
      'Class_instanceNestedLocal_localMethod',
      'Class_instanceNestedLocal_localMethod_closure',
      'Class_instanceNestedLocal_localMethod_nestedLocalMethod'
    ]);
  });
}
