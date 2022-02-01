// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.15

/// Marks its argument as live and prevents tree-shaking.
///
/// This is more hermetic than using `package:expect` or `print`. This function
/// may need to be updated as optimizations improve.
@pragma('dart2js:noInline')
void makeLive(dynamic x) => x;

@pragma('dart2js:noInline')
void _subtypeAtRuntime<Sub, Super>() => makeLive(<Sub>[] is List<Super>);

void subtype<Sub extends Super, Super>() => _subtypeAtRuntime<Sub, Super>();
void notSubtype<Sub, Super>() => _subtypeAtRuntime<Sub, Super>();
