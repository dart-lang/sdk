// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface DocumentFragment extends Element default DocumentFragmentWrappingImplementation {
 
  DocumentFragment();

  DocumentFragment.html(String html);

  /** WARNING: Currently this doesn't work on Dartium (issue 649). */
  DocumentFragment.xml(String xml);

  DocumentFragment.svg(String svg);

  DocumentFragment clone(bool deep);
}
