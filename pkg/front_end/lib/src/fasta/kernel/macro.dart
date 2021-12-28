// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

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
  Map<Library, LibraryMacroApplicationData> libraryData = {};
}

class MacroApplications {
  final List<MacroApplication> macros;

  MacroApplications(this.macros);
}

class MacroApplication {
  final Class cls;
  final String constructorName;
  // TODO(johnniwinther): Add support for arguments.

  MacroApplication(this.cls, this.constructorName);
}

class LibraryMacroApplicationData {
  Map<Class, ClassMacroApplicationData> classData = {};
  Map<Member, MacroApplications> memberApplications = {};
}

class ClassMacroApplicationData {
  MacroApplications? classApplications;
  Map<Member, MacroApplications> memberApplications = {};
}
