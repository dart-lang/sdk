// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import '../api_prototype/compiler_options.dart'
    show CompilerOptions, DiagnosticMessage;
import '../api_prototype/experimental_flags.dart' show ExperimentalFlag;
import '../api_prototype/terminal_color_support.dart'
    show printDiagnosticMessage;
import '../base/common.dart';
import '../fasta/messages.dart' show FormattedMessage;
import '../fasta/severity.dart' show Severity;
import '../kernel_generator_impl.dart' show InternalCompilerResult;
import 'compiler_common.dart' show compileScript, toTestUri;
import 'id.dart'
    show ActualData, ClassId, Id, IdKind, IdValue, MemberId, NodeId;
import 'id_extractor.dart' show DataExtractor;
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
export '../kernel_generator_impl.dart' show InternalCompilerResult;
export '../fasta/messages.dart' show FormattedMessage;

/// Test configuration used for testing CFE in its default state.
const TestConfig defaultCfeConfig = const TestConfig(cfeMarker, 'cfe');

/// Test configuration used for testing CFE with extension methods.
const TestConfig cfeExtensionMethodsConfig = const TestConfig(
    cfeMarker, 'cfe with extension methods',
    experimentalFlags: const {ExperimentalFlag.extensionMethods: true});

class TestConfig {
  final String marker;
  final String name;
  final Map<ExperimentalFlag, bool> experimentalFlags;
  final Uri librariesSpecificationUri;

  const TestConfig(this.marker, this.name,
      {this.experimentalFlags = const {}, this.librariesSpecificationUri});

  void customizeCompilerOptions(CompilerOptions options) {}
}

// TODO(johnniwinther): Support annotations for compile-time errors.
abstract class DataComputer<T> {
  const DataComputer();

  /// Called before testing to setup flags needed for data collection.
  void setup() {}

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data.
  void computeMemberData(InternalCompilerResult compilerResult, Member member,
      Map<Id, ActualData<T>> actualMap,
      {bool verbose}) {}

  /// Function that computes a data mapping for [cls].
  ///
  /// Fills [actualMap] with the data.
  void computeClassData(InternalCompilerResult compilerResult, Class cls,
      Map<Id, ActualData<T>> actualMap,
      {bool verbose}) {}

  /// Function that computes a data mapping for [extension].
  ///
  /// Fills [actualMap] with the data.
  void computeExtensionData(InternalCompilerResult compilerResult,
      Extension extension, Map<Id, ActualData<T>> actualMap,
      {bool verbose}) {}

  /// Function that computes a data mapping for [library].
  ///
  /// Fills [actualMap] with the data.
  void computeLibraryData(InternalCompilerResult compilerResult,
      Library library, Map<Id, ActualData<T>> actualMap,
      {bool verbose}) {}

  /// Returns `true` if this data computer supports tests with compile-time
  /// errors.
  ///
  /// Unsuccessful compilation might leave the compiler in an inconsistent
  /// state, so this testing feature is opt-in.
  bool get supportsErrors => false;

  /// Returns data corresponding to [error].
  T computeErrorData(InternalCompilerResult compiler, Id id,
          List<FormattedMessage> errors) =>
      null;

  /// Returns the [DataInterpreter] used to check the actual data with the
  /// expected data.
  DataInterpreter<T> get dataValidator;
}

class CfeCompiledData<T> extends CompiledData<T> {
  final InternalCompilerResult compilerResult;

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
      int offset;
      if (id.className != null) {
        Class cls = lookupClass(library, id.className);
        member = lookupClassMember(cls, id.memberName);
        offset = member.fileOffset;
        if (offset == -1) {
          offset = cls.fileOffset;
        }
      } else {
        member = lookupLibraryMember(library, id.memberName);
        offset = member.fileOffset;
      }
      if (offset == -1) {
        offset = 0;
      }
      return offset;
    } else if (id is ClassId) {
      Library library = lookupLibrary(compilerResult.component, uri);
      Extension extension =
          lookupExtension(library, id.className, required: false);
      if (extension != null) {
        return extension.fileOffset;
      }
      Class cls = lookupClass(library, id.className);
      return cls.fileOffset;
    }
    return null;
  }

  @override
  void reportError(Uri uri, int offset, String message,
      {bool succinct: false}) {
    printMessageInLocation(
        compilerResult.component.uriToSource, uri, offset, message,
        succinct: succinct);
  }
}

