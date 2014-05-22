#!/usr/bin/python

# Copyright (c) 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Utility functions specific to dartium buildbot checkouts
"""
import os

def srcPath():
  """Return the path [dartium_checkout]/src

       Only valid if this file is in a dartium checkout.
  """
  # This file is in [dartium checkout]/src/dart/tools/dartium/,
  # if we are in a dartium checkout that checks out dart into src.
  # This function cannot be in utils.py because __file__ is wrong
  # when other modules with the name 'utils' are imported indirectly.
  return os.path.dirname(
         os.path.dirname(
         os.path.dirname(
         os.path.dirname(os.path.abspath(__file__)))))
