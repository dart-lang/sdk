// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Packages=.packages

// We expect this to not cause any errors. An empty packages file is valid,
// you should only run into problems if you try to resolve a package import.
library empty_packages_file_noimports_test;

main() {}
