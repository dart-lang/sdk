// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';
import 'dart:io';

import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/kernel/element_map_impl.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;

import '../helpers/compiler_helper.dart';
import '../helpers/memory_compiler.dart';
import '../equivalence/id_equivalence.dart';

export 'package:_fe_analyzer_shared/src/testing/id_testing.dart'
    show DataInterpreter, StringDataInterpreter;
export '../helpers/memory_compiler.dart' show CollectedMessage;

const String specMarker = 'spec';
const String prodMarker = 'prod';
const String twoDeferredFragmentMarker = 'two-frag';
const String threeDeferredFragmentMarker = 'three-frag';

const TestConfig specConfig = TestConfig(specMarker, 'compliance mode', []);

const TestConfig prodConfig = TestConfig(prodMarker, 'production mode',
    [Flags.omitImplicitChecks, Flags.laxRuntimeTypeToString]);

const TestConfig twoDeferredFragmentConfig = TestConfig(
    twoDeferredFragmentMarker,
    'two deferred fragment mode',
    ['${Flags.mergeFragmentsThreshold}=2']);

const TestConfig threeDeferredFragmentConfig = TestConfig(
    threeDeferredFragmentMarker,
    'three deferred fragment mode',
    ['${Flags.mergeFragmentsThreshold}=3']);

/// Default internal configurations not including experimental features.
const List<TestConfig> defaultInternalConfigs = [specConfig, prodConfig];

/// All internal configurations including experimental features.
const List<TestConfig> allInternalConfigs = [specConfig, prodConfig];

/// Compliance mode configurations (with strong mode checks) including
/// experimental features.
const List<TestConfig> allSpecConfigs = [specConfig];

/// Test configuration used in tests shared with CFE.
const TestConfig sharedConfig = TestConfig(dart2jsMarker, 'dart2js', []);

abstract class DataComputer<T> {
  const DataComputer();

  /// Called before testing to setup flags needed for data collection.
  void setup() {}

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data.
  void computeMemberData(
      Compiler compiler, MemberEntity member, Map<Id, ActualData<T>> actualMap,
      {bool verbose});

  /// Returns `true` if frontend member should be tested.
  bool get testFrontend => false;

  /// Function that computes a data mapping for [cls].
  ///
  /// Fills [actualMap] with the data.
  void computeClassData(
      Compiler compiler, ClassEntity cls, Map<Id, ActualData<T>> actualMap,
      {bool verbose}) {}

  /// Function that computes a data mapping for [library].
  ///
  /// Fills [actualMap] with the data.
  void computeLibraryData(Compiler compiler, LibraryEntity library,
      Map<Id, ActualData<T>> actualMap,
      {bool verbose}) {}

  /// Returns `true` if this data computer supports tests with compile-time
  /// errors.
  ///
  /// Unsuccessful compilation might leave the compiler in an inconsistent
  /// state, so this testing feature is opt-in.
  bool get supportsErrors => false;

  /// Returns data corresponding to [error].
  T computeErrorData(Compiler compiler, Id id, List<CollectedMessage> errors) =>
      null;

  DataInterpreter<T> get dataValidator;
}

const String stopAfterTypeInference = 'stopAfterTypeInference';

/// Reports [message] as an error using [spannable] as error location.
void reportError(
    DiagnosticReporter reporter, Spannable spannable, String message) {
  reporter
      .reportErrorMessage(spannable, MessageKind.GENERIC, {'text': message});
}

