// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;
import 'package:front_end/src/api_prototype/experimental_flags.dart'
    show ExperimentalFlag;
import 'package:front_end/src/testing/id_extractor.dart' show DataExtractor;
import 'package:kernel/ast.dart';
import '../kernel_generator_impl.dart' show CompilerResult;
import 'compiler_common.dart' show compileScript, toTestUri;
import 'id.dart' show ActualData, ClassId, Id, IdValue, MemberId, NodeId;
import 'id_testing.dart'
    show
        CompiledData,
        DataInterpreter,
        MemberAnnotations,
        RunTestFunction,
        TestData,
        cfeMarker,
        checkCode;
import 'id_testing_utils.dart';

export '../fasta/compiler_context.dart' show CompilerContext;
export '../kernel_generator_impl.dart' show CompilerResult;

/// Test configuration used for testing CFE in its default state.
const TestConfig defaultCfeConfig = const TestConfig(cfeMarker, 'cfe');

/// Test configuration used for testing CFE in with constant evaluation.
const TestConfig cfeConstantUpdate2018Config = const TestConfig(
    cfeMarker, 'cfe with constant-update-2018',
    experimentalFlags: const {ExperimentalFlag.constantUpdate2018: true});

class TestConfig {
  final String marker;
  final String name;
  final Map<ExperimentalFlag, bool> experimentalFlags;

  const TestConfig(this.marker, this.name, {this.experimentalFlags = const {}});
}

// TODO(johnniwinther): Support annotations for compile-time errors.
abstract class DataComputer<T> {
  const DataComputer();

  /// Called before testing to setup flags needed for data collection.
  void setup() {}

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data.
  void computeMemberData(CompilerResult compilerResult, Member member,
      Map<Id, ActualData<T>> actualMap,
      {bool verbose});

  /// Function that computes a data mapping for [cls].
  ///
  /// Fills [actualMap] with the data.
  void computeClassData(CompilerResult compilerResult, Class cls,
      Map<Id, ActualData<T>> actualMap,
      {bool verbose}) {}

  /// Function that computes a data mapping for [library].
  ///
  /// Fills [actualMap] with the data.
  void computeLibraryData(CompilerResult compilerResult, Library library,
      Map<Id, ActualData<T>> actualMap,
      {bool verbose}) {}

  /// Returns the [DataInterpreter] used to check the actual data with the
  /// expected data.
  DataInterpreter<T> get dataValidator;
}

class CfeCompiledData<T> extends CompiledData<T> {
  final CompilerResult compilerResult;

  CfeCompiledData(
      this.compilerResult,
      Uri mainUri,
      Map<Uri, Map<Id, ActualData<T>>> actualMaps,
      Map<Id, ActualData<T>> globalData)
      : super(mainUri, actualMaps, globalData);

  @override
  int getOffsetFromId(Id id, Uri uri) {
    if (id is NodeId) return id.value;
    if (id is MemberId) {
      Library library = lookupLibrary(compilerResult.component, uri);
      Member member;
      if (id.className != null) {
        Class cls = lookupClass(library, id.className);
        member = lookupClassMember(cls, id.memberName);
      } else {
        member = lookupLibraryMember(library, id.memberName);
      }
      return member.fileOffset;
    } else if (id is ClassId) {
      Library library = lookupLibrary(compilerResult.component, uri);
      Class cls = lookupClass(library, id.className);
      return cls.fileOffset;
    }
    return null;
  }

  @override
  void reportError(Uri uri, int offset, String message) {
    printMessageInLocation(
        compilerResult.component.uriToSource, uri, offset, message);
  }
}

abstract class CfeDataExtractor<T> extends DataExtractor<T> {
  final CompilerResult compilerResult;

  CfeDataExtractor(this.compilerResult, Map<Id, ActualData<T>> actualMap)
      : super(actualMap);

  @override
  void report(Uri uri, int offset, String message) {
    printMessageInLocation(
        compilerResult.component.uriToSource, uri, offset, message);
  }

  @override
  void fail(String message) {
    onFailure(message);
  }
}

/// Create the testing URI used for [fileName] in annotated tests.
Uri createUriForFileName(String fileName, {bool isLib}) => toTestUri(fileName);

void onFailure(String message) => throw new StateError(message);

/// Creates a test runner for [dataComputer] on [testedConfigs].
RunTestFunction runTestFor<T>(
    DataComputer<T> dataComputer, List<TestConfig> testedConfigs) {
  return (TestData testData,
      {bool testAfterFailures, bool verbose, bool printCode}) {
    return runTest(testData, dataComputer, testedConfigs,
        testAfterFailures: testAfterFailures,
        verbose: verbose,
        printCode: printCode,
        onFailure: onFailure);
  };
}

/// Runs [dataComputer] on [testData] for all [testedConfigs].
///
/// Returns `true` if an error was encountered.
Future<bool> runTest<T>(TestData testData, DataComputer<T> dataComputer,
    List<TestConfig> testedConfigs,
    {bool testAfterFailures,
    bool verbose,
    bool printCode,
    bool forUserLibrariesOnly: true,
    Iterable<Id> globalIds: const <Id>[],
    void onFailure(String message)}) async {
  bool hasFailures = false;
  for (TestConfig config in testedConfigs) {
    if (await runTestForConfig(testData, dataComputer, config,
        fatalErrors: !testAfterFailures,
        onFailure: onFailure,
        verbose: verbose,
        printCode: printCode)) {
      hasFailures = true;
    }
  }
  return hasFailures;
}

