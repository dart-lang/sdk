#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This is the entry point to create Dart APIs from the IDL database."""

import dartgenerator
import database
import fremontcutbuilder
import logging.config
import multiemitter
import optparse
import os
import shutil
import subprocess
import sys
from generator import TypeRegistry
from htmleventgenerator import HtmlEventGenerator
from htmlrenamer import HtmlRenamer
from systemhtml import DartLibraryEmitter, Dart2JSBackend,\
                       HtmlDartInterfaceGenerator, DartLibrary, DartLibraries
from systemnative import CPPLibraryEmitter, DartiumBackend
from templateloader import TemplateLoader

_logger = logging.getLogger('dartdomgenerator')

_libraries = ['html', 'svg', 'web_audio']

class GeneratorOptions(object):
  def __init__(self, templates, database, type_registry, renamer):
    self.templates = templates
    self.database = database
    self.type_registry = type_registry
    self.renamer = renamer

# TODO(vsm): Remove once we fix Dartium to pass in the database directly.
def Generate(database_dir, use_database_cache, dart2js_output_dir=None,
             dartium_output_dir=None):
  database = LoadDatabase(database_dir, use_database_cache)
  GenerateFromDatabase(database, dart2js_output_dir, dartium_output_dir)

def LoadDatabase(database_dir, use_database_cache):
  common_database = database.Database(database_dir)
  if use_database_cache:
    common_database.LoadFromCache()
  else:
    common_database.Load()
  return common_database

def GenerateFromDatabase(common_database, dart2js_output_dir,
                         dartium_output_dir):
  current_dir = os.path.dirname(__file__)
  auxiliary_dir = os.path.join(current_dir, '..', 'src')
  template_dir = os.path.join(current_dir, '..', 'templates')

  generator = dartgenerator.DartGenerator()
  generator.LoadAuxiliary(auxiliary_dir)

  generator.FilterMembersWithUnidentifiedTypes(common_database)
  webkit_database = common_database.Clone()

  # Generate Dart interfaces for the WebKit DOM.
  generator.FilterInterfaces(database = webkit_database,
                             or_annotations = ['WebKit', 'Dart'],
                             exclude_displaced = ['WebKit'],
                             exclude_suppressed = ['WebKit', 'Dart'])
  generator.FixEventTargets(webkit_database)
  generator.AddMissingArguments(webkit_database)

  emitters = multiemitter.MultiEmitter()
  renamer = HtmlRenamer(webkit_database)
  type_registry = TypeRegistry(webkit_database, renamer)

  def RunGenerator(dart_libraries, dart_output_dir,
                   template_loader, backend_factory):
    options = GeneratorOptions(
        template_loader, webkit_database, type_registry, renamer)
    dart_library_emitter = DartLibraryEmitter(
        emitters, dart_output_dir, dart_libraries)
    event_generator = HtmlEventGenerator(webkit_database, template_loader)

    def generate_interface(interface):
      backend = backend_factory(interface)
      interface_generator = HtmlDartInterfaceGenerator(
          options, dart_library_emitter, event_generator, interface, backend)
      interface_generator.Generate()

    generator.Generate(webkit_database, common_database, generate_interface)

    dart_library_emitter.EmitLibraries(auxiliary_dir)

  if dart2js_output_dir:
    template_paths = ['html/dart2js', 'html/impl', 'html/interface', '']
    template_loader = TemplateLoader(template_dir,
                                     template_paths,
                                     {'DARTIUM': False, 'DART2JS': True})
    backend_options = GeneratorOptions(
        template_loader, webkit_database, type_registry, renamer)
    backend_factory = lambda interface:\
        Dart2JSBackend(interface, backend_options)

    dart_output_dir = os.path.join(dart2js_output_dir, 'dart')
    dart_libraries = DartLibraries(
        _libraries, template_loader, 'dart2js', dart2js_output_dir)

    RunGenerator(dart_libraries, dart_output_dir,
        template_loader, backend_factory)

  if dartium_output_dir:
    template_paths = ['html/dartium', 'html/impl', 'html/interface', '']
    template_loader = TemplateLoader(template_dir,
                                     template_paths,
                                     {'DARTIUM': True, 'DART2JS': False})
    backend_options = GeneratorOptions(
        template_loader, webkit_database, type_registry, renamer)
    cpp_output_dir = os.path.join(dartium_output_dir, 'cpp')
    cpp_library_emitter = CPPLibraryEmitter(emitters, cpp_output_dir)
    backend_factory = lambda interface:\
        DartiumBackend(interface, cpp_library_emitter, backend_options)

    dart_output_dir = os.path.join(dartium_output_dir, 'dart')
    dart_libraries = DartLibraries(
        _libraries, template_loader, 'dartium', dartium_output_dir)

    RunGenerator(dart_libraries, dart_output_dir,
                 template_loader, backend_factory)
    cpp_library_emitter.EmitDerivedSources(
        template_loader.Load('cpp_derived_sources.template'),
        dartium_output_dir)
    cpp_library_emitter.EmitResolver(
        template_loader.Load('cpp_resolver.template'), dartium_output_dir)

  _logger.info('Flush...')
  emitters.Flush()

