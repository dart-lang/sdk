#!/usr/bin/env python3
#
# Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
"""Tool used for rendering Dart Native Runtime wiki as HTML.

Usage: runtime/tools/wiki/build/build.py [--deploy]

If invoked without --deploy the tool would serve development version of the
wiki which supports fast edit-(auto)refresh cycle.

If invoked with --deploy it would build deployment version in the
/tmp/dart-vm-wiki directory.
"""

from __future__ import annotations

import argparse
import asyncio
import codecs
import coloredlogs
import glob
import jinja2
import logging
import markdown
import os
import posixpath
import re
import shutil
import subprocess
import sys
import time
import urllib

from aiohttp import web, WSCloseCode, WSMsgType
from http.server import HTTPServer, SimpleHTTPRequestHandler
from markdown.extensions.codehilite import CodeHiliteExtension
from pathlib import Path
from typing import Callable, Dict, Sequence
from watchdog.events import FileSystemEventHandler
from watchdog.observers import Observer
from xrefs import XrefExtension

# Configure logging to use colors.
coloredlogs.install(
    level='INFO', fmt='%(asctime)s - %(message)s', datefmt='%H:%M:%S')

# Declare various directory paths.
# We expected to be located in runtime/tools/wiki/build.
TOOL_DIR = os.path.dirname(os.path.realpath(__file__))
SDK_DIR = os.path.relpath(os.path.join(TOOL_DIR, '..', '..', '..', '..'))

WIKI_SOURCE_DIR = os.path.join(SDK_DIR, 'runtime', 'docs')

STYLES_DIR = os.path.relpath(os.path.join(TOOL_DIR, '..', 'styles'))
STYLES_INCLUDES_DIR = os.path.join(STYLES_DIR, 'includes')

TEMPLATES_DIR = os.path.relpath(os.path.join(TOOL_DIR, '..', 'templates'))
TEMPLATES_INCLUDES_DIR = os.path.join(TEMPLATES_DIR, 'includes')

PAGE_TEMPLATE = 'page.html'

OUTPUT_DIR = '/tmp/dart-vm-wiki'
OUTPUT_CSS_DIR = os.path.join(OUTPUT_DIR, 'css')

