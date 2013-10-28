// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch int get numberOfProcessors => null;

patch String get pathSeparator => '/';

patch String get operatingSystem => null;

patch String get localHostname => null;

patch String get version => null;

patch Map<String, String> get environment => null;

patch String get executable => null;

patch Uri get script => null;

// An unmodifiable list.
patch List<String> get executableArguments => new List<String>(0);

patch String get packageRoot => null;
