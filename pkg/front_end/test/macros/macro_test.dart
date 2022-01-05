// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';

import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/fasta/kernel/macro.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:kernel/ast.dart';

Future<void> main(List<String> args) async {
  enableMacros = true;

  Directory dataDir =
      new Directory.fromUri(Platform.script.resolve('data/tests'));
  await runTests<Features>(dataDir,
      args: args,
      createUriForFileName: createUriForFileName,
      onFailure: onFailure,
      runTest: runTestFor(const MacroDataComputer(), [
        new TestConfig(cfeMarker, 'cfe',
            explicitExperimentalFlags: {ExperimentalFlag.macros: true},
            packageConfigUri:
                Platform.script.resolve('data/package_config.json'))
      ]));
}

class MacroDataComputer extends DataComputer<Features> {
  const MacroDataComputer();

  @override
  void computeMemberData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Member member,
      Map<Id, ActualData<Features>> actualMap,
      {bool? verbose}) {
    member.accept(new MacroDataExtractor(compilerResult, actualMap));
  }

  @override
  void computeClassData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Class cls,
      Map<Id, ActualData<Features>> actualMap,
      {bool? verbose}) {
    new MacroDataExtractor(compilerResult, actualMap).computeForClass(cls);
  }

  @override
  void computeLibraryData(
      TestConfig config,
      InternalCompilerResult compilerResult,
      Library library,
      Map<Id, ActualData<Features>> actualMap,
      {bool? verbose}) {
    new MacroDataExtractor(compilerResult, actualMap)
        .computeForLibrary(library);
  }

  @override
  DataInterpreter<Features> get dataValidator =>
      const FeaturesDataInterpreter();
}

class Tags {
  static const String macrosAreAvailable = 'macrosAreAvailable';
  static const String macrosAreApplied = 'macrosAreApplied';
  static const String compilationSequence = 'compilationSequence';
  static const String declaredMacros = 'declaredMacros';
  static const String appliedMacros = 'appliedMacros';
}

String importUriToString(Uri importUri) {
  if (importUri.scheme == 'package') {
    return importUri.toString();
  } else if (importUri.scheme == 'dart') {
    return importUri.toString();
  } else {
    return importUri.pathSegments.last;
  }
}

String libraryToString(Library library) => importUriToString(library.importUri);

String strongComponentToString(Iterable<Uri> uris) {
  List<String> list = uris.map(importUriToString).toList();
  list.sort();
  return list.join('|');
}

class MacroDataExtractor extends CfeDataExtractor<Features> {
  late final MacroDeclarationData macroDeclarationData;
  late final MacroApplicationData macroApplicationData;

  MacroDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<Features>> actualMap)
      : super(compilerResult, actualMap) {
    macroDeclarationData = compilerResult
        .kernelTargetForTesting!.loader.dataForTesting!.macroDeclarationData;
    macroApplicationData = compilerResult
        .kernelTargetForTesting!.loader.dataForTesting!.macroApplicationData;
  }

  LibraryMacroApplicationData? getLibraryMacroApplicationData(Library library) {
    return macroApplicationData.libraryData[library];
  }

  MacroApplications? getLibraryMacroApplications(Library library) {
    return getLibraryMacroApplicationData(library)?.libraryApplications;
  }

  ClassMacroApplicationData? getClassMacroApplicationData(Class cls) {
    LibraryMacroApplicationData? applicationData =
        getLibraryMacroApplicationData(cls.enclosingLibrary);
    if (applicationData != null) {
      return applicationData.classData[cls];
    }
    return null;
  }

  MacroApplications? getClassMacroApplications(Class cls) {
    return getClassMacroApplicationData(cls)?.classApplications;
  }

  MacroApplications? getMemberMacroApplications(Member member) {
    Class? enclosingClass = member.enclosingClass;
    if (enclosingClass != null) {
      return getClassMacroApplicationData(enclosingClass)
          ?.memberApplications[member];
    } else {
      return getLibraryMacroApplicationData(member.enclosingLibrary)
          ?.memberApplications[member];
    }
  }

  void registerMacroApplications(
      Features features, MacroApplications? macroApplications) {
    if (macroApplications != null) {
      for (Class cls in macroApplications.macros) {
        features.addElement(Tags.appliedMacros, cls.name);
      }
    }
  }

  @override
  Features computeClassValue(Id id, Class node) {
    Features features = new Features();
    if (getClassMacroApplicationData(node) != null) {
      features.add(Tags.macrosAreApplied);
    }
    registerMacroApplications(features, getClassMacroApplications(node));
    return features;
  }

  @override
  Features computeLibraryValue(Id id, Library node) {
    Features features = new Features();
    if (macroDeclarationData.macrosAreAvailable) {
      features.add(Tags.macrosAreAvailable);
    }
    if (node == compilerResult.component!.mainMethod!.enclosingLibrary) {
      if (macroDeclarationData.compilationSequence != null) {
        features.markAsUnsorted(Tags.compilationSequence);
        for (List<Uri> component in macroDeclarationData.compilationSequence!) {
          features.addElement(
              Tags.compilationSequence, strongComponentToString(component));
        }
      }
    }
    List<String>? macroClasses =
        macroDeclarationData.macroDeclarations[node.importUri];
    if (macroClasses != null) {
      for (String clsName in macroClasses) {
        features.addElement(Tags.declaredMacros, clsName);
      }
    }
    if (getLibraryMacroApplicationData(node) != null) {
      features.add(Tags.macrosAreApplied);
    }
    registerMacroApplications(features, getLibraryMacroApplications(node));
    return features;
  }

  @override
  Features computeMemberValue(Id id, Member node) {
    Features features = new Features();
    registerMacroApplications(features, getMemberMacroApplications(node));
    return features;
  }
}
