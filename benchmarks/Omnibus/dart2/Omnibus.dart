// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// @dart=2.10
//
// A benchmark that contains several other benchmarks.
//
// With no arguments, run all benchmarks once.
// With arguments, run only the specified benchmarks in command-line order.
//
//     -N: run benchmarks N times, defaults to once.

import '../../ListCopy/dart/ListCopy.dart' as lib_ListCopy;
import '../../BigIntParsePrint/dart/BigIntParsePrint.dart'
    as lib_BigIntParsePrint;
import '../../MD5/dart/md5.dart' as lib_MD5;
import '../../RuntimeType/dart/RuntimeType.dart' as lib_RuntimeType;
import '../../SHA1/dart/sha1.dart' as lib_SHA1;
import '../../SHA256/dart/sha256.dart' as lib_SHA256;
import '../../SkeletalAnimation/dart/SkeletalAnimation.dart'
    as lib_SkeletalAnimation;
import '../../SkeletalAnimationSIMD/dart/SkeletalAnimationSIMD.dart'
    as lib_SkeletalAnimationSIMD;
import '../../TypedDataDuplicate/dart/TypedDataDuplicate.dart'
    as lib_TypedDataDuplicate;
import '../../Utf8Decode/dart/Utf8Decode.dart' as lib_Utf8Decode;
import '../../Utf8Encode/dart/Utf8Encode.dart' as lib_Utf8Encode;

final Map<String, Function()> benchmarks = {
  'ListCopy': lib_ListCopy.main,
  'BigIntParsePrint': lib_BigIntParsePrint.main,
  'MD5': lib_MD5.main,
  'RuntimeType': lib_RuntimeType.main,
  'SHA1': lib_SHA1.main,
  'SHA256': lib_SHA256.main,
  'SkeletalAnimation': lib_SkeletalAnimation.main,
  'SkeletalAnimationSIMD': lib_SkeletalAnimationSIMD.main,
  'TypedDataDuplicate': lib_TypedDataDuplicate.main,
  'Utf8Decode': () => lib_Utf8Decode.main([]),
  'Utf8Encode': () => lib_Utf8Encode.main([]),
};

main(List<String> originalArguments) {
  List<String> args = List.of(originalArguments);

  int repeats = 1;

  for (final arg in args.toList()) {
    int count = int.tryParse(arg);
    if (count != null && count < 0) {
      repeats = 0 - count;
      args.remove(arg);
    }
  }

  List<Function()> mains = [];

  for (final name in args.toList()) {
    final function = benchmarks[name];
    if (function == null) {
      print("Unknown benchmark: '$name'");
    } else {
      mains.add(function);
      args.remove(name);
    }
  }
  if (args.isNotEmpty) return; // We will have printed an error.

  if (mains.isEmpty) mains = benchmarks.values.toList();

  for (var i = 0; i < repeats; i++) {
    for (final function in mains) {
      function();
    }
  }
}
