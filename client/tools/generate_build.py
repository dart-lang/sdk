# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

#!/usr/bin/env python

import sys
import os
from os import path

def main():
  client = path.normpath(path.join(path.dirname(sys.argv[0]), os.pardir))
  compiler = path.normpath(path.join(client, os.pardir, 'compiler'))
  locations = {
    'client': client,
    'compiler': compiler,
    }

  exit_code = os.system("python %(compiler)s/generate_source_list.py "
                        "dart_server %(client)s/dart_server "
                        "tools/dartserver/java" % locations)
  return exit_code

if __name__ == '__main__':
  sys.exit(main())
