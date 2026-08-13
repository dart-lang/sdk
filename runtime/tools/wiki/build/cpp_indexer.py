# Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
"""Clang based C++ code indexer which produces xref.json."""
from __future__ import annotations

import glob
import json
import logging
import os
import platform
import re
import sys
import subprocess

from contextlib import contextmanager
from dataclasses import dataclass, field
from typing import Dict, Optional, Set

from marshmallow_dataclass import class_schema
from progress.bar import ShadyBar

_libclang_path = None
_clang_include_dir = None
if platform.system() == 'Darwin':
    _path_to_llvm = subprocess.check_output(['brew', '--prefix', 'llvm'],
                                            encoding='utf-8').strip()
    _clang_include_dir = glob.glob(f'{_path_to_llvm}/lib/clang/**/include')[0]
    _libclang_path = f'{_path_to_llvm}/lib/libclang.dylib'
    sys.path.append(
        f'{_path_to_llvm}/lib/python{sys.version_info.major}.{sys.version_info.minor}/site-packages'
    )

# pylint: disable=wrong-import-position,line-too-long
from clang.cindex import Config, CompilationDatabase, Cursor, CursorKind, Index, SourceLocation, TranslationUnit

if _libclang_path is not None:
    Config.set_library_file(_libclang_path)

_DART_CONFIGURATION = 'Release' + (
    'ARM64' if platform.uname().machine == 'arm64' else 'X64')
_DART_BUILD_DIR = ('xcodebuild' if platform.system() == 'Darwin' else
                   'out') + '/' + _DART_CONFIGURATION


@contextmanager
def _change_working_directory_to(path):
    oldpwd = os.getcwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(oldpwd)


def _create_compilation_database():
    """Create compilation database for the default configuration.

    Extacts compilation database (compile_commands.json) for the default
    build configuration and filters it down to commands taht builds just
    the core VM pieces in the host configuration.
    """
    logging.info('Extracting compilation commands from build files for %s',
                 _DART_CONFIGURATION)
    with _change_working_directory_to(_DART_BUILD_DIR):
        commands = json.loads(
            subprocess.check_output(['ninja', '-C', '.', '-t', 'compdb',
                                     'cxx']))
    pattern = re.compile(
        r'libdart(_vm|_compiler)?_precompiler_host_targeting_host\.')
    with open('compile_commands.json', 'w', encoding='utf-8') as outfile:
        json.dump([
            cmd for cmd in commands
            if pattern.search(cmd['command']) is not None
        ], outfile)


def _get_current_commit_hash():
    return subprocess.check_output(['git', 'merge-base', 'main', 'HEAD'],
                                   text=True).strip()


@dataclass
class _ClassInfo:
    location: str
    members: Dict[str, str] = field(default_factory=dict)


@dataclass
class Location:
    """Symbol location referring to a line in a specific file."""
    filename: str
    lineno: int


@dataclass
class SymbolsIndex:
    """Index of C++ symbols extracted from source."""
    commit: str
    files: list[str] = field(default_factory=list)
    classes: Dict[str, _ClassInfo] = field(default_factory=dict)
    functions: Dict[str, str] = field(default_factory=dict)

    def try_resolve(self, ref: str) -> Optional[Location]:
        """Resolve the location of the given reference."""
        loc = self._try_resolve_impl(ref)
        if loc is not None:
            return self._location_from_string(loc)
        return None

    def _try_resolve_impl(self, ref: str) -> Optional[str]:
        if ref in self.functions:
            return self.functions[ref]
        if ref in self.classes:
            return self.classes[ref].location
        if '::' in ref:
            (class_name, function_name) = ref.rsplit('::', 1)
            if class_name in self.classes:
                return self.classes[class_name].members.get(function_name)
        return None

    def _location_from_string(self, loc: str) -> Location:
        (file_idx, line_idx) = loc.split(':', 1)
        return Location(self.files[int(file_idx)], int(line_idx))


