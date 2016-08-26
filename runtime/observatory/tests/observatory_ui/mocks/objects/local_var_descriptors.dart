// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class LocalVarDescriptorsRefMock implements M.LocalVarDescriptorsRef {
  final String id;
  final String name;
  const LocalVarDescriptorsRefMock({this.id: 'local-var-id',
                              this.name: 'local_var_name'});
}