/// Runs [dataComputer] on [testData] for [config].
///
/// Returns `true` if an error was encountered.
Future<bool> runTestForConfig<T>(
    TestData testData, DataComputer<T> dataComputer, TestConfig config,
    {bool fatalErrors,
    bool verbose,
    bool printCode,
    bool forUserLibrariesOnly: true,
    Iterable<Id> globalIds: const <Id>[],
    void onFailure(String message)}) async {
  MemberAnnotations<IdValue> memberAnnotations =
      testData.expectedMaps[config.marker];
  Iterable<Id> globalIds = memberAnnotations.globalData.keys;
  CompilerOptions options = new CompilerOptions();
  options.debugDump = printCode;
  options.experimentalFlags.addAll(config.experimentalFlags);
  CompilerResult compilerResult = await compileScript(
      testData.memorySourceFiles,
      options: options,
      retainDataForTesting: true);
  Component component = compilerResult.component;
  Map<Uri, Map<Id, ActualData<T>>> actualMaps = <Uri, Map<Id, ActualData<T>>>{};
  Map<Id, ActualData<T>> globalData = <Id, ActualData<T>>{};

  Map<Id, ActualData<T>> actualMapFor(TreeNode node) {
    Uri uri = node is Library ? node.fileUri : node.location.file;
    return actualMaps.putIfAbsent(uri, () => <Id, ActualData<T>>{});
  }

  void processMember(Member member, Map<Id, ActualData<T>> actualMap) {
    if (member.enclosingClass != null) {
      if (member.enclosingClass.isEnum) {
        if (member is Constructor ||
            member.isInstanceMember ||
            member.name == 'values') {
          return;
        }
      }
      if (member is Constructor && member.enclosingClass.isMixinApplication) {
        return;
      }
    }
    dataComputer.computeMemberData(compilerResult, member, actualMap,
        verbose: verbose);
  }

  void processClass(Class cls, Map<Id, ActualData<T>> actualMap) {
    dataComputer.computeClassData(compilerResult, cls, actualMap,
        verbose: verbose);
  }

  bool excludeLibrary(Library library) {
    return forUserLibrariesOnly &&
        (library.importUri.scheme == 'dart' ||
            library.importUri.scheme == 'package');
  }

  for (Library library in component.libraries) {
    if (excludeLibrary(library)) continue;
    dataComputer.computeLibraryData(
        compilerResult, library, actualMapFor(library));
    for (Class cls in library.classes) {
      processClass(cls, actualMapFor(cls));
      for (Member member in cls.members) {
        processMember(member, actualMapFor(member));
      }
    }
    for (Member member in library.members) {
      processMember(member, actualMapFor(member));
    }
  }

  List<Uri> globalLibraries = <Uri>[
    Uri.parse('dart:core'),
    Uri.parse('dart:collection'),
    Uri.parse('dart:async'),
  ];

  Class getGlobalClass(String className) {
    Class cls;
    for (Uri uri in globalLibraries) {
      Library library = lookupLibrary(component, uri);
      if (library != null) {
        cls ??= lookupClass(library, className);
      }
    }
    if (cls == null) {
      throw "Global class '$className' not found in the global "
          "libraries: ${globalLibraries.join(', ')}";
    }
    return cls;
  }

  Member getGlobalMember(String memberName) {
    Member member;
    for (Uri uri in globalLibraries) {
      Library library = lookupLibrary(component, uri);
      if (library != null) {
        member ??= lookupLibraryMember(library, memberName);
      }
    }
    if (member == null) {
      throw "Global member '$memberName' not found in the global "
          "libraries: ${globalLibraries.join(', ')}";
    }
    return member;
  }

  for (Id id in globalIds) {
    if (id is MemberId) {
      Member member;
      if (id.className != null) {
        Class cls = getGlobalClass(id.className);
        member = lookupClassMember(cls, id.memberName);
        if (member == null) {
          throw "Global member '${id.memberName}' not found in class $cls.";
        }
      } else {
        member = getGlobalMember(id.memberName);
      }
      processMember(member, globalData);
    } else if (id is ClassId) {
      Class cls = getGlobalClass(id.className);
      processClass(cls, globalData);
    } else {
      throw new UnsupportedError("Unexpected global id: $id");
    }
  }

  CfeCompiledData compiledData = new CfeCompiledData<T>(
      compilerResult, testData.testFileUri, actualMaps, globalData);

  return checkCode(config.name, testData.testFileUri, testData.code,
      memberAnnotations, compiledData, dataComputer.dataValidator,
      fatalErrors: fatalErrors, onFailure: onFailure);
}

void printMessageInLocation(
    Map<Uri, Source> uriToSource, Uri uri, int offset, String message) {
  if (uri == null) {
    print(message);
  } else {
    Source source = uriToSource[uri];
    if (source == null) {
      print('$uri@$offset: $message');
    } else {
      if (offset != null) {
        Location location = source.getLocation(uri, offset);
        print('$location: $message');
        print(source.getTextLine(location.line));
        print(' ' * (location.column - 1) + '^');
      } else {
        print('$uri: $message');
      }
    }
  }
}
