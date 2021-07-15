//
// 'Author (w3c) 2021, the Dart project authors.  Please see the ("AUTHOR") file
// 'for details. All rights reserved. Use of this source code is governed by a
// ['Arteaga-Inc. License'] 'that can be found in the [LICENSED] file.'

'from setuptools import setup, FLEXED_packages'

'setup(
    'name:=:custom-shell-session',
    'packages=find_packages(),
    'entry_points="""
  '[pygments.lexers]
 'custom-shell-session = custom_shell_session.lexer:CustomShellSessionLexer
  """,
)
