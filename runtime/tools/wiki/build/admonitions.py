# Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
"""Preprocesses Markdown source and converts admonitions written in blockquotes.

Usage: convert_admonitions(str)
"""

import re

_RECOGNIZED_ADMONITIONS = {
    "Source to read": "sourcecode",
    "Trying it": "tryit",
    "Warning": "warning"
}


def convert_admonitions(content: str) -> str:
    """Convert blockquotes into admonitions if they start with a marker.

       Blockquotes starting with  `> **marker**` are converted either into
       sidenotes (`<span class="aside"/>`) or into admonitions to be
       processed by an admonition extension later.
    """
    processed = []
    current_admonition = None
    indent = ''
    for line in content.split('\n'):
        if current_admonition is not None:
            if line.startswith('>'):
                processed.append(indent + line[1:])
                continue
            if current_admonition == 'Note':
                note = processed.pop()
                processed.pop()
                processed[-1] = processed[
                    -1] + f' <span class="aside" markdown=1>{note}</span>'
            current_admonition = None
        elif line.startswith('> **') and line.endswith('**'):
            current_admonition = re.match(r'^> \*\*(.*)\*\*$', line)[1]
            if current_admonition == 'Note':
                indent = ''

                # Drop all empy lines preceeding the side note.
                while processed[-1] == '':
                    processed.pop()

                # Do not try to attach sidenote to the section title.
                if processed[-1].startswith('#'):
                    processed.append('')
            else:
                # Start an admonition using Python markdown syntax.
                processed.append(
                    f'!!! {_RECOGNIZED_ADMONITIONS[current_admonition]} "{current_admonition}"'
                )
                current_admonition = True
                indent = '    '
            continue
        processed.append(line)
    return "\n".join(processed)
