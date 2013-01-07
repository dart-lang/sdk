// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that deprecated language features are diagnosed correctly.

import 'dart:async';
import 'dart:uri';

import '../../../sdk/lib/_internal/compiler/compiler.dart';
import '../../utils/dummy_compiler_test.dart' as dummy;

main() {
  StringBuffer messages = new StringBuffer();
  void handler(Uri uri, int begin, int end, String message, Diagnostic kind) {
    if (kind == Diagnostic.VERBOSE_INFO) return;
    if (identical(kind.name, 'source map')) return;
    if (uri == null) {
      messages.add('$kind: $message\n');
    } else {
      Expect.equals('main:${uri.path}', '$uri');
      String source = TEST_SOURCE[uri.path];
      Expect.isNotNull(source);
      messages.add('$begin<${source.substring(begin, end)}>:${uri.path}:'
                   '$kind: $message\n');
    }
  }

  Future<String> provider(Uri uri) {
    if (uri.scheme != "main") return dummy.provider(uri);
    String source = TEST_SOURCE[uri.path];
    Expect.isNotNull(source);
    return (new Completer<String>()..complete(source)).future;
  }

  String code = deprecatedFutureValue(
      compile(new Uri.fromComponents(scheme: 'main'),
              new Uri.fromComponents(scheme: 'lib', path: '/'),
              new Uri.fromComponents(scheme: 'package', path: '/'),
              provider, handler));
  if (code == null) {
    throw 'Compilation failed: ${messages}';
  }
  Expect.stringEquals(
      // This string is comprised of lines of the following format:
      //
      // offset<source>:path:kind: message
      //
      // "offset" is the character offset from the beginning of TEST_SOURCE.
      // "source" is the substring of TEST_SOURCE that the compiler is
      // indicating as erroneous.
      // "path" is the URI path.
      // "kind" is the result of calling toString on a [Diagnostic] object.
      // "message" is the expected message as a [String].  This is a
      // short-term solution and should eventually changed to include
      // a symbolic reference to a MessageKind.
      "0<#library('test');>::${deprecatedMessage('# tags')}\n"
      "38<interface>::${deprecatedMessage('interface declarations')}\n"
      "19<part 'part.dart';>::${deprecatedMessage('missing part-of tag')}\n"
      "0<>:/part.dart:info: Note: This file has no part-of tag, but it is being"
      " used as a part.\n"
      "163<Fisk>::${deprecatedMessage('interface factories')}\n"

      // TODO(ahe): Should be <Fisk.hest>.
      "183<Fisk>::${deprecatedMessage('interface factories')}\n"

      // TODO(ahe): Should be <bar>.
      "109<Foo>::${deprecatedMessage('conflicting constructor')}\n"

      "129<bar>::info: This member conflicts with a constructor.\n"
      "200<Dynamic>::${deprecatedMessage('Dynamic')}\n"
      "221<()>::${deprecatedMessage('getter parameters')}\n",
      messages.toString());
}

deprecatedMessage(feature) {
  return
    "warning: Warning: deprecated language feature, $feature"
    ", will be removed in a future Dart milestone.";
}

const Map<String, String> TEST_SOURCE =
  const <String, String>{ '': """
#library('test');

part 'part.dart';

interface Fisk default Foo {
  Fisk();
  Fisk.hest();
}

class Foo {
  Foo.bar();
  static bar() => new Foo.bar();
  factory Fisk() {}
  factory Fisk.hest() {}
  Dynamic fisk;
  get x() => null;
}

main() {
  var a = Foo.bar();
  var b = new Foo.bar();
  new Fisk();
  new Fisk.hest();
}
""",
    // TODO(ahe): Why isn't this 'part.dart'? Why the leading slash?
    '/part.dart': '',
  };
