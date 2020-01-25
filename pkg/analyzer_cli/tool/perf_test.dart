// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The only purpose of this file is to enable analyzer tests on `perf.dart`,
/// the code here just has a dummy import to the rest of the code.
import 'perf.dart' as m;

void main() => print('done ${m.scanTotalChars}');
