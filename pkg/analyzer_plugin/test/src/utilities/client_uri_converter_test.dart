// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/src/utilities/client_uri_converter.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClientUriConverterTest);
  });
}

@reflectiveTest
class ClientUriConverterTest with ResourceProviderMixin {
  Future<void> test_noop_fromUri() async {
    var converter = ClientUriConverter.noop(pathContext);

    for (var fileUri in [
      Uri.file(convertPath('/a/b.dart')),
      Uri.file(convertPath('/a/b.txt')),
      Uri.file(convertPath('/a/b')),
      Uri.file(convertPath('/')),
    ]) {
      // For no-op, should be the same as simple fromUri on pathContext.
      expect(converter.fromClientUri(fileUri), pathContext.fromUri(fileUri));
    }
  }

  Future<void> test_noop_toUri() async {
    var converter = ClientUriConverter.noop(pathContext);

    for (var filePath in [
      convertPath('/a/b.dart'),
      convertPath('/a/b.txt'),
      convertPath('/a/b'),
      convertPath('/'),
    ]) {
      // For no-op, should be the same as simple toUri on pathContext.
      expect(converter.toClientUri(filePath), pathContext.toUri(filePath));
    }
  }

  void test_withVirtualFileSupport_toClientFilePath_macro() {
    var converter = ClientUriConverter.withVirtualFileSupport(path.posix);
    expect(
      converter.toClientFilePath('/a/my b.macro.dart'),
      'dart-macro+file:///a/my%20b.dart',
    );
  }

  void test_withVirtualFileSupport_toClientFilePath_posix() {
    var context = path.posix;
    _assertToClientFilePath(context, [
      '/',
      '/a/b.dart',
      '/home/user/my project/lib/a.dart',
      '/a/x%20y.dart',
      '/a/\u00fc\u00e9/\u4e2d.dart',
      '/a/\u{1F600}.dart',
      '/a/\uD800x\uDC00.dart',
      '/a/ #?%/b c',
      for (var c = 0; c < 0x80; c++)
        if (c != 0x2F) '/a/x${String.fromCharCode(c)}y.dart',
      for (var c = 0; c < 0x80; c++)
        if (c != 0x2E && c != 0x2F) '/a/${String.fromCharCode(c)}',
    ]);
  }

  void test_withVirtualFileSupport_toClientFilePath_windows() {
    var context = path.windows;
    _assertToClientFilePath(context, [
      r'C:\',
      r'C:\a\b.dart',
      r'c:\a\b.dart',
      r'Z:\Users\John Smith\my project\lib\a.dart',
      'C:\\a\\\u00fc\\\u{1F600}.dart',
      r'C:\a\ #%\b c',
      r'\\Server\Share\a b.dart',
      r'\\wsl.localhost\Ubuntu\home\a.dart',
      for (var c = 0; c < 0x80; c++)
        if (c != 0x2F && c != 0x5C) 'C:\\a\\x${String.fromCharCode(c)}y.dart',
    ]);
  }

  void _assertToClientFilePath(path.Context context, List<String> filePaths) {
    var converter = ClientUriConverter.withVirtualFileSupport(context);
    for (var filePath in filePaths) {
      expect(
        converter.toClientFilePath(filePath),
        context.toUri(filePath).toString(),
        reason: filePath,
      );
    }
  }
}
