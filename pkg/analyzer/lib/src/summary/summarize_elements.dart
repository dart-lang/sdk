// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';

/**
 * Object that gathers information uses it to assemble a new
 * [PackageBundleBuilder].
 */
class PackageBundleAssembler {
  /**
   * Value that will be stored in [PackageBundle.majorVersion] for any summaries
   * created by this code.  When making a breaking change to the summary format,
   * this value should be incremented by 1 and [currentMinorVersion] should be
   * reset to zero.
   */
  static const int currentMajorVersion = 1;

  /**
   * Value that will be stored in [PackageBundle.minorVersion] for any summaries
   * created by this code.  When making a non-breaking change to the summary
   * format that clients might need to be aware of (such as adding a kind of
   * data that was previously not summarized), this value should be incremented
   * by 1.
   */
  static const int currentMinorVersion = 1;

  LinkedNodeBundleBuilder _bundle2;

  /**
   * Assemble a new [PackageBundleBuilder] using the gathered information.
   */
  PackageBundleBuilder assemble() {
    return new PackageBundleBuilder(
        majorVersion: currentMajorVersion,
        minorVersion: currentMinorVersion,
        bundle2: _bundle2);
  }

  void setBundle2(LinkedNodeBundleBuilder bundle2) {
    if (this._bundle2 != null) {
      throw StateError('Bundle2 may be set only once.');
    }
    _bundle2 = bundle2;
  }
}
