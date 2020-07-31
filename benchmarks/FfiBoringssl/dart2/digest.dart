// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import 'dlopen_helper.dart';
import 'types.dart';

// See:
// https://commondatastorage.googleapis.com/chromium-boringssl-docs/digest.h.html

DynamicLibrary openSsl() {
  // Force load crypto.
  dlopenPlatformSpecific('crypto',
      path: Platform.script.resolve('../native/out/').path);
  final ssl = dlopenPlatformSpecific('ssl',
      path: Platform.script.resolve('../native/out/').path);
  return ssl;
}

final DynamicLibrary ssl = openSsl();

/// The following functions return EVP_MD objects that implement the named
/// hash function.
///
/// ```c
/// const EVP_MD *EVP_sha512(void);
/// ```
final Pointer<EVP_MD> Function() EVP_sha512 =
    ssl.lookupFunction<Pointer<EVP_MD> Function(), Pointer<EVP_MD> Function()>(
        'EVP_sha512');

/// EVP_MD_CTX_new allocates and initialises a fresh EVP_MD_CTX and returns it,
/// or NULL on allocation failure. The caller must use EVP_MD_CTX_free to
/// release the resulting object.
///
/// ```c
/// EVP_MD_CTX *EVP_MD_CTX_new(void);
/// ```
final Pointer<EVP_MD_CTX> Function() EVP_MD_CTX_new = ssl.lookupFunction<
    Pointer<EVP_MD_CTX> Function(),
    Pointer<EVP_MD_CTX> Function()>('EVP_MD_CTX_new');

/// EVP_MD_CTX_free calls EVP_MD_CTX_cleanup and then frees ctx itself.
///
/// ```c
/// void EVP_MD_CTX_free(EVP_MD_CTX *ctx);
/// ```
final void Function(Pointer<EVP_MD_CTX>) EVP_MD_CTX_free = ssl.lookupFunction<
    Void Function(Pointer<EVP_MD_CTX>),
    void Function(Pointer<EVP_MD_CTX>)>('EVP_MD_CTX_free');

/// EVP_DigestInit acts like EVP_DigestInit_ex except that ctx is initialised
/// before use.
///
/// ```c
/// int EVP_DigestInit(EVP_MD_CTX *ctx, const EVP_MD *type);
/// ```
final int Function(Pointer<EVP_MD_CTX>, Pointer<EVP_MD>) EVP_DigestInit =
    ssl.lookupFunction<Int32 Function(Pointer<EVP_MD_CTX>, Pointer<EVP_MD>),
        int Function(Pointer<EVP_MD_CTX>, Pointer<EVP_MD>)>('EVP_DigestInit');

/// EVP_DigestUpdate hashes len bytes from data into the hashing operation
/// in ctx. It returns one.
///
/// ```c
/// int EVP_DigestUpdate(EVP_MD_CTX *ctx, const void *data,
///                                     size_t len);
/// ```
final int Function(Pointer<EVP_MD_CTX>, Pointer<Data>, int) EVP_DigestUpdate =
    ssl.lookupFunction<
        Int32 Function(Pointer<EVP_MD_CTX>, Pointer<Data>, IntPtr),
        int Function(
            Pointer<EVP_MD_CTX>, Pointer<Data>, int)>('EVP_DigestUpdate');

/// EVP_DigestFinal acts like EVP_DigestFinal_ex except that EVP_MD_CTX_cleanup
/// is called on ctx before returning.
///
/// ```c
/// int EVP_DigestFinal(EVP_MD_CTX *ctx, uint8_t *md_out,
///                                    unsigned int *out_size);
/// ```
final int Function(Pointer<EVP_MD_CTX>, Pointer<Bytes>, Pointer<Uint32>)
    EVP_DigestFinal = ssl.lookupFunction<
        Int32 Function(Pointer<EVP_MD_CTX>, Pointer<Bytes>, Pointer<Uint32>),
        int Function(Pointer<EVP_MD_CTX>, Pointer<Bytes>,
            Pointer<Uint32>)>('EVP_DigestFinal');

/// EVP_MD_CTX_size returns the digest size of ctx, in bytes. It will crash if
/// a digest hasn't been set on ctx.
///
/// ```c
/// size_t EVP_MD_CTX_size(const EVP_MD_CTX *ctx);
/// ```
final int Function(Pointer<EVP_MD_CTX>) EVP_MD_CTX_size = ssl.lookupFunction<
    IntPtr Function(Pointer<EVP_MD_CTX>),
    int Function(Pointer<EVP_MD_CTX>)>('EVP_MD_CTX_size');
