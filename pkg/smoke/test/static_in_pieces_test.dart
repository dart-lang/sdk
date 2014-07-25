// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that a static configuration can be loaded in pieces, even with
/// deferred imports.
library smoke.test.static_in_pieces_test;

import 'package:unittest/unittest.dart';
import 'package:smoke/smoke.dart' show Declaration, PROPERTY, METHOD;
import 'package:smoke/static.dart' show useGeneratedCode, StaticConfiguration;
import 'piece1.dart' as p1;
import 'piece2.dart' deferred as p2;
import 'common.dart' as smoke_0;
import 'common.dart' as common show main;

abstract class _M0 {} // C & A

final configuration = new StaticConfiguration(
    checkedMode: false,
    getters: {
      #i: (o) => o.i,
      #inc0: (o) => o.inc0,
      #inc1: (o) => o.inc1,
      #inc2: (o) => o.inc2,
    },
    setters: {
      #i: (o, v) { o.i = v; },
    },
    parents: {
      smoke_0.AnnotB: smoke_0.Annot,
      smoke_0.D: _M0,
      smoke_0.E2: smoke_0.E,
      smoke_0.F2: smoke_0.F,
      _M0: smoke_0.C,
    },
    declarations: {
      smoke_0.A: {
        #i: const Declaration(#i, int),
        #inc0: const Declaration(#inc0, Function, kind: METHOD),
        #inc1: const Declaration(#inc1, Function, kind: METHOD),
        #inc2: const Declaration(#inc2, Function, kind: METHOD),
        #j: const Declaration(#j, int),
        #j2: const Declaration(#j2, int, kind: PROPERTY),
      },
      smoke_0.B: {
        #f: const Declaration(#f, int, isFinal: true),
        #w: const Declaration(#w, int, kind: PROPERTY),
      },
      smoke_0.C: {
        #b: const Declaration(#b, smoke_0.B),
        #inc: const Declaration(#inc, Function, kind: METHOD),
        #x: const Declaration(#x, int),
        #y: const Declaration(#y, String),
      },
      smoke_0.D: {
        #i2: const Declaration(#i2, int, kind: PROPERTY, isFinal: true),
        #x2: const Declaration(#x2, int, kind: PROPERTY, isFinal: true),
      },
      smoke_0.E: {
        #noSuchMethod: const Declaration(#noSuchMethod, Function, kind: METHOD),
        #y: const Declaration(#y, int, kind: PROPERTY, isFinal: true),
      },
      smoke_0.E2: {},
      smoke_0.F: {
        #staticMethod: const Declaration(#staticMethod, Function, kind: METHOD, isStatic: true),
      },
      smoke_0.F2: {},
      smoke_0.G: {
        #b: const Declaration(#b, int, annotations: const [smoke_0.a1]),
        #d: const Declaration(#d, int, annotations: const [smoke_0.a2]),
      },
      _M0: {
        #i: const Declaration(#i, int),
        #inc: const Declaration(#inc, Function, kind: METHOD),
        #inc0: const Declaration(#inc0, Function, kind: METHOD),
        #j: const Declaration(#j, int),
        #j2: const Declaration(#j2, int, kind: PROPERTY),
      },
    },
    staticMethods: {},
    names: {});

main() {
  useGeneratedCode(configuration);

  expect(configuration.getters[#j], isNull);

  configuration.addAll(p1.configuration);
  expect(configuration.getters[#j], isNotNull);

  p2.loadLibrary().then((_) {
    expect(configuration.names[#i], isNull);
    configuration.addAll(p2.configuration);
    expect(configuration.names[#i], 'i');
    common.main();
  });
}
