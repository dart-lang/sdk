// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface XPathEvaluator {

  XPathExpression createExpression(String expression = null, XPathNSResolver resolver = null);

  XPathNSResolver createNSResolver(Node nodeResolver = null);

  XPathResult evaluate(String expression = null, Node contextNode = null, XPathNSResolver resolver = null, int type = null, XPathResult inResult = null);
}
