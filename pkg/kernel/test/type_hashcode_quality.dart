// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:kernel/kernel.dart';
import 'dart:io';

String usage = '''
Usage: type_hashcode_quality FILE.dill

Counts the number of hash collisions between DartTypes in the given file.
''';

void main(List<String> args) {
  if (args.length == 0) {
    print(usage);
    exit(1);
  }
  Program program = loadProgramFromBinary(args[0]);
  var visitor = new DartTypeCollector();
  program.accept(visitor);
  print('''
Types:      ${visitor.numberOfTypes}
Collisions: ${visitor.numberOfCollisions}''');
}

class DartTypeCollector extends RecursiveVisitor {
  final Set<DartType> seenTypes = new Set<DartType>();
  final Map<int, DartType> table = <int, DartType>{};
  int numberOfCollisions = 0;
  int numberOfTypes = 0;

  @override
  defaultDartType(DartType node) {
    if (!seenTypes.add(node)) return;
    ++numberOfTypes;
    int hash = node.hashCode;
    if (hash == 0) {
      print('Type has a hash code of zero: $node');
    }
    DartType existing = table[hash];
    if (existing == null) {
      table[hash] = node;
    } else if (existing != node) {
      print('Collision between $existing and $node');
      ++numberOfCollisions;
    }
  }
}
