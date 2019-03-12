// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/ir/annotations.dart';
import 'package:compiler/src/js_backend/native_data.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/kernel/element_map_impl.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;

import '../helpers/args_helper.dart';
import '../helpers/memory_compiler.dart';

const String pathPrefix = 'sdk/tests/compiler/dart2js_native/';

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

@pragma('dart2js:tryInline')
method3() {}

@tryInline
method4() {}

main() {
}
''',
  '$pathPrefix/jslib1.dart': '''

@JS('lib1')
library lib1;

import 'package:js/js.dart';

@JS('JsInteropClass1')
class Class1 {
  @JS('jsInteropMethod1')
  external method1();
  
  external method2();
}

''',
  '$pathPrefix/jslib2.dart': '''

@JS()
library lib2;

import 'package:js/js.dart';

@JS()
@anonymous
class Class2 {
}

@JS('jsInteropMethod3')
external method3();
''',
  '$pathPrefix/nativelib.dart': '''
import 'dart:_js_helper';

@Native('NativeClass1')
class Class1 {
}

@Native('NativeClass2,!nonleaf')
class Class2 {
}

@Native('NativeClass3a,NativeClass3b')
class Class3 {
}


''',
};

const Map<String, String> expectedNativeClassNames = {
  '$pathPrefix/nativelib.dart::Class1': 'NativeClass1',
  '$pathPrefix/nativelib.dart::Class2': 'NativeClass2,!nonleaf',
  '$pathPrefix/nativelib.dart::Class3': 'NativeClass3a,NativeClass3b',
};

const Map<String, String> expectedJsInteropLibraryNames = {
  '$pathPrefix/jslib1.dart': 'lib1',
  '$pathPrefix/jslib2.dart': '',
};

const Map<String, String> expectedJsInteropClassNames = {
  '$pathPrefix/jslib1.dart::Class1': 'JsInteropClass1',
  '$pathPrefix/jslib2.dart::Class2': '',
};

const Map<String, String> expectedJsInteropMemberNames = {
  '$pathPrefix/jslib1.dart::Class1::method1': 'jsInteropMethod1',
  '$pathPrefix/jslib2.dart::method3': 'jsInteropMethod3',
};

const Set<String> expectedAnonymousJsInteropClasses = {
  '$pathPrefix/jslib2.dart::Class2',
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
      useIrAnnotationsDataForTesting = useIr;
      CompilationResult result = await runCompiler(
          entryPoint: Uri.parse('memory:$pathPrefix/main.dart'),
          memorySourceFiles: source,
          packageConfig: packageConfig,
          librariesSpecificationUri: librariesSpecificationUri,
          options: (useIr
              ? ['${Flags.enableLanguageExperiments}=constant-update-2018']
              : [])
            ..addAll(options));
      Expect.isTrue(result.isSuccess);
      Compiler compiler = result.compiler;
      KernelFrontEndStrategy frontendStrategy = compiler.frontendStrategy;
      KernelToElementMapImpl elementMap = frontendStrategy.elementMap;
      NativeData nativeData =
          compiler.resolutionWorldBuilder.closedWorldForTesting.nativeData;
      ir.Component component = elementMap.env.mainComponent;
      IrAnnotationData annotationData;
      if (useIr) {
        annotationData = processAnnotations(component);
      }

      void testMember(String idPrefix, ir.Member member,
          {bool implicitJsInteropMember}) {
        String memberId = '$idPrefix::${member.name.name}';
        MemberEntity memberEntity = elementMap.getMember(member);

        String expectedJsInteropMemberName =
            expectedJsInteropMemberNames[memberId];
        Set<String> expectedPragmaNames = {};
        if (expectedNoInlineMethods.contains(memberId)) {
          expectedPragmaNames.add('dart2js:noInline');
        }
        if (expectedTryInlineMethods.contains(memberId)) {
          expectedPragmaNames.add('dart2js:tryInline');
        }
        if (useIr) {
          Expect.equals(
              expectedJsInteropMemberName,
              annotationData.getJsInteropMemberName(member),
              "Unexpected js interop member name from IR for $member");

          List<PragmaAnnotationData> pragmaAnnotations =
              annotationData.getMemberPragmaAnnotationData(member);
          Set<String> pragmaNames =
              pragmaAnnotations.map((d) => d.name).toSet();
          Expect.setEquals(expectedPragmaNames, pragmaNames,
              "Unexpected pragmas from IR for $member");
        }
        bool isJsInteropMember =
            (implicitJsInteropMember && member.isExternal) ||
                expectedJsInteropMemberName != null;
        Expect.equals(
            isJsInteropMember,
            nativeData.isJsInteropMember(memberEntity),
            "Unexpected js interop member result from native data for $member");
        Expect.equals(
            isJsInteropMember
                ? expectedJsInteropMemberName ?? memberEntity.name
                : null,
            nativeData.getJsInteropMemberName(memberEntity),
            "Unexpected js interop member name from native data for $member");
        List<PragmaAnnotationData> pragmaAnnotations = frontendStrategy
            .modularStrategyForTesting
            .getPragmaAnnotationData(member);
        Set<String> pragmaNames = pragmaAnnotations.map((d) => d.name).toSet();
        Expect.setEquals(expectedPragmaNames, pragmaNames,
            "Unexpected pragmas from modular strategy for $member");
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
                      nativeData.isJsInteropClass(classEntity));
            }
          }
          for (ir.Member member in library.members) {
            testMember(libraryId, member, implicitJsInteropMember: false);
          }
        }
      }
    }

    print('test annotations from IR');
    await runTest(useIr: true);

    print('test annotations from K-model');
    await runTest(useIr: false);
  });
}
