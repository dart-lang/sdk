// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.metadata_test;

import 'dart:mirrors';

const string = 'a metadata string';

const symbol = const Symbol('symbol');

const hest = 'hest';

@symbol
@string
class MyClass {
  @hest
  @hest
  @symbol
  var x;
  var y;

  @string
  @symbol
  @string
  myMethod() => 1;
  myOtherMethod() => 2;
}

checkMetadata(DeclarationMirror mirror, List expectedMetadata) {
  List metadata = mirror.metadata.map((m) => m.reflectee).toList();
  if (metadata == null) {
    throw 'Null metadata on $mirror';
  }
  int expectedLength = expectedMetadata.length;
  int actualLength = metadata.length;
  if (expectedLength != actualLength) {
    throw 'Expected length = $expectedLength, but got length = $actualLength.';
  }
  for (int i = 0; i < expectedLength; i++) {
    if (metadata[i] != expectedMetadata[i]) {
      throw '${metadata[i]} is not "${expectedMetadata[i]}"'
          ' in $mirror at index $i';
    }
  }
  print(metadata);
}

@symbol
@string
@symbol
main() {
  if (MirrorSystem.getName(symbol) != 'symbol') {
    // This happened in dart2js due to how early library metadata is
    // computed.
    throw 'Bad constant: $symbol';
  }

  MirrorSystem mirrors = currentMirrorSystem();
  ClassMirror myClassMirror = reflectClass(MyClass);
  checkMetadata(myClassMirror, [symbol, string]);
  LibraryMirror lib = mirrors.findLibrary(#test.metadata_test);
  MethodMirror function = lib.declarations[#main];
  checkMetadata(function, [symbol, string, symbol]);
  MethodMirror method = myClassMirror.declarations[#myMethod];
  checkMetadata(method, [string, symbol, string]);
  method = myClassMirror.declarations[#myOtherMethod];
  checkMetadata(method, []);

  VariableMirror xMirror = myClassMirror.declarations[#x];
  checkMetadata(xMirror, [hest, hest, symbol]);

  VariableMirror yMirror = myClassMirror.declarations[#y];
  checkMetadata(yMirror, []);

  // TODO(ahe): Test local functions.
}
