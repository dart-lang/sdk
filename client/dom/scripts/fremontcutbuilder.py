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
    'css',
    'dom',
    'fileapi',
    'html',
    'html/canvas',
    'inspector',
    'loader',
    'loader/appcache',
    'notifications',
    'page',
    'plugins',
    'storage',
    # TODO(vsm): Fix generator to deal with multiple
    # 'svg',
    # TODO(vsm): Fix parser/idl file to re-enable this.
    #    'webaudio',
    'websockets',
    'workers',
    'xml',
  ]
  # TODO(vsm): Move this to a README.
  # This is the Dart SVN revision.
  webkit_revision = '1060'

  # TODO(vsm): Reconcile what is exposed here and inside WebKit code
  # generation.
  webkit_defines = [
      'LANGUAGE_DART',
      'ENABLE_DOM_STORAGE',
      'ENABLE_NOTIFICATIONS',
      'ENABLE_OFFLINE_WEB_APPLICATIONS',
      'ENABLE_REQUEST_ANIMATION_FRAME',
      'ENABLE_WEB_TIMING',
      ]
  webkit_options = databasebuilder.DatabaseBuilderOptions(
      idl_syntax=idlparser.WEBKIT_SYNTAX,
# TODO(vsm): What else should we define as on when processing IDL?
      idl_defines=webkit_defines,
      source='WebKit',
      source_attributes={'revision': webkit_revision},
      type_rename_map={
        'float': 'double',
        'BarInfo': 'BarProp',
        'DedicatedWorkerContext': 'DedicatedWorkerGlobalScope',
        'DOMApplicationCache': 'ApplicationCache',
        'DOMCoreException': 'DOMException',
        'DOMFormData': 'FormData',
        'DOMObject': 'object',
        'DOMSelection': 'Selection',
        'DOMWindow': 'Window',
        'SharedWorkerContext': 'SharedWorkerGlobalScope',
        'WorkerContext': 'WorkerGlobalScope',
      })

  for dir_name in webkit_dirs:
    dir_path = os.path.join(current_dir, '..', '..', '..', '..',
                'third_party', 'WebKit', 'Source', 'WebCore', dir_name)
    builder.import_idl_directory(dir_path, webkit_options)

  webkit_supplemental_options = databasebuilder.DatabaseBuilderOptions(
    idl_syntax=idlparser.FREMONTCUT_SYNTAX,
    source='WebKit',
    rename_operation_arguments_on_merge=True)
  builder.import_idl_file(
      os.path.join(current_dir, '..', 'idl',
                   'dart', 'webkit-supplemental.idl'),
      webkit_supplemental_options)

  # Import Dart idl:
  dart_options = databasebuilder.DatabaseBuilderOptions(
    idl_syntax=idlparser.FREMONTCUT_SYNTAX,
    source='Dart',
    rename_operation_arguments_on_merge=True)

  builder.import_idl_file(os.path.join(current_dir, '..', 'idl',
                     'dart', 'dart.idl'), dart_options)

  builder.set_same_signatures({
    'EventListener': 'Function',
    'int': 'long',
  })

  # Merging:
  builder.merge_imported_interfaces()

  builder.fix_displacements('WebKit')

  # Cleanup:
  builder.normalize_annotations(['WebKit', 'Dart'])

  db.Save()

if __name__ == '__main__':
  sys.exit(main())
