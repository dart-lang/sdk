// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See inspector.txt for expected behavior.

library manual_inspector_test;

import 'dart:isolate';
import 'dart:mirrors';
import 'dart:profiler';
import 'dart:typed_data';

class A <T> {}
class B <S extends num> {}

var array;
var bigint;
var blockClean;
var blockCopying;
var blockFull;
var blockFullWithChain;
var boundedType;
var capability;
var counter;
var expando;
var float32x4;
var float64;
var float64x2;
var gauge;
var growableList;
var int32x4;
var isolate;
var map;
var mint;
var mirrorClass;
var mirrorClosure;
var mirrorInstance;
var mirrorReference;
var portReceive;
var portSend;
var regex;
var smi;
var stacktrace;
var string;
var stringLatin1;
var stringSnowflake;
var stringUnicode;
var theFalse;
var theNull;
var theTrue;
var type;
var typeParameter;
var typedData;
var uninitialized = new Object();
var userTag;
var weakProperty;

extractPrivateField(obj, name) {
  return reflect(obj).getField(MirrorSystem.getSymbol(name, reflect(obj).type.owner)).reflectee;
}

genStacktrace() {
  try {
    num.parse(',');
  } catch (e, s) {
    return s;
  }
}

genCleanBlock() {
  block(x) => x;
  return block;
}

genCopyingBlock() {
  final x = 'I could be copied down';
  block() => x;
  return block;
}

genFullBlock() {
  var x = 0;
  block() => x++;
  return block;
}

genFullBlockWithChain() {
  var x = 0;
  outer() {
    var y = 0;
    block() => x++ + y++;
    return block;
  }
  return outer;
}

secondMain(msg) { }

main() {
  print("Started main");

  array = new List(1);
  bigint = 1 << 65;
  blockClean = genCleanBlock();
  blockCopying = genCopyingBlock();
  blockFull = genFullBlock();
  blockFullWithChain = genFullBlockWithChain();
  boundedType = extractPrivateField(reflect(new B<int>()).type.typeVariables.single, '_reflectee');
  counter = new Counter("CounterName", "Counter description");
  expando = new Expando("expando-name");
  expando[array] = 'The weakly associated value';
  float32x4 = new Float32x4.zero();
  float64 = 3.14;
  float64x2 = new Float64x2.zero();
  gauge = new Gauge("GaugeName", "Gauge description", 0.0, 100.0);
  growableList = new List();
  int32x4 = new Int32x4(0,0,0,0);
  map = { "x":3, "y":4 };
  mint = 1 << 32;
  mirrorClass = reflectClass(Object);
  mirrorClosure = reflect(blockFull);
  mirrorInstance = reflect("a reflectee");
  mirrorReference = extractPrivateField(mirrorClass, '_reflectee');
  portReceive = new RawReceivePort();
  regex = new RegExp("a*b+c");
  smi = 7;
  stacktrace = genStacktrace();
  string = "Hello";
  stringLatin1 = "blåbærgrød";
  stringSnowflake = "❄";
  stringUnicode = "Îñţérñåţîöñåļîžåţîờñ";
  theFalse = false;
  theNull = null;
  theTrue = true;
  type = String;
  typeParameter = extractPrivateField(reflectClass(A).typeVariables.single, '_reflectee');
  typedData = extractPrivateField(new ByteData(64), '_typedData');
  userTag = new UserTag("Example tag name");
  weakProperty = extractPrivateField(expando, '_data').firstWhere((e) => e != null);

  Isolate.spawn(secondMain, "Hello").then((otherIsolate) {
    isolate = otherIsolate;
    portSend = otherIsolate.controlPort;
    capability = otherIsolate.terminateCapability;
  });

  print("Finished main");
}
