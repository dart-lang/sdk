// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/executor.dart';

import '../builder/class_builder.dart';
import '../builder/member_builder.dart';
import '../source/source_class_builder.dart';
import '../source/source_library_builder.dart';

bool enableMacros = false;

final Uri macroLibraryUri =
    Uri.parse('package:_fe_analyzer_shared/src/macros/api.dart');
const String macroClassName = 'Macro';

class MacroDeclarationData {
  bool macrosAreAvailable = false;
  Map<Uri, List<String>> macroDeclarations = {};
  List<List<Uri>>? compilationSequence;
}

class MacroApplicationData {
  Map<SourceLibraryBuilder, LibraryMacroApplicationData> libraryData = {};

  Future<void> loadMacroIds(
      Future<MacroExecutor> Function() macroExecutorProvider) async {
    MacroExecutor macroExecutor = await macroExecutorProvider();

    Map<ClassBuilder, MacroClassIdentifier> classIdCache = {};

    Map<MacroApplication, MacroInstanceIdentifier> instanceIdCache = {};

    Future<void> ensureMacroClassIds(MacroApplications? applications) async {
      if (applications != null) {
        for (MacroApplication application in applications.macros) {
          MacroClassIdentifier macroClass =
              classIdCache[application.classBuilder] ??=
                  await macroExecutor.loadMacro(
                      application.classBuilder.library.importUri,
                      application.classBuilder.name);
          instanceIdCache[application] = await macroExecutor.instantiateMacro(
              macroClass,
              application.constructorName,
              // TODO(johnniwinther): Support macro arguments.
              new Arguments([], {}));
        }
      }
    }

    for (LibraryMacroApplicationData libraryData in libraryData.values) {
      for (ClassMacroApplicationData classData
          in libraryData.classData.values) {
        await ensureMacroClassIds(classData.classApplications);
        for (MacroApplications applications
            in classData.memberApplications.values) {
          await ensureMacroClassIds(applications);
        }
      }
      for (MacroApplications applications
          in libraryData.memberApplications.values) {
        await ensureMacroClassIds(applications);
      }
    }
  }
}

class MacroApplications {
  final List<MacroApplication> macros;

  MacroApplications(this.macros);
}

class MacroApplication {
  final ClassBuilder classBuilder;
  final String constructorName;
  // TODO(johnniwinther): Add support for arguments.

  MacroApplication(this.classBuilder, this.constructorName);
}

class LibraryMacroApplicationData {
  Map<SourceClassBuilder, ClassMacroApplicationData> classData = {};
  Map<MemberBuilder, MacroApplications> memberApplications = {};
}

class ClassMacroApplicationData {
  MacroApplications? classApplications;
  Map<MemberBuilder, MacroApplications> memberApplications = {};
}
