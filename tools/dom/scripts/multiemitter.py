#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Templating to help generate structured text."""

import os
import sys
import subprocess
import time
import emitter
import logging

_logger = logging.getLogger('multiemitter')

class MultiEmitter(object):
  """A set of Emitters that write to different files.

  Each entry has a key.

  file --> emitter
  key --> emitter

  """

  def __init__(self, logging_level=logging.WARNING):
    self._key_to_emitter = {}     # key -> Emitter
    self._filename_to_emitter = {}    # filename -> Emitter

    _logger.setLevel(logging_level)


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
      _logger.info('Mkdir - %s' % dir)
      os.makedirs(dir)

  # If file exists and is unchanged, return.
  new_contents = ''.join(lines)
  if os.path.exists(path):
    with open(path) as fd:
      contents = fd.read()
    if new_contents == contents:
      _logger.info('Unchanged file %s' % path)
      return

  # Write the file.
  num_attempts = 4
  for i in range(num_attempts):
    try:
      _logger.info('Writing (attempt %d) - %s' % (i + 1, path))
      with open(path, 'w') as fd:
        fd.write(new_contents)
      return
    except IOError as error:
      last_attempt = (i == (num_attempts - 1))
      if not last_attempt:
        # Sleep for 50 ms and try again
        time.sleep(0.05)
      else:
        # FIXME(kustermann): Remove this later on.
        # We try to get more debugging information to figure out why we
        # sometimes get a "Permission denied" error when opening the file for
        # writing. (hypothesis: Another process has already opened the file.)
        _logger.info('Got exception (%s) ' % error)

        if sys.platform  == 'win32':
          handle_file = r'E:\handle.exe'
          if os.path.exists(handle_file):
            _logger.info('Running handle.exe for debugging purposes')
            subprocess.call([handle_file, '-a', r'E:\b\build\slave'])
          else:
            _logger.info("Couldn't find %s. Not printing open handles."
                         % handle_file)
        raise error
