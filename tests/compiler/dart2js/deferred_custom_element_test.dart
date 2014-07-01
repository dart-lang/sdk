// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of the graph segmentation algorithm used by deferred loading
// to determine which elements can be deferred and which libraries
// much be included in the initial download (loaded eagerly).

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_source_file_helper.dart';
import "dart:async";

class FakeOutputStream<T> extends EventSink<T> {
  void add(T event) {}
  void addError(T event, [StackTrace stackTrace]) {}
  void close() {}
}

void main() {
  Uri script = currentDirectory.resolveUri(Platform.script);
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  var provider = new MemorySourceFileProvider(MEMORY_SOURCE_FILES);
  var handler = new FormattingDiagnosticHandler(provider);

  Compiler compiler = new Compiler(provider.readStringFromUri,
                                   (name, extension) => new FakeOutputStream(),
                                   handler.diagnosticHandler,
                                   libraryRoot,
                                   packageRoot,
                                   [],
                                   {});
  asyncTest(() => compiler.run(Uri.parse('memory:main.dart')).then((_) {
    var outputUnitForElement = compiler.deferredLoadTask.outputUnitForElement;
    var mainOutputUnit = compiler.deferredLoadTask.mainOutputUnit;
    var lib =
        compiler.libraryLoader.lookupLibrary(Uri.parse("memory:lib.dart"));
    var customType = lib.find("CustomType");
    var foo = lib.find("foo");
    Expect.notEquals(mainOutputUnit, outputUnitForElement(foo));
    // Native elements are not deferred
    Expect.equals(mainOutputUnit, outputUnitForElement(customType));
  }));
}

// The main library imports a file defining a custom element.
// Registering this class implicitly causes the constructors to be
// live. Check that this is handled.
const Map MEMORY_SOURCE_FILES = const {"main.dart": """
import "lib.dart" deferred as a;
import 'dart:html';

main() {
  document.registerElement("foo-tag", a.a);
  a.foo();
}
""", "lib.dart": """
import 'dart:html';
var a = CustomType;

class CustomType extends HtmlElement {
  factory CustomType() => null;
  CustomType.created() : super.created() ;
}

foo() {}
""",};
