// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:args/args.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/ir/annotations.dart';
import 'package:compiler/src/js_backend/native_data.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/element_map_impl.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;

import '../helpers/args_helper.dart';
import '../helpers/memory_compiler.dart';

const String pathPrefix = 'sdk/tests/dart2js_2/native/';

const Map<String, String> source = {
  '$pathPrefix/main.dart': '''

library lib;

import 'package:meta/dart2js.dart';

import 'jslib1.dart';
import 'jslib2.dart';
import 'nativelib.dart';

@pragma('dart2js:noInline')
method1() {}

@noInline
method2() {}

@pragma(const String.fromEnvironment('foo', defaultValue: 'dart2js:tryInline'))
method3() {}

@tryInline
method4() {}

main() {
  method1();
  method2();
  method3();
  method4();
  new JsClass1()..jsMethod1()..jsMethod2();
  new JsClass2();
  jsMethod3();
  new NativeClass1()..nativeMethod()..nativeField;
  new NativeClass2()..nativeField;
  new NativeClass3()..nativeMethod()..nativeGetter;
  nativeMethod();
}
''',
  '$pathPrefix/jslib1.dart': '''

@JS('lib1')
library lib1;

import 'package:js/js.dart';

@JS('JsInteropClass1')
class JsClass1 {
  @JS('jsInteropMethod1')
  external jsMethod1();
  
  external jsMethod2();
}

''',
  '$pathPrefix/jslib2.dart': '''

@JS()
library lib2;

import 'package:js/js.dart';

@JS()
@anonymous
class JsClass2 {
}

@JS('jsInteropMethod3')
external jsMethod3();

external jsMethod4();
''',
  '$pathPrefix/nativelib.dart': '''
library lib3; 
 
import 'dart:_js_helper';

@Native('Class1')
class NativeClass1 {
  @JSName('field1')
  var nativeField;
  
  @JSName('method1')
  nativeMethod() native;
}

@Native('Class2,!nonleaf')
class NativeClass2 {
  @JSName('field2')
  var nativeField;
}

@Native('Class3a,Class3b')
class NativeClass3 {
  
  @JSName('method2')
  get nativeGetter native;

  @Creates('String')
  @Returns('int')
  nativeMethod() native;
}

@JSName('method3')
nativeMethod() native;
''',
};

const Map<String, String> expectedNativeClassNames = {
  '$pathPrefix/nativelib.dart::NativeClass1': 'Class1',
  '$pathPrefix/nativelib.dart::NativeClass2': 'Class2,!nonleaf',
  '$pathPrefix/nativelib.dart::NativeClass3': 'Class3a,Class3b',
};

const Map<String, String> expectedNativeMemberNames = {
  '$pathPrefix/nativelib.dart::NativeClass1::nativeField': 'field1',
  '$pathPrefix/nativelib.dart::NativeClass1::nativeMethod': 'method1',
  '$pathPrefix/nativelib.dart::NativeClass2::nativeField': 'field2',
  '$pathPrefix/nativelib.dart::NativeClass3::nativeGetter': 'method2',
  '$pathPrefix/nativelib.dart::nativeMethod': 'method3',
};

const Map<String, String> expectedCreates = {
  '$pathPrefix/nativelib.dart::NativeClass3::nativeMethod': 'String',
};

const Map<String, String> expectedReturns = {
  '$pathPrefix/nativelib.dart::NativeClass3::nativeMethod': 'int',
};

const Map<String, String> expectedJsInteropLibraryNames = {
  '$pathPrefix/jslib1.dart': 'lib1',
  '$pathPrefix/jslib2.dart': '',
};

const Map<String, String> expectedJsInteropClassNames = {
  '$pathPrefix/jslib1.dart::JsClass1': 'JsInteropClass1',
  '$pathPrefix/jslib2.dart::JsClass2': '',
};

const Map<String, String> expectedJsInteropMemberNames = {
  '$pathPrefix/jslib1.dart::JsClass1::jsMethod1': 'jsInteropMethod1',
  '$pathPrefix/jslib2.dart::jsMethod3': 'jsInteropMethod3',
};

const Set<String> expectedAnonymousJsInteropClasses = {
  '$pathPrefix/jslib2.dart::JsClass2',
};

const Set<String> expectedNoInlineMethods = {
  '$pathPrefix/main.dart::method1',
  '$pathPrefix/main.dart::method2',
};

const Set<String> expectedTryInlineMethods = {
  '$pathPrefix/main.dart::method3',
  '$pathPrefix/main.dart::method4',
};

