// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.treeshaker_dump;

import 'dart:io';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/transformations/treeshaker.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as pathlib;
import 'package:kernel/text/ast_to_text.dart';

ArgParser parser = new ArgParser(allowTrailingOptions: true)
  ..addFlag('used', help: 'Print used members', negatable: false)
  ..addFlag('unused', help: 'Print unused members', negatable: false)
  ..addFlag('instantiated',
      help: 'Print instantiated classes', negatable: false)
  ..addFlag('types', help: 'Print classes used as a type', negatable: false)
  ..addFlag('summary',
      help: 'Print short summary of tree shaking results', defaultsTo: true)
  ..addFlag('diff',
      help: 'Print textual output before and after tree shaking.\n'
          'Files are written to FILE.before.txt and FILE.after.txt',
      negatable: false)
  ..addOption('output',
      help: 'The --diff files are written to the given directory instead of '
          'the working directory')
  ..addFlag('strong', help: 'Run the tree shaker in strong mode');

String usage = '''
Usage: treeshaker_dump [options] FILE.dill

Runs tree shaking on the given program and prints information about the results.

Example:
  treeshaker_dump --instantiated foo.dill

Example:
    treeshaker_dump --diff foo.dill
    diff -cd foo.{before,after}.txt > diff.txt
    # open diff.txt in an editor

Options:
${parser.usage}
''';

main(List<String> args) {
  if (args.isEmpty) {
    print(usage);
    exit(1);
  }
  ArgResults options = parser.parse(args);
  if (options.rest.length != 1) {
    print('Exactly one file should be given.');
    exit(1);
  }
  String filename = options.rest.single;

  if (options['output'] != null && !options['diff']) {
    print('--output must be used with --diff');
    exit(1);
  }

  bool strong = options['strong'];

  Program program = loadProgramFromBinary(filename);
  CoreTypes coreTypes = new CoreTypes(program);
  ClassHierarchy hierarchy = new ClosedWorldClassHierarchy(program);
  TreeShaker shaker =
      new TreeShaker(coreTypes, hierarchy, program, strongMode: strong);
  int totalClasses = 0;
  int totalInstantiationCandidates = 0;
  int totalMembers = 0;
  int usedClasses = 0;
  int instantiatedClasses = 0;
  int usedMembers = 0;

  void visitMember(Member member) {
    if (member.isAbstract) return; // Abstract members are not relevant.
    ++totalMembers;
    bool isUsed = shaker.isMemberBodyUsed(member);
    if (isUsed) {
      ++usedMembers;
    }
    if (isUsed && options['used'] || !isUsed && options['unused']) {
      String prefix = (options['used'] && options['unused'])
          ? (isUsed ? 'USED   ' : 'UNUSED ')
          : '';
      print('$prefix$member');
    }
  }

  for (var library in program.libraries) {
    library.members.forEach(visitMember);
    for (Class classNode in library.classes) {
      ++totalClasses;
      if (shaker.isInstantiated(classNode)) {
        ++instantiatedClasses;
        ++totalInstantiationCandidates;
      } else if (!classNode.isAbstract &&
          classNode.members.any((m) => m.isInstanceMember)) {
        ++totalInstantiationCandidates;
      }
      if (shaker.isHierarchyUsed(classNode)) {
        ++usedClasses;
      }
      classNode.members.forEach(visitMember);
      if (options['instantiated'] && shaker.isInstantiated(classNode)) {
        print(classNode);
      }
      if (options['types'] && shaker.isHierarchyUsed(classNode)) {
        print(classNode);
      }
    }
  }

  if (options['summary']) {
    print('Classes used:         ${ratio(usedClasses, totalClasses)}');
    print('Classes instantiated: '
        '${ratio(instantiatedClasses, totalInstantiationCandidates)}');
    print('Members used:         ${ratio(usedMembers, totalMembers)}');
  }

  if (options['diff']) {
    String name = pathlib.basenameWithoutExtension(filename);
    String outputDir = options['output'] ?? '';
    String beforeFile = pathlib.join(outputDir, '$name.before.txt');
    String afterFile = pathlib.join(outputDir, '$name.after.txt');
    NameSystem names = new NameSystem();
    StringBuffer before = new StringBuffer();
    new Printer(before, syntheticNames: names).writeProgramFile(program);
    new File(beforeFile).writeAsStringSync('$before');
    new TreeShaker(coreTypes, hierarchy, program, strongMode: strong)
        .transform(program);
    StringBuffer after = new StringBuffer();
    new Printer(after, syntheticNames: names).writeProgramFile(program);
    new File(afterFile).writeAsStringSync('$after');
    print('Text written to $beforeFile and $afterFile');
  }
}

String ratio(num x, num total) {
  return '$x / $total (${percent(x, total)})';
}

String percent(num x, num total) {
  return total == 0 ? '0%' : ((100 * x / total).toStringAsFixed(0) + '%');
}
