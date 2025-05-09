// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// A benchmark that contains several other benchmarks.
//
// With no arguments, run all benchmarks once.
// With arguments, run only the specified benchmarks in command-line order.
//
//     -N: run benchmarks N times, defaults to once.

// ignore_for_file: library_prefixes

import '../../BigIntParsePrint/dart/BigIntParsePrint.dart'
    deferred as lib_BigIntParsePrint;
import '../../Iterators/dart/Iterators.dart' deferred as lib_Iterators;
import '../../ListCopy/dart/ListCopy.dart' deferred as lib_ListCopy;
import '../../MD5/dart/md5.dart' deferred as lib_MD5;
import '../../MapCopy/dart/MapCopy.dart' deferred as lib_MapCopy;
import '../../MultipleReturns/dart/MultipleReturns.dart'
    deferred as lib_MultipleReturns;
import '../../RecordCollections/dart/RecordCollections.dart'
    deferred as lib_RecordCollections;
import '../../RuntimeType/dart/RuntimeType.dart' deferred as lib_RuntimeType;
import '../../SHA1/dart/sha1.dart' deferred as lib_SHA1;
import '../../SHA256/dart/sha256.dart' deferred as lib_SHA256;
import '../../SkeletalAnimation/dart/SkeletalAnimation.dart'
    deferred as lib_SkeletalAnimation;
import '../../SkeletalAnimationSIMD/dart/SkeletalAnimationSIMD.dart'
    deferred as lib_SkeletalAnimationSIMD;
import '../../SwitchFSM/dart/SwitchFSM.dart' deferred as lib_SwitchFSM;
import '../../TypedDataDuplicate/dart/TypedDataDuplicate.dart'
    deferred as lib_TypedDataDuplicate;
import '../../UiMatrix/dart/UiMatrixHarness.dart' deferred as lib_UiMatrix;
import '../../Utf8Decode/dart/Utf8Decode.dart' deferred as lib_Utf8Decode;
import '../../Utf8Encode/dart/Utf8Encode.dart' deferred as lib_Utf8Encode;

class Lib {
  final Future Function() load;
  final void Function() main;
  Lib(this.load, this.main);
}

final Map<String, Lib> benchmarks = {
  'BigIntParsePrint': Lib(
    lib_BigIntParsePrint.loadLibrary,
    () => lib_BigIntParsePrint.main(),
  ),
  'Iterators': Lib(lib_Iterators.loadLibrary, () => lib_Iterators.main([])),
  'ListCopy': Lib(lib_ListCopy.loadLibrary, () => lib_ListCopy.main()),
  'MapCopy': Lib(lib_MapCopy.loadLibrary, () => lib_MapCopy.main([])),
  'MD5': Lib(lib_MD5.loadLibrary, () => lib_MD5.main()),
  'MultipleReturns': Lib(
    lib_MultipleReturns.loadLibrary,
    () => lib_MultipleReturns.main(),
  ),
  'RecordCollections': Lib(
    lib_RecordCollections.loadLibrary,
    () => lib_RecordCollections.main(),
  ),
  'RuntimeType': Lib(lib_RuntimeType.loadLibrary, () => lib_RuntimeType.main()),
  'SHA1': Lib(lib_SHA1.loadLibrary, () => lib_SHA1.main()),
  'SHA256': Lib(lib_SHA256.loadLibrary, () => lib_SHA256.main()),
  'SkeletalAnimation': Lib(
    lib_SkeletalAnimation.loadLibrary,
    () => lib_SkeletalAnimation.main(),
  ),
  'SkeletalAnimationSIMD': Lib(
    lib_SkeletalAnimationSIMD.loadLibrary,
    () => lib_SkeletalAnimationSIMD.main(),
  ),
  'SwitchFSM': Lib(lib_SwitchFSM.loadLibrary, () => lib_SwitchFSM.main()),
  'TypedDataDuplicate': Lib(
    lib_TypedDataDuplicate.loadLibrary,
    () => lib_TypedDataDuplicate.main(),
  ),
  'UiMatrix': Lib(lib_UiMatrix.loadLibrary, () => lib_UiMatrix.main()),
  'Utf8Decode': Lib(lib_Utf8Decode.loadLibrary, () => lib_Utf8Decode.main([])),
  'Utf8Encode': Lib(lib_Utf8Encode.loadLibrary, () => lib_Utf8Encode.main([])),
};

void main(List<String> originalArguments) async {
  final List<String> args = List.of(originalArguments);

  int repeats = 1;

  for (final arg in args.toList()) {
    final int? count = int.tryParse(arg);
    if (count != null && count < 0) {
      repeats = 0 - count;
      args.remove(arg);
    }
  }

  final preload = args.remove('--preload');

  List<Lib> libs = [];

  for (final name in args.toList()) {
    final lib = benchmarks[name];
    if (lib == null) {
      print("Unknown benchmark: '$name'");
    } else {
      libs.add(lib);
      args.remove(name);
    }
  }
  if (args.isNotEmpty) return; // We will have printed an error.

  if (libs.isEmpty) libs = benchmarks.values.toList();

  if (preload) {
    for (final lib in libs) {
      await lib.load();
    }
  }

  for (var i = 0; i < repeats; i++) {
    for (final lib in libs) {
      if (!preload) await lib.load();
      lib.main();
    }
  }
}
