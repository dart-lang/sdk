// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Macro-benchmark for ffi with boringssl.

// @dart=2.9

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ffi/ffi.dart';

import 'digest.dart';
import 'types.dart';

//
// BoringSSL functions
//

Uint8List inventData(int length) {
  final result = Uint8List(length);
  for (int i = 0; i < length; i++) {
    result[i] = i % 256;
  }
  return result;
}

Uint8List toUint8List(Bytes bytes, int length) {
  final result = Uint8List(length);
  final uint8bytes = bytes.asUint8Pointer();
  for (int i = 0; i < length; i++) {
    result[i] = uint8bytes[i];
  }
  return result;
}

void copyFromUint8ListToTarget(Uint8List source, Data target) {
  final int length = source.length;
  final uint8target = target.asUint8Pointer();
  for (int i = 0; i < length; i++) {
    uint8target[i] = source[i];
  }
}

String hash(Pointer<Data> data, int length, Pointer<EVP_MD> hashAlgorithm) {
  final context = EVP_MD_CTX_new();
  EVP_DigestInit(context, hashAlgorithm);
  EVP_DigestUpdate(context, data, length);
  final int resultSize = EVP_MD_CTX_size(context);
  final Pointer<Bytes> result = allocate<Uint8>(count: resultSize).cast();
  EVP_DigestFinal(context, result, nullptr);
  EVP_MD_CTX_free(context);
  final String hash = base64Encode(toUint8List(result.ref, resultSize));
  free(result);
  return hash;
}

//
// Benchmark fixtures.
//

// Number of repeats: 1 && Length in bytes: 10000000
//  * CPU: Intel(R) Xeon(R) Gold 6154
//    * Architecture: x64
//      * 23000 - 52000000 us (without optimizations)
//      * 23000 - 30000 us (with optimizations)
const int L = 1000; // Length of data in bytes.

final hashAlgorithm = EVP_sha512();

// Hash of generated data of `L` bytes with `hashAlgorithm`.
const String expectedHash =
    'bNLtqb+cBZcSkCmwBUuB5DP2uLe0madetwXv10usGUFJg1sdGhTEi+aW5NWIRW1RKiLq56obV74rVurn014Iyw==';

/// This benchmark runs a digest algorithm on data residing in C memory.
///
/// This benchmark is intended as macro benchmark with a realistic workload.
class DigestCMemory extends BenchmarkBase {
  DigestCMemory() : super('FfiBoringssl.DigestCMemory');

  Pointer<Data> data; // Data in C memory that we want to digest.

  @override
  void setup() {
    data = allocate<Uint8>(count: L).cast();
    copyFromUint8ListToTarget(inventData(L), data.ref);
    hash(data, L, hashAlgorithm);
  }

  @override
  void teardown() {
    free(data);
  }

  @override
  void run() {
    final String result = hash(data, L, hashAlgorithm);
    if (result != expectedHash) {
      throw Exception('$name: Unexpected result: $result');
    }
  }
}

/// This benchmark runs a digest algorithm on data residing in Dart memory.
///
/// This benchmark is intended as macro benchmark with a realistic workload.
class DigestDartMemory extends BenchmarkBase {
  DigestDartMemory() : super('FfiBoringssl.DigestDartMemory');

  Uint8List data; // Data in C memory that we want to digest.

  @override
  void setup() {
    data = inventData(L);
    final Pointer<Data> dataInC = allocate<Uint8>(count: L).cast();
    copyFromUint8ListToTarget(data, dataInC.ref);
    hash(dataInC, L, hashAlgorithm);
    free(dataInC);
  }

  @override
  void teardown() {}

  @override
  void run() {
    final Pointer<Data> dataInC = allocate<Uint8>(count: L).cast();
    copyFromUint8ListToTarget(data, dataInC.ref);
    final String result = hash(dataInC, L, hashAlgorithm);
    free(dataInC);
    if (result != expectedHash) {
      throw Exception('$name: Unexpected result: $result');
    }
  }
}

//
// Main driver.
//

void main() {
  final benchmarks = [
    () => DigestCMemory(),
    () => DigestDartMemory(),
  ];
  for (final benchmark in benchmarks) {
    benchmark().report();
  }
}
