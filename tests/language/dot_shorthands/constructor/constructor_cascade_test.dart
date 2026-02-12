// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Context type is propagated down in cascades for constructor dot shorthands.

import '../dot_shorthand_helper.dart';

class Cascade {
  late ConstructorClass ctor;
  late ConstructorExt ctorExt;
}

class CascadeCollection {
  late List<ConstructorClass> ctorList;
  late Set<ConstructorClass> ctorSet;
  late Map<ConstructorClass, ConstructorClass> ctorMap;
  late Map<ConstructorClass, (ConstructorClass, ConstructorClass)> ctorMap2;

  late List<ConstructorExt> ctorExtList;
  late Set<ConstructorExt> ctorExtSet;
  late Map<ConstructorExt, ConstructorExt> ctorExtMap;
  late Map<ConstructorExt, (ConstructorExt, ConstructorExt)> ctorExtMap2;
}

class CascadeMethod {
  void ctor(ConstructorClass ctor) => print(ctor);
  void ctorExt(ConstructorExt ctor) => print(ctor);
}

void main() {
  Cascade()
    ..ctor = .new(1)
    ..ctor = .regular(1)
    ..ctor = .named(x: 1)
    ..ctor = .optional(1)
    ..ctorExt = .new(1)
    ..ctorExt = .regular(1)
    ..ctorExt = .named(x: 1)
    ..ctorExt = .optional(1);

  dynamic mayBeNull = null;
  Cascade()
    ..ctor = mayBeNull ?? .new(1)
    ..ctor = mayBeNull ?? .regular(1)
    ..ctor = mayBeNull ?? .named(x: 1)
    ..ctor = mayBeNull ?? .optional(1)
    ..ctorExt = mayBeNull ?? .new(1)
    ..ctorExt = mayBeNull ?? .regular(1)
    ..ctorExt = mayBeNull ?? .named(x: 1)
    ..ctorExt = mayBeNull ?? .optional(1);

  CascadeCollection()
    ..ctorList = [.new(1), .regular(1), .named(x: 1), .optional(1)]
    ..ctorSet = {.new(1), .regular(1), .named(x: 1), .optional(1)}
    ..ctorMap = {
      .new(1): .new(1),
      .regular(1): .regular(1),
      .named(x: 1): .named(x: 1),
      .optional(1): .optional(1),
    }
    ..ctorMap2 = {
      .new(1): (.new(1), .new(1)),
      .regular(1): (.regular(1), .regular(1)),
      .named(x: 1): (.named(x: 1), .named(x: 1)),
      .optional(1): (.optional(1), .optional(1)),
    }
    ..ctorExtList = [.new(1), .regular(1), .named(x: 1), .optional(1)]
    ..ctorExtSet = {.new(1), .regular(1), .named(x: 1), .optional(1)}
    ..ctorExtMap = {
      .new(1): .new(1),
      .regular(1): .regular(1),
      .named(x: 1): .named(x: 1),
      .optional(1): .optional(1),
    }
    ..ctorExtMap2 = {
      .new(1): (.new(1), .new(1)),
      .regular(1): (.regular(1), .regular(1)),
      .named(x: 1): (.named(x: 1), .named(x: 1)),
      .optional(1): (.optional(1), .optional(1)),
    };

  CascadeMethod()
    ..ctor(.new(1))
    ..ctor(.regular(1))
    ..ctor(.named(x: 1))
    ..ctor(.optional(1))
    ..ctorExt(.new(1))
    ..ctorExt(.regular(1))
    ..ctorExt(.named(x: 1))
    ..ctorExt(.optional(1));

  ConstructorClass ctor = .new(1)..toString();
  ConstructorClass ctorRegular = .regular(1)..toString();
  ConstructorClass ctorNamed = .named(x: 1)..toString();
  ConstructorClass ctorOptional = .optional(1)..toString();
  ConstructorExt ctorExt = .new(1)..toString();
  ConstructorExt ctorExtRegular = .regular(1)..toString();
  ConstructorExt ctorExtNamed = .named(x: 1)..toString();
  ConstructorExt ctorExtOptional = .optional(1)..toString();
}
