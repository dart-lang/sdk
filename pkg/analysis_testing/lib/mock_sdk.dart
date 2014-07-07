// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library testing.mock_sdk;

import 'package:analyzer/file_system/file_system.dart' as resource;
import 'package:analyzer/file_system/memory_file_system.dart' as resource;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';


class MockSdk implements DartSdk {
  final resource.MemoryResourceProvider provider =
      new resource.MemoryResourceProvider();

  MockSdk() {
    // TODO(paulberry): Add to this as needed.
    const Map<String, String> pathToContent = const {
      "/lib/core/core.dart": '''
          library dart.core;
          class Object {}
          class Function {}
          class StackTrace {}
          class Symbol {}
          class Type {}

          class String extends Object {}
          class bool extends Object {}
          abstract class num extends Object {
            num operator +(num other);
            num operator -(num other);
            num operator *(num other);
            num operator /(num other);
          }
          abstract class int extends num {
            int operator -();
          }
          class double extends num {}
          class DateTime extends Object {}
          class Null extends Object {}

          class Deprecated extends Object {
            final String expires;
            const Deprecated(this.expires);
          }
          const Object deprecated = const Deprecated("next release");

          abstract class List<E> extends Object {
            void add(E value);
            E operator [](int index);
            void operator []=(int index, E value);
          }
          class Map<K, V> extends Object {}

          void print(Object object) {}
          ''',

      "/lib/html/dartium/html_dartium.dart": '''
          library dart.html;
          class HtmlElement {}
          ''',

      "/lib/math/math.dart": '''
          library dart.math;
          '''
    };

    pathToContent.forEach((String path, String content) {
      provider.newFile(path, content);
    });
  }

  // Not used
  @override
  AnalysisContext get context => throw unimplemented;

  @override
  List<SdkLibrary> get sdkLibraries => throw unimplemented;

  @override
  String get sdkVersion => throw unimplemented;

  UnimplementedError get unimplemented => new UnimplementedError();

  @override
  List<String> get uris => throw unimplemented;

  // Not used.
  @override
  Source fromEncoding(UriKind kind, Uri uri) {
    resource.Resource file = provider.getResource(uri.path);
    if (file is resource.File) {
      return file.createSource(kind);
    }
    return null;
  }

  // Not used.
  @override
  SdkLibrary getSdkLibrary(String dartUri) {
    // getSdkLibrary() is only used to determine whether a library is internal
    // to the SDK.  The mock SDK doesn't have any internals, so it's safe to
    // return null.
    return null;
  }

  // Not used.
  @override
  Source mapDartUri(String dartUri) {
    const Map<String, String> uriToPath = const {
      "dart:core": "/lib/core/core.dart",
      "dart:html": "/lib/html/dartium/html_dartium.dart",
      "dart:math": "/lib/math/math.dart"
    };

    String path = uriToPath[dartUri];
    if (path != null) {
      resource.File file = provider.getResource(path);
      return file.createSource(UriKind.DART_URI);
    }

    // If we reach here then we tried to use a dartUri that's not in the
    // table above.
    throw unimplemented;
  }
}
