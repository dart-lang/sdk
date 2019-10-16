// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class VMRef {
  /// A name identifying this vm. Not guaranteed to be unique.
  String get name;

  /// [Not actually from the apis]
  /// A name used to identify the VM in the UI.
  String get displayName;
}

abstract class VM implements VMRef {
  /// Word length on target architecture (e.g. 32, 64).
  int get architectureBits;

  /// The CPU we are generating code for.
  String get targetCPU;

  /// The CPU we are actually running on.
  String get hostCPU;

  /// The Dart VM version string.
  String get version;

  String get embedder;

  /// The amount of memory currently allocated by native code in zones.
  int get nativeZoneMemoryUsage;

  /// The process id for the VM.
  int get pid;

  /// The current amount of native heap allocated memory within the VM.
  int get heapAllocatedMemoryUsage;

  /// The current number of allocations on the native heap within the VM.
  int get heapAllocationCount;

  int get maxRSS;
  int get currentRSS;

  /// The time that the VM started in milliseconds since the epoch.
  ///
  /// Suitable to pass to DateTime.fromMillisecondsSinceEpoch.
  DateTime get startTime;

  // A list of isolates running in the VM.
  Iterable<IsolateRef> get isolates;

  /// Enable the sampling profiler.
  Future enableProfiler();
}
