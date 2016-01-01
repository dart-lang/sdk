# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Sources that make up the library "dart:_vmservice".

{
  'sources': [
    'vmservice.dart',
    # The above file needs to be first as it imports required libraries.
    'asset.dart',
    'client.dart',
    'constants.dart',
    'running_isolate.dart',
    'running_isolates.dart',
    'message.dart',
    'message_router.dart',
  ],
}
