#
# Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
from setuptools import setup, find_packages

setup(
    name='custom-shell-session',
    packages=find_packages(),
    entry_points="""
  [pygments.lexers]
  custom-shell-session = custom_shell_session.lexer:CustomShellSessionLexer
  """,
)
