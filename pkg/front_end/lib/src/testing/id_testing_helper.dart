// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:_fe_analyzer_shared/src/testing/id.dart'
    show
        ActualData,
        ClassId,
        DataRegistry,
        Id,
        IdKind,
        IdValue,
        MemberId,
        NodeId;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:front_end/src/base/nnbd_mode.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/target/targets.dart';

import '../api_prototype/compiler_options.dart'
    show CompilerOptions, DiagnosticMessage;
import '../api_prototype/experimental_flags.dart'
    show AllowedExperimentalFlags, ExperimentalFlag;
import '../api_prototype/terminal_color_support.dart'
    show printDiagnosticMessage;
import '../base/common.dart';
import '../fasta/kernel/macro/macro.dart';
import '../fasta/messages.dart' show FormattedMessage;
import '../kernel_generator_impl.dart' show InternalCompilerResult;
import 'compiler_common.dart' show compileScript, toTestUri;
import 'id_extractor.dart' show DataExtractor;
import 'id_testing_utils.dart';

export '../fasta/compiler_context.dart' show CompilerContext;
export '../fasta/messages.dart' show FormattedMessage;
export '../kernel_generator_impl.dart' show InternalCompilerResult;

/// Test configuration used for testing CFE in its default state.
const TestConfig defaultCfeConfig = const TestConfig(cfeMarker, 'cfe');

/// Test configuration used for testing CFE without nnbd in addition to the
/// default state.
const TestConfig cfeNoNonNullableConfig = const TestConfig(
    cfeMarker, 'cfe without nnbd',
    explicitExperimentalFlags: const {ExperimentalFlag.nonNullable: false});

/// Test configuration used for testing CFE with nnbd in addition to the
/// default state.
const TestConfig cfeNonNullableConfig = const TestConfig(
    cfeWithNnbdMarker, 'cfe with nnbd',
    explicitExperimentalFlags: const {ExperimentalFlag.nonNullable: true});

/// Test configuration used for testing CFE with nnbd as the default state.
const TestConfig cfeNonNullableOnlyConfig = const TestConfig(
    cfeMarker, 'cfe with nnbd',
    explicitExperimentalFlags: const {ExperimentalFlag.nonNullable: true});

class TestConfig {
  final String marker;
  final String name;
  final Map<ExperimentalFlag, bool> explicitExperimentalFlags;
  final AllowedExperimentalFlags? allowedExperimentalFlags;
  final Uri? librariesSpecificationUri;
  final Uri? packageConfigUri;
  // TODO(johnniwinther): Tailor support to redefine selected platform
  // classes/members only.
  final bool compileSdk;
  final TestTargetFlags targetFlags;
  final NnbdMode nnbdMode;

  const TestConfig(this.marker, this.name,
      {this.explicitExperimentalFlags = const {},
      this.allowedExperimentalFlags,
      this.librariesSpecificationUri,
      this.packageConfigUri,
      this.compileSdk = false,
      this.targetFlags = const TestTargetFlags(),
      this.nnbdMode = NnbdMode.Weak});

  /// Called before running test on [testData].
  ///
  /// This allows tests to customize the [options] based on the [testData].
  ///
  /// A custom object can be returned. This is passed to data computer.
  dynamic customizeCompilerOptions(
          CompilerOptions options, TestData testData) =>
      null;

  /// Called after running test on [testData] with the resulting
  /// [testResultData].
  void onCompilationResult(TestData testData, TestResultData testResultData) {}
}

abstract class DataComputer<T> {
  const DataComputer();

  /// Called before testing to setup flags needed for data collection.
  void setup() {}

  /// Called to allow for (awaited) inspection of the [testResultData] from
  /// running the test.
  Future<void> inspectTestResultData(TestResultData testResultData) {
    return new Future.value(null);
  }

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data.
  void computeMemberData(TestResultData testResultData, Member member,
      Map<Id, ActualData<T>> actualMap,
      {bool? verbose}) {}

  /// Function that computes a data mapping for [cls].
  ///
  /// Fills [actualMap] with the data.
  void computeClassData(TestResultData testResultData, Class cls,
      Map<Id, ActualData<T>> actualMap,
      {bool? verbose}) {}

  /// Function that computes a data mapping for [extension].
  ///
  /// Fills [actualMap] with the data.
  void computeExtensionData(TestResultData testResultData, Extension extension,
      Map<Id, ActualData<T>> actualMap,
      {bool? verbose}) {}

