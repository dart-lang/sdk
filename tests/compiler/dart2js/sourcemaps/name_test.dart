// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library source_map_name_test;

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common_elements.dart' show JElementEnvironment;
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/io/kernel_source_information.dart';
import 'package:compiler/src/js_model/js_world.dart';
import '../helpers/memory_compiler.dart';

const String SOURCE = '''

var toplevelField;
toplevelMethod() {}
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

main() {
  asyncTest(() async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': SOURCE},
        options: [Flags.disableInlining]);
    Compiler compiler = result.compiler;
    JsClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
    JElementEnvironment env = closedWorld.elementEnvironment;
    LibraryEntity mainApp = env.mainLibrary;

    check(MemberEntity element, String expectedName) {
      String name = computeKernelElementNameForSourceMaps(
          closedWorld.elementMap, element);
      Expect.equals(expectedName, name,
          "Unexpected name '$name' for $element, expected '$expectedName'.");
    }

    MemberEntity lookup(String name) {
      MemberEntity element;
      int dotPosition = name.indexOf('.');
      if (dotPosition != -1) {
        String clsName = name.substring(0, dotPosition);
        ClassEntity cls = env.lookupClass(mainApp, clsName);
        Expect.isNotNull(cls, "Class '$clsName' not found.");
        var subname = name.substring(dotPosition + 1);
        element = env.lookupLocalClassMember(cls, subname) ??
            env.lookupConstructor(cls, subname);
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
          index++;
        });
      }
    }

    checkName('toplevelField');
    checkName('toplevelMethod');
    checkName('toplevelAnonymous', ['toplevelAnonymous.<anonymous function>']);
    checkName('toplevelLocal', ['toplevelLocal.localMethod']);
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
