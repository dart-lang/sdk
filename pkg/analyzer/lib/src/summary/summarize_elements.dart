// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary/format.dart';

/// Object that gathers information uses it to assemble a new
/// [PackageBundleBuilder].
class PackageBundleAssembler {
  LinkedNodeBundleBuilder _bundle2;

  /// Assemble a new [PackageBundleBuilder] using the gathered information.
  PackageBundleBuilder assemble() {
    return PackageBundleBuilder(bundle2: _bundle2);
  }

  void setBundle2(LinkedNodeBundleBuilder bundle2) {
    if (this._bundle2 != null) {
      throw StateError('Bundle2 may be set only once.');
    }
    _bundle2 = bundle2;
  }
}