abstract class CfeDataExtractor<T> extends DataExtractor<T> {
  final InternalCompilerResult compilerResult;

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
Uri createUriForFileName(String fileName) => toTestUri(fileName);

void onFailure(String message) => throw new StateError(message);

/// Creates a test runner for [dataComputer] on [testedConfigs].
RunTestFunction runTestFor<T>(
    DataComputer<T> dataComputer, List<TestConfig> testedConfigs) {
  retainDataForTesting = true;
  return (TestData testData,
      {bool testAfterFailures, bool verbose, bool succinct, bool printCode}) {
    return runTest(testData, dataComputer, testedConfigs,
        testAfterFailures: testAfterFailures,
        verbose: verbose,
        succinct: succinct,
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
    bool succinct,
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
        succinct: succinct,
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
    bool succinct,
    bool printCode,
    bool forUserLibrariesOnly: true,
    Iterable<Id> globalIds: const <Id>[],
    void onFailure(String message)}) async {
  MemberAnnotations<IdValue> memberAnnotations =
      testData.expectedMaps[config.marker];
  Iterable<Id> globalIds = memberAnnotations.globalData.keys;
  CompilerOptions options = new CompilerOptions();
  List<FormattedMessage> errors = [];
  options.onDiagnostic = (DiagnosticMessage message) {
    if (message is FormattedMessage && message.severity == Severity.error) {
      errors.add(message);
    }
    if (!succinct) printDiagnosticMessage(message, print);
  };
  options.debugDump = printCode;
  options.experimentalFlags.addAll(config.experimentalFlags);
  if (config.librariesSpecificationUri != null) {
    Set<Uri> testFiles =
        testData.memorySourceFiles.keys.map(createUriForFileName).toSet();
    if (testFiles.contains(config.librariesSpecificationUri)) {
      options.librariesSpecificationUri = config.librariesSpecificationUri;
    }
  }
  config.customizeCompilerOptions(options);
  InternalCompilerResult compilerResult = await compileScript(
      testData.memorySourceFiles,
      options: options,
      retainDataForTesting: true);

  Component component = compilerResult.component;
  Map<Uri, Map<Id, ActualData<T>>> actualMaps = <Uri, Map<Id, ActualData<T>>>{};
  Map<Id, ActualData<T>> globalData = <Id, ActualData<T>>{};

  Map<Id, ActualData<T>> actualMapForUri(Uri uri) {
    return actualMaps.putIfAbsent(uri, () => <Id, ActualData<T>>{});
  }

  if (errors.isNotEmpty) {
    if (!dataComputer.supportsErrors) {
      onFailure("Compilation with compile-time errors not supported for this "
          "testing setup.");
    }

    Map<Uri, Map<int, List<FormattedMessage>>> errorMap = {};
    for (FormattedMessage error in errors) {
      Map<int, List<FormattedMessage>> map =
          errorMap.putIfAbsent(error.uri, () => {});
      List<FormattedMessage> list = map.putIfAbsent(error.charOffset, () => []);
      list.add(error);
    }

    errorMap.forEach((Uri uri, Map<int, List<FormattedMessage>> map) {
      map.forEach((int offset, List<DiagnosticMessage> list) {
        NodeId id = new NodeId(offset, IdKind.error);
        T data = dataComputer.computeErrorData(compilerResult, id, list);
        if (data != null) {
          Map<Id, ActualData<T>> actualMap = actualMapForUri(uri);
          actualMap[id] = new ActualData<T>(id, data, uri, offset, list);
        }
      });
    });
  }

  Map<Id, ActualData<T>> actualMapFor(TreeNode node) {
    Uri uri = node is Library
        ? node.fileUri
        : (node is Member ? node.fileUri : node.location.file);
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

  void processExtension(Extension extension, Map<Id, ActualData<T>> actualMap) {
    dataComputer.computeExtensionData(compilerResult, extension, actualMap,
        verbose: verbose);
  }

  bool excludeLibrary(Library library) {
    return forUserLibrariesOnly &&
        (library.importUri.scheme == 'dart' ||
            library.importUri.scheme == 'package');
  }

  for (Library library in component.libraries) {
    if (excludeLibrary(library) &&
        !testData.memorySourceFiles.containsKey(library.fileUri.path)) {
      continue;
    }
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
    for (Extension extension in library.extensions) {
      processExtension(extension, actualMapFor(extension));
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
      fatalErrors: fatalErrors, succinct: succinct, onFailure: onFailure);
}

void printMessageInLocation(
    Map<Uri, Source> uriToSource, Uri uri, int offset, String message,
    {bool succinct: false}) {
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
        if (!succinct) {
          print(source.getTextLine(location.line));
          print(' ' * (location.column - 1) + '^');
        }
      } else {
        print('$uri: $message');
      }
    }
  }
}