  /// Function that computes a data mapping for [extensionTypeDeclaration].
  ///
  /// Fills [actualMap] with the data.
  void computeExtensionTypeDeclarationData(
      TestResultData testResultData,
      ExtensionTypeDeclaration extensionTypeDeclaration,
      Map<Id, ActualData<T>> actualMap,
      {bool? verbose}) {}

  /// Function that computes a data mapping for [library].
  ///
  /// Fills [actualMap] with the data.
  void computeLibraryData(TestResultData testResultData, Library library,
      Map<Id, ActualData<T>> actualMap,
      {bool? verbose}) {}

  /// Returns `true` if this data computer supports tests with compile-time
  /// errors.
  ///
  /// Unsuccessful compilation might leave the compiler in an inconsistent
  /// state, so this testing feature is opt-in.
  bool get supportsErrors => false;

  /// Returns data corresponding to [error].
  T? computeErrorData(TestResultData testResultData, Id id,
          List<FormattedMessage> errors) =>
      null;

  /// Returns the [DataInterpreter] used to check the actual data with the
  /// expected data.
  DataInterpreter<T> get dataValidator;

  /// Returns `true` if data should be collected for member signatures.
  bool get includeMemberSignatures => false;
}

/// Auxiliary data from running a test.
class TestResultData {
  /// The test config used to run the test.
  final TestConfig config;

  /// CustomData is passed from [TestConfig.customizeCompilerOptions].
  final dynamic customData;

  /// The compiler result from running the test, include access to the used
  /// compiler.
  final InternalCompilerResult compilerResult;

  TestResultData(this.config, this.customData, this.compilerResult);
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
      Library library = lookupLibrary(compilerResult.component!, uri)!;
      Member? member;
      int offset = -1;
      if (id.className != null) {
        Class? cls = lookupClass(library, id.className!, required: false);
        if (cls != null) {
          member = lookupClassMember(cls, id.memberName, required: false);
          if (member != null) {
            offset = member.fileOffset;
            if (offset == -1) {
              offset = cls.fileOffset;
            }
          } else {
            offset = cls.fileOffset;
          }
        }
      } else {
        member = lookupLibraryMember(library, id.memberName, required: false);
        offset = member?.fileOffset ?? 0;
      }
      if (offset == -1) {
        offset = 0;
      }
      return offset;
    } else if (id is ClassId) {
      Library library = lookupLibrary(compilerResult.component!, uri)!;
      Extension? extension =
          lookupExtension(library, id.className, required: false);
      if (extension != null) {
        return extension.fileOffset;
      }
      Class? cls = lookupClass(library, id.className, required: false);
      return cls?.fileOffset ?? 0;
    }
    return 0;
  }

  @override
  void reportError(Uri uri, int offset, String message,
      {bool succinct = false}) {
    printMessageInLocation(
        compilerResult.component!.uriToSource, uri, offset, message,
        succinct: succinct);
  }
}

mixin CfeDataRegistryMixin<T> implements DataRegistry<T> {
  InternalCompilerResult get compilerResult;

  @override
  void report(Uri uri, int offset, String message) {
    printMessageInLocation(
        compilerResult.component!.uriToSource, uri, offset, message);
  }

  @override
  void fail(String message) {
    onFailure(message);
  }
}

class CfeDataRegistry<T> with DataRegistry<T>, CfeDataRegistryMixin<T> {
  @override
  final InternalCompilerResult compilerResult;

  @override
  final Map<Id, ActualData<T>> actualMap;

  CfeDataRegistry(this.compilerResult, this.actualMap);
}

abstract class CfeDataExtractor<T> extends DataExtractor<T>
    with CfeDataRegistryMixin<T> {
  @override
  final InternalCompilerResult compilerResult;

  CfeDataExtractor(this.compilerResult, Map<Id, ActualData<T>> actualMap)
      : super(actualMap);
}

/// Create the testing URI used for [fileName] in annotated tests.
Uri createUriForFileName(String fileName) => toTestUri(fileName);

void onFailure(String message) => throw new StateError(message);

/// Creates a test runner for [dataComputer] on [testedConfigs].
RunTestFunction<T> runTestFor<T>(
    DataComputer<T> dataComputer, List<TestConfig> testedConfigs) {
  retainDataForTesting = true;
  return (MarkerOptions markerOptions, TestData testData,
      {required bool testAfterFailures,
      required bool verbose,
      required bool succinct,
      required bool printCode,
      Map<String, List<String>>? skipMap,
      required Uri nullUri}) {
    return runTest(markerOptions, testData, dataComputer, testedConfigs,
        testAfterFailures: testAfterFailures,
        verbose: verbose,
        succinct: succinct,
        printCode: printCode,
        onFailure: onFailure,
        skipMap: skipMap,
        nullUri: nullUri);
  };
}

