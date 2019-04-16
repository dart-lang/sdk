// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';

class CoreTypes {
  final LinkedElementFactory _elementFactory;

  LibraryElement _coreLibrary;
  ClassElement _objectClass;

  CoreTypes(this._elementFactory);

  LibraryElement get coreLibrary {
    return _coreLibrary ??= _elementFactory.libraryOfUri('dart:core');
  }

  ClassElement get objectClass {
    return _objectClass ??= _getCoreClass('Object');
  }

  ClassElement _getCoreClass(String name) {
    return coreLibrary.getType(name);
  }
}
