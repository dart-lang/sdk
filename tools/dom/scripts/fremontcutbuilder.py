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

FEATURE_DISABLED = [
    'ENABLE_BATTERY_STATUS',
    'ENABLE_CSS3_CONDITIONAL_RULES',
    'ENABLE_CSS_DEVICE_ADAPTATION',
    'ENABLE_CUSTOM_SCHEME_HANDLER',
    'ENABLE_ENCRYPTED_MEDIA_V2',
    'ENABLE_INSPECTOR', # Internal DevTools API.
    'ENABLE_MEDIA_CAPTURE', # Only enabled on Android.
    'ENABLE_MICRODATA',
    'ENABLE_ORIENTATION_EVENTS', # Only enabled on Android.
    'ENABLE_PROXIMITY_EVENTS',
    'ENABLE_SPEECH_SYNTHESIS',
    'ENABLE_WEBVTT_REGIONS',
    'ENABLE_XHR_TIMEOUT',
]

FEATURE_DEFINES = [
    'ENABLE_BLOB',
    'ENABLE_CALENDAR_PICKER',
    'ENABLE_CANVAS_PATH',
    'ENABLE_CANVAS_PROXY',
    'ENABLE_CSS_FILTERS',
    'ENABLE_CSS_REGIONS',
    'ENABLE_CSS_SHADERS',
    'ENABLE_CUSTOM_ELEMENTS',
    'ENABLE_DATALIST_ELEMENT',
    'ENABLE_DETAILS_ELEMENT',
    'ENABLE_DEVICE_ORIENTATION',
    'ENABLE_DIALOG_ELEMENT',
    'ENABLE_DIRECTORY_UPLOAD',
    'ENABLE_DOWNLOAD_ATTRIBUTE',
    'ENABLE_ENCRYPTED_MEDIA',
    'ENABLE_FILE_SYSTEM',
    'ENABLE_FILTERS',
    'ENABLE_FONT_LOAD_EVENTS',
    'ENABLE_GAMEPAD',
    'ENABLE_GEOLOCATION',
    'ENABLE_INPUT_SPEECH',
    'ENABLE_JAVASCRIPT_DEBUGGER',
    'ENABLE_LEGACY_NOTIFICATIONS',
    'ENABLE_MEDIA_STATISTICS',
    'ENABLE_MEDIA_STREAM',
    'ENABLE_METER_ELEMENT',
    'ENABLE_NAVIGATOR_CONTENT_UTILS',
    'ENABLE_NOTIFICATIONS',
    'ENABLE_PAGE_POPUP',
    'ENABLE_PERFORMANCE_TIMELINE',
    'ENABLE_POINTER_LOCK',
    'ENABLE_PROGRESS_ELEMENT',
    'ENABLE_QUOTA',
    'ENABLE_REQUEST_ANIMATION_FRAME',
    'ENABLE_REQUEST_AUTOCOMPLETE',
    'ENABLE_RESOURCE_TIMING',
    'ENABLE_SCRIPTED_SPEECH',
    'ENABLE_SHADOW_DOM',
    'ENABLE_SHARED_WORKERS',
    'ENABLE_SQL_DATABASE',
    'ENABLE_STYLE_SCOPED',
    'ENABLE_SVG',
    'ENABLE_SVG_FONTS',
    'ENABLE_TOUCH_EVENTS',
    'ENABLE_USER_TIMING',
    'ENABLE_VIDEO',
    'ENABLE_VIDEO_TRACK',
    'ENABLE_WEB_AUDIO',
    'ENABLE_WEBGL',
    'ENABLE_WEB_SOCKETS',
    'ENABLE_WEB_TIMING',
    'ENABLE_WORKERS',
    'ENABLE_XSLT',
]

def build_database(idl_files, database_dir, parallel=False):
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

  webkit_options = databasebuilder.DatabaseBuilderOptions(
      idl_syntax=idlparser.WEBKIT_SYNTAX,
      # TODO(vsm): What else should we define as on when processing IDL?
      idl_defines=webkit_defines + FEATURE_DEFINES,
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
    raise Exception('There are some unused conditionals %s' %
        sorted(unused_conditionals))

  unknown_conditionals = conditionals_met - known_conditionals
  if unknown_conditionals:
    raise Exception('There are some unknown conditionals %s' %
        sorted(unknown_conditionals))

  db.Save()
  return db

def main(parallel=False):
  current_dir = os.path.dirname(__file__)

  ignored_idls = [
    'AbstractView.idl',
    ]

  idl_files = []

  webcore_dir = os.path.join(current_dir, '..', '..', '..', 'third_party',
                             'WebCore')
  if not os.path.exists(webcore_dir):
    raise RuntimeError('directory not found: %s' % webcore_dir)

  DIRS_TO_IGNORE = [
      'bindings', # Various test IDLs
      'testing', # IDLs to expose testing APIs
      'networkinfo', # Not yet used in Blink yet
      'vibration', # Not yet used in Blink yet
  ]

  def visitor(arg, dir_name, names):
    if os.path.basename(dir_name) in DIRS_TO_IGNORE:
      names[:] = [] # Do not go underneath
    for name in names:
      file_name = os.path.join(dir_name, name)
      (interface, ext) = os.path.splitext(file_name)
      if ext == '.idl' and name not in ignored_idls:
        idl_files.append(file_name)

  os.path.walk(webcore_dir, visitor, webcore_dir)

  database_dir = os.path.join(current_dir, '..', 'database')
  return build_database(idl_files, database_dir, parallel=parallel)

if __name__ == '__main__':
  sys.exit(main())