/// Compute actual data for all members defined in the program with the
/// [entryPoint] and [memorySourceFiles].
///
/// Actual data is computed using [computeMemberData].
Future<CompiledData<T>> computeData<T>(Uri entryPoint,
    Map<String, String> memorySourceFiles, DataComputer<T> dataComputer,
    {List<String> options: const <String>[],
    bool verbose: false,
    bool testFrontend: false,
    bool printCode: false,
    bool forUserLibrariesOnly: true,
    bool skipUnprocessedMembers: false,
    bool skipFailedCompilations: false,
    Iterable<Id> globalIds: const <Id>[]}) async {
  OutputCollector outputCollector = new OutputCollector();
  DiagnosticCollector diagnosticCollector = new DiagnosticCollector();
  Uri packageConfig;
  Uri wantedPackageConfig = createUriForFileName(".packages");
  for (String key in memorySourceFiles.keys) {
    if (key == wantedPackageConfig.path) {
      packageConfig = wantedPackageConfig;
      break;
    }
  }
  CompilationResult result = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      outputProvider: outputCollector,
      diagnosticHandler: diagnosticCollector,
      options: options,
      beforeRun: (compiler) {
        compiler.stopAfterTypeInference =
            options.contains(stopAfterTypeInference);
      },
      packageConfig: packageConfig,
      unsafeToTouchSourceFiles: true);
  if (!result.isSuccess) {
    if (skipFailedCompilations) return null;
    Expect.isTrue(
        dataComputer.supportsErrors,
        "Compilation with compile-time errors not supported for this "
        "testing setup.");
  }
  if (printCode) {
    print('--code------------------------------------------------------------');
    print(outputCollector.getOutput('', OutputType.js));
    print('------------------------------------------------------------------');
  }
  Compiler compiler = result.compiler;

  Map<Uri, Map<Id, ActualData<T>>> actualMaps = <Uri, Map<Id, ActualData<T>>>{};
  Map<Id, ActualData<T>> globalData = <Id, ActualData<T>>{};

  Map<Id, ActualData<T>> actualMapForUri(Uri uri) {
    return actualMaps.putIfAbsent(uri, () => <Id, ActualData<T>>{});
  }

  Map<Uri, Map<int, List<CollectedMessage>>> errors = {};
  for (CollectedMessage error in diagnosticCollector.errors) {
    Map<int, List<CollectedMessage>> map =
        errors.putIfAbsent(error.uri, () => {});
    List<CollectedMessage> list = map.putIfAbsent(error.begin, () => []);
    list.add(error);
  }

  errors.forEach((Uri uri, Map<int, List<CollectedMessage>> map) {
    map.forEach((int offset, List<CollectedMessage> list) {
      NodeId id = new NodeId(offset, IdKind.error);
      T data = dataComputer.computeErrorData(compiler, id, list);
      if (data != null) {
        Map<Id, ActualData<T>> actualMap = actualMapForUri(uri);
        actualMap[id] = new ActualData<T>(id, data, uri, offset, list);
      }
    });
  });

  if (!result.isSuccess) {
    return new Dart2jsCompiledData<T>(
        compiler, null, entryPoint, actualMaps, globalData);
  }

  dynamic closedWorld = testFrontend
      ? compiler.frontendClosedWorldForTesting
      : compiler.backendClosedWorldForTesting;
  ElementEnvironment elementEnvironment = closedWorld?.elementEnvironment;
  CommonElements commonElements = closedWorld.commonElements;

  Map<Id, ActualData<T>> actualMapFor(Entity entity) {
    SourceSpan span =
        compiler.backendStrategy.spanFromSpannable(entity, entity);
    return actualMapForUri(span.uri);
  }

  void processMember(MemberEntity member, Map<Id, ActualData<T>> actualMap) {
    if (member.isAbstract) {
      return;
    }
    if (skipUnprocessedMembers &&
        !closedWorld.processedMembers.contains(member)) {
      return;
    }
    if (member.enclosingClass != null) {
      if (elementEnvironment.isEnumClass(member.enclosingClass)) {
        if (member.isConstructor ||
            member.isInstanceMember ||
            member.name == 'values') {
          return;
        }
      }
      if (member.isConstructor &&
          elementEnvironment.isMixinApplication(member.enclosingClass)) {
        return;
      }
    }
    dataComputer.computeMemberData(compiler, member, actualMap,
        verbose: verbose);
  }

  void processClass(ClassEntity cls, Map<Id, ActualData<T>> actualMap) {
    if (skipUnprocessedMembers && !closedWorld.isImplemented(cls)) {
      return;
    }
    dataComputer.computeClassData(compiler, cls, actualMap, verbose: verbose);
  }

  bool excludeLibrary(LibraryEntity library) {
    return forUserLibrariesOnly &&
        (library.canonicalUri.scheme == 'dart' ||
            library.canonicalUri.scheme == 'package');
  }

  ir.Library getIrLibrary(LibraryEntity library) {
    KernelFrontendStrategy frontendStrategy = compiler.frontendStrategy;
    KernelToElementMapImpl elementMap = frontendStrategy.elementMap;
    LibraryEntity kLibrary =
        elementMap.elementEnvironment.lookupLibrary(library.canonicalUri);
    return elementMap.getLibraryNode(kLibrary);
  }

  for (LibraryEntity library in elementEnvironment.libraries) {
    if (excludeLibrary(library) &&
        !memorySourceFiles.containsKey(getIrLibrary(library).fileUri.path)) {
      continue;
    }

    dataComputer.computeLibraryData(
        compiler, library, actualMapForUri(getIrLibrary(library).fileUri),
        verbose: verbose);
    elementEnvironment.forEachClass(library, (ClassEntity cls) {
      processClass(cls, actualMapFor(cls));
    });
  }

  for (MemberEntity member in closedWorld.processedMembers) {
    if (excludeLibrary(member.library) &&
        !memorySourceFiles
            .containsKey(getIrLibrary(member.library).fileUri.path)) continue;
    processMember(member, actualMapFor(member));
  }

  List<LibraryEntity> globalLibraries = <LibraryEntity>[
    commonElements.coreLibrary,
    elementEnvironment.lookupLibrary(Uri.parse('dart:collection')),
    commonElements.interceptorsLibrary,
    commonElements.jsHelperLibrary,
    commonElements.asyncLibrary,
  ];

  LibraryEntity htmlLibrary =
      elementEnvironment.lookupLibrary(Uri.parse('dart:html'), required: false);
  if (htmlLibrary != null) {
    globalLibraries.add(htmlLibrary);
  }

  ClassEntity getGlobalClass(String className) {
    ClassEntity cls;
    for (LibraryEntity library in globalLibraries) {
      cls ??= elementEnvironment.lookupClass(library, className);
    }
    Expect.isNotNull(
        cls,
        "Global class '$className' not found in the global "
        "libraries: ${globalLibraries.map((l) => l.canonicalUri).join(', ')}");
    return cls;
  }

  MemberEntity getGlobalMember(String memberName) {
    MemberEntity member;
    for (LibraryEntity library in globalLibraries) {
      member ??= elementEnvironment.lookupLibraryMember(library, memberName);
    }
    Expect.isNotNull(
        member,
        "Global member '$memberName' not found in the global "
        "libraries: ${globalLibraries.map((l) => l.canonicalUri).join(', ')}");
    return member;
  }

  for (Id id in globalIds) {
    if (id is MemberId) {
      MemberEntity member;
      if (id.className != null) {
        ClassEntity cls = getGlobalClass(id.className);
        member = elementEnvironment.lookupClassMember(cls, id.memberName);
        member ??= elementEnvironment.lookupConstructor(cls, id.memberName);
        Expect.isNotNull(
            member, "Global member '$member' not found in class $cls.");
      } else {
        member = getGlobalMember(id.memberName);
      }
      processMember(member, globalData);
    } else if (id is ClassId) {
      ClassEntity cls = getGlobalClass(id.className);
      processClass(cls, globalData);
    } else {
      throw new UnsupportedError("Unexpected global id: $id");
    }
  }

  return new Dart2jsCompiledData<T>(
      compiler, elementEnvironment, entryPoint, actualMaps, globalData);
}

