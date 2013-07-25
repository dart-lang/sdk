#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import database
import databasebuilder
import idlparser
import logging.config
import os.path
import sys

_logger = logging.getLogger('fremontcutbuilder')

# See:
#  http://src.chromium.org/viewvc/multivm/trunk/webkit/Source/core/features.gypi
# for ENABLE_* flags defined in Chromium / Blink.
# We list all ENABLE flags used in IDL in one of these two lists.
FEATURE_DISABLED = [
    'ENABLE_CUSTOM_SCHEME_HANDLER',
    'ENABLE_MEDIA_CAPTURE', # Only enabled on Android.
    'ENABLE_ORIENTATION_EVENTS', # Only enabled on Android.
    'ENABLE_WEBVTT_REGIONS',
]

FEATURE_DEFINES = [
    'ENABLE_CALENDAR_PICKER', # Not on Android
    'ENABLE_ENCRYPTED_MEDIA_V2',
    'ENABLE_INPUT_SPEECH', # Not on Android
    'ENABLE_LEGACY_NOTIFICATIONS', # Not on Android
    'ENABLE_NAVIGATOR_CONTENT_UTILS', # Not on Android
    'ENABLE_NOTIFICATIONS', # Not on Android
    'ENABLE_SVG_FONTS',
    'ENABLE_WEB_AUDIO', # Not on Android
]

def build_database(idl_files, database_dir, feature_defines=None, parallel=False):
  """This code reconstructs the FremontCut IDL database from W3C,
  WebKit and Dart IDL files."""
  current_dir = os.path.dirname(__file__)
  logging.config.fileConfig(os.path.join(current_dir, "logging.conf"))

  db = database.Database(database_dir)

  # Delete all existing IDLs in the DB.
  db.Delete()

  builder = databasebuilder.DatabaseBuilder(db)

  # TODO(vsm): Move this to a README.
  # This is the Dart SVN revision.
  webkit_revision = '1060'

  # TODO(vsm): Reconcile what is exposed here and inside WebKit code
  # generation.  We need to recheck this periodically for now.
  webkit_defines = [ 'LANGUAGE_DART', 'LANGUAGE_JAVASCRIPT' ]

  if feature_defines is None:
    feature_defines = FEATURE_DEFINES

  webkit_options = databasebuilder.DatabaseBuilderOptions(
      idl_syntax=idlparser.WEBKIT_SYNTAX,
      # TODO(vsm): What else should we define as on when processing IDL?
      idl_defines=webkit_defines + feature_defines,
      source='WebKit',
      source_attributes={'revision': webkit_revision})

  # Import WebKit IDLs.
  builder.import_idl_files(idl_files, webkit_options, parallel)

  # Import Dart idl:
  dart_options = databasebuilder.DatabaseBuilderOptions(
    idl_syntax=idlparser.FREMONTCUT_SYNTAX,
    source='Dart',
    rename_operation_arguments_on_merge=True)

  builder.import_idl_files(
      [ os.path.join(current_dir, '..', 'idl', 'dart', 'dart.idl') ],
      dart_options,
      parallel)

  # Merging:
  builder.merge_imported_interfaces()

  builder.fetch_constructor_data(webkit_options)
  builder.fix_displacements('WebKit')

  # Cleanup:
  builder.normalize_annotations(['WebKit', 'Dart'])

  conditionals_met = set(
      'ENABLE_' + conditional for conditional in builder.conditionals_met)
  known_conditionals = set(FEATURE_DEFINES + FEATURE_DISABLED)

  unused_conditionals = known_conditionals - conditionals_met
  if unused_conditionals:
    _logger.warning('There are some unused conditionals %s' %
        sorted(unused_conditionals))
    _logger.warning('Please update fremontcutbuilder.py')

  unknown_conditionals = conditionals_met - known_conditionals
  if unknown_conditionals:
    _logger.warning('There are some unknown conditionals %s' %
        sorted(unknown_conditionals))
    _logger.warning('Please update fremontcutbuilder.py')

  db.Save()
  return db

def main(parallel=False):
  current_dir = os.path.dirname(__file__)

  idl_files = []

  # Check default location in a regular dart enlistment.
  webcore_dir = os.path.join(current_dir, '..', '..', '..', 'third_party',
                             'WebCore')

  if not os.path.exists(webcore_dir):
    # Check default location in a dartium enlistment.
    webcore_dir = os.path.join(current_dir, '..', '..', '..', '..',
                               'third_party', 'WebKit', 'Source')

  if not os.path.exists(webcore_dir):
    raise RuntimeError('directory not found: %s' % webcore_dir)

  DIRS_TO_IGNORE = [
      'bindings', # Various test IDLs
      'testing', # IDLs to expose testing APIs
      'networkinfo', # Not yet used in Blink yet
      'vibration', # Not yet used in Blink yet
      'inspector',
  ]

  def visitor(arg, dir_name, names):
    if os.path.basename(dir_name) in DIRS_TO_IGNORE:
      names[:] = [] # Do not go underneath
    for name in names:
      file_name = os.path.join(dir_name, name)
      (interface, ext) = os.path.splitext(file_name)
      if ext == '.idl':
        idl_files.append(file_name)

  os.path.walk(webcore_dir, visitor, webcore_dir)

  database_dir = os.path.join(current_dir, '..', 'database')
  return build_database(idl_files, database_dir, parallel=parallel)

if __name__ == '__main__':
  sys.exit(main())
