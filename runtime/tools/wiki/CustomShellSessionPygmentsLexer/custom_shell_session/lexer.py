#
# Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
"""Simple lexer for shell sessions.

Highlights command lines (lines starting with $ prompt) and comments starting
with #. For example:

    # This is a comment
    $ this-is-a-command
    This is output of the command

    $ this-is-a-multiline-command with-some-arguments \
      and more arguments \
      and more arguments
    And some output.

"""

from pygments.lexer import RegexLexer, words
from pygments.token import Comment, Generic, Keyword

_comment_style = Comment
# Note: there is a slight inversion of styles to make it easier to read.
# We highlight output with Prompt style and command as a normal text.
_output_style = Generic.Prompt
_command_style = Generic.Text
_prompt_style = Keyword


class CustomShellSessionLexer(RegexLexer):
    name = 'CustomShellSession'
    aliases = ['custom-shell-session']
    filenames = ['*.log']
    tokens = {
        'root': [
            (r'#.*\n', _comment_style),
            (r'^\$', _prompt_style, 'command'),
            (r'.', _output_style),
        ],
        'command': [
            (r'\\\n', _command_style),  # Continue in 'command' state.
            (r'$', _command_style, '#pop'),  # End of line without escape.
            (r'.',
             _command_style),  # Anything else continue in 'command' state.
        ]
    }
