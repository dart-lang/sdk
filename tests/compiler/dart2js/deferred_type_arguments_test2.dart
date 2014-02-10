// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the additional runtime type support is output to the right
// Files when using deferred loading.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_source_file_helper.dart';
import "dart:async";

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
       as dart2js;

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

  Map<String, MemoryOutputSink> outputs = new Map<String, MemoryOutputSink>();

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
    var lib = compiler.libraries["dart:html"];
    var entry = lib.find("Entry");
    Expect.equals(mainOutputUnit, outputUnitForElement(entry));
  }));
}

// If the following all occurs:
// - Importing dart:html
// - running Zone.current.createTimer
// - calling new ByteData
// - having classes with fields named offset and entries

// The native class _EntryArray<Entry> to will be emitted - and that triggers
// the class Entry to be emitted.
//
// We need to make sure that deferred loading finds the Entry class.
const Map MEMORY_SOURCE_FILES = const {"main.dart": """
import 'dart:async';
import 'dart:html';
@a import 'dart:typed_data';

const a = const DeferredLibrary("a");
class B {
  var offset;

  B() {
    offset++;
  }
}

class C {
  var entries;

  C() {
    entries++;
  }
}

main() {
  new C();
  new B();
  new ByteData(0);
  Zone.current.createTimer(null, null);
}
""",};
