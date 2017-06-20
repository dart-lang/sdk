// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library related_types.test;

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/messages.dart';
import 'package:compiler/src/elements/elements.dart';
import 'memory_compiler.dart';

import 'related_types.dart';

const String CODE = '''
Map<String, int> topLevelMap;
List<String> topLevelList;

Map<String, int> getTopLevelMap() => null;
List<String> getTopLevelList() => null;

class Class {
  Map<String, int> instanceMap;
  List<String> instanceList;

  Map<String, int> getInstanceMap() => null;
  List<String> getInstanceList() => null;

  static Map<String, int> staticMap;
  static List<String> staticList;

  static Map<String, int> getStaticMap() => null;
  static List<String> getStaticList() => null;
  
  test_instanceMapIndex() {
    instanceMap[0];
  }
  test_instanceMapContainsKey() {
    instanceMap.containsKey(0);
  }
  test_instanceMapContainsValue() {
    instanceMap.containsValue('');
  }
  test_instanceMapRemove() {
    instanceMap.remove(0);
  }
  test_instanceListContains() {
    instanceList.contains(0);
  }
  test_instanceListRemove() {
    instanceList.remove(0);
  }
  
  test_getInstanceMapIndex() {
    getInstanceMap()[0];
  }
  test_getInstanceMapContainsKey() {
    getInstanceMap().containsKey(0);
  }
  test_getInstanceMapContainsValue() {
    getInstanceMap().containsValue('');
  }
  test_getInstanceMapRemove() {
    getInstanceMap().remove(0);
  }
  test_getInstanceListContains() {
    getInstanceList().contains(0);
  }
  test_getInstanceListRemove() {
    getInstanceList().remove(0);
  }
  
  static test_staticMapIndex() {
    staticMap[0];
  }
  static test_staticMapContainsKey() {
    staticMap.containsKey(0);
  }
  static test_staticMapContainsValue() {
    staticMap.containsValue('');
  }
  static test_staticMapRemove() {
    staticMap.remove(0);
  }
  static test_staticListContains() {
    staticList.contains(0);
  }
  static test_staticListRemove() {
    staticList.remove(0);
  }
  
  static test_getStaticMapIndex() {
    getStaticMap()[0];
  }
  static test_getStaticMapContainsKey() {
    getStaticMap().containsKey(0);
  }
  static test_getStaticMapContainsValue() {
    getStaticMap().containsValue('');
  }
  static test_getStaticMapRemove() {
    getStaticMap().remove(0);
  }
  static test_getStaticListContains() {
    getStaticList().contains(0);
  }
  static test_getStaticListRemove() {
    getStaticList().remove(0);
  }
}

main() {}

test_equals() => 0 == '';
test_notEquals() => 0 != '';
test_index() => <String, int>{}[0];

test_localMapIndex() {
  Map<String, int> map;
  map[0];
}
test_localMapContainsKey() {
  Map<String, int> map;
  map.containsKey(0);
}
test_localMapContainsValue() {
  Map<String, int> map;
  map.containsValue('');
}
test_localMapRemove() {
  Map<String, int> map;
  map.remove(0);
}
test_localListContains() {
  List<String> list;
  list.contains(0);
}
test_localListRemove() {
  List<String> list;
  list.remove(0);
}

test_topLevelMapIndex() {
  topLevelMap[0];
}
test_topLevelMapContainsKey() {
  topLevelMap.containsKey(0);
}
test_topLevelMapContainsValue() {
  topLevelMap.containsValue('');
}
test_topLevelMapRemove() {
  topLevelMap.remove(0);
}
test_topLevelListContains() {
  topLevelList.contains(0);
}
test_topLevelListRemove() {
  topLevelList.remove(0);
}

test_getTopLevelMapIndex() {
  getTopLevelMap()[0];
}
test_getTopLevelMapContainsKey() {
  getTopLevelMap().containsKey(0);
}
test_getTopLevelMapContainsValue() {
  getTopLevelMap().containsValue('');
}
test_getTopLevelMapRemove() {
  getTopLevelMap().remove(0);
}
test_getTopLevelListContains() {
  getTopLevelList().contains(0);
}
test_getTopLevelListRemove() {
  getTopLevelList().remove(0);
}

test_staticMapIndex() {
  Class.staticMap[0];
}
test_staticMapContainsKey() {
  Class.staticMap.containsKey(0);
}
test_staticMapContainsValue() {
  Class.staticMap.containsValue('');
}
test_staticMapRemove() {
  Class.staticMap.remove(0);
}
test_staticListContains() {
  Class.staticList.contains(0);
}
test_staticListRemove() {
  Class.staticList.remove(0);
}

test_getStaticMapIndex() {
  Class.getStaticMap()[0];
}
test_getStaticMapContainsKey() {
  Class.getStaticMap().containsKey(0);
}
test_getStaticMapContainsValue() {
  Class.getStaticMap().containsValue('');
}
test_getStaticMapRemove() {
  Class.getStaticMap().remove(0);
}
test_getStaticListContains() {
  Class.getStaticList().contains(0);
}
test_getStaticListRemove() {
  Class.getStaticList().remove(0);
}
  
test_instanceMapIndex(Class c) {
  c.instanceMap[0];
}
test_instanceMapContainsKey(Class c) {
  c.instanceMap.containsKey(0);
}
test_instanceMapContainsValue(Class c) {
  c.instanceMap.containsValue('');
}
test_instanceMapRemove(Class c) {
  c.instanceMap.remove(0);
}
test_instanceListContains(Class c) {
  c.instanceList.contains(0);
}
test_instanceListRemove(Class c) {
  c.instanceList.remove(0);
}

test_getInstanceMapIndex(Class c) {
  c.getInstanceMap()[0];
}
test_getInstanceMapContainsKey(Class c) {
  c.getInstanceMap().containsKey(0);
}
test_getInstanceMapContainsValue(Class c) {
  c.getInstanceMap().containsValue('');
}
test_getInstanceMapRemove(Class c) {
  c.getInstanceMap().remove(0);
}
test_getInstanceListContains(Class c) {
  c.getInstanceList().contains(0);
}
test_getInstanceListRemove(Class c) {
  c.getInstanceList().remove(0);
}
''';

main(List<String> arguments) {
  asyncTest(() async {
    DiagnosticCollector collector = new DiagnosticCollector();
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': CODE},
        options: [Flags.analyzeOnly, Flags.analyzeMain],
        diagnosticHandler: collector);
    Expect.isFalse(
        collector.hasRegularMessages, "Unexpected analysis messages.");
    Compiler compiler = result.compiler;
    ElementEnvironment elementEnvironment =
        compiler.frontendStrategy.elementEnvironment;
    compiler.closeResolution(elementEnvironment.mainFunction);

    void checkMember(Element element) {
      MemberElement member = element;
      if (!member.name.startsWith('test_')) return;

      collector.clear();
      checkMemberElement(compiler, member);
      Expect.equals(
          1, collector.hints.length, "Unexpected hint count for $member.");
      Expect.equals(
          MessageKind.NO_COMMON_SUBTYPES,
          collector.hints.first.message.kind,
          "Unexpected message kind ${collector.hints.first.message.kind} "
          "for $member.");
    }

    LibraryElement mainApp = elementEnvironment.mainLibrary;
    mainApp.forEachLocalMember((Element element) {
      if (element.isClass) {
        ClassElement cls = element;
        cls.forEachLocalMember(checkMember);
      } else {
        checkMember(element);
      }
    });
  });
}
