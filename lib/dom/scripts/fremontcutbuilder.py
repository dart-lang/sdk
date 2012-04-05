#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import database
import databasebuilder
import idlparser
import os.path
import logging.config
import sys


def main():
  """This code reconstructs the FremontCut IDL database from W3C,
  WebKit and Dart IDL files."""
  current_dir = os.path.dirname(__file__)
  logging.config.fileConfig(os.path.join(current_dir, "logging.conf"))

  db = database.Database(os.path.join(current_dir, '..', 'database'))

  # Delete all existing IDLs in the DB.
  db.Delete()

  builder = databasebuilder.DatabaseBuilder(db)

  # Import WebKit IDL files:
  webkit_dirs = [
      'Modules/speech',
      'Modules/indexeddb',
      'css',
      'dom',
      'fileapi',
      'Modules/filesystem',
      'html',
      'html/canvas',
      'inspector',
      'loader',
      'loader/appcache',
      'Modules/mediastream',
      'Modules/geolocation',
      'notifications',
      'page',
      'plugins',
      'storage',
      'Modules/webdatabase',
      'svg',
      'Modules/webaudio',
      'Modules/websockets',
      'workers',
      'xml',
      ]

  # TODO(vsm): Move this to a README.
  # This is the Dart SVN revision.
  webkit_revision = '1060'

  # TODO(vsm): Reconcile what is exposed here and inside WebKit code
  # generation.  We need to recheck this periodically for now.
  webkit_defines = [
      'LANGUAGE_DART',
      'LANGUAGE_JAVASCRIPT',

      # Enabled Chrome WebKit build.
      'ENABLE_3D_PLUGIN',
      'ENABLE_3D_RENDERING',
      'ENABLE_ACCELERATED_2D_CANVAS',
      'ENABLE_BLOB',
      'ENABLE_BLOB_SLICE',
      'ENABLE_CHANNEL_MESSAGING',
      'ENABLE_CLIENT_BASED_GEOLOCATION',
      'ENABLE_DATA_TRANSFER_ITEMS',
      'ENABLE_DETAILS',
      'ENABLE_DEVICE_ORIENTATION',
      'ENABLE_DIRECTORY_UPLOAD',
      'ENABLE_DOWNLOAD_ATTRIBUTE',
      'ENABLE_FILE_SYSTEM',
      'ENABLE_FILTERS',
      'ENABLE_FULLSCREEN_API',
      'ENABLE_GAMEPAD',
      'ENABLE_GEOLOCATION',
      'ENABLE_GESTURE_EVENTS',
      'ENABLE_GESTURE_RECOGNIZER',
      'ENABLE_INDEXED_DATABASE',
      'ENABLE_INPUT_SPEECH',
      'ENABLE_JAVASCRIPT_DEBUGGER',
      'ENABLE_JAVASCRIPT_I18N_API',
      'ENABLE_LINK_PREFETCH',
      'ENABLE_MEDIA_SOURCE',
      'ENABLE_MEDIA_STATISTICS',
      'ENABLE_MEDIA_STREAM',
      'ENABLE_METER_TAG',
      'ENABLE_MHTML',
      'ENABLE_MOUSE_LOCK_API',
      'ENABLE_MUTATION_OBSERVERS',
      'ENABLE_NOTIFICATIONS',
      'ENABLE_PAGE_VISIBILITY_API',
      'ENABLE_PROGRESS_TAG',
      'ENABLE_QUOTA',
      'ENABLE_REGISTER_PROTOCOL_HANDLER',
      'ENABLE_REQUEST_ANIMATION_FRAME',
      'ENABLE_RUBY',
      'ENABLE_SANDBOX',
      'ENABLE_SCRIPTED_SPEECH',
      'ENABLE_SHADOW_DOM',
      'ENABLE_SHARED_WORKERS',
      'ENABLE_SMOOTH_SCROLLING',
      'ENABLE_SPEECH_RECOGNITION',
      'ENABLE_SQL_DATABASE',
      'ENABLE_SVG',
      'ENABLE_SVG_FONTS',
      'ENABLE_TOUCH_EVENTS',
      'ENABLE_V8_SCRIPT_DEBUG_SERVER',
      'ENABLE_VIDEO',
      'ENABLE_VIDEO_TRACK',
      'ENABLE_WEBGL',
      'ENABLE_WEB_AUDIO',
      'ENABLE_WEB_SOCKETS',
      'ENABLE_WEB_TIMING',
      'ENABLE_WORKERS',
      'ENABLE_XHR_RESPONSE_BLOB',
      'ENABLE_XSLT',
      ]
  webkit_options = databasebuilder.DatabaseBuilderOptions(
      idl_syntax=idlparser.WEBKIT_SYNTAX,
# TODO(vsm): What else should we define as on when processing IDL?
      idl_defines=webkit_defines,
      source='WebKit',
      source_attributes={'revision': webkit_revision},
      type_rename_map={
        # Some of these are typos in the IDL.
        'float': 'double',
        'BarInfo': 'BarProp',
        'DedicatedWorkerContext': 'DedicatedWorkerGlobalScope',
        'DOMApplicationCache': 'ApplicationCache',
        'DOMCoreException': 'DOMException',
        'DOMExceptionJSC': 'DOMException', # Node.replaceChild
        'DomException': 'DOMException',    # Navigator.registerProtocolHandler
        'DOMFormData': 'FormData',
        'DOMObject': 'object',
        'DOMSelection': 'Selection',
        'DOMWindow': 'Window',
        'Exception': 'DOMException',     # NotificationCenter.createNotification
        'SharedWorkerContext': 'SharedWorkerGlobalScope',
        'WorkerContext': 'WorkerGlobalScope',
      })

  optional_argument_whitelist = [
      ('CSSStyleDeclaration', 'setProperty', 'priority'),
      ('IDBDatabase', 'transaction', 'mode'),
      ]

  # Assume Dartium checkout.
  webcore_path = os.path.join(current_dir, '..', '..', '..', '..',
                              'third_party', 'WebKit', 'Source', 'WebCore')

  if not os.path.exists(webcore_path):
    # Fall back to standard Dart checkout.
    webcore_path = os.path.join(current_dir, '..', '..', '..',
                                'third_party', 'WebCore')

  for dir_name in webkit_dirs:
    dir_path = os.path.join(webcore_path, dir_name)
    builder.import_idl_directory(dir_path, webkit_options)

  webkit_supplemental_options = databasebuilder.DatabaseBuilderOptions(
    idl_syntax=idlparser.FREMONTCUT_SYNTAX,
    source='WebKit',
    rename_operation_arguments_on_merge=True)
  builder.import_idl_file(
      os.path.join(current_dir, '..', 'idl', 'dart', 'webkit-supplemental.idl'),
      webkit_supplemental_options)

  # Import Dart idl:
  dart_options = databasebuilder.DatabaseBuilderOptions(
    idl_syntax=idlparser.FREMONTCUT_SYNTAX,
    source='Dart',
    rename_operation_arguments_on_merge=True)

  builder.import_idl_file(
      os.path.join(current_dir, '..', 'idl', 'dart', 'dart.idl'),
      dart_options)

  builder.set_same_signatures({
    'EventListener': 'Function',
    'int': 'long',
  })

  # Merging:
  builder.merge_imported_interfaces(optional_argument_whitelist)

  builder.fix_displacements('WebKit')

  # Cleanup:
  builder.normalize_annotations(['WebKit', 'Dart'])

  db.Save()

if __name__ == '__main__':
  sys.exit(main())