main(List<String> args) {
  ArgParser argParser = createArgParser();

  asyncTest(() async {
    ArgResults argResults = argParser.parse(args);
    Uri librariesSpecificationUri = getLibrariesSpec(argResults);
    Uri packageConfig = getPackages(argResults);
    List<String> options = getOptions(argResults);

    runTest({bool useIr}) async {
      CompilationResult result = await runCompiler(
          entryPoint: Uri.parse('memory:$pathPrefix/main.dart'),
          memorySourceFiles: source,
          packageConfig: packageConfig,
          librariesSpecificationUri: librariesSpecificationUri,
          options: options);
      Expect.isTrue(result.isSuccess);
      Compiler compiler = result.compiler;
      KernelFrontendStrategy frontendStrategy = compiler.frontendStrategy;
      KernelToElementMapImpl elementMap = frontendStrategy.elementMap;
      ir.Component component = elementMap.env.mainComponent;
      IrAnnotationData annotationData =
          frontendStrategy.irAnnotationDataForTesting;

      void testAll(NativeData nativeData) {
        void testMember(String idPrefix, ir.Member member,
            {bool implicitJsInteropMember, bool implicitNativeMember}) {
          if (memberIsIgnorable(member)) return;
          String memberId = '$idPrefix::${member.name.text}';
          MemberEntity memberEntity = elementMap.getMember(member);

          String expectedJsInteropMemberName =
              expectedJsInteropMemberNames[memberId];
          String expectedNativeMemberName = expectedNativeMemberNames[memberId];
          Set<String> expectedPragmaNames = {};
          if (expectedNoInlineMethods.contains(memberId)) {
            expectedPragmaNames.add('dart2js:noInline');
          }
          if (expectedTryInlineMethods.contains(memberId)) {
            expectedPragmaNames.add('dart2js:tryInline');
          }

          String expectedCreatesText = expectedCreates[memberId];
          String expectedReturnsText = expectedReturns[memberId];

          if (useIr) {
            Expect.equals(
                expectedJsInteropMemberName,
                annotationData.getJsInteropMemberName(member),
                "Unexpected js interop member name from IR for $member, "
                "id: $memberId");

            Expect.equals(
                expectedNativeMemberName,
                annotationData.getNativeMemberName(member),
                "Unexpected js interop member name from IR for $member, "
                "id: $memberId");

            List<PragmaAnnotationData> pragmaAnnotations =
                annotationData.getMemberPragmaAnnotationData(member);
            Set<String> pragmaNames =
                pragmaAnnotations.map((d) => d.name).toSet();
            Expect.setEquals(expectedPragmaNames, pragmaNames,
                "Unexpected pragmas from IR for $member, " "id: $memberId");

            List<String> createsAnnotations =
                annotationData.getCreatesAnnotations(member);
            Expect.equals(
                expectedCreatesText,
                createsAnnotations.isEmpty
                    ? null
                    : createsAnnotations.join(','),
                "Unexpected create annotations from IR for $member, "
                "id: $memberId");

            List<String> returnsAnnotations =
                annotationData.getReturnsAnnotations(member);
            Expect.equals(
                expectedReturnsText,
                returnsAnnotations.isEmpty
                    ? null
                    : returnsAnnotations.join(','),
                "Unexpected returns annotations from IR for $member, "
                "id: $memberId");
          }

          bool isJsInteropMember =
              (implicitJsInteropMember && member.isExternal) ||
                  expectedJsInteropMemberName != null;
          Expect.equals(
              isJsInteropMember,
              nativeData.isJsInteropMember(memberEntity),
              "Unexpected js interop member result from native data for $member, "
              "id: $memberId");
          Expect.equals(
              isJsInteropMember
                  ? expectedJsInteropMemberName ?? memberEntity.name
                  : null,
              nativeData.getJsInteropMemberName(memberEntity),
              "Unexpected js interop member name from native data for $member, "
              "id: $memberId");

          bool isNativeMember =
              implicitNativeMember || expectedNativeMemberName != null;
          Expect.equals(
              isNativeMember || isJsInteropMember,
              nativeData.isNativeMember(memberEntity),
              "Unexpected native member result from native data for $member, "
              "id: $memberId");
          Expect.equals(
              isNativeMember
                  ? expectedNativeMemberName ?? memberEntity.name
                  : (isJsInteropMember
                      ? expectedJsInteropMemberName ?? memberEntity.name
                      : null),
              nativeData.getFixedBackendName(memberEntity),
              "Unexpected fixed backend name from native data for $member, "
              "id: $memberId");

          if (expectedCreatesText != null) {
            String createsText;
            if (memberEntity.isField) {
              createsText = nativeData
                  .getNativeFieldLoadBehavior(memberEntity)
                  .typesInstantiated
                  .join(',');
            } else {
              createsText = nativeData
                  .getNativeMethodBehavior(memberEntity)
                  .typesInstantiated
                  .join(',');
            }
            Expect.equals(
                expectedCreatesText,
                createsText,
                "Unexpected create annotations from native data for $member, "
                "id: $memberId");
          }

          if (expectedReturnsText != null) {
            String returnsText;
            if (memberEntity.isField) {
              returnsText = nativeData
                  .getNativeFieldLoadBehavior(memberEntity)
                  .typesReturned
                  .join(',');
            } else {
              returnsText = nativeData
                  .getNativeMethodBehavior(memberEntity)
                  .typesReturned
                  .join(',');
            }
            Expect.equals(
                expectedReturnsText,
                returnsText,
                "Unexpected returns annotations from native data for $member, "
                "id: $memberId");
          }

          List<PragmaAnnotationData> pragmaAnnotations = frontendStrategy
              .modularStrategyForTesting
              .getPragmaAnnotationData(member);
          Set<String> pragmaNames =
              pragmaAnnotations.map((d) => d.name).toSet();
          Expect.setEquals(
              expectedPragmaNames,
              pragmaNames,
              "Unexpected pragmas from modular strategy for $member, "
              "id: $memberId");
        }

        for (ir.Library library in component.libraries) {
          if (library.importUri.scheme == 'memory') {
            String libraryId = library.importUri.path;
            LibraryEntity libraryEntity = elementMap.getLibrary(library);

            String expectedJsInteropLibraryName =
                expectedJsInteropLibraryNames[libraryId];
            if (useIr) {
              Expect.equals(
                  expectedJsInteropLibraryName,
                  annotationData.getJsInteropLibraryName(library),
                  "Unexpected js library name from IR for $library");
            }
            Expect.equals(
                expectedJsInteropLibraryName != null,
                nativeData.isJsInteropLibrary(libraryEntity),
                "Unexpected js library result from native data for $library");
            Expect.equals(
                expectedJsInteropLibraryName,
                nativeData.getJsInteropLibraryName(libraryEntity),
                "Unexpected js library name from native data for $library");

            for (ir.Class cls in library.classes) {
              String clsId = '$libraryId::${cls.name}';
              ClassEntity classEntity = elementMap.getClass(cls);

              String expectedNativeClassName = expectedNativeClassNames[clsId];
              if (useIr) {
                Expect.equals(
                    expectedNativeClassName,
                    annotationData.getNativeClassName(cls),
                    "Unexpected native class name from IR for $cls");
              }
              bool isNativeClass = nativeData.isNativeClass(classEntity) &&
                  !nativeData.isJsInteropClass(classEntity);
              String nativeDataClassName;
              if (isNativeClass) {
                nativeDataClassName =
                    nativeData.getNativeTagsOfClass(classEntity).join(',');
                if (nativeData.hasNativeTagsForcedNonLeaf(classEntity)) {
                  nativeDataClassName += ',!nonleaf';
                }
              }
              Expect.equals(expectedNativeClassName != null, isNativeClass,
                  "Unexpected native class result from native data for $cls");

              Expect.equals(expectedNativeClassName, nativeDataClassName,
                  "Unexpected native class name from native data for $cls");

              String expectedJsInteropClassName =
                  expectedJsInteropClassNames[clsId];
              if (useIr) {
                Expect.equals(
                    expectedJsInteropClassName,
                    annotationData.getJsInteropClassName(cls),
                    "Unexpected js class name from IR for $cls");
              }
              Expect.equals(
                  expectedJsInteropClassName != null,
                  nativeData.isJsInteropClass(classEntity),
                  "Unexpected js class result from native data for $cls");
              Expect.equals(
                  expectedJsInteropClassName,
                  nativeData.getJsInteropClassName(classEntity),
                  "Unexpected js class name from native data for $cls");

              bool expectedAnonymousJsInteropClass =
                  expectedAnonymousJsInteropClasses.contains(clsId);
              if (useIr) {
                Expect.equals(
                    expectedAnonymousJsInteropClass,
                    annotationData.isAnonymousJsInteropClass(cls),
                    "Unexpected js anonymous class result from IR for $cls");
              }
              Expect.equals(
                  expectedAnonymousJsInteropClass,
                  nativeData.isAnonymousJsInteropClass(classEntity),
                  "Unexpected js anonymousclass result from native data for "
                  "$cls");

              for (ir.Member member in cls.members) {
                testMember(clsId, member,
                    implicitJsInteropMember:
                        nativeData.isJsInteropClass(classEntity),
                    implicitNativeMember: member is! ir.Constructor &&
                        nativeData.isNativeClass(classEntity) &&
                        !nativeData.isJsInteropClass(classEntity));
              }
            }
            for (ir.Member member in library.members) {
              testMember(libraryId, member,
                  implicitJsInteropMember: expectedJsInteropLibraryName != null,
                  implicitNativeMember: false);
            }
          }
        }
      }

      testAll(compiler.frontendClosedWorldForTesting.nativeData);
      if (useIr) {
        testAll(new NativeDataImpl.fromIr(elementMap, annotationData));
      }
    }

    print('test annotations from K-model');
    await runTest(useIr: false);

    print('test annotations from IR');
    await runTest(useIr: true);
  });
}
