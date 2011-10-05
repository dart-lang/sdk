# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import testing

def GetConfiguration(context, root):
  return ClientCompilationTestConfiguration(context, root)


class  ClientCompilationTestConfiguration(
    testing.CompilationTestConfiguration):
 def __init__(self, context, root):
    super(ClientCompilationTestConfiguration, self).__init__(context, root)

 def SourceDirs(self):
   return [
      'async',
      'base',
      'box2d',
      'dom',
      'json',
      'observable',
      'samples',
      'streams',
      'testing',
      'tests',
      'touch',
      'util',
      'view',
      'weld']
