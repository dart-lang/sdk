// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests unconstrained inferencing with sound variance.

// SharedOptions=--enable-experiment=variance

import "variance_helper.dart";

void covariantListInfer<T>(Covariant<List<T>> x) {}
void contravariantListInfer<T>(Contravariant<List<T>> x) {}
void invariantListInfer<T>(Invariant<List<T>> x) {}

main() {
  var cov = new Covariant();
  covariantListInfer(Covariant());

  var contra = new Contravariant();
  contravariantListInfer(Contravariant());

  var inv = new Invariant();
  invariantListInfer(Invariant());
}
