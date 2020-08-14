// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';

enum Kind {
  regular,
  native,
  jsInterop,
}

main() {
  asyncTest(() async {
    await runTest('tests/dart2js_2/jsinterop_test.dart', '', {
      'Class': Kind.regular,
      'JsInteropClass': Kind.jsInterop,
      'topLevelField': Kind.regular,
      'topLevelGetter': Kind.regular,
      'topLevelSetter': Kind.regular,
      'topLevelFunction': Kind.regular,
      'externalTopLevelGetter': Kind.jsInterop,
      'externalTopLevelSetter': Kind.jsInterop,
      'externalTopLevelFunction': Kind.jsInterop,
      'externalTopLevelJsInteropGetter': Kind.jsInterop,
      'externalTopLevelJsInteropSetter': Kind.jsInterop,
      'externalTopLevelJsInteropFunction': Kind.jsInterop,
      'Class.generative': Kind.regular,
      'Class.fact': Kind.regular,
      'Class.instanceField': Kind.regular,
      'Class.instanceGetter': Kind.regular,
      'Class.instanceSetter': Kind.regular,
      'Class.instanceMethod': Kind.regular,
      'Class.staticField': Kind.regular,
      'Class.staticGetter': Kind.regular,
      'Class.staticSetter': Kind.regular,
      'Class.staticMethod': Kind.regular,
      'JsInteropClass.externalGenerative': Kind.jsInterop,
      'JsInteropClass.externalFact': Kind.jsInterop,
      'JsInteropClass.externalJsInteropGenerative': Kind.jsInterop,
      'JsInteropClass.externalJsInteropFact': Kind.jsInterop,
      'JsInteropClass.externalInstanceGetter': Kind.jsInterop,
      'JsInteropClass.externalInstanceSetter': Kind.jsInterop,
      'JsInteropClass.externalInstanceMethod': Kind.jsInterop,
      'JsInteropClass.externalStaticGetter': Kind.jsInterop,
      'JsInteropClass.externalStaticSetter': Kind.jsInterop,
      'JsInteropClass.externalStaticMethod': Kind.jsInterop,
      'JsInteropClass.externalInstanceJsInteropGetter': Kind.jsInterop,
      'JsInteropClass.externalInstanceJsInteropSetter': Kind.jsInterop,
      'JsInteropClass.externalInstanceJsInteropMethod': Kind.jsInterop,
      'JsInteropClass.externalStaticJsInteropGetter': Kind.jsInterop,
      'JsInteropClass.externalStaticJsInteropSetter': Kind.jsInterop,
      'JsInteropClass.externalStaticJsInteropMethod': Kind.jsInterop,
    }, skipList: [
      // TODO(34174): Js-interop fields should not be allowed.
      '01',
      '02',
      '03',
      '04',
      '38',
      '42',
      '46',
      '51',
      // TODO(33834): Non-external constructors should not be allowed.
      '35',
      '37',
      // TODO(34345): Non-external static members should not be allowed.
      '43',
      '44',
      '45',
      '52',
      '53',
      '54',
    ]);
    await runTest('tests/dart2js_2/non_jsinterop_test.dart', '', {
      'Class': Kind.regular,
      'JsInteropClass': Kind.jsInterop,
      'topLevelField': Kind.regular,
      'topLevelGetter': Kind.regular,
      'topLevelSetter': Kind.regular,
      'topLevelFunction': Kind.regular,
      'externalTopLevelJsInteropGetter': Kind.jsInterop,
      'externalTopLevelJsInteropSetter': Kind.jsInterop,
      'externalTopLevelJsInteropFunction': Kind.jsInterop,
      'Class.generative': Kind.regular,
      'Class.fact': Kind.regular,
      'Class.instanceField': Kind.regular,
      'Class.instanceGetter': Kind.regular,
      'Class.instanceSetter': Kind.regular,
      'Class.instanceMethod': Kind.regular,
      'Class.staticField': Kind.regular,
      'Class.staticGetter': Kind.regular,
      'Class.staticSetter': Kind.regular,
      'Class.staticMethod': Kind.regular,
      'JsInteropClass.externalGenerative': Kind.jsInterop,
      'JsInteropClass.externalFact': Kind.jsInterop,
      'JsInteropClass.externalJsInteropGenerative': Kind.jsInterop,
      'JsInteropClass.externalJsInteropFact': Kind.jsInterop,
      'JsInteropClass.externalInstanceGetter': Kind.jsInterop,
      'JsInteropClass.externalInstanceSetter': Kind.jsInterop,
      'JsInteropClass.externalInstanceMethod': Kind.jsInterop,
      'JsInteropClass.externalStaticGetter': Kind.jsInterop,
      'JsInteropClass.externalStaticSetter': Kind.jsInterop,
      'JsInteropClass.externalStaticMethod': Kind.jsInterop,
      'JsInteropClass.externalInstanceJsInteropGetter': Kind.jsInterop,
      'JsInteropClass.externalInstanceJsInteropSetter': Kind.jsInterop,
      'JsInteropClass.externalInstanceJsInteropMethod': Kind.jsInterop,
      'JsInteropClass.externalStaticJsInteropGetter': Kind.jsInterop,
      'JsInteropClass.externalStaticJsInteropSetter': Kind.jsInterop,
      'JsInteropClass.externalStaticJsInteropMethod': Kind.jsInterop,
    }, skipList: [
      // TODO(34174): Js-interop fields should not be allowed.
      '01',
      '02',
      '03',
      '04',
      '38',
      '42',
      '46',
      '51',
      // TODO(33834): Non-external constructors should not be allowed.
      '35',
      '37',
      // TODO(34345): Non-external static members should not be allowed.
      '43',
      '44',
      '45',
      '52',
      '53',
      '54',
    ]);

    await runTest(
        'tests/dart2js_2/native/native_test.dart', 'tests/dart2js_2/native/', {
      'Class': Kind.regular,
      'NativeClass': Kind.native,
      'topLevelField': Kind.regular,
      'topLevelGetter': Kind.regular,
      'topLevelSetter': Kind.regular,
      'topLevelFunction': Kind.regular,
      'nativeTopLevelGetter': Kind.native,
      'nativeTopLevelSetter': Kind.native,
      'nativeTopLevelFunction': Kind.native,
      'Class.generative': Kind.regular,
      'Class.fact': Kind.regular,
      'Class.instanceField': Kind.regular,
      'Class.instanceGetter': Kind.regular,
      'Class.instanceSetter': Kind.regular,
      'Class.instanceMethod': Kind.regular,
      'Class.staticField': Kind.regular,
      'Class.staticGetter': Kind.regular,
      'Class.staticSetter': Kind.regular,
      'Class.staticMethod': Kind.regular,
      'Class.nativeInstanceGetter': Kind.native,
      'Class.nativeInstanceSetter': Kind.native,
      'Class.nativeInstanceMethod': Kind.native,
      'NativeClass.generative': Kind.regular,
      'NativeClass.fact': Kind.regular,
      'NativeClass.nativeGenerative': Kind.native,
      'NativeClass.nativeFact': Kind.native,
      'NativeClass.instanceField': Kind.native,
      'NativeClass.instanceGetter': Kind.regular,
      'NativeClass.instanceSetter': Kind.regular,
      'NativeClass.instanceMethod': Kind.regular,
      'NativeClass.staticField': Kind.regular,
      'NativeClass.staticGetter': Kind.regular,
      'NativeClass.staticSetter': Kind.regular,
      'NativeClass.staticMethod': Kind.regular,
      'NativeClass.nativeInstanceGetter': Kind.native,
      'NativeClass.nativeInstanceSetter': Kind.native,
      'NativeClass.nativeInstanceMethod': Kind.native,
      'NativeClass.nativeStaticGetter': Kind.native,
      'NativeClass.nativeStaticSetter': Kind.native,
      'NativeClass.nativeStaticMethod': Kind.native,
    },
        skipList: [
          // External constructors in non-native class
          //'08',
          //'09',
          // External instance members in non-native class
          //'22',
          //'23',
          //'24',
          // External static members in non-native class
          //'25',
          //'26',
          //'27',
          // External instance members in native class
          //'36',
          //'37',
          //'38',
          // External static members in native class
          //'39',
          //'40',
          //'41',
        ]);
  });
}

