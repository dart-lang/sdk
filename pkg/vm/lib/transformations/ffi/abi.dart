// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common.dart';

// TODO(http://dartbug.com/47823): Remove this copy of `Abi`.

/// The hardware architectures the Dart VM runs on.
enum _Architecture {
  arm,
  arm64,
  ia32,
  x64,
  riscv32,
  riscv64,
}

extension on _Architecture {
  /// The size of integer registers and memory addresses in bytes.
  int get wordSize {
    switch (this) {
      case _Architecture.arm:
      case _Architecture.ia32:
      case _Architecture.riscv32:
        return 4;
      case _Architecture.arm64:
      case _Architecture.x64:
      case _Architecture.riscv64:
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

/// An application binary interface (ABI).
///
/// An ABI defines the memory layout of data
/// and the function call protocol for native code.
/// It is usually defined by the an operating system for each
/// architecture that operating system runs on.
///
/// The Dart VM can run on a variety of operating systems and architectures.
/// Supported ABIs are represented by `Abi` objects.
/// See [values] for all the supported ABIs.
class Abi {
  /// The application binary interface for Android on the Arm architecture.
  static const androidArm = _androidArm;

  /// The application binary interface for Android on the Arm64 architecture.
  static const androidArm64 = _androidArm64;

  /// The application binary interface for Android on the IA32 architecture.
  static const androidIA32 = _androidIA32;

  /// The application binary interface for android on the X64 architecture.
  static const androidX64 = _androidX64;

  /// The application binary interface for Fuchsia on the Arm64 architecture.
  static const fuchsiaArm64 = _fuchsiaArm64;

  /// The application binary interface for Fuchsia on the X64 architecture.
  static const fuchsiaX64 = _fuchsiaX64;

  /// The application binary interface for iOS on the Arm architecture.
  static const iosArm = _iosArm;

  /// The application binary interface for iOS on the Arm64 architecture.
  static const iosArm64 = _iosArm64;

  /// The application binary interface for iOS on the X64 architecture.
  static const iosX64 = _iosX64;

  /// The application binary interface for Linux on the Arm architecture.
  ///
  /// Does not distinguish between hard and soft fp. Currently, no uses of Abi
  /// require this distinction.
  static const linuxArm = _linuxArm;

  /// The application binary interface for linux on the Arm64 architecture.
  static const linuxArm64 = _linuxArm64;

  /// The application binary interface for linux on the IA32 architecture.
  static const linuxIA32 = _linuxIA32;

  /// The application binary interface for linux on the X64 architecture.
  static const linuxX64 = _linuxX64;

  /// The application binary interface for linux on 32-bit RISC-V.
  static const linuxRiscv32 = _linuxRiscv32;

  /// The application binary interface for linux on 64-bit RISC-V.
  static const linuxRiscv64 = _linuxRiscv64;

  /// The application binary interface for MacOS on the Arm64 architecture.
  static const macosArm64 = _macosArm64;

  /// The application binary interface for MacOS on the X64 architecture.
  static const macosX64 = _macosX64;

  /// The application binary interface for Windows on the Arm64 architecture.
  static const windowsArm64 = _windowsArm64;

  /// The application binary interface for Windows on the IA32 architecture.
  static const windowsIA32 = _windowsIA32;

  /// The application binary interface for Windows on the X64 architecture.
  static const windowsX64 = _windowsX64;

  /// The ABIs that the DartVM can run on, sorted alphabetically.
  ///
  /// Does not contain macosIA32, we stopped supporting it.
  /// https://github.com/dart-lang/sdk/issues/39810
  ///
  /// Includes [windowsArm64], even though it is currently not supported.
  /// Support has been requested for Flutter.
  /// https://github.com/flutter/flutter/issues/53120
  static const values = [
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
    linuxRiscv32,
    linuxRiscv64,
    macosArm64,
    macosX64,
    windowsArm64,
    windowsIA32,
    windowsX64,
  ];

  /// The ABI the Dart VM is currently running on.
  external factory Abi.current();

  /// A string representation of this ABI.
  ///
  /// The string is equal to the 'on' part from `Platform.version` and
  /// `dart --version`.
  @override
  String toString() => '${_os.name}_${_architecture.name}';

  /// The size of both integer registers and memory addresses in bytes.
  int get wordSize => _architecture.wordSize;

  /// The operating system of this [Abi].
  final _OS _os;

  /// The architecture of this [Abi].
  final _Architecture _architecture;

  /// The constructor is private so that we can use [Abi.values] as opaque
  /// tokens.
  const Abi._(this._architecture, this._os);

  static const _androidArm = Abi._(_Architecture.arm, _OS.android);
  static const _androidArm64 = Abi._(_Architecture.arm64, _OS.android);
  static const _androidIA32 = Abi._(_Architecture.ia32, _OS.android);
  static const _androidX64 = Abi._(_Architecture.x64, _OS.android);
  static const _fuchsiaArm64 = Abi._(_Architecture.arm64, _OS.fuchsia);
  static const _fuchsiaX64 = Abi._(_Architecture.x64, _OS.fuchsia);
  static const _iosArm = Abi._(_Architecture.arm, _OS.ios);
  static const _iosArm64 = Abi._(_Architecture.arm64, _OS.ios);
  static const _iosX64 = Abi._(_Architecture.x64, _OS.ios);
  static const _linuxArm = Abi._(_Architecture.arm, _OS.linux);
  static const _linuxArm64 = Abi._(_Architecture.arm64, _OS.linux);
  static const _linuxIA32 = Abi._(_Architecture.ia32, _OS.linux);
  static const _linuxX64 = Abi._(_Architecture.x64, _OS.linux);
  static const _linuxRiscv32 = Abi._(_Architecture.riscv32, _OS.linux);
  static const _linuxRiscv64 = Abi._(_Architecture.riscv64, _OS.linux);
  static const _macosArm64 = Abi._(_Architecture.arm64, _OS.macos);
  static const _macosX64 = Abi._(_Architecture.x64, _OS.macos);
  static const _windowsArm64 = Abi._(_Architecture.arm64, _OS.windows);
  static const _windowsIA32 = Abi._(_Architecture.ia32, _OS.windows);
  static const _windowsX64 = Abi._(_Architecture.x64, _OS.windows);
}

// Keep consistent with sdk/lib/ffi/abi.dart.
const Map<Abi, String> abiNames = {
  Abi.androidArm: 'androidArm',
  Abi.androidArm64: 'androidArm64',
  Abi.androidIA32: 'androidIA32',
  Abi.androidX64: 'androidX64',
  Abi.fuchsiaArm64: 'fuchsiaArm64',
  Abi.fuchsiaX64: 'fuchsiaX64',
  Abi.iosArm: 'iosArm',
  Abi.iosArm64: 'iosArm64',
  Abi.iosX64: 'iosX64',
  Abi.linuxArm: 'linuxArm',
  Abi.linuxArm64: 'linuxArm64',
  Abi.linuxIA32: 'linuxIA32',
  Abi.linuxX64: 'linuxX64',
  Abi.linuxRiscv32: 'linuxRiscv32',
  Abi.linuxRiscv64: 'linuxRiscv64',
  Abi.macosArm64: 'macosArm64',
  Abi.macosX64: 'macosX64',
  Abi.windowsArm64: 'windowsArm64',
  Abi.windowsIA32: 'windowsIA32',
  Abi.windowsX64: 'windowsX64',
};

/// The size of integer registers and memory addresses in bytes per [Abi].
// Keep consistent with sdk/lib/_internal/vm/lib/ffi_patch.dart
final Map<Abi, int> wordSize =
    Map.unmodifiable({for (final abi in Abi.values) abi: abi.wordSize});

/// Alignment for types that are not aligned to a multiple of their size.
///
/// When a type occurs in a struct or union, it's usually aligned
/// to a multiple of its own size.
/// Some ABIs have types which are not aligned to their own size,
/// but to a smaller size.
///
/// This map maps each [Abi] to a mapping from types that are not
/// aligned by their size, to their actual alignment.
/// If such a map is empty, which many are,
/// it means that all types are aligned to their own size in that ABI.
///
/// See runtime/vm/compiler/ffi/abi.cc for asserts in the VM that verify these
/// alignments.
const Map<Abi, Map<NativeType, int>> nonSizeAlignment = {
  // _wordSize64
  Abi.androidArm64: _wordSize64,
  Abi.androidX64: _wordSize64,
  Abi.fuchsiaArm64: _wordSize64,
  Abi.fuchsiaX64: _wordSize64,
  Abi.iosArm64: _wordSize64,
  Abi.iosX64: _wordSize64,
  Abi.linuxArm64: _wordSize64,
  Abi.linuxX64: _wordSize64,
  Abi.linuxRiscv64: _wordSize64,
  Abi.macosArm64: _wordSize64,
  Abi.macosX64: _wordSize64,
  Abi.windowsArm64: _wordSize64,
  Abi.windowsX64: _wordSize64,
  // _wordSize32Align32
  Abi.androidIA32: _wordSize32Align32,
  Abi.iosArm: _wordSize32Align32,
  Abi.linuxIA32: _wordSize32Align32,
  // _wordSize32Align64
  Abi.androidArm: _wordSize32Align64,
  Abi.linuxArm: _wordSize32Align64,
  Abi.linuxRiscv32: _wordSize32Align64,
  Abi.windowsIA32: _wordSize32Align64,
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
// Arm always requires 8 byte alignment for 8 byte values:
// http://infocenter.arm.com/help/topic/com.arm.doc.ihi0042d/IHI0042D_aapcs.pdf 4.1 Fundamental Data Types
const Map<NativeType, int> _wordSize32Align64 = {};
