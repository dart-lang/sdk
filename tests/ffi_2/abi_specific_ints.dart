// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:ffi';

// TODO(dacoharkes): These should move to `package:ffi`.

/// Represents a native unsigned pointer-sized integer in C.
///
/// [UintPtr] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
  Abi.androidArm64: Uint64(),
  Abi.androidIA32: Uint32(),
  Abi.androidX64: Uint64(),
  Abi.fuchsiaArm64: Uint64(),
  Abi.fuchsiaX64: Uint64(),
  Abi.iosArm: Uint32(),
  Abi.iosArm64: Uint64(),
  Abi.iosX64: Uint64(),
  Abi.linuxArm: Uint32(),
  Abi.linuxArm64: Uint64(),
  Abi.linuxIA32: Uint32(),
  Abi.linuxX64: Uint64(),
  Abi.macosArm64: Uint64(),
  Abi.macosX64: Uint64(),
  Abi.windowsArm64: Uint64(),
  Abi.windowsIA32: Uint32(),
  Abi.windowsX64: Uint64(),
})
class UintPtr extends AbiSpecificInteger {
  const UintPtr();
}

/// `long` in C.
///
/// [Long] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
@AbiSpecificIntegerMapping({
  Abi.androidArm: Int32(),
  Abi.androidArm64: Int64(),
  Abi.androidIA32: Int32(),
  Abi.androidX64: Int64(),
  Abi.fuchsiaArm64: Int64(),
  Abi.fuchsiaX64: Int64(),
  Abi.iosArm: Int32(),
  Abi.iosArm64: Int64(),
  Abi.iosX64: Int64(),
  Abi.linuxArm: Int32(),
  Abi.linuxArm64: Int64(),
  Abi.linuxIA32: Int32(),
  Abi.linuxX64: Int64(),
  Abi.macosArm64: Int64(),
  Abi.macosX64: Int64(),
  Abi.windowsArm64: Int32(),
  Abi.windowsIA32: Int32(),
  Abi.windowsX64: Int32(),
})
class Long extends AbiSpecificInteger {
  const Long();
}

/// `unsigned long` in C.
///
/// [UnsignedLong] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
  Abi.androidArm64: Uint64(),
  Abi.androidIA32: Uint32(),
  Abi.androidX64: Uint64(),
  Abi.fuchsiaArm64: Uint64(),
  Abi.fuchsiaX64: Uint64(),
  Abi.iosArm: Uint32(),
  Abi.iosArm64: Uint64(),
  Abi.iosX64: Uint64(),
  Abi.linuxArm: Uint32(),
  Abi.linuxArm64: Uint64(),
  Abi.linuxIA32: Uint32(),
  Abi.linuxX64: Uint64(),
  Abi.macosArm64: Uint64(),
  Abi.macosX64: Uint64(),
  Abi.windowsArm64: Uint32(),
  Abi.windowsIA32: Uint32(),
  Abi.windowsX64: Uint32(),
})
class UnsignedLong extends AbiSpecificInteger {
  const UnsignedLong();
}

/// `wchar_t` in C.
///
/// The signedness of `wchar_t` is undefined in C. Here, it is exposed as an
/// unsigned integer.
///
/// [WChar] is not constructible in the Dart code and serves purely as marker in
/// type signatures.
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
  Abi.androidArm64: Uint32(),
  Abi.androidIA32: Uint32(),
  Abi.androidX64: Uint32(),
  Abi.fuchsiaArm64: Uint32(),
  Abi.fuchsiaX64: Uint32(),
  Abi.iosArm: Uint32(),
  Abi.iosArm64: Uint32(),
  Abi.iosX64: Uint32(),
  Abi.linuxArm: Uint32(),
  Abi.linuxArm64: Uint32(),
  Abi.linuxIA32: Uint32(),
  Abi.linuxX64: Uint32(),
  Abi.macosArm64: Uint32(),
  Abi.macosX64: Uint32(),
  Abi.windowsArm64: Uint16(),
  Abi.windowsIA32: Uint16(),
  Abi.windowsX64: Uint16(),
})
class WChar extends AbiSpecificInteger {
  const WChar();
}