runTest(String fileName, String location, Map<String, Kind> expectations,
    {List<String> skipList: const <String>[]}) async {
  print('--------------------------------------------------------------------');
  print('Testing $fileName');
  print('--------------------------------------------------------------------');
  String test = new File(fileName).readAsStringSync();

  List<String> commonLines = <String>[];
  Map<String, SubTest> subTests = <String, SubTest>{};

  int lineIndex = 0;
  for (String line in test.split('\n')) {
    int index = line.indexOf('//#');
    if (index != -1) {
      String prefix = line.substring(0, index);
      String suffix = line.substring(index + 3);
      String name = suffix.substring(0, suffix.indexOf((':'))).trim();
      SubTest subTest = subTests.putIfAbsent(name, () => new SubTest());
      subTest.lines[lineIndex] = line;
      int commentIndex = prefix.indexOf('// ');
      if (commentIndex != -1) {
        String combinedErrors = prefix.substring(commentIndex + 3);
        for (String error in combinedErrors.split(',')) {
          subTest.expectedErrors.add(error.trim());
        }
      }
      commonLines.add('');
    } else {
      commonLines.add(line);
    }
    lineIndex++;
  }

  String path = '${location}main.dart';
  Uri entryPoint = Uri.parse('memory:$path');
  await runPositiveTest(
      entryPoint, {path: commonLines.join('\n')}, expectations);
  for (String name in subTests.keys) {
    if (!skipList.contains(name)) {
      SubTest subTest = subTests[name];
      await runNegativeTest(
          subTest, entryPoint, {path: subTest.generateCode(commonLines)});
    }
  }
}

