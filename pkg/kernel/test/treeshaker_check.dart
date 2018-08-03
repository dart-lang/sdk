// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.treeshaker_check;

import 'dart:io';

import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/transformations/treeshaker.dart';

String usage = '''
Usage: treeshaker_check FILE.dill

Run the tree shaker on FILE.dill and perform some internal sanity checks.
''';

main(List<String> args) {
  if (args.length == 0) {
    print(usage);
    exit(1);
  }
  var component = loadComponentFromBinary(args[0]);
  var coreTypes = new CoreTypes(component);
  var hierarchy = new ClassHierarchy(component);
  var shaker = new TreeShaker(coreTypes, hierarchy, component);
  shaker.transform(component);
  new TreeShakingSanityCheck(shaker).visit(component);
}

class TreeShakingSanityCheck extends RecursiveVisitor {
  final TreeShaker shaker;
  bool isInCoreLibrary = false;

  TreeShakingSanityCheck(this.shaker);

  void visit(Node node) {
    node.accept(this);
  }

  visitLibrary(Library node) {
    isInCoreLibrary = (node.importUri.scheme == 'dart');
    super.visitLibrary(node);
  }

  defaultMember(Member member) {
    if (!isInCoreLibrary &&
        member is! Constructor &&
        !shaker.isMemberUsed(member)) {
      throw 'Unused member $member was not removed';
    }
  }

  defaultMemberReference(Member target) {
    if (!shaker.isMemberUsed(target)) {
      throw 'Found reference to $target';
    }
  }
}
