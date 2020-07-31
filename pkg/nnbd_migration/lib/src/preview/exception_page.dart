// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:nnbd_migration/src/preview/preview_page.dart';
import 'package:nnbd_migration/src/preview/preview_site.dart';

/// The page that is displayed when an exception is encountered in the process
/// of composing the content of a different page.
class ExceptionPage extends PreviewPage {
  /// The message from the exception that caused this page to be displayed.
  final String message;

  /// The stack trace of the exception that caused this page to be displayed.
  final StackTrace stackTrace;

  /// Initialize a newly created exception page within the given [site]. The
  /// [message] and [stackTrace] are used to describe the exception to the user.
  ExceptionPage(PreviewSite site, String path, this.message, this.stackTrace)
      : super(site, path.substring(1));

  @override
  bool get requiresAuth => false;

  @override
  void generateBody(Map<String, String> params) {
    buf.write('''
<h1>500 Exception in preview</h1>
<p>
We're sorry, but you've encountered a bug in the preview tool. Please visit
<a href='https://github.com/dart-lang/sdk/issues/new'>
github.com/dart-lang/sdk/issues/new</a> to report the issue and include the
stack trace below.
</p>
<h2>$message</h2>
<p style="white-space: pre">
${htmlEscape.convert(stackTrace.toString())}
</p>
''');
  }
}