class Dart2jsCompiledData<T> extends CompiledData<T> {
  final Compiler compiler;
  final ElementEnvironment elementEnvironment;

  Dart2jsCompiledData(
      this.compiler,
      this.elementEnvironment,
      Uri mainUri,
      Map<Uri, Map<Id, ActualData<T>>> actualMaps,
      Map<Id, ActualData<T>> globalData)
      : super(mainUri, actualMaps, globalData);

  @override
  int getOffsetFromId(Id id, Uri uri) {
    return compiler.reporter
        .spanFromSpannable(computeSpannable(elementEnvironment, uri, id))
        ?.begin;
  }

  @override
  void reportError(Uri uri, int offset, String message,
      {bool succinct: false}) {
    compiler.reporter.reportErrorMessage(
        computeSourceSpanFromUriOffset(uri, offset),
        MessageKind.GENERIC,
        {'text': message});
  }
}

typedef void Callback();

class TestConfig {
  final String marker;
  final String name;
  final List<String> options;

  const TestConfig(this.marker, this.name, this.options);
}

/// Check code for all test files int [data] using [computeFromAst] and
/// [computeFromKernel] from the respective front ends. If [skipForKernel]
/// contains the name of the test file it isn't tested for kernel.
///
/// [libDirectory] contains the directory for any supporting libraries that need
/// to be loaded. We expect supporting libraries to have the same prefix as the
/// original test in [dataDir]. So, for example, if testing `foo.dart` in
/// [dataDir], then this function will consider any files named `foo.*\.dart`,
/// such as `foo2.dart`, `foo_2.dart`, and `foo_blah_blah_blah.dart` in
/// [libDirectory] to be supporting library files for `foo.dart`.
/// [setUpFunction] is called once for every test that is executed.
/// If [forUserSourceFilesOnly] is true, we examine the elements in the main
/// file and any supporting libraries.
Future<void> checkTests<T>(Directory dataDir, DataComputer<T> dataComputer,
    {List<String> skip: const <String>[],
    bool filterActualData(IdValue idValue, ActualData<T> actualData),
    List<String> options: const <String>[],
    List<String> args: const <String>[],
    bool forUserLibrariesOnly: true,
    Callback setUpFunction,
    int shards: 1,
    int shardIndex: 0,
    void onTest(Uri uri),
    List<TestConfig> testedConfigs = const []}) async {
  if (testedConfigs.isEmpty) testedConfigs = defaultInternalConfigs;
  Set<String> testedMarkers =
      testedConfigs.map((config) => config.marker).toSet();
  Expect.isTrue(
      testedConfigs.length == testedMarkers.length,
      "Unexpected test markers $testedMarkers. "
      "Tested configs: $testedConfigs.");

  dataComputer.setup();

  Future<Map<String, TestResult<T>>> checkTest(TestData testData,
      {bool testAfterFailures,
      bool verbose,
      bool succinct,
      bool printCode,
      Map<String, List<String>> skipMap,
      Uri nullUri}) async {
    for (TestConfig testConfiguration in testedConfigs) {
      Expect.isTrue(
          testData.expectedMaps.containsKey(testConfiguration.marker),
          "Unexpected test marker '${testConfiguration.marker}'. "
          "Supported markers: ${testData.expectedMaps.keys}.");
    }

    String name = testData.name;
    List<String> testOptions = options.toList();
    if (name.endsWith('_ea.dart')) {
      testOptions.add(Flags.enableAsserts);
    }

    if (setUpFunction != null) setUpFunction();

    Map<String, TestResult<T>> results = {};
    if (skip.contains(name)) {
      print('--skipped ------------------------------------------------------');
    } else {
      for (TestConfig testConfiguration in testedConfigs) {
        if (skipForConfig(testData.name, testConfiguration.marker, skipMap)) {
          continue;
        }
        print('--from (${testConfiguration.name})-------------');
        results[testConfiguration.marker] = await runTestForConfiguration(
            testConfiguration, dataComputer, testData, testOptions,
            filterActualData: filterActualData,
            verbose: verbose,
            succinct: succinct,
            testAfterFailures: testAfterFailures,
            forUserLibrariesOnly: forUserLibrariesOnly,
            printCode: printCode);
      }
    }
    return results;
  }

  await runTests<T>(dataDir,
      args: args,
      shards: shards,
      shardIndex: shardIndex,
      onTest: onTest,
      createUriForFileName: createUriForFileName,
      onFailure: Expect.fail,
      runTest: checkTest);
}