/// Runs [dataComputer] on [testData] for all [testedConfigs].
///
/// Returns `true` if an error was encountered.
Future<Map<String, TestResult<T>>> runTest<T>(
    MarkerOptions markerOptions,
    TestData testData,
    DataComputer<T> dataComputer,
    List<TestConfig> testedConfigs,
    {required bool testAfterFailures,
    required bool verbose,
    required bool succinct,
    required bool printCode,
    bool forUserLibrariesOnly = true,
    Iterable<Id> globalIds = const <Id>[],
    required void onFailure(String message),
    Map<String, List<String>>? skipMap,
    required Uri nullUri}) async {
  for (TestConfig config in testedConfigs) {
    if (!testData.expectedMaps.containsKey(config.marker)) {
      throw new ArgumentError("Unexpected test marker '${config.marker}'. "
          "Supported markers: ${testData.expectedMaps.keys}.");
    }
  }

  Map<String, TestResult<T>> results = {};
  for (TestConfig config in testedConfigs) {
    if (skipForConfig(testData.name, config.marker, skipMap)) {
      continue;
    }
    results[config.marker] = await runTestForConfig(
        markerOptions, testData, dataComputer, config,
        fatalErrors: !testAfterFailures,
        onFailure: onFailure,
        verbose: verbose,
        succinct: succinct,
        printCode: printCode,
        nullUri: nullUri);
  }
  return results;
}

