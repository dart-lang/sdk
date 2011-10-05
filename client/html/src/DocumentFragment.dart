// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface DocumentFragment extends Node factory DocumentFragmentWrappingImplementation {
 
  DocumentFragment();

  Element queryOne(String selectors);

  ElementList query(String selectors);
}
