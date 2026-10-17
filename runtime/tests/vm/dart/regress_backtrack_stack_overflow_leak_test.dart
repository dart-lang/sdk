// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--intrinsify
// VMOptions=--no_intrinsify

// Regression test for interpreter backtrack-stack and registers native heap
// leak when StackOverflowError is caught.
//
// Note: RSS is an environmental metric subject to allocator behavior. This test
// acts as a coarse regression sentinel, verifying that resident memory plateaus
// after warmup rather than growing continuously. Before the fix, each caught
// overflow leaked ~64 MiB of resident memory (~256 MiB over 4 runs).
// After the fix, native storage is released before aborting and growth remains
// near zero (<64 MiB threshold). Under sanitizer configurations (ASan, MSan,
// TSan), quarantine allocators retain freed heap chunks, so this test should be
// skipped via vm.status on sanitizer bots.

import 'dart:io';

import 'package:expect/expect.dart';

void main() {
  const captureCount = 1000;
  final pattern = '^(?:${'()' * captureCount}a)*z\$';
  final regexp = RegExp(pattern);
  final subject = 'a' * 4500;

  // Non-overflowing control pattern matches normally without error.
  Expect.isFalse(regexp.hasMatch('a' * 4000));

  // Two warmup iterations ensure regexp compilation, bytecode tables, and VM
  // runtime structures are fully initialized before sampling the baseline.
  for (var i = 0; i < 2; i++) {
    Expect.throws<StackOverflowError>(() => regexp.hasMatch(subject));
  }
  final initialRss = ProcessInfo.currentRss;

  // Run multiple caught overflow iterations.
  // Before the fix, each caught overflow leaked ~64 MiB of resident memory
  // (~256 MiB over 4 iterations).
  // After the fix, native storage is released before aborting and RSS plateaus.
  for (var i = 0; i < 4; i++) {
    Expect.throws<StackOverflowError>(() => regexp.hasMatch(subject));
  }
  final finalRss = ProcessInfo.currentRss;

  if (Platform.isLinux || Platform.isMacOS) {
    final growth = finalRss - initialRss;
    Expect.isTrue(
      growth < 64 * 1024 * 1024,
      'Excessive RSS growth (${growth ~/ (1024 * 1024)} MB) indicates '
      'native backtrack stack memory leak',
    );
  }
}
