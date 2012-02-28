// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface XMLDocument extends Document, XMLElement
    default XMLDocumentWrappingImplementation {

  /** WARNING: Currently this doesn't work on Dartium (issue 649). */
  XMLDocument.xml(String xml);

  XMLDocument clone(bool deep);
}
