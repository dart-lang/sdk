# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

{
  'sources': [
    # TODO(ager): remove byte_arrays.dart and inline the code in
    # scalarlist.dart. The reason for not doing that at this point is
    # that the VM does not allow normal library structure for builtin
    # libraries.
    'byte_arrays.dart',
  ],
}
