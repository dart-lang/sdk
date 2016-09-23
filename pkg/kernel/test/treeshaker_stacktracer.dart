// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.treeshaker.stacktracer;

import 'package:kernel/kernel.dart';
import 'package:kernel/transformations/treeshaker.dart';
import 'dart:io';
import 'package:ansicolor/ansicolor.dart';

String usage = '''
USAGE: treeshaker_stacktracer FILE.dill STACKTRACE.txt

Given a program and a stack trace from it, highlight the stack trace entries
that the tree shaker marked as unreachable.  These are indicative of bugs
in the tree shaker since their presence in the stack trace proves them reachable.

Example usage:
  ${comment("# Not shown: insert a 'throw' in testcase.dart")}
  dart testcase.dart > error.txt  ${comment("# Get the stack trace")}
  dartk testcase.dart -l -otestcase.dill  ${comment("# Compile binary")}
  dart test/treeshaker_stacktracer.dart testcase.dill error.txt ${comment("# Analyze")}
''';

String legend = '''
Legend:
    ${reachable('reachable member')} or ${reachable('instantiated class')}
    ${unreachable('unreachable member')} or ${unreachable('uninstantiated class')}
    ${unknown('name unrecognized')}
''';

// TODO: Also support the stack trace format from stack_trace.
RegExp stackTraceEntry = new RegExp(r'(#[0-9]+\s+)([a-zA-Z0-9_$.&<> ]+) \((.*)\)');

AnsiPen reachable = new AnsiPen()..green();
AnsiPen unreachable = new AnsiPen()..red();
AnsiPen unknown = new AnsiPen()..gray(level: 0.5);
AnsiPen filecolor = new AnsiPen()..gray(level: 0.5);
AnsiPen comment = new AnsiPen()..gray(level: 0.5);

String stackTraceName(Member member) {
  String name = member.name?.name;
  String className = member.enclosingClass?.name;
  if (member is Constructor && name != null) {
    return '$className.$className';
  } else if (className != null) {
    return '$className.$name';
  } else {
    return name;
  }
}

int findReachablePrefix(String name, Set<String> strings) {
  for (int index = name.length;
      index > 0;
      index = name.lastIndexOf('.', index - 1)) {
    if (strings.contains(name.substring(0, index))) {
      return index;
    }
  }
  return 0;
}

String shortenFilename(String filename) {
  if (filename.startsWith('file:')) {
    int libIndex = filename.lastIndexOf('lib/');
    if (libIndex != -1) {
      return filename.substring(libIndex + 'lib/'.length);
    }
  }
  return filename;
}

main(List<String> args) {
  if (args.length != 2) {
    print(usage);
    exit(1);
  }
  List<String> stackTrace = new File(args[1]).readAsLinesSync();
  Program program = loadProgramFromBinary(args[0]);
  TreeShaker shaker = new TreeShaker(program);
  Set<String> reachablePatterns = new Set<String>();
  Set<String> allMembers = new Set<String>();
  Set<String> instantiatedClasses = new Set<String>();
  void visitMember(Member member) {
    allMembers.add(stackTraceName(member));
    if (shaker.isMemberUsed(member)) {
      reachablePatterns.add(stackTraceName(member));
    }
  }
  for (var library in program.libraries) {
    for (var classNode in library.classes) {
      if (shaker.isInstantiated(classNode)) {
        instantiatedClasses.add(classNode.name);
      }
      classNode.members.forEach(visitMember);
    }
    library.members.forEach(visitMember);
  }
  for (String line in stackTrace) {
    var match = stackTraceEntry.matchAsPrefix(line);
    if (match == null) continue;
    String entry = match.group(2);
    int reachableIndex = findReachablePrefix(entry, reachablePatterns);
    int knownIndex = findReachablePrefix(entry, allMembers);
    int classIndex = findReachablePrefix(entry, instantiatedClasses);
    if (reachableIndex == 0) {
      reachableIndex = classIndex;
      if (reachableIndex > knownIndex) {
        knownIndex = reachableIndex;
      }
    }
    String numberPart = match.group(1);
    String reachablePart = reachable(entry.substring(0, reachableIndex));
    String knownPart = unreachable(entry.substring(reachableIndex, knownIndex));
    String unknownPart = unknown(entry.substring(knownIndex));
    String filePart = filecolor(shortenFilename(match.group(3)));
    String string = '$numberPart$reachablePart$knownPart$unknownPart';
    print(string.padRight(110) + filePart);
  }
  print(legend);
}
