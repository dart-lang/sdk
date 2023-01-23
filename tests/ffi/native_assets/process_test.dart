// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Assumes we have no native asset mapping, so we look up the symbols in the
// process.

import 'dart:ffi';
import 'dart:io';

import 'package:expect/expect.dart';

void main() {
  testSuccess();
  testFailure();
  print('done');
}

void testSuccess() {
  final p1 = malloc<Int64>();
  Expect.notEquals(nullptr, p1);
  malloc.free(p1);
}

@FfiNative<Pointer Function(IntPtr)>('malloc')
external Pointer posixMalloc(int size);

@FfiNative<Pointer Function(IntPtr, IntPtr)>('calloc')
external Pointer posixCalloc(int num, int size);

@FfiNative<Void Function(Pointer)>('free')
external void posixFree(Pointer pointer);

@FfiNative<Pointer Function(Size)>('CoTaskMemAlloc')
external Pointer winCoTaskMemAlloc(int cb);

@FfiNative<Void Function(Pointer)>('CoTaskMemFree')
external void winCoTaskMemFree(Pointer pv);

class _MallocAllocator implements Allocator {
  const _MallocAllocator();

  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    Pointer<T> result;
    if (Platform.isWindows) {
      result = winCoTaskMemAlloc(byteCount).cast();
    } else {
      result = posixMalloc(byteCount).cast();
    }
    if (result.address == 0) {
      throw ArgumentError('Could not allocate $byteCount bytes.');
    }
    return result;
  }

  @override
  void free(Pointer pointer) {
    if (Platform.isWindows) {
      winCoTaskMemFree(pointer);
    } else {
      posixFree(pointer);
    }
  }
}

const Allocator malloc = _MallocAllocator();

void testFailure() {
  Expect.throws<ArgumentError>(() {
    symbolIsNotDefined();
  });
  try {
    symbolIsNotDefined();
  } on ArgumentError catch (e) {
    if (Platform.isWindows) {
      Expect.contains(
          'None of the loaded modules contained the requested symbol',
          e.message);
    } else if (Platform.isMacOS || Platform.isIOS) {
      Expect.contains('symbol_is_not_defined_29903211', e.message);
      Expect.contains('symbol not found', e.message);
    } else {
      Expect.contains(
          'undefined symbol: symbol_is_not_defined_29903211', e.message);
    }
  }
}

@FfiNative<Void Function()>('symbol_is_not_defined_29903211')
external void symbolIsNotDefined();
