// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/vm/reload.dart';

/// Connects to an existing VM's service protocol and issues a hot-reload
/// request. The VM must have been launched with `--observe` to enable the
/// service protocol.
///
// TODO(sigmund): provide flags to configure the vm-service port.
main(List<String> args) async {
  if (args.length == 0) {
    print('usage: reload <entry-uri>');
    return;
  }

  var reloader = new VmReloader();
  await reloader.reload(Uri.base.resolve(args.first));
  await reloader.disconnect();
}
