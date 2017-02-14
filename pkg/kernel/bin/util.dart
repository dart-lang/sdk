// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/transformations/treeshaker.dart';

/// Parses all given [embedderEntryPointManifests] and returns the program roots
/// specified in them.
///
/// A embedder manifest consists of lines of the following form:
///
///   <import-uri>,<class-name>,<member-name>
///
/// Where
///
///   <import-uri> : The uri of the library which contains the root.
///   <class-name> : Is either the name of the class or '::' for the library.
///   <member-name>: Can be of the forms:
///
///     - get:<name>
///     - set:<name>
///     - <field-name>
///     - <procedure-name>
///     - <constructor-name>
///     - <klass>.<factory-constructor-name>
///     - *external-instantiation*
///
List<ProgramRoot> parseProgramRoots(List<String> embedderEntryPointManifests) {
  List<ProgramRoot> roots = <ProgramRoot>[];

  for (var file in embedderEntryPointManifests) {
    var lines = new File(file).readAsStringSync().trim().split('\n');
    for (var line in lines) {
      var parts = line.split(',');
      assert(parts.length == 3);

      var library = parts[0];
      var klass = parts[1];
      var member = parts[2];

      // The vm represents the toplevel class as '::'.
      if (klass == '::') klass = null;

      ProgramRootKind kind = ProgramRootKind.Other;

      if (member.startsWith('set:')) {
        kind = ProgramRootKind.Setter;
        member = member.substring('set:'.length);
      } else if (member.startsWith('get:')) {
        kind = ProgramRootKind.Getter;
        member = member.substring('get:'.length);
      } else if (member == "*external-instantiation*") {
        kind = ProgramRootKind.ExternallyInstantiatedClass;
        member = null;
      } else if (member.startsWith('$klass.')) {
        kind = ProgramRootKind.Constructor;
        member = member.substring('$klass.'.length);
      }

      roots.add(new ProgramRoot(library, klass, member, kind));
    }
  }

  return roots;
}
