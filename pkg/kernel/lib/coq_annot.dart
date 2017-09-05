// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Please see the comments in `pkg/kernel/lib/transformations/coq.dart` for more
// info.

library kernel.coq_annot;

const coq = 1; // field or class
const coqref = 2; // class only
const nocoq = 3; // field only
const coqopt = 4; // field only

// library only
class CoqLib {
  final String destPathRelative;
  const CoqLib(this.destPathRelative);
}

// TODO(30609): Since fasta currently throws away annotations on Enums, we use a
// list to identify which enums to convert.
var coqEnums = ["kernel.ast::ProcedureKind", "kernel.ast::AsyncMarker"];
