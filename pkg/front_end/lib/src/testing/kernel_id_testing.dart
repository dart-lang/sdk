// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/uri.dart';
import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';
import 'package:kernel/ast.dart';

import '../base/messages.dart';
import 'id_testing_utils.dart';

/// Identifier for a test configuration.
class TestConfig {
  /// The id for the test config. This is used in test annotations to
  /// distinguish between expectations that differ between configs.
  ///
  /// For instance if config 'a' expects 'A' and config 'b' expects 'B' on 'foo'
  /// then the annotation in the data file would be
  ///
  ///     /*a:A*/ /*b:B*/ foo
  ///
  final String marker;

  /// The descriptive name of the config, used on error reporting.
  final String name;

  const TestConfig(this.marker, this.name);
}

/// The compilation result of an id-test for given test [config].
abstract class TestResultData<C extends TestConfig, R> {
  /// The test config used to run the test.
  final C config;

  /// The compiler result from running the test, include access to the used
  /// compiler.
  final R compilerResult;

  TestResultData(this.config, this.compilerResult);

  Component get component;
}

/// Abstract base class used for computing the id-test annotation data for
/// different parts of a [Component].
abstract class DataComputer<T, C extends TestConfig, R,
    D extends TestResultData<C, R>> {
  const DataComputer();

  /// Called before testing to setup flags needed for data collection.
  void setup() {}

  /// Called to allow for (awaited) inspection of the [testResultData] from
  /// running the test.
  Future<void> inspectTestResultData(D testResultData) {
    return new Future.value(null);
  }

  /// Function that computes a data mapping for [member].
  ///
  /// Fills [actualMap] with the data.
  void computeMemberData(
      D testResultData, Member member, Map<Id, ActualData<T>> actualMap,
      {bool? verbose}) {}

  /// Function that computes a data mapping for [cls].
  ///
  /// Fills [actualMap] with the data.
  void computeClassData(
      D testResultData, Class cls, Map<Id, ActualData<T>> actualMap,
      {bool? verbose}) {}

  /// Function that computes a data mapping for [extension].
  ///
  /// Fills [actualMap] with the data.
  void computeExtensionData(
      D testResultData, Extension extension, Map<Id, ActualData<T>> actualMap,
      {bool? verbose}) {}

  /// Function that computes a data mapping for [extensionTypeDeclaration].
  ///
  /// Fills [actualMap] with the data.
  void computeExtensionTypeDeclarationData(
      D testResultData,
      ExtensionTypeDeclaration extensionTypeDeclaration,
      Map<Id, ActualData<T>> actualMap,
      {bool? verbose}) {}

  /// Function that computes a data mapping for [library].
  ///
  /// Fills [actualMap] with the data.
  void computeLibraryData(
      D testResultData, Library library, Map<Id, ActualData<T>> actualMap,
      {bool? verbose}) {}

  /// Returns `true` if this data computer supports tests with compile-time
  /// errors.
  ///
  /// Unsuccessful compilation might leave the compiler in an inconsistent
  /// state, so this testing feature is opt-in.
  bool get supportsErrors => false;

  /// Returns data corresponding to [error].
  T? computeErrorData(D testResultData, Id id, List<FormattedMessage> errors) =>
      null;

  /// Returns the [DataInterpreter] used to check the actual data with the
  /// expected data.
  DataInterpreter<T> get dataValidator;

  /// Returns `true` if data should be collected for member signatures.
  bool get includeMemberSignatures => false;
}

/// [CompiledData] that includes [Component] and the [compilerResult].
class KernelCompiledData<T, R> extends CompiledData<T> {
  final R compilerResult;
  final Component component;

  KernelCompiledData(this.compilerResult, this.component, super.mainUri,
      super.actualMaps, super.globalData);

  @override
  int getOffsetFromId(Id id, Uri uri) {
    if (id is NodeId) return id.value;
    if (id is MemberId) {
      Library library = lookupLibrary(component, uri)!;
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
      Library library = lookupLibrary(component, uri)!;
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
    printMessageInLocation(component.uriToSource, uri, offset, message,
        succinct: succinct);
  }
}

String createMessageInLocation(
    Map<Uri, Source> uriToSource, Uri? uri, int offset, String message,
    {bool succinct = false}) {
  StringBuffer sb = new StringBuffer();
  if (uri == null) {
    sb.write("(null uri)@$offset: $message");
  } else {
    Source? source = uriToSource[uri];
    if (source == null) {
      sb.write('$uri@$offset: $message');
    } else {
      if (offset >= 1) {
        Location location = source.getLocation(uri, offset);
        sb.write('$location: $message');
        if (!succinct) {
          sb.writeln('');
          sb.writeln(source.getTextLine(location.line));
          sb.write(' ' * (location.column - 1) + '^');
        }
      } else {
        sb.write('$uri: $message');
      }
    }
  }
  return sb.toString();
}

void printMessageInLocation(
    Map<Uri, Source> uriToSource, Uri? uri, int offset, String message,
    {bool succinct = false}) {
  print(createMessageInLocation(uriToSource, uri, offset, message,
      succinct: succinct));
}

/// Computes the [TestResult] for an id-test [testData] using the result of
/// the compilation in [testResultData].
Future<TestResult<T>> processCompiledResult<T, C extends TestConfig, R,
        D extends TestResultData<C, R>>(
    MarkerOptions markerOptions,
    TestData testData,
    DataComputer<T, C, R, D> dataComputer,
    D testResultData,
    List<FormattedMessage> errors,
    {required bool fatalErrors,
    required bool verbose,
    required bool succinct,
    bool forUserLibrariesOnly = true,
    required void onFailure(String message),
    required Uri nullUri}) async {
  C config = testResultData.config;
  R compilerResult = testResultData.compilerResult;
  Component component = testResultData.component;
  Map<Uri, Map<Id, ActualData<T>>> actualMaps = <Uri, Map<Id, ActualData<T>>>{};
  Map<Id, ActualData<T>> globalData = <Id, ActualData<T>>{};

  Map<Id, ActualData<T>> actualMapForUri(Uri? uri) {
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
      bool isMacroLibrary = false;
      if (uri != null && isMacroLibraryUri(uri)) {
        isMacroLibrary = true;
        uri = toOriginLibraryUri(uri);
      }
      Map<int, List<FormattedMessage>> map =
          errorMap.putIfAbsent(uri ?? nullUri, () => {});
      List<FormattedMessage> list =
          map.putIfAbsent(isMacroLibrary ? -1 : error.charOffset, () => []);
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
    if (isMacroLibraryUri(uri)) {
      uri = toOriginLibraryUri(uri);
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
    if (member.isExtensionTypeMember) {
      for (ExtensionTypeDeclaration extension
          in member.enclosingLibrary.extensionTypeDeclarations) {
        for (ExtensionTypeMemberDescriptor descriptor
            in extension.memberDescriptors) {
          if (descriptor.tearOffReference == member.reference) {
            return;
          }
        }
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

  MemberAnnotations<IdValue> memberAnnotations =
      testData.expectedMaps[config.marker]!;
  Iterable<Id> globalIds = memberAnnotations.globalData.keys;

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

  KernelCompiledData<T, R> compiledData = new KernelCompiledData<T, R>(
      compilerResult, component, testData.entryPoint, actualMaps, globalData);
  return checkCode(markerOptions, config.marker, config.name, testData,
      memberAnnotations, compiledData, dataComputer.dataValidator,
      fatalErrors: fatalErrors, succinct: succinct, onFailure: onFailure);
}
