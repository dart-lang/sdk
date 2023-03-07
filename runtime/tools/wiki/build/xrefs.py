# Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
"""Markdown extension for xrefs and reference to other Markdown files.

Xref is a reference of form [`symbol`][] or [text][`symbol`], where symbol
is expected to be one of the following:

   * package:-scheme URI - it will be resolved using .packages file in the
     root directory
   * file path
   * C++ symbol - will be resolved through xref.json file (see README.md)

Xrefs are converted to GitHub links.

Additionally this extension retargets links pointing to markdown files to
the html files produced from these markdown files.

Usage: markdown.markdown(extensions=[XrefExtension()])
"""

import json
import logging
import os
import re

import xml.etree.ElementTree as etree
from typing import Dict, Optional
from urllib.parse import urlparse

from cpp_indexer import SymbolsIndex, load_index
from markdown.extensions import Extension
from markdown.inlinepatterns import InlineProcessor
from markdown.treeprocessors import Treeprocessor


class _XrefPattern(InlineProcessor):
    """Converts xrefs into GitHub links.

    Recognizes [`symbol`][] and [text][`symbol`] link formats where symbol
    is expected to be one of the following:

    * Fully qualified reference to a C++ class, method or function;
    * Package URI pointing to one of the packages included in the SDK
    checkout.
    * File reference to one of the file in the SDK.
    """

    XREF_RE = r'\[`(?P<symbol>[^]]+)`\]?\[\]|\[(?P<text>[^]]*)\]\[`(?P<target>[^]]+)`\]'

    def __init__(self, md, symbols_index: SymbolsIndex,
                 packages: Dict[str, str]):
        super().__init__(_XrefPattern.XREF_RE)
        self.symbols_index = symbols_index
        self.packages = packages
        self.md = md

    def handleMatch(self, m, data):
        text = m.group('text')
        symbol = m.group('symbol')
        if symbol is None:
            symbol = m.group('target')

        uri = self._resolve_ref(symbol) or '#broken-link'

        # Remember this xref. build process can later use this information
        # to produce xref reference section at the end of the markdown file.
        self.md.xrefs[f"`{symbol}`"] = uri

        # Create <a href='uri'>text</a> element. If text is not defined
        # simply use a slightly sanitized symbol name.
        anchor = etree.Element('a')
        anchor.attrib['href'] = uri
        anchor.attrib['target'] = '_blank'
        if text is not None:
            anchor.text = text
        else:
            code = etree.Element('code')
            code.text = re.sub(r'^dart::', '', symbol)
            anchor.append(code)

        # Replace the whole pattern match with anchor element.
        return anchor, m.start(0), m.end(0)

    def _resolve_ref(self, ref: str) -> Optional[str]:
        if ref.startswith('package:'):
            # Resolve as package uri via .packages.
            uri = urlparse(ref)
            (package_name, *path_to_file) = uri.path.split('/', 1)
            package_path = self.packages[package_name]
            if len(path_to_file) == 0:
                return self._make_github_uri(package_path)
            else:
                return self._make_github_uri(
                    os.path.join(package_path, path_to_file[0]))
        elif os.path.exists(ref):
            # Resolve as a file link.
            return self._make_github_uri(ref)
        else:
            # Resolve as a symbol.
            loc = self.symbols_index.try_resolve(ref)
            if loc is not None:
                return self._make_github_uri(loc.filename, loc.lineno)

        logging.error('Failed to resolve xref %s', ref)
        return None

    def _make_github_uri(self, file: str, lineno: Optional[int] = None) -> str:
        """Generates source link pointing to GitHub"""
        fragment = f'#L{lineno}' if lineno is not None else ''
        return f'https://github.com/dart-lang/sdk/blob/{self.symbols_index.commit}/{file}{fragment}'


class _MdLinkFixerTreeprocessor(Treeprocessor):
    """Redirects links pointing to .md files to .html files built from them."""

    def run(self, root):
        for elem in root.iter('a'):
            href = elem.get('href')
            if href is None:
                continue
            parsed_href = urlparse(href)
            if parsed_href.path.endswith('.md'):
                elem.set(
                    'href',
                    parsed_href._replace(path=parsed_href.path[:-3] +
                                         '.html').geturl())


class XrefExtension(Extension):
    """Markdown extension which handles xrefs and links to markdown files."""
    symbols_index: SymbolsIndex
    packages: Dict[str, str]

    def __init__(self) -> None:
        super().__init__()
        self.symbols_index = load_index('xref.json')
        self.packages = XrefExtension._load_package_config()

    def extendMarkdown(self, md):
        md.xrefs = {}
        md.treeprocessors.register(_MdLinkFixerTreeprocessor(), 'mdlinkfixer',
                                   0)
        md.inlinePatterns.register(
            _XrefPattern(md, self.symbols_index, self.packages), 'xref', 200)

    @staticmethod
    def _load_package_config() -> Dict[str, str]:
        # Load package_config.json file into a dictionary.
        with open('.dart_tool/package_config.json',
                  encoding='utf-8') as package_config_file:
            package_config = json.load(package_config_file)
            return dict([(pkg['name'],
                          os.path.normpath(
                              os.path.join('.dart_tool/', pkg['rootUri'],
                                           pkg['packageUri'])))
                         for pkg in package_config['packages']
                         if 'packageUri' in pkg])
