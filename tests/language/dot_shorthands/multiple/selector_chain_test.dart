// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dot shorthands selector chains in collections, cascades, `??` and other
// contexts.

import 'dart:async';

import '../dot_shorthand_helper.dart';

class Cascade {
  late StaticMember member;
  late ConstructorWithNonFinal ctor;
}

void main() {
  StaticMember memberField = .member().field;
  StaticMember memberMethod = .member().method();
  StaticMember memberMixed = .member().method().field;
  StaticMember memberMixed2 = .member().field.method();

  ConstructorWithNonFinal ctorField = .new(1).field;
  ConstructorWithNonFinal ctorMethod = .new(1).method();
  ConstructorWithNonFinal ctorMixed =
      .new(1).method().field;
  ConstructorWithNonFinal ctorMixed2 =
      .new(1).field.method();

  // FutureOr
  FutureOr<StaticMember> futureOrMember = .member().field.method();
  FutureOr<ConstructorWithNonFinal> futureOrCtor =
      .new(1).field.method();

  // Collection literals
  var memberList = <StaticMember>[
    .member().field,
    .member().field.method(),
  ];
  var memberSet = <StaticMember>{
    .member().field,
    .member().field.method(),
  };
  var memberMap = <StaticMember, StaticMember>{
    .member().field: .member().field,
    .member().field.method(): .member().field.method(),
  };

  var ctorList = <ConstructorWithNonFinal>[
    .new(1).field,
    .new(1).method().field,
  ];
  var ctorSet = <ConstructorWithNonFinal>{
    .new(1).field,
    .new(1).method().field,
  };
  var ctorMap = <ConstructorWithNonFinal, ConstructorWithNonFinal>{
    .new(1).field: .new(1).field,
    .new(1).method().field:
        .new(1).method().field,
  };

  // Cascades
  Cascade()
    ..member = .member().field.method()
    ..ctor = .new(1).method().field;

  StaticMember memberCascade = .member().field.method()..toString();
  ConstructorWithNonFinal ctorCascade =
      .new(1).method().field..toString();

  // If-null
  StaticMember? staticMemberNull = null as StaticMember?;
  StaticMember ifNullMember =
      staticMemberNull ?? .member().field.method();
  StaticMember ifNullMember2 =
      .member().field.methodNullable() ?? .member();

  ConstructorWithNonFinal? ctorNull = null as ConstructorWithNonFinal?;
  ConstructorWithNonFinal ifNullCtor =
      ctorNull ?? .new(1).method().field;
  ConstructorWithNonFinal ifNullCtor2 =
      .new(1).method().field.methodNullable() ??
      ConstructorWithNonFinal(1);
}