/// Runs [dataComputer] on [testData] for [config].
///
/// Returns `true` if an error was encountered.
Future<TestResult<T>> runTestForConfig<T>(MarkerOptions markerOptions,
    TestData testData, DataComputer<T> dataComputer, TestConfig config,
    {required bool fatalErrors,
    required bool verbose,
    required bool succinct,
    required bool printCode,
    bool forUserLibrariesOnly = true,
    Iterable<Id> globalIds = const <Id>[],
    required void onFailure(String message),
    required Uri nullUri}) async {
  MemberAnnotations<IdValue> memberAnnotations =
      testData.expectedMaps[config.marker]!;
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
  options.target = new TestTargetWrapper(
      new NoneTarget(config.targetFlags), config.targetFlags);
  options.explicitExperimentalFlags.addAll(config.explicitExperimentalFlags);
  options.allowedExperimentalFlagsForTesting = config.allowedExperimentalFlags;
  options.nnbdMode = config.nnbdMode;
  if (config.librariesSpecificationUri != null) {
    Set<Uri> testFiles =
        testData.memorySourceFiles.keys.map(createUriForFileName).toSet();
    if (testFiles.contains(config.librariesSpecificationUri)) {
      options.librariesSpecificationUri = config.librariesSpecificationUri;
      options.compileSdk = config.compileSdk;
    }
  }
  options.packagesFileUri = config.packageConfigUri;
  dynamic customData = config.customizeCompilerOptions(options, testData);
  InternalCompilerResult compilerResult = await compileScript(
      testData.memorySourceFiles,
      options: options,
      retainDataForTesting: true,
      requireMain: false) as InternalCompilerResult;

  TestResultData testResultData =
      new TestResultData(config, customData, compilerResult);
  config.onCompilationResult(testData, testResultData);

  Component component = compilerResult.component!;
  Map<Uri, Map<Id, ActualData<T>>> actualMaps = <Uri, Map<Id, ActualData<T>>>{};
  Map<Id, ActualData<T>> globalData = <Id, ActualData<T>>{};

  Map<Id, ActualData<T>> actualMapForUri(Uri? uri) {
    if (uri?.scheme == augmentationScheme) {
      throw new UnsupportedError(
          "Annotations are not support on augmentation uris.");
    }
    return actualMaps.putIfAbsent(uri ?? nullUri, () => <Id, ActualData<T>>{});
  }

  if (errors.isNotEmpty) {
    if (!dataComputer.supportsErrors) {
      onFailure("Compilation with compile-time errors not supported for this "
          "testing setup.");
    }

    Map<Uri, Map<int, List<FormattedMessage>>> errorMap = {};
    for (FormattedMessage error in errors) {
      Uri? uri = error.uri;
      bool isAugmentation = uri?.scheme == augmentationScheme;
      if (isAugmentation) {
        uri = testData.entryPoint;
      }
      Map<int, List<FormattedMessage>> map =
          errorMap.putIfAbsent(uri ?? nullUri, () => {});
      List<FormattedMessage> list =
          map.putIfAbsent(isAugmentation ? -1 : error.charOffset, () => []);
      list.add(error);
    }

    errorMap.forEach((Uri uri, Map<int, List<FormattedMessage>> map) {
      map.forEach((int offset, List<FormattedMessage> list) {
        if (offset < 0) {
          // Position errors without offset in the begin of the file.
          offset = 0;
        }
        NodeId id = new NodeId(offset, IdKind.error);
        T? data = dataComputer.computeErrorData(testResultData, id, list);
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
        : (node is Member ? node.fileUri : node.location!.file);
    if (uri.scheme == augmentationScheme) {
      TreeNode library = node;
      while (library is! Library) {
        library = library.parent!;
      }
      uri = library.fileUri;
    }
    return actualMapForUri(uri);
  }

  void processMember(Member member, Map<Id, ActualData<T>> actualMap) {
    if (!dataComputer.includeMemberSignatures && member is Procedure) {
      if (member.isMemberSignature ||
          (member.isForwardingStub && !member.isForwardingSemiStub)) {
        return;
      }
    }
    if (member.enclosingClass != null) {
      if (member.enclosingClass!.isEnum) {
        if (member is Constructor ||
            member.isInstanceMember ||
            member.name.text == 'values') {
          return;
        }
      }
      if (member is Constructor && member.enclosingClass.isMixinApplication) {
        return;
      }
    }
    dataComputer.computeMemberData(testResultData, member, actualMap,
        verbose: verbose);
  }

  void processClass(Class cls, Map<Id, ActualData<T>> actualMap) {
    dataComputer.computeClassData(testResultData, cls, actualMap,
        verbose: verbose);
  }

  void processExtension(Extension extension, Map<Id, ActualData<T>> actualMap) {
    dataComputer.computeExtensionData(testResultData, extension, actualMap,
        verbose: verbose);
  }

  void processExtensionTypeDeclaration(
      ExtensionTypeDeclaration extensionTypeDeclaration,
      Map<Id, ActualData<T>> actualMap) {
    dataComputer.computeExtensionTypeDeclarationData(
        testResultData, extensionTypeDeclaration, actualMap,
        verbose: verbose);
  }

  bool excludeLibrary(Library library) {
    return forUserLibrariesOnly &&
        (library.importUri.isScheme('dart') ||
            library.importUri.isScheme('package'));
  }

  await dataComputer.inspectTestResultData(testResultData);

  for (Library library in component.libraries) {
    if (excludeLibrary(library) &&
        !testData.memorySourceFiles.containsKey(library.fileUri.path)) {
      continue;
    }
    dataComputer.computeLibraryData(
        testResultData, library, actualMapFor(library));
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
    for (ExtensionTypeDeclaration extensionTypeDeclaration
        in library.extensionTypeDeclarations) {
      processExtensionTypeDeclaration(
          extensionTypeDeclaration, actualMapFor(extensionTypeDeclaration));
    }
  }

  List<Uri> globalLibraries = <Uri>[
    Uri.parse('dart:core'),
    Uri.parse('dart:collection'),
    Uri.parse('dart:async'),
  ];

  Class getGlobalClass(String className) {
    Class? cls;
    for (Uri uri in globalLibraries) {
      Library? library = lookupLibrary(component, uri);
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
    Member? member;
    for (Uri uri in globalLibraries) {
      Library? library = lookupLibrary(component, uri);
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
      Member? member;
      if (id.className != null) {
        Class? cls = getGlobalClass(id.className!);
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

  CfeCompiledData<T> compiledData = new CfeCompiledData<T>(
      compilerResult, testData.entryPoint, actualMaps, globalData);
  return checkCode(markerOptions, config.marker, config.name, testData,
      memberAnnotations, compiledData, dataComputer.dataValidator,
      fatalErrors: fatalErrors, succinct: succinct, onFailure: onFailure);
}

void printMessageInLocation(
    Map<Uri, Source> uriToSource, Uri? uri, int offset, String message,
    {bool succinct = false}) {
  if (uri == null) {
    print("(null uri)@$offset: $message");
  } else {
    Source? source = uriToSource[uri];
    if (source == null) {
      print('$uri@$offset: $message');
    } else {
      if (offset >= 1) {
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
