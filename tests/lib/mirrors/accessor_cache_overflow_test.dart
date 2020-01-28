// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test runs invokes getField and setField enough times to get cached
// closures generated and with enough different field names to trip the path
// that flushes the closure cache.

library test.hot_get_field;

import 'dart:mirrors';
import 'package:expect/expect.dart';

const int optimizationThreshold = 20;

main() {
  var digits = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F'
  ];
  var symbols = new List();
  for (var high in digits) {
    for (var low in digits) {
      symbols.add(MirrorSystem.getSymbol("v$high$low"));
    }
  }

  var im = reflect(new C());
  for (var i = 0; i < optimizationThreshold * 2; i++) {
    for (var fieldName in symbols) {
      im.getField(fieldName);
      im.setField(fieldName, 'foo');
    }
  }
}

class C {
  var v00;
  var v01;
  var v02;
  var v03;
  var v04;
  var v05;
  var v06;
  var v07;
  var v08;
  var v09;
  var v0A;
  var v0B;
  var v0C;
  var v0D;
  var v0E;
  var v0F;
  var v10;
  var v11;
  var v12;
  var v13;
  var v14;
  var v15;
  var v16;
  var v17;
  var v18;
  var v19;
  var v1A;
  var v1B;
  var v1C;
  var v1D;
  var v1E;
  var v1F;
  var v20;
  var v21;
  var v22;
  var v23;
  var v24;
  var v25;
  var v26;
  var v27;
  var v28;
  var v29;
  var v2A;
  var v2B;
  var v2C;
  var v2D;
  var v2E;
  var v2F;
  var v30;
  var v31;
  var v32;
  var v33;
  var v34;
  var v35;
  var v36;
  var v37;
  var v38;
  var v39;
  var v3A;
  var v3B;
  var v3C;
  var v3D;
  var v3E;
  var v3F;
  var v40;
  var v41;
  var v42;
  var v43;
  var v44;
  var v45;
  var v46;
  var v47;
  var v48;
  var v49;
  var v4A;
  var v4B;
  var v4C;
  var v4D;
  var v4E;
  var v4F;
  var v50;
  var v51;
  var v52;
  var v53;
  var v54;
  var v55;
  var v56;
  var v57;
  var v58;
  var v59;
  var v5A;
  var v5B;
  var v5C;
  var v5D;
  var v5E;
  var v5F;
  var v60;
  var v61;
  var v62;
  var v63;
  var v64;
  var v65;
  var v66;
  var v67;
  var v68;
  var v69;
  var v6A;
  var v6B;
  var v6C;
  var v6D;
  var v6E;
  var v6F;
  var v70;
  var v71;
  var v72;
  var v73;
  var v74;
  var v75;
  var v76;
  var v77;
  var v78;
  var v79;
  var v7A;
  var v7B;
  var v7C;
  var v7D;
  var v7E;
  var v7F;
  var v80;
  var v81;
  var v82;
  var v83;
  var v84;
  var v85;
  var v86;
  var v87;
  var v88;
  var v89;
  var v8A;
  var v8B;
  var v8C;
  var v8D;
  var v8E;
  var v8F;
  var v90;
  var v91;
  var v92;
  var v93;
  var v94;
  var v95;
  var v96;
  var v97;
  var v98;
  var v99;
  var v9A;
  var v9B;
  var v9C;
  var v9D;
  var v9E;
  var v9F;
  var vA0;
  var vA1;
  var vA2;
  var vA3;
  var vA4;
  var vA5;
  var vA6;
  var vA7;
  var vA8;
  var vA9;
  var vAA;
  var vAB;
  var vAC;
  var vAD;
  var vAE;
  var vAF;
  var vB0;
  var vB1;
  var vB2;
  var vB3;
  var vB4;
  var vB5;
  var vB6;
  var vB7;
  var vB8;
  var vB9;
  var vBA;
  var vBB;
  var vBC;
  var vBD;
  var vBE;
  var vBF;
  var vC0;
  var vC1;
  var vC2;
  var vC3;
  var vC4;
  var vC5;
  var vC6;
  var vC7;
  var vC8;
  var vC9;
  var vCA;
  var vCB;
  var vCC;
  var vCD;
  var vCE;
  var vCF;
  var vD0;
  var vD1;
  var vD2;
  var vD3;
  var vD4;
  var vD5;
  var vD6;
  var vD7;
  var vD8;
  var vD9;
  var vDA;
  var vDB;
  var vDC;
  var vDD;
  var vDE;
  var vDF;
  var vE0;
  var vE1;
  var vE2;
  var vE3;
  var vE4;
  var vE5;
  var vE6;
  var vE7;
  var vE8;
  var vE9;
  var vEA;
  var vEB;
  var vEC;
  var vED;
  var vEE;
  var vEF;
  var vF0;
  var vF1;
  var vF2;
  var vF3;
  var vF4;
  var vF5;
  var vF6;
  var vF7;
  var vF8;
  var vF9;
  var vFA;
  var vFB;
  var vFC;
  var vFD;
  var vFE;
  var vFF;
}