Uri createUriForFileName(String fileName) {
  // Pretend this is a dart2js_native test to allow use of 'native'
  // keyword and import of private libraries.
  return Uri.parse('memory:sdk/tests/dart2js/native/$fileName');
}

Future<TestResult<T>> runTestForConfiguration<T>(TestConfig testConfiguration,
    DataComputer<T> dataComputer, TestData testData, List<String> options,
    {bool filterActualData(IdValue idValue, ActualData<T> actualData),
    bool verbose: false,
    bool succinct: false,
    bool printCode: false,
    bool forUserLibrariesOnly: true,
    bool testAfterFailures: false}) async {
  MemberAnnotations<IdValue> annotations =
      testData.expectedMaps[testConfiguration.marker];
  CompiledData<T> compiledData = await computeData(
      testData.entryPoint, testData.memorySourceFiles, dataComputer,
      options: [...options, ...testConfiguration.options],
      verbose: verbose,
      printCode: printCode,
      testFrontend: dataComputer.testFrontend,
      forUserLibrariesOnly: forUserLibrariesOnly,
      globalIds: annotations.globalData.keys);
  return await checkCode(testConfiguration.name, testData.testFileUri,
      testData.code, annotations, compiledData, dataComputer.dataValidator,
      filterActualData: filterActualData,
      fatalErrors: !testAfterFailures,
      onFailure: Expect.fail,
      succinct: succinct);
}

