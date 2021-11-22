// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Directory, Platform;

import 'package:_fe_analyzer_shared/src/testing/id.dart' show ActualData, Id;
import 'package:_fe_analyzer_shared/src/testing/id_testing.dart';

import 'package:_fe_analyzer_shared/src/testing/features.dart';
import 'package:front_end/src/testing/id_testing_helper.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';

Future<void> main(List<String> args) async {
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

final Uri macroLibraryUri = Uri.parse('package:macro_builder/src/macro.dart');
const String macroClassName = 'Macro';

class MacroDeclarationData {
  Class? macroClass;
  Map<Library, List<Class>> macroDeclarations = {};
  Set<Class> macroClasses = {};
}

MacroDeclarationData computeMacroDeclarationData(
    Component component, ClassHierarchy classHierarchy) {
  MacroDeclarationData data = new MacroDeclarationData();
  Class? macroClass;
  outer:
  for (Library library in component.libraries) {
    if (library.importUri == macroLibraryUri) {
      for (Class cls in library.classes) {
        if (cls.name == macroClassName) {
          macroClass = cls;
          break outer;
        }
      }
    }
  }
  if (macroClass != null) {
    data.macroClass = macroClass;
    for (Library library in component.libraries) {
      for (Class cls in library.classes) {
        if (classHierarchy.isSubtypeOf(cls, macroClass)) {
          (data.macroDeclarations[library] ??= []).add(cls);
          data.macroClasses.add(cls);
        }
      }
    }
  }
  return data;
}

class MacroApplications {
  List<Class> macros = [];
}

class LibraryMacroApplicationData {
  MacroApplications? libraryApplications;
  Map<Class, ClassMacroApplicationData> classData = {};
  Map<Typedef, MacroApplications> typedefApplications = {};
  Map<Member, MacroApplications> memberApplications = {};
}

class ClassMacroApplicationData {
  MacroApplications? classApplications;
  Map<Member, MacroApplications> memberApplications = {};
}

MacroApplications? computeMacroApplications(
    List<Expression> annotations, MacroDeclarationData macroDeclarationData) {
  MacroApplications applications = new MacroApplications();
  bool hasApplications = false;
  for (Expression annotation in annotations) {
    if (annotation is ConstantExpression) {
      Constant constant = annotation.constant;
      if (constant is InstanceConstant) {
        if (macroDeclarationData.macroClasses.contains(constant.classNode)) {
          applications.macros.add(constant.classNode);
          hasApplications = true;
        }
      }
    }
  }
  return hasApplications ? applications : null;
}

ClassMacroApplicationData? computeClassMacroApplicationData(
    Class cls, MacroDeclarationData macroDeclarationData) {
  ClassMacroApplicationData data = new ClassMacroApplicationData();
  data.classApplications =
      computeMacroApplications(cls.annotations, macroDeclarationData);
  for (Member member in cls.members) {
    MacroApplications? macroApplications =
        computeMacroApplications(member.annotations, macroDeclarationData);
    if (macroApplications != null) {
      data.memberApplications[member] = macroApplications;
    }
  }
  return data.classApplications != null || data.memberApplications.isNotEmpty
      ? data
      : null;
}

LibraryMacroApplicationData? computeLibraryMacroApplicationData(
    Library library, MacroDeclarationData macroDeclarationData) {
  LibraryMacroApplicationData data = new LibraryMacroApplicationData();
  data.libraryApplications =
      computeMacroApplications(library.annotations, macroDeclarationData);
  for (Typedef typedef in library.typedefs) {
    MacroApplications? macroApplications =
        computeMacroApplications(typedef.annotations, macroDeclarationData);
    if (macroApplications != null) {
      data.typedefApplications[typedef] = macroApplications;
    }
  }
  for (Member member in library.members) {
    MacroApplications? macroApplications =
        computeMacroApplications(member.annotations, macroDeclarationData);
    if (macroApplications != null) {
      data.memberApplications[member] = macroApplications;
    }
  }
  for (Class cls in library.classes) {
    ClassMacroApplicationData? classMacroApplicationData =
        computeClassMacroApplicationData(cls, macroDeclarationData);
    if (classMacroApplicationData != null) {
      data.classData[cls] = classMacroApplicationData;
    }
  }
  return data.libraryApplications != null ||
          data.classData.isNotEmpty ||
          data.memberApplications.isNotEmpty ||
          data.typedefApplications.isNotEmpty
      ? data
      : null;
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
  static const String declaredMacros = 'declaredMacros';
  static const String appliedMacros = 'appliedMacros';
}

class MacroDataExtractor extends CfeDataExtractor<Features> {
  late final ClassHierarchy classHierarchy;
  late final MacroDeclarationData macroDeclarationData;

  MacroDataExtractor(InternalCompilerResult compilerResult,
      Map<Id, ActualData<Features>> actualMap)
      : super(compilerResult, actualMap) {
    // TODO(johnniwinther): Why isn't `_UserTag` available in the
    // [ClassHierarchy] provided by the [compilerResult]?
    classHierarchy = new ClassHierarchy(
        compilerResult.component!, new CoreTypes(compilerResult.component!));
    macroDeclarationData =
        computeMacroDeclarationData(compilerResult.component!, classHierarchy);
  }

  LibraryMacroApplicationData? getLibraryMacroApplicationData(Library library) {
    return computeLibraryMacroApplicationData(library, macroDeclarationData);
  }

  MacroApplications? getLibraryMacroApplications(Library library) {
    return getLibraryMacroApplicationData(library)?.libraryApplications;
  }

  ClassMacroApplicationData? getClassMacroApplicationData(Class cls) {
    LibraryMacroApplicationData? applicationData =
        computeLibraryMacroApplicationData(
            cls.enclosingLibrary, macroDeclarationData);
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
  Features computeLibraryValue(Id id, Library node) {
    Features features = new Features();
    if (macroDeclarationData.macroClass != null) {
      features.add(Tags.macrosAreAvailable);
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
  Features computeClassValue(Id id, Class node) {
    Features features = new Features();
    if (getClassMacroApplicationData(node) != null) {
      features.add(Tags.macrosAreApplied);
    }
    registerMacroApplications(features, getClassMacroApplications(node));
    return features;
  }

  @override
  Features computeMemberValue(Id id, Member node) {
    Features features = new Features();
    registerMacroApplications(features, getMemberMacroApplications(node));
    return features;
  }
}
