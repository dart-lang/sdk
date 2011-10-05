// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface InjectedScriptHost {

  void clearConsoleMessages();

  void copyText(String text);

  int databaseId(Object database);

  Object evaluate(String text);

  void inspect(Object objectId, Object hints);

  Object inspectedNode(int num);

  Object internalConstructorName(Object object);

  bool isHTMLAllCollection(Object object);

  int storageId(Object storage);

  String type(Object object);
}
