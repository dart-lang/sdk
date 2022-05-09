#!/usr/bin/env dart
// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/src/tool/command_line_util.dart';

void usage() {
  print("Compares the hierarchies of two dill files.");
  print("");
  print("Usage: dart <script> dillFile1.dill dillFile2.dill "
      "[import:uri#classToIgnore|another:uri#andClassToIgnore]");
  exit(1);
}

void main(List<String> args) {
  CommandLineHelper.requireVariableArgumentCount([2, 3], args, usage);
  CommandLineHelper.requireFileExists(args[0]);
  CommandLineHelper.requireFileExists(args[1]);
  Component binary1 = CommandLineHelper.tryLoadDill(args[0]);
  Component binary2 = CommandLineHelper.tryLoadDill(args[1]);
  Map<Uri, Set<String>> ignoresMap = {};
  if (args.length >= 3) {
    List<String> ignores = args[2].split("|");
    for (String ignore in ignores) {
      List<String> uriClassName = ignore.split("#");
      if (uriClassName.length != 2) {
        print("Ignoring '$ignore' as it doesn't conform to "
            "'importUri#className'");
        continue;
      }
      Uri uri = Uri.parse(uriClassName[0]);
      String className = uriClassName[1];
      (ignoresMap[uri] ??= {}).add(className);
    }
  }

  print("(1): ${args[0]}");
  print("(2): ${args[1]}");
  print("");

  ClosedWorldClassHierarchy ch1 =
      new ClassHierarchy(binary1, new CoreTypes(binary1))
          as ClosedWorldClassHierarchy;
  ClosedWorldClassHierarchy ch2 =
      new ClassHierarchy(binary2, new CoreTypes(binary2))
          as ClosedWorldClassHierarchy;

  Map<Uri, Library> libMap1 = createLibMap(binary1);
  Map<Uri, Library> libMap2 = createLibMap(binary2);
  Set<Uri> agreeingImportUris = new Set<Uri>.from(libMap1.keys)
    ..retainAll(libMap2.keys);

  for (Uri uri in agreeingImportUris) {
    Library lib1 = libMap1[uri]!;
    Library lib2 = libMap2[uri]!;
    Map<String, Class> libClass1 =
        createPublicClassMap(lib1, ignored: ignoresMap[uri]);
    Map<String, Class> libClass2 =
        createPublicClassMap(lib2, ignored: ignoresMap[uri]);
    Set<String> agreeingClasses = new Set<String>.from(libClass1.keys)
      ..retainAll(libClass2.keys);
    if (agreeingClasses.length != libClass1.length ||
        libClass1.length != libClass2.length) {
      print("Missing classes in lib $uri");
      Set<String> missing = new Set<String>.from(libClass1.keys)
        ..removeAll(libClass2.keys);
      if (missing.isNotEmpty) {
        print("In (1) but not in (2): ${missing.toList()}");
      }
      missing = new Set<String>.from(libClass2.keys)..removeAll(libClass1.keys);
      if (missing.isNotEmpty) {
        print("In (2) but not in (1): ${missing.toList()}");
      }
      print("");
    }

    for (String className in agreeingClasses) {
      Class c1 = libClass1[className]!;
      Class c2 = libClass2[className]!;
      Set<ClassReference> c1Supertypes = createClassReferenceSet(
          ch1.getAllSupertypeClassesForTesting(c1),
          onlyPublic: true,
          ignoresMap: ignoresMap);
      Set<ClassReference> c2Supertypes = createClassReferenceSet(
          ch2.getAllSupertypeClassesForTesting(c2),
          onlyPublic: true,
          ignoresMap: ignoresMap);
      Set<ClassReference> missing = new Set<ClassReference>.from(c1Supertypes)
        ..removeAll(c2Supertypes);
      if (missing.isNotEmpty) {
        print("$c1 in $lib1 from (1) has these extra supertypes: "
            "${missing.toList()}");
      }
      missing = new Set<ClassReference>.from(c2Supertypes)
        ..removeAll(c1Supertypes);
      if (missing.isNotEmpty) {
        print("$c2 in $lib2 from (2) has these extra supertypes: "
            "${missing.toList()}");
      }
    }
  }
}

Map<Uri, Library> createLibMap(Component c) {
  Map<Uri, Library> map = {};
  for (Library lib in c.libraries) {
    map[lib.importUri] = lib;
  }
  return map;
}

Map<String, Class> createPublicClassMap(Library lib,
    {required Set<String>? ignored}) {
  Map<String, Class> map = {};
  for (Class c in lib.classes) {
    if (c.name.startsWith("_")) continue;
    if (ignored?.contains(c.name) ?? false) continue;
    map[c.name] = c;
  }
  return map;
}

Set<ClassReference> createClassReferenceSet(List<Class> classes,
    {required bool onlyPublic, required Map<Uri, Set<String>> ignoresMap}) {
  Set<ClassReference> result = {};
  for (Class c in classes) {
    if (onlyPublic && c.name.startsWith("_")) continue;
    Set<String>? ignored = ignoresMap[c.enclosingLibrary.importUri];
    if (ignored?.contains(c.name) ?? false) continue;
    result.add(new ClassReference(c.name, c.enclosingLibrary.importUri));
  }
  return result;
}

class ClassReference {
  final String name;
  final Uri libImportUri;

  const ClassReference(this.name, this.libImportUri);

  @override
  int get hashCode => name.hashCode * 13 + libImportUri.hashCode * 17;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ClassReference) return false;
    if (name != other.name) return false;
    if (libImportUri != other.libImportUri) return false;
    return true;
  }

  @override
  String toString() {
    return "$name ($libImportUri)";
  }
}
