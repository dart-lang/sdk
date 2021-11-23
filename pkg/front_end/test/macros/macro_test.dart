// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';

import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:front_end/src/fasta/kernel/macro.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/util/graph.dart';

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

String libraryToString(Library library) {
  if (library.importUri.scheme == 'package') {
    return library.importUri.toString();
  } else if (library.importUri.scheme == 'dart') {
    return library.importUri.toString();
  } else {
    return library.importUri.pathSegments.last;
  }
}

String strongComponentToString(Iterable<Library> libraries) {
  List<String> list = libraries.map(libraryToString).toList();
  list.sort();
  return list.join('|');
}

void computeCompilationSequence(
    MacroDeclarationData macroDeclarationData, Graph<Library> libraryGraph,
    {required bool Function(Library) filter}) {
  List<List<Library>> stronglyConnectedComponents =
      computeStrongComponents(libraryGraph);

  Graph<List<Library>> strongGraph =
      new StrongComponentGraph(libraryGraph, stronglyConnectedComponents);
  List<List<List<Library>>> componentLayers = [];
  topologicalSort(strongGraph, layers: componentLayers);
  List<List<Library>> layeredComponents = [];
  List<Library> currentLayer = [];
  for (List<List<Library>> layer in componentLayers) {
    bool declaresMacro = false;
    for (List<Library> component in layer) {
      for (Library library in component) {
        if (filter(library)) continue;
        if (macroDeclarationData.macroDeclarations.containsKey(library)) {
          declaresMacro = true;
        }
        currentLayer.add(library);
      }
    }
    if (declaresMacro) {
      layeredComponents.add(currentLayer);
      currentLayer = [];
    }
  }
  if (currentLayer.isNotEmpty) {
    layeredComponents.add(currentLayer);
  }
  macroDeclarationData.compilationSequence = layeredComponents;
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

  List<List<Library>> getCompilationSequence() {
    computeCompilationSequence(macroDeclarationData,
        new LibraryGraph(compilerResult.component!.libraries),
        filter: (Library library) => library.importUri.scheme == 'dart');
    return macroDeclarationData.compilationSequence;
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
    if (macroDeclarationData.macroClass != null) {
      features.add(Tags.macrosAreAvailable);
    }
    if (node == compilerResult.component!.mainMethod!.enclosingLibrary) {
      features.markAsUnsorted(Tags.compilationSequence);
      for (List<Library> component in getCompilationSequence()) {
        features.addElement(
            Tags.compilationSequence, strongComponentToString(component));
      }
    }
    List<Class>? macroClasses = macroDeclarationData.macroDeclarations[node];
    if (macroClasses != null) {
      for (Class cls in macroClasses) {
        features.addElement(Tags.declaredMacros, cls.name);
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
