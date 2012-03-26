#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This is the entry point to create Dart APIs from the IDL database."""

import dartgenerator
import database
import logging.config
import optparse
import os
import shutil
import subprocess
import sys

_logger = logging.getLogger('dartdomgenerator')

_webkit_renames = {
    # W3C -> WebKit name conversion
    # TODO(vsm): Maybe Store these renames in the IDLs.
    'ApplicationCache': 'DOMApplicationCache',
    'BarProp': 'BarInfo',
    'DedicatedWorkerGlobalScope': 'DedicatedWorkerContext',
    'FormData': 'DOMFormData',
    'Selection': 'DOMSelection',
    'SharedWorkerGlobalScope': 'SharedWorkerContext',
    'Window': 'DOMWindow',
    'WorkerGlobalScope': 'WorkerContext'}

_html_strip_webkit_prefix_classes = [
    'Animation',
    'AnimationEvent',
    'AnimationList',
    'BlobBuilder',
    'CSSKeyframeRule',
    'CSSKeyframesRule',
    'CSSMatrix',
    'CSSTransformValue',
    'Flags',
    'LoseContext',
    'Point',
    'TransitionEvent']

def HasAncestor(interface, names_to_match, database):
  for parent in interface.parents:
    if (parent.type.id in names_to_match or
        (database.HasInterface(parent.type.id) and
        HasAncestor(database.GetInterface(parent.type.id), names_to_match,
            database))):
      return True
  return False

def _MakeHtmlRenames(common_database):
  html_renames = {}

  for interface in common_database.GetInterfaces():
    if (interface.id.startswith("HTML") and
        HasAncestor(interface, ['Element', 'Document'], common_database)):
      html_renames[interface.id] = interface.id[4:]

  for subclass in _html_strip_webkit_prefix_classes:
    html_renames['WebKit' + subclass] = subclass

  # TODO(jacobr): we almost want to add this commented out line back.
  #    html_renames['HTMLCollection'] = 'ElementList'
  #    html_renames['NodeList'] = 'ElementList'
  #    html_renames['HTMLOptionsCollection'] = 'ElementList'
  html_renames['DOMWindow'] = 'Window'

  return html_renames

def GenerateDOM(systems, generate_html_systems, output_dir, use_database_cache):
  current_dir = os.path.dirname(__file__)

  generator = dartgenerator.DartGenerator(
      auxiliary_dir=os.path.join(current_dir, '..', 'src'),
      template_dir=os.path.join(current_dir, '..', 'templates'),
      base_package='')
  generator.LoadAuxiliary()

  common_database = database.Database(
      os.path.join(current_dir, '..', 'database'))
  if use_database_cache:
    common_database.LoadFromCache()
  else:
    common_database.Load()
  # Remove these types since they are mapped directly to dart.
  common_database.DeleteInterface('DOMStringMap')
  common_database.DeleteInterface('DOMStringList')

  generator.RenameTypes(common_database, {
      # W3C -> Dart renames
      'AbstractView': 'Window',
      'Function': 'EventListener',
      'DOMStringMap': 'Map<String, String>',
      'DOMStringList': 'List<String>',
      }, False)
  generator.FilterMembersWithUnidentifiedTypes(common_database)
  webkit_database = common_database.Clone()

  # Generate Dart interfaces for the WebKit DOM.
  generator.FilterInterfaces(database = webkit_database,
                             or_annotations = ['WebKit', 'Dart'],
                             exclude_displaced = ['WebKit'],
                             exclude_suppressed = ['WebKit', 'Dart'])
  generator.RenameTypes(webkit_database, _webkit_renames, False)

  if generate_html_systems:
    html_renames = _MakeHtmlRenames(common_database)
    generator.RenameTypes(webkit_database, html_renames, True)
    html_renames_inverse = dict((v,k) for k, v in html_renames.iteritems())
  else:
    html_renames_inverse = {}

  webkit_renames_inverse = dict((v,k) for k, v in _webkit_renames.iteritems())

  generator.Generate(database = webkit_database,
                     output_dir = output_dir,
                     lib_dir = output_dir,
                     module_source_preference = ['WebKit', 'Dart'],
                     source_filter = ['WebKit', 'Dart'],
                     super_database = common_database,
                     common_prefix = 'common',
                     super_map = webkit_renames_inverse,
                     html_map = html_renames_inverse,
                     systems = systems)

  generator.Flush()

  if 'frog' in systems:
    _logger.info('Copy dom_frog to frog/')
    subprocess.call(['cd ../generated ; '
                     '../../../client/tools/copy_dart.py ../frog dom_frog.dart'],
                    shell=True);

  if 'htmlfrog' in systems:
    _logger.info('Copy html_frog to ../html/frog/')
    subprocess.call(['cd ../../html/generated ; '
                     '../../../client/tools/copy_dart.py ../frog html_frog.dart'],
                    shell=True);

  if 'htmldartium' in systems:
    _logger.info('Copy html_dartium to ../html/dartium/')
    subprocess.call(['cd ../../html/generated ; '
                     '../../../client/tools/copy_dart.py ../dartium html_dartium.dart'],
                    shell=True);

  # Copy dummy DOM where dartc build expects it.
  if 'dummy' in systems:
    _logger.info('Copy dom_dummy to dom.dart')
    subprocess.call(['cd ../generated ; '
                     '../../../client/tools/copy_dart.py dummy dom_dummy.dart ;'
                     'cp dummy/dom_dummy.dart ../dom.dart'],
                    shell=True);

def main():
  parser = optparse.OptionParser()
  parser.add_option('--systems', dest='systems',
                    action='store', type='string',
                    default='frog,dummy,wrapping,htmlfrog,htmldartium',
                    help='Systems to generate (frog, native, dummy, '
                         'htmlfrog, htmldartium)')
  parser.add_option('--output-dir', dest='output_dir',
                    action='store', type='string',
                    default=None,
                    help='Directory to put the generated files')
  parser.add_option('--use-database-cache', dest='use_database_cache',
                    action='store_true',
                    default=False,
                    help='''Use the cached database from the previous run to
                    improve startup performance''')
  (options, args) = parser.parse_args()

  current_dir = os.path.dirname(__file__)
  systems = options.systems.split(',')
  html_system_names = ['htmldartium', 'htmlfrog']
  html_systems = [s for s in systems if s in html_system_names]
  dom_systems = [s for s in systems if s not in html_system_names]

  use_database_cache = options.use_database_cache
  logging.config.fileConfig(os.path.join(current_dir, 'logging.conf'))

  if dom_systems:
    output_dir = options.output_dir or os.path.join(current_dir,
        '../generated')
    GenerateDOM(dom_systems, False, output_dir, use_database_cache)

  if html_systems:
    output_dir = options.output_dir or os.path.join(current_dir,
        '../../html/generated')
    GenerateDOM(html_systems, True, output_dir, use_database_cache or dom_systems)

if __name__ == '__main__':
  sys.exit(main())
