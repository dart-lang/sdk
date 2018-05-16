// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

/// Returns a [Component] object containing empty definitions of core SDK classes.
Component createMockSdkComponent() {
  var coreLib = new Library(Uri.parse('dart:core'), name: 'dart.core');
  var asyncLib = new Library(Uri.parse('dart:async'), name: 'dart.async');
  var internalLib =
      new Library(Uri.parse('dart:_internal'), name: 'dart._internal');

  Class addClass(Library lib, Class c) {
    lib.addClass(c);
    return c;
  }

  var objectClass = addClass(coreLib, new Class(name: 'Object'));
  var objectType = objectClass.rawType;

  TypeParameter typeParam(String name, [DartType bound]) {
    return new TypeParameter(name, bound ?? objectType);
  }

  Class class_(String name,
      {Supertype supertype,
      List<TypeParameter> typeParameters,
      List<Supertype> implementedTypes}) {
    return new Class(
        name: name,
        supertype: supertype ?? objectClass.asThisSupertype,
        typeParameters: typeParameters,
        implementedTypes: implementedTypes);
  }

  addClass(coreLib, class_('Null'));
  addClass(coreLib, class_('bool'));
  var num = addClass(coreLib, class_('num'));
  addClass(coreLib, class_('String'));
  var iterable =
      addClass(coreLib, class_('Iterable', typeParameters: [typeParam('T')]));
  {
    var T = typeParam('T');
    addClass(
        coreLib,
        class_('List', typeParameters: [
          T
        ], implementedTypes: [
          new Supertype(iterable, [new TypeParameterType(T)])
        ]));
  }
  addClass(
      coreLib, class_('Map', typeParameters: [typeParam('K'), typeParam('V')]));
  addClass(coreLib, class_('int', supertype: num.asThisSupertype));
  addClass(coreLib, class_('double', supertype: num.asThisSupertype));
  addClass(coreLib, class_('Iterator', typeParameters: [typeParam('T')]));
  addClass(coreLib, class_('Symbol'));
  addClass(coreLib, class_('Type'));
  addClass(coreLib, class_('Function'));
  addClass(coreLib, class_('Invocation'));
  addClass(asyncLib, class_('Future', typeParameters: [typeParam('T')]));
  addClass(asyncLib, class_('FutureOr', typeParameters: [typeParam('T')]));
  addClass(asyncLib, class_('Stream', typeParameters: [typeParam('T')]));
  addClass(internalLib, class_('Symbol'));

  return new Component(libraries: [coreLib, asyncLib, internalLib]);
}
