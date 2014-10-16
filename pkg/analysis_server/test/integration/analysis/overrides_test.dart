// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.integration.analysis.overrides;

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../integration_tests.dart';

@ReflectiveTestCase()
class Test extends AbstractAnalysisServerIntegrationTest {
  test_overrides() {
    String pathname = sourcePath('test.dart');
    String text =
        r'''
abstract class Interface1 {
  method0();
  method1();
  method2();
  method3();
}

abstract class Interface2 {
  method0();
  method1();
  method4();
  method5();
}

abstract class Base {
  method0();
  method2();
  method4();
  method6();
}

class Target extends Base implements Interface1, Interface2 {
  method0() {}
  method1() {}
  method2() {}
  method3() {}
  method4() {}
  method5() {}
  method6() {}
  method7() {}
}
''';
    writeFile(pathname, text);
    standardAnalysisSetup();
    sendAnalysisSetSubscriptions({
      AnalysisService.OVERRIDES: [pathname]
    });
    List<Override> overrides;
    onAnalysisOverrides.listen((AnalysisOverridesParams params) {
      expect(params.file, equals(pathname));
      overrides = params.overrides;
    });
    return analysisFinished.then((_) {
      int targetOffset = text.indexOf('Target');
      Override findOverride(String methodName) {
        int methodOffset = text.indexOf(methodName, targetOffset);
        for (Override override in overrides) {
          if (override.offset == methodOffset) {
            return override;
          }
        }
        return null;
      }
      void checkOverrides(String methodName, bool
          expectedOverridesBase, List<String> expectedOverridesInterfaces) {
        Override override = findOverride(methodName);
        if (!expectedOverridesBase && expectedOverridesInterfaces.isEmpty) {
          // This method overrides nothing, so it should not appear in the
          // overrides list.
          expect(override, isNull);
          return;
        } else {
          expect(override, isNotNull);
        }
        expect(override.length, equals(methodName.length));
        OverriddenMember superclassMember = override.superclassMember;
        if (expectedOverridesBase) {
          expect(superclassMember.element.name, equals(methodName));
          expect(superclassMember.className, equals('Base'));
        } else {
          expect(superclassMember, isNull);
        }
        List<OverriddenMember> interfaceMembers = override.interfaceMembers;
        if (expectedOverridesInterfaces.isNotEmpty) {
          expect(interfaceMembers, isNotNull);
          Set<String> actualOverridesInterfaces = new Set<String>();
          for (OverriddenMember overriddenMember in interfaceMembers) {
            expect(overriddenMember.element.name, equals(methodName));
            String className = overriddenMember.className;
            bool wasAdded = actualOverridesInterfaces.add(className);
            expect(wasAdded, isTrue);
          }
          expect(actualOverridesInterfaces, equals(
              expectedOverridesInterfaces.toSet()));
        } else {
          expect(interfaceMembers, isNull);
        }
      }
      checkOverrides('method0', true, ['Interface1', 'Interface2']);
      checkOverrides('method1', false, ['Interface1', 'Interface2']);
      checkOverrides('method2', true, ['Interface1']);
      checkOverrides('method3', false, ['Interface1']);
      checkOverrides('method4', true, ['Interface2']);
      checkOverrides('method5', false, ['Interface2']);
      checkOverrides('method6', true, []);
      checkOverrides('method7', false, []);
    });
  }
}

main() {
  runReflectiveTests(Test);
}
