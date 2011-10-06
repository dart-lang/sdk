// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _XPathNSResolverWrappingImplementation extends DOMWrapperBase implements XPathNSResolver {
  _XPathNSResolverWrappingImplementation() : super() {}

  static create__XPathNSResolverWrappingImplementation() native {
    return new _XPathNSResolverWrappingImplementation();
  }

  String lookupNamespaceURI(String prefix) {
    return _lookupNamespaceURI(this, prefix);
  }
  static String _lookupNamespaceURI(receiver, prefix) native;

  String get typeName() { return "XPathNSResolver"; }
}
