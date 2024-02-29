// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:kernel/binary/ast_from_binary.dart";
import "package:kernel/kernel.dart";
import "package:kernel/target/targets.dart";
import "package:kernel/verifier.dart";
import "package:vm/modular/target/vm.dart";

void main(List<String> args) {
  if (args.length != 1) throw "Usage: dart <script> <dill>";
  Component component = loadComponent(new File(args.single));
  Target target = new VmTarget(new TargetFlags());
  verifyComponent(
    target,
    VerificationStage.afterModularTransformations,
    component,
  );
}

Component loadComponent(File f) {
  Component component = new Component();
  new BinaryBuilder(f.readAsBytesSync(), disableLazyReading: true)
      .readComponent(component);
  return component;
}
