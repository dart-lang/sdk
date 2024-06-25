// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/lowering_predicates.dart';
import 'package:front_end/src/source/name_scheme.dart';
import 'package:kernel/ast.dart';

void main() {
  testExtractQualifiedNameFromExtensionMethodName();
}

void testExtractQualifiedNameFromExtensionMethodName() {
  // Doesn't crash on null and returns null in that case.
  expect(extractQualifiedNameFromExtensionMethodName(null), null);

  // When given data it actually extracts what we want.
  for (ContainerType containerType in [
    ContainerType.ExtensionType,
    ContainerType.Extension
  ]) {
    for (bool isStatic in [true, false]) {
      String encodedName = NameScheme.createProcedureNameForTesting(
          containerName: new TesterContainerName("Foo"),
          containerType: containerType,
          isStatic: isStatic,
          kind: ProcedureKind.Method,
          name: "bar");
      String extracted =
          extractQualifiedNameFromExtensionMethodName(encodedName)!;
      expectDifferent(encodedName, extracted);
      expect(extracted, "Foo.bar");
    }
  }
}

class TesterContainerName extends ContainerName {
  @override
  final String name;

  TesterContainerName(this.name);

  @override
  void attachMemberName(MemberName name) {}
}

void expect(Object? actual, Object? expect) {
  if (expect != actual) throw "Expected $expect got $actual";
}

void expectDifferent(Object? actual, Object? expectNot) {
  if (expectNot == actual) throw "Expected not $expectNot got $actual";
}
