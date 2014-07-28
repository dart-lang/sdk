// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Part of the static_in_pieces_test
library smoke.test.piece2;

import 'package:smoke/smoke.dart' show Declaration, PROPERTY, METHOD;
import 'package:smoke/static.dart' show useGeneratedCode, StaticConfiguration;
import 'common.dart' as smoke_0;

final configuration = new StaticConfiguration(
    checkedMode: false,
    getters: {
      #j2: (o) => o.j2,
    },
    setters: {
      #j2: (o, v) { o.j2 = v; },
    },
    parents: {},
    declarations: {
      smoke_0.A: {},
      smoke_0.B: {
        #a: const Declaration(#a, smoke_0.A),
      },
      smoke_0.K: {
        #k: const Declaration(#k, int, annotations: const [const smoke_0.AnnotC(named: true)]),
        #k2: const Declaration(#k2, int, annotations: const [const smoke_0.AnnotC()]),
      },
    },
    staticMethods: {
      smoke_0.A: {
        #staticInc: smoke_0.A.staticInc,
      },
    },
    names: {
      #i: r'i',
    });
