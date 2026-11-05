// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

/// Returns a [Component] object containing empty definitions of core SDK
/// classes.
Component createMockSdkComponent() {
  Library coreLib = new Library(
    Uri.parse('dart:core'),
    name: 'dart.core',
    fileUri: Uri.parse('dart:core'),
  );
  Library asyncLib = new Library(
    Uri.parse('dart:async'),
    name: 'dart.async',
    fileUri: Uri.parse('dart:async'),
  );
  Library internalLib = new Library(
    Uri.parse('dart:_internal'),
    name: 'dart._internal',
    fileUri: Uri.parse('dart:_internal'),
  );

  Class objectClass = new Class(name: 'Object', fileUri: coreLib.fileUri);
  coreLib.addClass(objectClass);

  Class addClass(
    Library lib,
    String name, {
    Supertype? supertype,
    TypeParameterList? typeParameters,
    List<Supertype>? implementedTypes,
  }) {
    Class c = new Class(
      name: name,
      supertype: supertype ?? objectClass.asThisSupertype,
      typeParameters: typeParameters,
      implementedTypes: implementedTypes,
      fileUri: lib.fileUri,
    );
    lib.addClass(c);
    return c;
  }

  InterfaceType objectType = new InterfaceType(
    objectClass,
    coreLib.nonNullable,
  );

  TypeParameter typeParam(String name, [DartType? bound]) {
    return new TypeParameter(name, bound ?? objectType);
  }

  addClass(coreLib, 'Null');
  addClass(coreLib, 'bool');
  Class num = addClass(coreLib, 'num');
  addClass(coreLib, 'String');
  Class iterable = addClass(
    coreLib,
    'Iterable',
    typeParameters: new TypeParameterList(typeParam('T')),
  );
  {
    TypeParameter T = typeParam('T');
    addClass(
      coreLib,
      'List',
      typeParameters: new TypeParameterList(T),
      implementedTypes: [
        new Supertype(
          iterable,
          new DartTypeList(new TypeParameterType.withDefaultNullability(T)),
        ),
      ],
    );
  }
  addClass(
    coreLib,
    'Map',
    typeParameters: new TypeParameterList(typeParam('K'), typeParam('V')),
  );
  addClass(coreLib, 'int', supertype: num.asThisSupertype);
  addClass(coreLib, 'double', supertype: num.asThisSupertype);
  addClass(
    coreLib,
    'Iterator',
    typeParameters: new TypeParameterList(typeParam('T')),
  );
  addClass(coreLib, 'Symbol');
  addClass(coreLib, 'Type');
  addClass(coreLib, 'Function');
  addClass(coreLib, 'Invocation');
  addClass(
    coreLib,
    'Future',
    typeParameters: new TypeParameterList(typeParam('T')),
  );
  addClass(
    asyncLib,
    'FutureOr',
    typeParameters: new TypeParameterList(typeParam('T')),
  );
  addClass(
    asyncLib,
    'Stream',
    typeParameters: new TypeParameterList(typeParam('T')),
  );
  addClass(internalLib, 'Symbol');

  return new Component(libraries: [coreLib, asyncLib, internalLib]);
}