class _Indexer:
    symbols_index: SymbolsIndex

    processed_files: Set[str]
    classes_by_usr: Dict[str, _ClassInfo]

    name_stack: list[str]
    info_stack: list[_ClassInfo]
    files_seen_in_unit: Set[str]

    def __init__(self):
        self.symbols_index = SymbolsIndex(commit=_get_current_commit_hash())

        self.processed_files = set()
        self.classes_by_usr = {}
        self.files_index = {}

        self.name_stack = []
        self.info_stack = []
        self.files_seen_in_unit = set()

    def index(self, unit: TranslationUnit):
        """Index the given translation unit and append new symbols to index."""
        self.name_stack.clear()
        self.info_stack.clear()
        self.files_seen_in_unit.clear()
        self._recurse(unit.cursor)
        self.processed_files |= self.files_seen_in_unit

    def _recurse(self, cursor: Cursor):
        name = ""
        kind = cursor.kind

        if cursor.location.file is not None:
            name = cursor.location.file.name
            if name in self.processed_files or not name.startswith('../..'):
                return
            self.files_seen_in_unit.add(name)

        if kind == CursorKind.CLASS_DECL:
            if not cursor.is_definition():
                return
            usr = cursor.get_usr()
            if usr in self.classes_by_usr:
                return
            self.name_stack.append(cursor.spelling)
            class_name = '::'.join(self.name_stack)
            class_info = _ClassInfo(self._format_location(cursor.location))
            self.info_stack.append(class_info)
            self.symbols_index.classes[class_name] = class_info
            self.classes_by_usr[usr] = class_info
        elif kind == CursorKind.NAMESPACE:
            self.name_stack.append(cursor.spelling)
        elif kind == CursorKind.FUNCTION_DECL and cursor.is_definition():
            namespace_prefix = ""
            if cursor.semantic_parent.kind == CursorKind.NAMESPACE:
                namespace_prefix = '::'.join(self.name_stack) + (
                    '::' if len(self.name_stack) > 0 else "")
            function_name = namespace_prefix + cursor.spelling
            self.symbols_index.functions[function_name] = self._format_location(
                cursor.location)
            return
        elif kind == CursorKind.CXX_METHOD and cursor.is_definition():
            parent = cursor.semantic_parent
            if parent.kind == CursorKind.CLASS_DECL:
                class_info_or_none = self.classes_by_usr.get(parent.get_usr())
                if class_info_or_none is None:
                    return
                class_info_or_none.members[
                    cursor.spelling] = self._format_location(cursor.location)
            return
        elif kind == CursorKind.VAR_DECL and cursor.is_definition():
            parent = cursor.semantic_parent
            if parent.kind == CursorKind.CLASS_DECL:
                class_info_or_none = self.classes_by_usr.get(parent.get_usr())
                if class_info_or_none is None:
                    return
                class_info_or_none.members[
                    cursor.spelling] = self._format_location(cursor.location)

        for child in cursor.get_children():
            self._recurse(child)

        if kind == CursorKind.NAMESPACE:
            self.name_stack.pop()
        elif kind == CursorKind.CLASS_DECL:
            self.name_stack.pop()
            self.info_stack.pop()

    def _format_location(self, loc: SourceLocation):
        file_name = loc.file.name
        lineno = loc.line
        return f'{self._get_file_index(file_name)}:{lineno}'

    def _get_file_index(self, file_name: str):
        index = self.files_index.get(file_name)
        if index is None:
            index = len(self.symbols_index.files)
            self.files_index[file_name] = index
            self.symbols_index.files.append(
                os.path.relpath(os.path.abspath(file_name),
                                os.path.abspath('../..')))
        return index


def _index_source() -> SymbolsIndex:
    indexer = _Indexer()

    _create_compilation_database()
    with _change_working_directory_to(_DART_BUILD_DIR):
        index = Index.create()
        compdb = CompilationDatabase.fromDirectory('.')

        commands = list(compdb.getAllCompileCommands())
        with ShadyBar('Indexing',
                      max=len(commands),
                      suffix='%(percent)d%% eta %(eta_td)s') as progress_bar:
            for command in commands:
                args = [
                    arg for arg in command.arguments
                    if arg.startswith('-I') or arg.startswith('-W') or
                    arg.startswith('-D') or arg.startswith('-i') or
                    arg.startswith('sdk/') or arg.startswith('-std')
                ] + [
                    '-Wno-macro-redefined', '-Wno-unused-const-variable',
                    '-Wno-unused-function', '-Wno-unused-variable'
                ]

                if _clang_include_dir is not None:
                    args.append(f'-I{_clang_include_dir}')

                unit = index.parse(command.filename, args=args)
                for diag in unit.diagnostics:
                    print(diag.format())

                indexer.index(unit)
                progress_bar.next()

    return indexer.symbols_index


_SymbolsIndexSchema = class_schema(SymbolsIndex)()


def load_index(filename: str) -> SymbolsIndex:
    """Load symbols index from the given file.

    If index is out of date or missing it will be generated.
    """
    index: SymbolsIndex

    if os.path.exists(filename):
        with open(filename, 'r', encoding='utf-8') as json_file:
            index = _SymbolsIndexSchema.loads(json_file.read())
        if _get_current_commit_hash() == index.commit:
            logging.info('Loaded symbols index from %s', filename)
            return index
        logging.warning(
            '%s is generated for commit %s while current commit is %s',
            filename, index.commit, _get_current_commit_hash())

    index = _index_source()
    with open(filename, 'w', encoding='utf-8') as json_file:
        json_file.write(_SymbolsIndexSchema.dumps(index))
    logging.info(
        'Successfully indexed C++ source and written symbols index into %s',
        filename)
    return index
