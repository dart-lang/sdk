# Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
"""Support for @{ref|text} reference links in Markdown.

This Markdown extension converts @{ref|text} into a link with the given
[text] pointing to a particular source code location. [ref] can be one of
the following:

   * package:-scheme URI - it will be resolved using .packages file in the
     root directory
   * file path
   * C++ symbol - will be resolved through xref.json file (see README.md)

Usage: markdown.markdown(extensions=[XrefExtension()])
"""

import json
import logging
import os
import subprocess

from markdown.extensions import Extension
from markdown.inlinepatterns import InlineProcessor
from markdown.util import etree
from typing import Optional
from urllib.parse import urlparse

_current_commit_hash = subprocess.run(['git', 'rev-parse', 'HEAD'],
                                      capture_output=True,
                                      encoding='utf8').stdout

# Load .packages file into a dictionary.
with open('.packages') as packages_file:
    _packages = dict([
        package_mapping.split(':', 1)
        for package_mapping in packages_file
        if not package_mapping.startswith('#')
    ])

# Load xref.json and verify that it was generated for the current commit to
# avoid discrepancies in the generated links.
with open('xref.json') as json_file:
    _xrefs = json.load(json_file)

if _current_commit_hash != _xrefs['commit']:
    logging.error(
        'xref.json is generated for commit %s while current commit is %s',
        _xrefs['commit'], _current_commit_hash)


def _make_github_uri(file: str, lineno: str = None) -> str:
    """Generates source link pointing to GitHub"""
    fragment = '#L%s' % (lineno) if lineno is not None else ''
    return 'https://github.com/dart-lang/sdk/blob/%s/%s%s' % (
        _current_commit_hash, file, fragment)


def _file_ref_to_github_uri(file_ref: str) -> str:
    """Generates source link pointing to GitHub from an xref.json reference."""
    (file_idx, line_idx) = file_ref.split(':', 1)
    return _make_github_uri(_xrefs['files'][int(file_idx)], line_idx)


def _resolve_ref_via_xref(ref: str) -> Optional[str]:
    """Resolve the target of the given reference via xref.json"""
    if ref in _xrefs['functions']:
        return _xrefs['functions'][ref]
    if ref in _xrefs['classes']:
        return _xrefs['classes'][ref][0]
    if '::' in ref:
        (class_name, function_name) = ref.rsplit('::', 1)
        if class_name in _xrefs['classes'] and len(
                _xrefs['classes'][class_name]) == 2:
            return _xrefs['classes'][class_name][1][function_name]
    logging.error('Failed to resolve xref %s' % ref)
    return None


def _resolve_ref(ref: str) -> Optional[str]:
    if ref.startswith('package:'):
        # Resolve as package uri via .packages.
        uri = urlparse(ref)
        (package_name, *path_to_file) = uri.path.split('/', 1)
        package_path = _packages[package_name]
        if len(path_to_file) == 0:
            return _make_github_uri(package_path)
        else:
            return _make_github_uri(os.path.join(package_path, path_to_file[0]))
    elif os.path.exists(ref):
        # Resolve as a file link.
        return _make_github_uri(_current_commit_hash, ref)
    else:
        # Resolve as a C++ symbol via xref.json
        file_ref = _resolve_ref_via_xref(ref)
        if file_ref is not None:
            return _file_ref_to_github_uri(file_ref)


class _XrefPattern(InlineProcessor):
    """InlineProcessor responsible for handling @{ref|text} syntax."""

    def handleMatch(self, m, data):
        ref = m.group(1)
        text = m.group(2)
        uri = _resolve_ref(ref)
        el = etree.Element('a')
        el.attrib['href'] = uri
        el.attrib['target'] = 'blank'
        el.text = text[1:] if text is not None else ref
        return el, m.start(0), m.end(0)


class XrefExtension(Extension):
    """Markdown extension responsible for expanding @{ref|text} into links."""

    def extendMarkdown(self, md):
        md.inlinePatterns.register(
            _XrefPattern(r'@{([^}|]*)(\|[^}]+)?}'), 'xref', 175)
