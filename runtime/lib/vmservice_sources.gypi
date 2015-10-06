# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Sources that make up the library "dart:_vmservice".

{
  'sources': [
    'vmservice/vmservice.dart',
    # The above file needs to be first as it imports required libraries.
    'vmservice/client.dart',
    'vmservice/constants.dart',
    'vmservice/running_isolate.dart',
    'vmservice/running_isolates.dart',
    'vmservice/message.dart',
    'vmservice/message_router.dart',
  ],
}