def GenerateSingleFile(library_path, output_dir, generated_output_dir=None):
  library_dir = os.path.dirname(library_path)
  library_filename = os.path.basename(library_path)
  copy_dart_script = os.path.relpath('../../../../tools/copy_dart.py',
      library_dir)
  output_dir = os.path.relpath(output_dir, library_dir)
  command = ' '.join(['cd', library_dir, ';',
                      copy_dart_script, output_dir, library_filename])
  subprocess.call([command], shell=True)

def main():
  parser = optparse.OptionParser()
  parser.add_option('--parallel', dest='parallel',
                    action='store_true', default=False,
                    help='Use fremontcut in parallel mode.')
  parser.add_option('--rebuild', dest='rebuild',
                    action='store_true', default=False,
                    help='Rebuild the database from IDL using fremontcut.')
  parser.add_option('--systems', dest='systems',
                    action='store', type='string',
                    default='htmldart2js,htmldartium',
                    help='Systems to generate (htmldart2js, htmldartium)')
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

  output_dir = options.output_dir or os.path.join(current_dir, '../generated')

  dart2js_output_dir = None
  if 'htmldart2js' in systems:
    dart2js_output_dir = os.path.join(output_dir, 'dart2js')
  dartium_output_dir = None
  if 'htmldartium' in systems:
    dartium_output_dir = os.path.join(output_dir, 'dartium')

  if options.rebuild:
    # Parse the IDL and create the database.
    database = fremontcutbuilder.main(options.parallel)
  else:
    # Load the previously generated database.
    database = LoadDatabase(database_dir, options.use_database_cache)
  GenerateFromDatabase(database, dart2js_output_dir, dartium_output_dir)

  _logger.info('Add documentation to generated classes.')
  html_to_json_script = os.path.relpath(
      '../../../../tools/html_json_doc/bin/html_json_doc.dart',
      current_dir)
  html_output_dir = os.path.join(output_dir, 'dart2js/dart/html/')
  svg_output_dir = os.path.join(output_dir, 'dart2js/dart/svg/')
  html_json_path = os.path.relpath('../docs/html_docs.json')
  svg_json_path = os.path.relpath('../docs/svg_docs.json')
  html_command = ' '.join(['dart', html_to_json_script, '--mode=json-to-html',
                      html_output_dir, html_json_path])
  svg_command = ' '.join(['dart', html_to_json_script, '--mode=json-to-html',
                      svg_output_dir, svg_json_path])
  subprocess.call([html_command], shell=True)
  subprocess.call([svg_command], shell=True)

  if 'htmldart2js' in systems:
    _logger.info('Generating dart2js single files.')
    for library_name in _libraries:
      GenerateSingleFile(
          os.path.join(dart2js_output_dir, '%s_dart2js.dart' % library_name),
          '../../%s/dart2js' % library_name)
  if 'htmldartium' in systems:
    _logger.info('Generating dartium single files.')
    for library_name in _libraries:
      GenerateSingleFile(
          os.path.join(dartium_output_dir, '%s_dartium.dart' % library_name),
          '../../%s/dartium' % library_name)

if __name__ == '__main__':
  sys.exit(main())
