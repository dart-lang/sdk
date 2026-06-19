import 'dart:developer';

import 'package:kernel/ast.dart';

void main() {
  Foo foo = new Foo();
  foo.foo();
}

class Foo {
  Library? leakViaField;
  Library? currentLibrary;

  Library createCurrentLibrary(Uri uri) {
    return currentLibrary = new Library(uri, fileUri: uri);
  }

  void foo() {
    Uri uri = Uri.parse("foo:bar/baz.dart");
    Library? firstLibrary = createCurrentLibrary(uri);
    leakViaField = firstLibrary;
    firstLibrary = null;
    createCurrentLibrary(uri);
    debugger();
  }
}
