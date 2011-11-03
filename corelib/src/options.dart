// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

/**
 * The Options object allows accessing the arguments which have been passed to
 * the current isolate.
 */
interface Options factory RuntimeOptions {
  /**
   * A newly constructed Options object contains the arguments exactly as they
   * have been passed to the isolate.
   */
  Options();

  /**
   * Returns a list of arguments that have been passed to this isolate. Any
   * modifications to the list will be contained to the options object owning
   * this list.
   */
  List<String> get arguments();
}
