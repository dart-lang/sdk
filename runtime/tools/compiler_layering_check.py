#!/usr/bin/env python
#
# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Simple tool for verifying that sources from one layer do not reference
# sources from another layer.
#
# Currently it only checks that core runtime headers RUNTIME_LAYER_HEADERS
# are not included into any sources listed in SHOULD_NOT_DEPEND_ON_RUNTIME.

import glob
import os
import re
import sys

INCLUDE_DIRECTIVE_RE = re.compile(r'^#include "(.*)"')

RUNTIME_LAYER_HEADERS = [
    'runtime/vm/isolate.h',
    'runtime/vm/object.h',
    'runtime/vm/raw_object.h',
    'runtime/vm/thread.h',
]

SHOULD_NOT_DEPEND_ON_RUNTIME = [
    'runtime/vm/allocation.h',
    'runtime/vm/growable_array.h',
]


class LayeringChecker(object):

    def __init__(self, root):
        self.root = root
        self.worklist = set()
        # Mapping from header to a set of files it is included into.
        self.included_into = dict()
        # Set of files that were parsed to avoid double parsing.
        self.loaded = set()
        # Mapping from headers to their layer.
        self.file_layers = {file: 'runtime' for file in RUNTIME_LAYER_HEADERS}

    def Check(self):
        self.AddAllSourcesToWorklist(os.path.join(self.root, 'runtime/vm'))
        self.BuildIncludesGraph()
        errors = self.PropagateLayers()
        errors += self.CheckNotInRuntime(SHOULD_NOT_DEPEND_ON_RUNTIME)
        return errors

    def CheckNotInRuntime(self, files):
        """Check that given files do not depend on runtime layer."""
        errors = []
        for file in files:
            if not os.path.exists(os.path.join(self.root, file)):
                errors.append('File %s does not exist.' % (file))
            if self.file_layers.get(file) is not None:
                errors.append(
                    'LAYERING ERROR: %s includes object.h or raw_object.h' %
                    (file))
        return errors

    def BuildIncludesGraph(self):
        while self.worklist:
            file = self.worklist.pop()
            deps = self.ExtractIncludes(file)
            self.loaded.add(file)
            for d in deps:
                if d not in self.included_into:
                    self.included_into[d] = set()
                self.included_into[d].add(file)
                if d not in self.loaded:
                    self.worklist.add(d)

    def PropagateLayers(self):
        """Propagate layering information through include graph.

    If A is in layer L and A is included into B then B is in layer L.
    """
        errors = []
        self.worklist = set(self.file_layers.keys())
        while self.worklist:
            file = self.worklist.pop()
            if file not in self.included_into:
                continue
            file_layer = self.file_layers[file]
            for tgt in self.included_into[file]:
                if tgt in self.file_layers:
                    if self.file_layers[tgt] != file_layer:
                        errors.add(
                            'Layer mismatch: %s (%s) is included into %s (%s)' %
                            (file, file_layer, tgt, self.file_layers[tgt]))
                self.file_layers[tgt] = file_layer
                self.worklist.add(tgt)
        return errors

    def AddAllSourcesToWorklist(self, dir):
        """Add all *.cc and *.h files from dir recursively into worklist."""
        for file in os.listdir(dir):
            path = os.path.join(dir, file)
            if os.path.isdir(path):
                self.AddAllSourcesToWorklist(path)
            elif path.endswith('.cc') or path.endswith('.h'):
                self.worklist.add(os.path.relpath(path, self.root))

    def ExtractIncludes(self, file):
        """Extract the list of includes from the given file."""
        deps = set()
        with open(os.path.join(self.root, file)) as file:
            for line in file:
                if line.startswith('namespace dart {'):
                    break

                m = INCLUDE_DIRECTIVE_RE.match(line)
                if m is not None:
                    header = os.path.join('runtime', m.group(1))
                    if os.path.isfile(os.path.join(self.root, header)):
                        deps.add(header)
        return deps


def DoCheck(sdk_root):
    """Run layering check at the given root folder."""
    return LayeringChecker(sdk_root).Check()


if __name__ == '__main__':
    errors = DoCheck('.')
    print '\n'.join(errors)
    if errors:
        sys.exit(-1)
