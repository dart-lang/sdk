# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import test

from os.path import join, exists

import testing

def GetConfiguration(context, root):
  return testing.BrowserTestConfiguration(
      context, root, fatal_static_type_errors=True)
