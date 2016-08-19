// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library main;

//@MirrorsUsed(targets: const ['C1', 'C2', '_privateGlobalField', '_privateGlobalMethod'])
import 'dart:mirrors';
import 'package:expect/expect.dart';
import 'private_symbol_mangling_lib.dart';

var _privateGlobalField = 1;

_privateGlobalMethod() => 9;

class C1 {
  var _privateField = 0;
  _privateMethod() => 2;
}

getPrivateGlobalFieldValue(LibraryMirror lib) {
  for (Symbol symbol in lib.declarations.keys) {
    DeclarationMirror decl = lib.declarations[symbol];
    if (decl is VariableMirror && decl.isPrivate) {
      return lib.getField(symbol).reflectee;
    }
  }
}

getPrivateFieldValue(InstanceMirror cls) {
  for (Symbol symbol in cls.type.declarations.keys) {
    DeclarationMirror decl = cls.type.declarations[symbol];
    if (decl is VariableMirror && decl.isPrivate) {
      return cls.getField(symbol).reflectee;
    }
  }
}

getPrivateGlobalMethodValue(LibraryMirror lib) {
  for (Symbol symbol in lib.declarations.keys) {
    DeclarationMirror decl = lib.declarations[symbol];
    if (decl is MethodMirror && decl.isRegularMethod && decl.isPrivate) {
      return lib.invoke(symbol, []).reflectee;
    }
  }
}

getPrivateMethodValue(InstanceMirror cls) {
  for (Symbol symbol in cls.type.declarations.keys) {
    DeclarationMirror decl = cls.type.declarations[symbol];
    if (decl is MethodMirror && decl.isRegularMethod && decl.isPrivate) {
      return cls.invoke(symbol, []).reflectee;
    }
  }
}

main() {
  LibraryMirror libmain = currentMirrorSystem().findLibrary(#main);
  LibraryMirror libother = currentMirrorSystem().findLibrary(#other);
  Expect.equals(1, getPrivateGlobalFieldValue(libmain));
  Expect.equals(3, getPrivateGlobalFieldValue(libother));
  Expect.equals(9, getPrivateGlobalMethodValue(libmain));
  Expect.equals(11, getPrivateGlobalMethodValue(libother));

  var c1 = reflect(new C1());
  var c2 = reflect(new C2());
  Expect.equals(0, getPrivateFieldValue(c1));
  Expect.equals(1, getPrivateFieldValue(c2));
  Expect.equals(2, getPrivateMethodValue(c1));
  Expect.equals(3, getPrivateMethodValue(c2));
}
