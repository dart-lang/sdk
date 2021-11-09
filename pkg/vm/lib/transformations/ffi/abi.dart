// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common.dart';

/// The hardware architectures the Dart VM runs on.
enum _Architecture {
  arm,
  arm64,
  ia32,
  x64,
}

extension on _Architecture {
  /// The size of integer registers and memory addresses in bytes.
  int get wordSize {
    switch (this) {
      case _Architecture.arm:
      case _Architecture.ia32:
        return 4;
      case _Architecture.arm64:
      case _Architecture.x64:
        return 8;
    }
  }
}

/// The operating systems the Dart VM runs on.
enum _OS {
  android,
  fuchsia,
  ios,
  linux,
  macos,
  windows,
}

/// Application binary interface.
///
/// The Dart VM can run on a variety of [Abi]s, see [supportedAbis].
class Abi {
  /// The operating system of this [Abi].
  // ignore: unused_field
  final _OS _os;

  /// The architecture of this [Abi].
  final _Architecture _architecture;

  /// The size of integer registers and memory addresses in bytes.
  int get wordSize => _architecture.wordSize;

  const Abi._(this._architecture, this._os);
}

const androidArm = Abi._(_Architecture.arm, _OS.android);
const androidArm64 = Abi._(_Architecture.arm64, _OS.android);
const androidIA32 = Abi._(_Architecture.ia32, _OS.android);
const androidX64 = Abi._(_Architecture.x64, _OS.android);
const fuchsiaArm64 = Abi._(_Architecture.arm64, _OS.fuchsia);
const fuchsiaX64 = Abi._(_Architecture.x64, _OS.fuchsia);
const iosArm = Abi._(_Architecture.arm, _OS.ios);
const iosArm64 = Abi._(_Architecture.arm64, _OS.ios);
const iosX64 = Abi._(_Architecture.x64, _OS.ios);
const linuxArm = Abi._(_Architecture.arm, _OS.linux);
const linuxArm64 = Abi._(_Architecture.arm64, _OS.linux);
const linuxIA32 = Abi._(_Architecture.ia32, _OS.linux);
const linuxX64 = Abi._(_Architecture.x64, _OS.linux);
const macosArm64 = Abi._(_Architecture.arm64, _OS.macos);

// No macosIA32, not intending to support.
// https://github.com/dart-lang/sdk/issues/39810

const macosX64 = Abi._(_Architecture.x64, _OS.macos);

/// Currently not supported, but feature requested for Flutter.
/// https://github.com/flutter/flutter/issues/53120
const windowsArm64 = Abi._(_Architecture.arm64, _OS.windows);
const windowsIA32 = Abi._(_Architecture.ia32, _OS.windows);
const windowsX64 = Abi._(_Architecture.x64, _OS.windows);

/// All ABIs that the DartVM can run on sorted alphabetically.
///
/// Keep consistent with runtime/vm/compiler/ffi/abi.cc.
const supportedAbisOrdered = [
  androidArm,
  androidArm64,
  androidIA32,
  androidX64,
  fuchsiaArm64,
  fuchsiaX64,
  iosArm,
  iosArm64,
  iosX64,
  linuxArm,
  linuxArm64,
  linuxIA32,
  linuxX64,
  macosArm64,
  macosX64,
  windowsArm64,
  windowsIA32,
  windowsX64,
];

/// The size of integer registers and memory addresses in bytes per [Abi].
// Keep consistent with sdk/lib/_internal/vm/lib/ffi_patch.dart
final Map<Abi, int> wordSize = {
  for (final abi in supportedAbisOrdered) abi: abi.wordSize
};

/// Struct and union fields that are not aligned to their size.
///
/// Has an entry for all Abis. Empty entries document that every native
/// type is aligned to it's own size in this ABI.
///
/// See runtime/vm/compiler/ffi/abi.cc for asserts in the VM that verify these
/// alignments.
const nonSizeAlignment = <Abi, Map<NativeType, int>>{
  // _wordSize64
  androidArm64: _wordSize64,
  androidX64: _wordSize64,
  fuchsiaArm64: _wordSize64,
  fuchsiaX64: _wordSize64,
  iosArm64: _wordSize64,
  iosX64: _wordSize64,
  linuxArm64: _wordSize64,
  linuxX64: _wordSize64,
  macosArm64: _wordSize64,
  macosX64: _wordSize64,
  windowsArm64: _wordSize64,
  windowsX64: _wordSize64,
  // _wordSize32Align32
  androidIA32: _wordSize32Align32,
  iosArm: _wordSize32Align32,
  linuxIA32: _wordSize32Align32,
  // _wordSize32Align64
  androidArm: _wordSize32Align64,
  linuxArm: _wordSize32Align64,
  windowsIA32: _wordSize32Align64,
};

// All 64 bit ABIs align struct fields to their size.
const Map<NativeType, int> _wordSize64 = {};

// x86 System V ABI:
// > uint64_t | size 8 | alignment 4
// > double   | size 8 | alignment 4
// https://github.com/hjl-tools/x86-psABI/wiki/intel386-psABI-1.1.pdf page 8.
//
// ios 32 bit alignment:
// https://developer.apple.com/documentation/uikit/app_and_environment/updating_your_app_from_32-bit_to_64-bit_architecture/updating_data_structures
const Map<NativeType, int> _wordSize32Align32 = {
  NativeType.kDouble: 4,
  NativeType.kInt64: 4,
  NativeType.kUint64: 4
};

// The default for MSVC x86:
// > The alignment-requirement for all data except structures, unions, and
// > arrays is either the size of the object or the current packing size
// > (specified with either /Zp or the pack pragma, whichever is less).
// https://docs.microsoft.com/en-us/cpp/c-language/padding-and-alignment-of-structure-members?view=vs-2019
//
// GCC _can_ compile on Linux to this alignment with -malign-double, but does
// not do so by default:
// > Warning: if you use the -malign-double switch, structures containing the
// > above types are aligned differently than the published application
// > binary interface specifications for the x86-32 and are not binary
// > compatible with structures in code compiled without that switch.
// https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html
//
// ARM always requires 8 byte alignment for 8 byte values:
// http://infocenter.arm.com/help/topic/com.arm.doc.ihi0042d/IHI0042D_aapcs.pdf 4.1 Fundamental Data Types
const Map<NativeType, int> _wordSize32Align64 = {};
