// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Or node
import '' deferred as OrAlive;
import '' deferred as OrAlive_1;
import '' deferred as OrAlive_2;
import '' deferred as OrDead;

// And node
import '' deferred as AndAlive;
import '' deferred as AndAlive_1;
import '' deferred as AndAlive_2;
import '' deferred as AndDead;

// Fuse node
import '' deferred as FuseAlive;
import '' deferred as FuseAlive_1;
import '' deferred as FuseAlive_2;
import '' deferred as FuseDead;

void main() async {
  print('main');
  switch (opaqueInt) {
    case 1:
      await OrAlive.loadLibrary();
      await OrAlive.testOr();
      break;
    case 2:
      await AndAlive.loadLibrary();
      await AndAlive.testAnd();
      break;
    case 3:
      await FuseAlive.loadLibrary();
      await FuseAlive.testFuse();
      break;
  }
}

Future testOr() async {
  switch (opaqueInt) {
    case 1:
      await OrAlive_1.loadLibrary();
      OrAlive_1.orTest_alive_1();
      break;
    case 2:
      await OrAlive_2.loadLibrary();
      OrAlive_2.orTest_alive_2();
      break;
    default:
      if (alwaysFalse) {
        await OrDead.loadLibrary();
        OrDead.orTest_dead();
      }
      break;
  }
}

Future testAnd() async {
  for (int i = 0; i < 3; ++i) {
    if (i == 0) {
      await AndAlive_1.loadLibrary();
      AndAlive_1.andTest_alive_1();
    } else if (i == 1) {
      await AndAlive_2.loadLibrary();
      AndAlive_2.andTest_alive_2();
    } else {
      if (!alwaysTrue) {
        await AndDead.loadLibrary();
        AndDead.andTest_dead();
      }
    }
  }
}

Future testFuse() async {
  await FuseAlive_1.loadLibrary();
  FuseAlive_1.fuseTest_alive_1();
  await FuseAlive_2.loadLibrary();
  FuseAlive_2.fuseTest_alive_2();
  if (alwaysFalse) {
    await FuseDead.loadLibrary();
    FuseDead.fuseTest_dead();
  }
}

void orTest_alive_1() => print('orTest_alive_1');
void orTest_alive_2() => print('orTest_alive_2');
void orTest_dead() => print('orTest_dead');

void andTest_alive_1() => print('andTest_alive_1');
void andTest_alive_2() => print('andTest_alive_2');
void andTest_dead() => print('andTest_dead');

void fuseTest_alive_1() => print('fuseTest_alive_1');
void fuseTest_alive_2() => print('fuseTest_alive_2');
void fuseTest_dead() => print('fuseTest_dead');

int get opaqueInt => int.parse('1');
bool get alwaysTrue => true;
bool get alwaysFalse => false;
