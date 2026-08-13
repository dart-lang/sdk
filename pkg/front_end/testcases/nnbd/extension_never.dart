// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension Extension on Never {
  extensionMethod() {}
}

implicitAccess(Never never) {
  never.extensionMethod();
  never.missingMethod();
}

explicitAccess(Never never) {
  Extension(never).extensionMethod();
}

main() {}
