// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'vm_offsets.g.dart';
export 'vm_offsets.g.dart';

const int smiBit = 0;
const int heapObjectTag = 1;
const int barrierOverlapShift = 2;

int objectAlignment(int wordSize) => wordSize * 2;
int log2objectAlignment(int log2wordSize) => log2wordSize + 1;

/// This bit is 0 for bool 'true', 1 for bool 'false'.
int boolValueBitPosition(int log2wordSize) => log2objectAlignment(log2wordSize);

/// The number of bits in the _magnitude_ of a Smi, not counting the sign bit.
int smiBits(int compressedWordSize) => (compressedWordSize * 8) - 2;

extension ComputedOffsets on VMOffsets {
  /// Offset of [entry] in the Thread.
  // ignore: non_constant_identifier_names
  int Thread_runtime_entry_offset(RuntimeEntry entry, int wordSize) =>
      Thread_AllocateArray_entry_point_offset +
      (entry.index - RuntimeEntry.AllocateArray.index) * wordSize;

  /// Offset of [entry] in the Thread.
  // ignore: non_constant_identifier_names
  int Thread_leaf_runtime_entry_offset(LeafRuntimeEntry entry, int wordSize) =>
      Thread_DeoptimizeCopyFrame_entry_point_offset +
      (entry.index - LeafRuntimeEntry.DeoptimizeCopyFrame.index) * wordSize;
}

// Symbol names used in Dart snapshots.

const String snapshotBuildIdAsmSymbol = "_kDartSnapshotBuildId";
const String vmSnapshotDataAsmSymbol = "_kDartVmSnapshotData";
const String vmSnapshotInstructionsAsmSymbol = "_kDartVmSnapshotInstructions";
const String vmSnapshotBssAsmSymbol = "_kDartVmSnapshotBss";
const String isolateSnapshotDataAsmSymbol = "_kDartIsolateSnapshotData";
const String isolateSnapshotInstructionsAsmSymbol =
    "_kDartIsolateSnapshotInstructions";
const String isolateSnapshotBssAsmSymbol = "_kDartIsolateSnapshotBss";
