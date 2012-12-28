#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Templating to help generate structured text."""

import os
import re
import emitter
import logging

_logger = logging.getLogger('multiemitter')

class MultiEmitter(object):
  """A set of Emitters that write to different files.

  Each entry has a key.

  file --> emitter
  key --> emitter

  """

  def __init__(self):
    self._key_to_emitter = {}     # key -> Emitter
    self._filename_to_emitter = {}    # filename -> Emitter


  def FileEmitter(self, filename, key=None):
    """Creates an emitter for writing to a file.

    When this MultiEmitter is flushed, the contents of the emitter are written
    to the file.

    Arguments:
      filename: a string, the path name of the file
      key: provides an access key to retrieve the emitter.

    Returns: the emitter.
    """
    e = emitter.Emitter()
    self._filename_to_emitter[filename] = e
    if key:
      self.Associate(key, e)
    return e

  def Associate(self, key, emitter):
    """Associates a key with an emitter."""
    self._key_to_emitter[key] = emitter

  def Find(self, key):
    """Returns the emitter associated with |key|."""
    return self._key_to_emitter[key]

  def Flush(self, writer=None):
    """Writes all pending files.

    Arguments:
      writer: a function called for each file and it's lines.
    """
    if not writer:
      writer = _WriteFile
    for file in sorted(self._filename_to_emitter.keys()):
      emitter = self._filename_to_emitter[file]
      writer(file, emitter.Fragments())


def _WriteFile(path, lines):
  (dir, file) = os.path.split(path)

  # Ensure dir exists.
  if dir:
    if not os.path.isdir(dir):
      os.makedirs(dir)

  # Remove file if pre-existing.
  if os.path.exists(path):
    os.remove(path)

  # Write the file.
  # _logger.info('Flushing - %s' % path)
  f = open(path, 'w')
  f.writelines(lines)
  f.close()
