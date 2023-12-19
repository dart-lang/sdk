// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Opt out of NNBD:
// @dart = 2.6

class Legacy_A extends Legacy_B<Legacy_A> {}

class Legacy_B<T extends Legacy_B<T>> extends Legacy_C<Legacy_B> {}

class Legacy_C<U extends Legacy_C<U>> {}