/// Compute a [Spannable] from an [id] in the library [mainUri].
Spannable computeSpannable(
    ElementEnvironment elementEnvironment, Uri mainUri, Id id) {
  if (id is NodeId) {
    return new SourceSpan(mainUri, id.value, id.value + 1);
  } else if (id is MemberId) {
    if (elementEnvironment == null) {
      // If compilation resulted in error we might not have an
      // element environment.
      return NO_LOCATION_SPANNABLE;
    }
    String memberName = id.memberName;
    bool isSetter = false;
    if (memberName != '[]=' && memberName != '==' && memberName.endsWith('=')) {
      isSetter = true;
      memberName = memberName.substring(0, memberName.length - 1);
    }
    LibraryEntity library = elementEnvironment.lookupLibrary(mainUri);
    if (id.className != null) {
      ClassEntity cls = elementEnvironment.lookupClass(library, id.className);
      if (cls == null) {
        // Constant expression in CFE might remove inlined parts of sources.
        print("No class '${id.className}' in $mainUri.");
        return NO_LOCATION_SPANNABLE;
      }
      MemberEntity member = elementEnvironment
          .lookupClassMember(cls, memberName, setter: isSetter);
      if (member == null) {
        ConstructorEntity constructor =
            elementEnvironment.lookupConstructor(cls, memberName);
        if (constructor == null) {
          // Constant expression in CFE might remove inlined parts of sources.
          print("No class member '${memberName}' in $cls.");
          return NO_LOCATION_SPANNABLE;
        }
        return constructor;
      }
      return member;
    } else {
      MemberEntity member = elementEnvironment
          .lookupLibraryMember(library, memberName, setter: isSetter);
      if (member == null) {
        // Constant expression in CFE might remove inlined parts of sources.
        print("No member '${memberName}' in $mainUri.");
        return NO_LOCATION_SPANNABLE;
      }
      return member;
    }
  } else if (id is ClassId) {
    LibraryEntity library = elementEnvironment.lookupLibrary(mainUri);
    ClassEntity cls = elementEnvironment.lookupClass(library, id.className);
    if (cls == null) {
      // Constant expression in CFE might remove inlined parts of sources.
      print("No class '${id.className}' in $mainUri.");
      return NO_LOCATION_SPANNABLE;
    }
    return cls;
  } else if (id is LibraryId) {
    return new SourceSpan(id.uri, null, null);
  }
  throw new UnsupportedError('Unsupported id $id.');
}
