// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These imports must not cause an error when this library is not selected by a
// conditional import, even if deprecated JS interop is disabled.
// ignore_for_file: deprecated_member_use, unused_import
import 'dart:html';
import 'dart:html_common';
import 'dart:indexed_db';
import 'dart:js';
import 'dart:js_util';
import 'dart:svg';
import 'dart:web_audio';
import 'dart:web_gl';

/// Selected when a `dart.library.*` condition for a deprecated JS interop
/// library is `true`.
const selectedLibrary = 'deprecated';
