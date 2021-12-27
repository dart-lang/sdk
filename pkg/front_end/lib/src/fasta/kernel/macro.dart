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
  final List<Class> macros;

  MacroApplications(this.macros);
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
