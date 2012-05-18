#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This is the entry point to create Dart APIs from the IDL database."""

import dartgenerator
import database
import logging.config
import multiemitter
import optparse
import os
import shutil
import subprocess
import sys
from systemfrog import FrogSystem
from systemhtml import HtmlInterfacesSystem, HtmlFrogSystem, HtmlDartiumSystem
from systeminterface import InterfacesSystem
from systemnative import NativeImplementationSystem
from templateloader import TemplateLoader

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

def Generate(systems, database_dir, use_database_cache, dom_output_dir,
             html_output_dir):
  current_dir = os.path.dirname(__file__)
  auxiliary_dir = os.path.join(current_dir, '..', 'src')
  template_dir = os.path.join(current_dir, '..', 'templates')

  generator = dartgenerator.DartGenerator()
  generator.LoadAuxiliary(auxiliary_dir)

  common_database = database.Database(database_dir)
  if use_database_cache:
    common_database.LoadFromCache()
  else:
    common_database.Load()

  generator.FilterMembersWithUnidentifiedTypes(common_database)
  dom_database = common_database.Clone()

  # Generate Dart interfaces for the WebKit DOM.
  generator.FilterInterfaces(database = dom_database,
                             or_annotations = ['WebKit', 'Dart'],
                             exclude_displaced = ['WebKit'],
                             exclude_suppressed = ['WebKit', 'Dart'])
  generator.RenameTypes(dom_database, _webkit_renames, True)
  generator.FixEventTargets(dom_database)

  emitters = multiemitter.MultiEmitter()
  html_renames = _MakeHtmlRenames(common_database)

  html_database = None
  if set(systems) & set(['htmlfrog', 'htmldartium']):
    html_database = dom_database.Clone()
    generator.RenameTypes(html_database, html_renames, False)

  for system in systems:
    if system in ['htmlfrog', 'htmldartium']:
      target_database = html_database
      output_dir = html_output_dir
      interface_system = HtmlInterfacesSystem(
          TemplateLoader(template_dir, ['html/interface', 'html', '']),
          target_database, emitters, output_dir)
    else:
      target_database = dom_database
      output_dir = dom_output_dir
      interface_system = InterfacesSystem(
          TemplateLoader(template_dir, ['dom/interface', 'dom', '']),
          target_database, emitters, output_dir)

    if system == 'dummy':
      implementation_system = dartgenerator.DummyImplementationSystem(
          TemplateLoader(template_dir, ['dom/dummy', 'dom', '']),
          target_database, emitters, output_dir)
    elif system == 'frog':
      implementation_system = FrogSystem(
          TemplateLoader(template_dir, ['dom/frog', 'dom', '']),
          target_database, emitters, output_dir)
    elif system == 'htmlfrog':
      implementation_system = HtmlFrogSystem(
          TemplateLoader(template_dir,
                         ['html/frog', 'html/impl', 'html', ''],
                         {'DARTIUM': False, 'FROG': True}),
          target_database, emitters, output_dir)
    elif system == 'htmldartium':
      implementation_system = HtmlDartiumSystem(
          TemplateLoader(template_dir,
                         ['html/dartium', 'html/impl', 'html', ''],
                         {'DARTIUM': True, 'FROG': False}),
          target_database, emitters, auxiliary_dir,
          output_dir)
    elif system == 'native':
      implementation_system = NativeImplementationSystem(
          TemplateLoader(template_dir, ['dom/native', 'dom', '']),
          target_database, html_renames, emitters, auxiliary_dir,
          output_dir)
    else:
      raise Exception('Unsupported system %s' % system_name)

    # Makes interface files available for listing in the library for the
    # implementation system.
    implementation_system._interface_system = interface_system

    for system in [interface_system, implementation_system]:
      generator.Generate(target_database, system,
                         source_filter=['WebKit', 'Dart'],
                         super_database=common_database,
                         common_prefix='common',
                         webkit_renames=_webkit_renames,
                         html_renames=html_renames)

  _logger.info('Flush...')
  emitters.Flush()

  if 'frog' in systems:
    _logger.info('Copy dom_frog to frog/')
    subprocess.call(['cd ../generated ; '
                     '../../../tools/copy_dart.py ../frog dom_frog.dart'],
                    shell=True);

  if 'htmlfrog' in systems:
    _logger.info('Copy html_frog to ../html/frog/')
    subprocess.call(['cd ../../html/generated ; '
                     '../../../tools/copy_dart.py ../frog html_frog.dart'],
                    shell=True);

  if 'htmldartium' in systems:
    _logger.info('Copy html_dartium to ../html/dartium/')
    subprocess.call(['cd ../../html/generated ; '
                     '../../../tools/copy_dart.py ../dartium html_dartium.dart'],
                    shell=True);

  # Copy dummy DOM where dartc build expects it.
  if 'dummy' in systems:
    _logger.info('Copy dom_dummy to dom.dart')
    subprocess.call(['cd ../generated ; '
                     '../../../tools/copy_dart.py dummy dom_dummy.dart ;'
                     'cp dummy/dom_dummy.dart ../dom.dart'],
                    shell=True);

def main():
  parser = optparse.OptionParser()
  parser.add_option('--systems', dest='systems',
                    action='store', type='string',
                    default='frog,dummy,htmlfrog,htmldartium',
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
  database_dir = os.path.join(current_dir, '..', 'database')
  logging.config.fileConfig(os.path.join(current_dir, 'logging.conf'))
  systems = options.systems.split(',')

  dom_output_dir = options.output_dir or os.path.join(current_dir,
      '../generated')
  html_output_dir = options.output_dir or os.path.join(current_dir,
      '../../html/generated')
  Generate(systems, database_dir, options.use_database_cache,
              dom_output_dir, html_output_dir)

if __name__ == '__main__':
  sys.exit(main())
