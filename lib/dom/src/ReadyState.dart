// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Contains the set of standard values returned by HTMLDocument.getReadyState.
 */
interface ReadyState {
  /**
   * Indicates the document is still loading and parsing.
   */
  static final String LOADING = "loading";

  /**
   * Indicates the document is finished parsing but is still loading
   * subresources.
   */
  static final String INTERACTIVE = "interactive";

  /**
   * Indicates the document and all subresources have been loaded.
   */
  static final String COMPLETE = "complete";
}
