# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file contains all sources for the Resources table.
{
  'sources': [
#  VM Service backend sources
    'vmservice/client.dart',
    'vmservice/constants.dart',
    'vmservice/resources.dart',
    'vmservice/running_isolate.dart',
    'vmservice/running_isolates.dart',
    'vmservice/server.dart',
    'vmservice/message.dart',
    'vmservice/message_router.dart',
    'vmservice/vmservice.dart',
    'vmservice/vmservice_io.dart',
# VM Service frontend sources
    'vmservice/client/deployed/web/index.html',
    'vmservice/client/deployed/web/favicon.ico',
    'vmservice/client/deployed/web/index.html_bootstrap.dart.js',
    'vmservice/client/deployed/web/img/isolate_icon.png',
    'vmservice/client/deployed/web/bootstrap_css/fonts/glyphicons-halflings-regular.ttf',
    'vmservice/client/deployed/web/bootstrap_css/fonts/glyphicons-halflings-regular.svg',
    'vmservice/client/deployed/web/bootstrap_css/fonts/glyphicons-halflings-regular.eot',
    'vmservice/client/deployed/web/bootstrap_css/fonts/glyphicons-halflings-regular.woff',
    'vmservice/client/deployed/web/bootstrap_css/css/bootstrap.min.css',
  ],
}

