// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Context type is propagated down in collection literals.
// Testing with constructor shorthands.

import '../dot_shorthand_helper.dart';

void main() {
  var ctorList = <ConstructorClass>[
    .new(1),
    .regular(1),
    .named(x: 1),
    .optional(1),
  ];
  var ctorSet = <ConstructorClass>{
    .new(1),
    .regular(1),
    .named(x: 1),
    .optional(1),
  };
  var ctorMap = <ConstructorClass, ConstructorClass>{
    .new(1): .new(1),
    .regular(1): .regular(1),
    .named(x: 1): .named(x: 1),
    .optional(1): .optional(1),
  };
  var ctorMap2 = <ConstructorClass, (ConstructorClass, ConstructorClass)>{
    .new(1): (.new(1), .new(1)),
    .regular(1): (.regular(1), .regular(1)),
    .named(x: 1): (.named(x: 1), .named(x: 1)),
    .optional(1): (.optional(1), .optional(1)),
  };

  var ctorExtList = <ConstructorExt>[
    .new(1),
    .regular(1),
    .named(x: 1),
    .optional(1),
  ];
  var ctorExtSet = <ConstructorExt>{
    .new(1),
    .regular(1),
    .named(x: 1),
    .optional(1),
  };
  var ctorExtMap = <ConstructorExt, ConstructorExt>{
    .new(1): .new(1),
    .regular(1): .regular(1),
    .named(x: 1): .named(x: 1),
    .optional(1): .optional(1),
  };
  var ctorExtMap2 = <ConstructorExt, (ConstructorExt, ConstructorExt)>{
    .new(1): (.new(1), .new(1)),
    .regular(1): (.regular(1), .regular(1)),
    .named(x: 1): (.named(x: 1), .named(x: 1)),
    .optional(1): (.optional(1), .optional(1)),
  };
}
