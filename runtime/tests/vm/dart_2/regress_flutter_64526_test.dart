// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests that functions with large number of optional positional parameters
// are compiled correctly and don't overflow instruction encoding.

import 'package:expect/expect.dart';

class CCC {
  var a00;
  var a01;
  var a02;
  var a03;
  var a04;
  var a05;
  var a06;
  var a07;
  var a08;
  var a09;
  var a10;
  var a11;
  var a12;
  var a13;
  var a14;
  var a15;
  var a16;
  var a17;
  var a18;
  var a19;
  var a20;
  var a21;
  var a22;
  var a23;
  var a24;
  var a25;
  var a26;
  var a27;
  var a28;
  var a29;
  var a30;
  var a31;
  var a32;
  var a33;
  var a34;
  var a35;
  var a36;
  var a37;
  var a38;
  var a39;
  var a40;
  var a41;
  var a42;
  var a43;
  var a44;
  var a45;
  var a46;
  var a47;
  var a48;
  var a49;
  CCC(
      [this.a00 = 'a00',
      this.a01 = 'a01',
      this.a02 = 'a02',
      this.a03 = 'a03',
      this.a04 = 'a04',
      this.a05 = 'a05',
      this.a06 = 'a06',
      this.a07 = 'a07',
      this.a08 = 'a08',
      this.a09 = 'a09',
      this.a10 = 'a10',
      this.a11 = 'a11',
      this.a12 = 'a12',
      this.a13 = 'a13',
      this.a14 = 'a14',
      this.a15 = 'a15',
      this.a16 = 'a16',
      this.a17 = 'a17',
      this.a18 = 'a18',
      this.a19 = 'a19',
      this.a20 = 'a20',
      this.a21 = 'a21',
      this.a22 = 'a22',
      this.a23 = 'a23',
      this.a24 = 'a24',
      this.a25 = 'a25',
      this.a26 = 'a26',
      this.a27 = 'a27',
      this.a28 = 'a28',
      this.a29 = 'a29',
      this.a30 = 'a30',
      this.a31 = 'a31',
      this.a32 = 'a32',
      this.a33 = 'a33',
      this.a34 = 'a34',
      this.a35 = 'a35',
      this.a36 = 'a36',
      this.a37 = 'a37',
      this.a38 = 'a38',
      this.a39 = 'a39',
      this.a40 = 'a40',
      this.a41 = 'a41',
      this.a42 = 'a42',
      this.a43 = 'a43',
      this.a44 = 'a44',
      this.a45 = 'a45',
      this.a46 = 'a46',
      this.a47 = 'a47',
      this.a48 = 'a48',
      this.a49 = 'a49']) {}
}

void main() {
  final o = CCC();
  Expect.equals('a00', o.a00);
  Expect.equals('a01', o.a01);
  Expect.equals('a02', o.a02);
  Expect.equals('a03', o.a03);
  Expect.equals('a04', o.a04);
  Expect.equals('a05', o.a05);
  Expect.equals('a06', o.a06);
  Expect.equals('a07', o.a07);
  Expect.equals('a08', o.a08);
  Expect.equals('a09', o.a09);
  Expect.equals('a10', o.a10);
  Expect.equals('a11', o.a11);
  Expect.equals('a12', o.a12);
  Expect.equals('a13', o.a13);
  Expect.equals('a14', o.a14);
  Expect.equals('a15', o.a15);
  Expect.equals('a16', o.a16);
  Expect.equals('a17', o.a17);
  Expect.equals('a18', o.a18);
  Expect.equals('a19', o.a19);
  Expect.equals('a20', o.a20);
  Expect.equals('a21', o.a21);
  Expect.equals('a22', o.a22);
  Expect.equals('a23', o.a23);
  Expect.equals('a24', o.a24);
  Expect.equals('a25', o.a25);
  Expect.equals('a26', o.a26);
  Expect.equals('a27', o.a27);
  Expect.equals('a28', o.a28);
  Expect.equals('a29', o.a29);
  Expect.equals('a30', o.a30);
  Expect.equals('a31', o.a31);
  Expect.equals('a32', o.a32);
  Expect.equals('a33', o.a33);
  Expect.equals('a34', o.a34);
  Expect.equals('a35', o.a35);
  Expect.equals('a36', o.a36);
  Expect.equals('a37', o.a37);
  Expect.equals('a38', o.a38);
  Expect.equals('a39', o.a39);
  Expect.equals('a40', o.a40);
  Expect.equals('a41', o.a41);
  Expect.equals('a42', o.a42);
  Expect.equals('a43', o.a43);
  Expect.equals('a44', o.a44);
  Expect.equals('a45', o.a45);
  Expect.equals('a46', o.a46);
  Expect.equals('a47', o.a47);
  Expect.equals('a48', o.a48);
  Expect.equals('a49', o.a49);
}