runPositiveTest(Uri entryPoint, Map<String, String> sources,
    Map<String, Kind> expectations) async {
  CompilationResult result =
      await runCompiler(entryPoint: entryPoint, memorySourceFiles: sources);
  Expect.isTrue(result.isSuccess);

  JClosedWorld closedWorld = result.compiler.backendClosedWorldForTesting;
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;

  void checkClass(ClassEntity cls,
      {bool isNative: false, bool isJsInterop: false}) {
    if (isJsInterop) {
      isNative = true;
    }
    Expect.equals(isJsInterop, closedWorld.nativeData.isJsInteropClass(cls),
        "Unexpected js interop class result for $cls.");
    Expect.equals(isNative, closedWorld.nativeData.isNativeClass(cls),
        "Unexpected native class result for $cls.");
    if (isJsInterop) {
      Expect.isTrue(closedWorld.nativeData.isJsInteropLibrary(cls.library),
          "Unexpected js interop library result for ${cls.library}.");
    }
  }

  void checkMember(MemberEntity member,
      {bool isNative: false, bool isJsInterop: false}) {
    if (isJsInterop) {
      isNative = true;
    }
    Expect.equals(isJsInterop, closedWorld.nativeData.isJsInteropMember(member),
        "Unexpected js interop member result for $member.");
    Expect.equals(isNative, closedWorld.nativeData.isNativeMember(member),
        "Unexpected native member result for $member.");
    if (isJsInterop) {
      Expect.isTrue(closedWorld.nativeData.isJsInteropLibrary(member.library),
          "Unexpected js interop library result for ${member.library}.");
    }
  }

  elementEnvironment.forEachLibraryMember(elementEnvironment.mainLibrary,
      (MemberEntity member) {
    if (member == elementEnvironment.mainFunction) return;

    Kind kind = expectations.remove(member.name);
    Expect.isNotNull(kind, "No expectations for $member");
    checkMember(member,
        isNative: kind == Kind.native, isJsInterop: kind == Kind.jsInterop);
  });

  elementEnvironment.forEachClass(elementEnvironment.mainLibrary,
      (ClassEntity cls) {
    Kind kind = expectations.remove(cls.name);
    Expect.isNotNull(kind, "No expectations for $cls");
    checkClass(cls,
        isNative: kind == Kind.native, isJsInterop: kind == Kind.jsInterop);

    checkClassMember(MemberEntity member) {
      Kind kind = expectations.remove('${cls.name}.${member.name}');
      Expect.isNotNull(kind, "No expectations for $member");
      checkMember(member,
          isNative: kind == Kind.native, isJsInterop: kind == Kind.jsInterop);
    }

    elementEnvironment.forEachConstructor(cls, checkClassMember);
    elementEnvironment.forEachLocalClassMember(cls, checkClassMember);
  });

  Expect.isTrue(expectations.isEmpty, "Untested expectations: $expectations");
}

runNegativeTest(
    SubTest subTest, Uri entryPoint, Map<String, String> sources) async {
  DiagnosticCollector collector = new DiagnosticCollector();
  CompilationResult result = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: sources,
      diagnosticHandler: collector);
  Expect.isFalse(result.isSuccess,
      "Expected compile time error(s) for\n$subTest");
  List<String> expected =
      subTest.expectedErrors.map((error) => 'MessageKind.' + error).toList();
  List<String> actual =
      collector.errors.map((error) => error.messageKind.toString()).toList();
  expected.sort();
  actual.sort();
  Expect.listEquals(expected, actual,
      "Unexpected compile time error(s) for\n$subTest");
}

class SubTest {
  List<String> expectedErrors = [];
  final Map<int, String> lines = <int, String>{};

  String generateCode(List<String> commonLines) {
    StringBuffer sb = new StringBuffer();
    int i = 0;
    while (i < commonLines.length) {
      if (lines.containsKey(i)) {
        sb.writeln(lines[i]);
      } else {
        sb.writeln(commonLines[i]);
      }
      i++;
    }
    return sb.toString();
  }

  @override
  String toString() {
    return lines.values.join('\n');
  }
}
