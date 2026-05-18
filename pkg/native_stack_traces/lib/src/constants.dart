// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The section name in which the build ID is stored as a note.
const String buildIdSectionName = '.note.gnu.build-id';
// The type of a build ID note.
const int buildIdNoteType = 3;
// The name of a build ID note.
const String buildIdNoteName = 'GNU';

// The dynamic symbol name for the isolate instructions section.
const String textSymbolName = '_kDartSnapshotText';

// The dynamic symbol name for the isolate data section.
const String dataSymbolName = '_kDartSnapshotData';

// The ID for the root loading unit.
const int rootLoadingUnitId = 1;

// The dynamic symbol name for the VM instructions section.
const String oldVmSymbolName = '_kDartVmSnapshotInstructions';

// The dynamic symbol name for the VM data section.
const String oldVmDataSymbolName = '_kDartVmSnapshotData';

// The dynamic symbol name for the isolate instructions section.
const String oldIsolateSymbolName = '_kDartIsolateSnapshotInstructions';

// The dynamic symbol name for the isolate data section.
const String oldIsolateDataSymbolName = '_kDartIsolateSnapshotData';
