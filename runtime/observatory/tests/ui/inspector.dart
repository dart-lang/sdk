// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: experiment_not_enabled
// @dart = 3.0

// See inspector.txt for expected behavior.

library manual_inspector_test;

import 'dart:isolate';
import 'dart:mirrors';
import 'dart:developer';
import 'dart:typed_data';

part 'inspector_part.dart';

var libraryField;
var node;
var uninitialized = new Object();

extractPrivateField(obj, name) {
  var lib = reflect(obj).type.owner as LibraryMirror;
  return reflect(obj).getField(MirrorSystem.getSymbol(name, lib)).reflectee;
}

class A<T> {}

class B<S extends num> {}

class S {}

mixin M {}

class MA extends S with M {}

class Node {
  static var classField;

  var nullable;
  var mixedType;
  var array;
  var arrayConst;
  var bigint;
  var blockClean;
  var blockCopying;
  var blockFull;
  var blockFullWithChain;
  var blockType;
  var boundedType;
  var capability;
  var expando;
  var finalizer;
  var finalizerEntry;
  var float32x4;
  var float64;
  var float64x2;
  var growableList;
  var int32x4;
  var isolate;
  var map;
  var mapConst;
  var mint;
  var mirrorClass;
  var mirrorClosure;
  var mirrorInstance;
  var mirrorReference;
  var portReceive;
  var portSend;
  var record;
  var recordType;
  var regex;
  late var sentinel;  // Not initialized
  var set;
  var setConst;
  var smi;
  var stacktrace;
  var string;
  var stringLatin1;
  var stringSnowflake;
  var stringUnicode;
  var stringHebrew;
  var stringTrebleClef;
  var theFalse;
  var theNull;
  var theTrue;
  var type;
  var typeParameter;
  var typedDataArray;
  var typedDataView;
  var typedDataUnmodifiableView;
  var userTag;
  var weakProperty;
  var weakReference;

  genStackTrace() {
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

  f(int x) {
    ++x;
    return x;
  }

  static staticMain() {
    node.main();
  }

  main() {
    print("Started main");

    f(9);

    nullable = 1;
    nullable = null;
    nullable = 1;
    mixedType = 1;
    mixedType = "2";
    mixedType = false;

    array = new List<dynamic>.filled(3, null);
    array[0] = 1;
    array[1] = 2;
    array[2] = 3;
    arrayConst = const [1, 2, 3];
    bigint = BigInt.one << 65;
    blockClean = genCleanBlock();
    blockCopying = genCopyingBlock();
    blockFull = genFullBlock();
    blockFullWithChain = genFullBlockWithChain();
    blockType = blockClean.runtimeType;
    boundedType = extractPrivateField(
        reflect(new B<int>()).type.typeVariables.single, '_reflectee');
    expando = new Expando("expando-name");
    expando[array] = 'The weakly associated value';
    finalizer = Finalizer<dynamic>((_){});
    finalizer.attach(this, this);
    float32x4 = new Float32x4(0.0, -1.0, 3.14, 2e28);
    float64 = 3.14;
    float64x2 = new Float64x2(0.0, 3.14);
    growableList = <dynamic>[];
    int32x4 = new Int32x4(0, 1, 10, 11);
    map = {
      "x-key": "x-value",
      "y-key": "y-value",
      "removed-key": "removed-value"
    };
    mapConst = const {
      1: 1.5,
      2: 2.5,
    };
    map.remove("removed-key");
    mint = 1 << 32;
    mirrorClass = reflectClass(Object);
    mirrorClosure = reflect(blockFull);
    mirrorInstance = reflect("a reflectee");
    mirrorReference = extractPrivateField(mirrorClass, '_reflectee');
    portReceive = new RawReceivePort();
    portSend = portReceive.sendPort;
    record = (1, 2, three: 3, four: 4);
    recordType = record.runtimeType;
    regex = new RegExp("a*b+c");
    set = {
      "element1", "element2", "removed-element"
    };
    set.remove("removed-element");
    setConst = const {
      10, 20, 30
    };
    smi = 7;
    stacktrace = genStackTrace();
    string = "Hello $smi ${smi.runtimeType}";
    stringLatin1 = "blåbærgrød";
    stringSnowflake = "❄";
    stringUnicode = "Îñţérñåţîöñåļîžåţîờñ";
    stringHebrew = "שלום רב שובך צפורה נחמדת"; // An example of Right-to-Left.
    stringTrebleClef = "𝄞"; // An example of a surrogate pair.
    theFalse = false;
    theNull = null;
    theTrue = true;
    type = String;
    typeParameter =
        extractPrivateField(reflectClass(A).typeVariables.single, '_reflectee');
    typedDataArray = Uint8List(32);
    typedDataView = Uint8List.view(typedDataArray.buffer, 16);
    typedDataUnmodifiableView = typedDataArray.asUnmodifiableView();
    userTag = new UserTag("Example tag name");
    weakProperty =
        extractPrivateField(expando, '_data').firstWhere((e) => e != null);
    weakReference = WeakReference(this);

    Isolate.spawn(secondMain, "Hello2").then((otherIsolate) {
      isolate = otherIsolate;
      portSend = otherIsolate.controlPort;
      capability = otherIsolate.terminateCapability;
    });
    Isolate.spawn(secondMain, "Hello3").then((otherIsolate) {
      isolate = otherIsolate;
      portSend = otherIsolate.controlPort;
      capability = otherIsolate.terminateCapability;
    });

    print("Finished main");
    busy();
  }

  busy() {
    var localVar = 0;
    while (true) {
      localVar = (localVar + 1) & 0xFFFF;
    }
  }
}

secondMain(msg) {
  print("Hello from second isolate");
}

var typed;

class Typed {
  var float32List = new Float32List(16);
  var float64List = new Float64List(16);

  var int32x4 = new Int32x4(1, 2, 3, 4);
  var float32x4 = new Float32x4.zero();
  var float64x2 = new Float64x2.zero();
  var int32x4List = new Int32x4List(16);
  var float32x4List = new Float32x4List(16);
  var float64x2List = new Float64x2List(16);

  var int8List = new Int8List(8);
  var int16List = new Int16List(8);
  var int32List = new Int32List(8);
  var int64List = new Int64List(8);
  var uint8List = new Uint8List(8);
  var uint16List = new Uint16List(8);
  var uint32List = new Uint32List(8);
  var uint64List = new Uint64List(8);
  var uint8ClampedList = new Uint8ClampedList(8);

  var byteBuffer = new Uint8List(8).buffer;
  var byteBuffer2 = new Float32List(8).buffer;

  var byteData = new ByteData(8);

  Typed() {
    float32List[0] = 3.14;
    int8List[0] = 5;
  }
}

main() {
  libraryField = 'Library field value';
  Node.classField = 'Class field value';
  typed = new Typed();
  node = new Node();
  Node.staticMain();
}

class C {
  static doPrint() {
    print("Original");
  }
}
