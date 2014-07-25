// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Part of the static_in_pieces_test
library smoke.test.piece1;

import 'package:smoke/smoke.dart' show Declaration, PROPERTY, METHOD;
import 'package:smoke/static.dart' show useGeneratedCode, StaticConfiguration;
import 'common.dart' as smoke_0;

final configuration = new StaticConfiguration(
    checkedMode: false,
    getters: {
      #j: (o) => o.j,
      #j2: (o) => o.j2,
    },
    setters: {},
    parents: {
      smoke_0.H: smoke_0.G,
    },
    declarations: {
      smoke_0.H: {
        #f: const Declaration(#f, int, annotations: const [smoke_0.a1]),
        #g: const Declaration(#g, int, annotations: const [smoke_0.a1]),
        #h: const Declaration(#h, int, annotations: const [smoke_0.a2]),
        #i: const Declaration(#i, int, annotations: const [smoke_0.a3]),
      },
    },
    staticMethods: {
      smoke_0.A: {
        #staticInc: smoke_0.A.staticInc,
      },
    },
    names: {});
