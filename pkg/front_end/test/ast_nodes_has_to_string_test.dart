// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File, Platform, stdin, exitCode;

import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import 'incremental_suite.dart' as helper;

Future<void> main(List<String> args) async {
  exitCode = 1;
  Map<Uri, List<Class>> classMap = {};
  Map<Uri, List<Class>> classMapWithOne = {};
  Component c;
  int toGo = 0;
  ClassHierarchy classHierarchy;
  Class memberClass;
  Class primitiveConstantClass;

  {
    Uri input = Platform.script.resolve("../tool/_fasta/compile.dart");
    CompilerOptions options = helper.getOptions();
    helper.TestIncrementalCompiler compiler =
        new helper.TestIncrementalCompiler(options, input,
            /*Uri initializeFrom*/ null, /*bool outlineOnly*/ true);
    IncrementalCompilerResult compilerResult = await compiler.computeDelta();
    c = compilerResult.component;
    classHierarchy = compilerResult.classHierarchy!;
    List<Library> libraries = c.libraries
        .where((Library lib) =>
            (lib.importUri.toString() == "package:kernel/ast.dart"))
        .toList();
    Library astLibrary = libraries.single;
    List<Class> classes =
        astLibrary.classes.where((Class c) => c.name == "Node").toList();
    Class nodeClass = classes.single;
    classes =
        astLibrary.classes.where((Class c) => c.name == "Member").toList();
    memberClass = classes.single;
    classes = astLibrary.classes
        .where((Class c) => c.name == "PrimitiveConstant")
        .toList();
    primitiveConstantClass = classes.single;

    for (Library library in c.libraries) {
      for (Class c in library.classes) {
        if (c.isAbstract) continue;
        if (classHierarchy.isSubInterfaceOf(c, nodeClass)) {
          List<Member> toStringList = classHierarchy
              .getInterfaceMembers(c)
              .where((Member m) =>
                  !m.isAbstract &&
                  m.name.text == "toString" &&
                  !m.enclosingLibrary.importUri.isScheme("dart"))
              .toList();
          if (toStringList.length > 1) throw "What?";
          if (toStringList.length == 1) {
            classMapWithOne[c.fileUri] ??= <Class>[];
            classMapWithOne[c.fileUri]!.add(c);
            continue;
          }
          toGo++;

          classMap[c.fileUri] ??= <Class>[];
          classMap[c.fileUri]!.add(c);
        }
      }
    }
  }
  if (toGo == 0) {
    print("OK");
    exitCode = 0;
  } else {
    String classes = classMap.values
        .map((list) => list.map((cls) => cls.name).join(', '))
        .join(', ');
    print("Missing toString() on $toGo class(es): ${classes}");

    if (args.length == 1 && args.single == "--interactive") {
      for (Uri uri in classMap.keys) {
        List<Class> classes = classMap[uri]!;
        print("Would you like to update ${classes.length} classes in ${uri}?"
            " (y/n)");
        if (stdin.readLineSync() != "y") {
          print("Skipping $uri");
          continue;
        }
        print("Continuing on $uri");
        classes.sort((Class a, Class b) {
          return a.fileEndOffset - b.fileEndOffset;
        });
        File f = new File.fromUri(uri);
        String src = f.readAsStringSync();
        StringBuffer newSrc = new StringBuffer();
        int from = 0;
        for (Class c in classes) {
          String innerContent = "";
          if (classHierarchy.isSubInterfaceOf(c, memberClass)) {
            innerContent = "\$name";
          } else if (classHierarchy.isSubInterfaceOf(
              c, primitiveConstantClass)) {
            innerContent = "\$value";
          }
          int to = c.fileEndOffset;
          newSrc.write(src.substring(from, to));
          // We're just before the final "}".
          newSrc.write("""

  @override
  String toString() {
    return "${c.name}(\${toStringInternal()})";
  }

  @override
  String toStringInternal() {
    return "${innerContent}";
  }
""");
          from = to;
        }
        newSrc.write(src.substring(from));
        f.writeAsStringSync(newSrc.toString());
      }
    }
  }

  if (args.length == 1 && args.single == "--interactive") {
    for (Uri uri in classMapWithOne.keys) {
      List<Class> classes = classMapWithOne[uri]!;
      print("Would you like to update toString for ${classes.length} "
          "classes in ${uri}? (y/n)");
      if (stdin.readLineSync() != "y") {
        print("Skipping $uri");
        continue;
      }
      print("Continuing on $uri");
      classes.sort((Class a, Class b) {
        return a.fileEndOffset - b.fileEndOffset;
      });
      File f = new File.fromUri(uri);
      String src = f.readAsStringSync();
      StringBuffer newSrc = new StringBuffer();
      int from = 0;
      for (Class c in classes) {
        String innerContent = "()";
        if (classHierarchy.isSubInterfaceOf(c, memberClass)) {
          innerContent = r"($name)";
        } else if (classHierarchy.isSubInterfaceOf(c, primitiveConstantClass)) {
          innerContent = r"($value)";
        }

        List<Member> toStringList = classHierarchy
            .getInterfaceMembers(c)
            .where((Member m) =>
                !m.isAbstract &&
                m.name.text == "toString" &&
                !m.enclosingLibrary.importUri.isScheme("dart"))
            .toList();
        Member toString = toStringList.single;
        if (toString.fileUri != uri) continue;
        int end = toString.fileEndOffset + 1;
        String existing = src.substring(toString.fileOffset, end).trim();
        if (!existing.contains('return "${c.name}${innerContent}";')) {
          continue;
        }

        innerContent = "";
        if (classHierarchy.isSubInterfaceOf(c, memberClass)) {
          innerContent = "\$name";
        } else if (classHierarchy.isSubInterfaceOf(c, primitiveConstantClass)) {
          innerContent = "\$value";
        }

        int to = toString.fileOffset;
        newSrc.write(src.substring(from, to));
        // We're just before the final "}".
        newSrc.write("""
toString() {
    return "${c.name}(\${toStringInternal()})";
  }

  @override
  String toStringInternal() {
    return "${innerContent}";
  }""");
        from = toString.fileEndOffset + 1;
      }
      newSrc.write(src.substring(from));
      f.writeAsStringSync(newSrc.toString());
    }
  }
}