# Clean output directory and recreate it.
shutil.rmtree(OUTPUT_DIR, ignore_errors=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(OUTPUT_CSS_DIR, exist_ok=True)

# Parse incoming arguments.
parser = argparse.ArgumentParser()
parser.add_argument('--deploy', dest='deploy', action='store_true')
parser.set_defaults(deploy=False)
args = parser.parse_args()

is_dev_mode = not args.deploy

# Initialize jinja environment.
jinja2_env = jinja2.Environment(
    loader=jinja2.FileSystemLoader(TEMPLATES_DIR),
    lstrip_blocks=True,
    trim_blocks=True)


class Artifact:
    """Represents a build artifact with its dependencies and way of building."""

    # Map of all discovered artifacts.
    all: Dict[str, Artifact] = {}

    # List of listeners which are notified whenever some artifact is rebuilt.
    listeners = []

    def __init__(self, output: str, inputs: Sequence[str]):
        Artifact.all[output] = self
        self.output = output
        self.inputs = inputs

    def depends_on(self, path: str) -> bool:
        """Check if this"""
        return path in self.inputs

    def build(self):
        pass

    @staticmethod
    def build_all():
        """Build all artifacts."""
        Artifact.build_matching(lambda obj: True)

    @staticmethod
    def build_matching(filter: Callable[[Artifact], bool]):
        """Build all artifacts matching the given filter."""
        rebuilt = False
        for _, artifact in Artifact.all.items():
            if filter(artifact):
                artifact.build()
                rebuilt = True

        # If any artifacts were rebuilt notify the listeners.
        if rebuilt:
            for listener in Artifact.listeners:
                listener()


class Page(Artifact):
    """A single wiki Page (a markdown file)."""

    def __init__(self, name: str):
        self.name = name
        super().__init__(
            os.path.join(OUTPUT_DIR, name + '.html'),
            [os.path.join(WIKI_SOURCE_DIR, name + '.md')])

    def __repr__(self):
        return 'Page(%s <- %s)' % (self.output, self.inputs[0])

    def depends_on(self, path: str):
        return path.startswith(TEMPLATES_INCLUDES_DIR) or super().depends_on(
            path)

    def load_markdown(self):
        with open(self.inputs[0], 'r') as file:
            content = file.read()
            content = re.sub(r'(?<=[^\n])\n+<aside>', '<span class="aside">',
                             content)
            content = re.sub(r'</aside>', '</span>', content)
            return content

    def build(self):
        logging.info('Build %s from %s', self.output, self.inputs[0])

        template = jinja2_env.get_template(PAGE_TEMPLATE)
        result = template.render({
            'dev':
            is_dev_mode,
            'body':
            markdown.markdown(
                self.load_markdown(),
                extensions=[
                    'admonition', 'extra',
                    CodeHiliteExtension(), 'tables', 'pymdownx.superfences',
                    XrefExtension()
                ])
        })

        os.makedirs(os.path.dirname(self.output), exist_ok=True)
        with codecs.open(self.output, "w", encoding='utf-8') as file:
            file.write(result)

        template_filename = template.filename  # pytype: disable=attribute-error
        self.inputs = [self.inputs[0], template_filename]


class Style(Artifact):
    """Stylesheet written in SASS which needs to be compiled to CSS."""

    def __init__(self, name: str):
        self.name = name
        super().__init__(
            os.path.join(OUTPUT_CSS_DIR, name + '.css'),
            [os.path.join(STYLES_DIR, name + '.scss')])

    def __repr__(self):
        return 'Style(%s <- %s)' % (self.output, self.inputs[0])

    def depends_on(self, path: str):
        return path.startswith(STYLES_INCLUDES_DIR) or super().depends_on(path)

    def build(self):
        logging.info('Build %s from %s', self.output, self.inputs[0])
        subprocess.call(['sass', self.inputs[0], self.output])


def find_images_directories():
    """Find all subdirectories called images within wiki."""
    return [
        f.relative_to(Path(WIKI_SOURCE_DIR)).as_posix()
        for f in Path(WIKI_SOURCE_DIR).rglob('images')
    ]


def find_artifacts():
    """Find all wiki pages and styles and create corresponding Artifacts."""
    Artifact.all = {}
    for f in Path(WIKI_SOURCE_DIR).rglob('*.md'):
        name = f.relative_to(Path(WIKI_SOURCE_DIR)).as_posix().rsplit('.', 1)[0]
        Page(name)

    for f in Path(STYLES_DIR).glob('*.scss'):
        Style(f.stem)


def build_for_deploy():
    logging.info('Building wiki for deployment into %s', OUTPUT_DIR)
    Artifact.build_all()
    for images_dir in find_images_directories():
        src = os.path.join(WIKI_SOURCE_DIR, images_dir)
        dst = os.path.join(OUTPUT_DIR, images_dir)
        logging.info('Copying %s <- %s', dst, src)
        shutil.rmtree(dst, ignore_errors=True)
        shutil.copytree(src, dst)

    # Some images directories contain OmniGraffle source files which need
    # to be removed before
    logging.info('Removing image source files (*.graffle)')
    for graffle in Path(OUTPUT_DIR).rglob('*.graffle'):
        logging.info('... removing %s', graffle.as_posix())


class ArtifactEventHandler(FileSystemEventHandler):
    """File system listener rebuilding artifacts based on changed paths."""

    def __init__(self):
        super().__init__()

    def on_modified(self, event):
        Artifact.build_matching(
            lambda artifact: artifact.depends_on(event.src_path))


def serve_for_development():
    logging.info('Serving wiki for development')
    Artifact.build_all()

    # Watch for file modifications and rebuild dependant artifacts when their
    # dependencies change.
    event_handler = ArtifactEventHandler()
    observer = Observer()
    observer.schedule(event_handler, TEMPLATES_DIR, recursive=False)
    observer.schedule(event_handler, WIKI_SOURCE_DIR, recursive=True)
    observer.schedule(event_handler, STYLES_DIR, recursive=True)
    observer.start()

    async def on_shutdown(app):
        for ws in app['websockets']:
            await ws.close(
                code=WSCloseCode.GOING_AWAY, message='Server shutdown')
        observer.stop()
        observer.join()

    async def handle_artifact(name):
        source_path = os.path.join(OUTPUT_DIR, name)
        logging.info('Handling source path %s for %s', source_path, name)
        if source_path in Artifact.all:
            return web.FileResponse(source_path)
        else:
            return web.HTTPNotFound()

    async def handle_page(request):
        name = request.match_info.get('name', 'index.html')
        if name == '' or name.endswith('/'):
            name = name + 'index.html'
        return await handle_artifact(name)

    async def handle_css(request):
        name = request.match_info.get('name')
        return await handle_artifact('css/' + name)

    async def websocket_handler(request):
        logging.info('websocket connection open')
        ws = web.WebSocketResponse()
        await ws.prepare(request)

        loop = asyncio.get_event_loop()

        def notify():
            logging.info('requesting reload')
            asyncio.run_coroutine_threadsafe(ws.send_str('reload'), loop)

        Artifact.listeners.append(notify)
        request.app['websockets'].append(ws)
        try:
            async for msg in ws:
                if msg.type == WSMsgType.ERROR:
                    logging.error(
                        'websocket connection closed with exception %s',
                        ws.exception())
        finally:
            logging.info('websocket connection closing')
            Artifact.listeners.remove(notify)
            request.app['websockets'].remove(ws)

        logging.info('websocket connection closed')
        return ws

    app = web.Application()
    app['websockets'] = []
    for images_dir in find_images_directories():
        app.router.add_static('/' + images_dir,
                              os.path.join(WIKI_SOURCE_DIR, images_dir))
    app.router.add_get('/ws', websocket_handler)
    app.router.add_get('/css/{name}', handle_css)
    app.router.add_get('/{name:[^{}]*}', handle_page)
    app.on_shutdown.append(on_shutdown)
    web.run_app(app, access_log_format='"%r" %s')


def main():
    find_artifacts()
    if is_dev_mode:
        serve_for_development()
    else:
        build_for_deploy()


if __name__ == '__main__':
    main()
