#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This is the entry point to create Dart APIs from the IDL database."""

import css_code_generator
import dartgenerator
import database
import fremontcutbuilder
import logging
import monitored
import multiemitter
import optparse
import os
import shutil
import subprocess
import sys
from dartmetadata import DartMetadata
from generator import TypeRegistry
from htmleventgenerator import HtmlEventGenerator
from htmlrenamer import HtmlRenamer
from systemhtml import DartLibraryEmitter, Dart2JSBackend,\
                       HtmlDartInterfaceGenerator, DartLibrary, DartLibraries,\
                       HTML_LIBRARY_NAMES
from systemnative import CPPLibraryEmitter, DartiumBackend, \
                         GetNativeLibraryEmitter
from templateloader import TemplateLoader

sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))
import utils

_logger = logging.getLogger('dartdomgenerator')

class GeneratorOptions(object):
  def __init__(self, templates, database, type_registry, renamer,
      metadata):
    self.templates = templates
    self.database = database
    self.type_registry = type_registry
    self.renamer = renamer
    self.metadata = metadata;

def LoadDatabase(database_dir, use_database_cache):
  common_database = database.Database(database_dir)
  if use_database_cache:
    common_database.LoadFromCache()
  else:
    common_database.Load()
  return common_database

def GenerateFromDatabase(common_database, dart2js_output_dir,
                         dartium_output_dir, update_dom_metadata=False):
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
  metadata = DartMetadata(
      os.path.join(current_dir, '..', 'dom.json'),
      os.path.join(current_dir, '..', 'docs', 'docs.json'))
  renamer = HtmlRenamer(webkit_database, metadata)
  type_registry = TypeRegistry(webkit_database, renamer)

  def RunGenerator(dart_libraries, dart_output_dir,
                   template_loader, backend_factory):
    options = GeneratorOptions(
        template_loader, webkit_database, type_registry, renamer,
        metadata)
    dart_library_emitter = DartLibraryEmitter(
        emitters, dart_output_dir, dart_libraries)
    event_generator = HtmlEventGenerator(webkit_database, renamer, metadata,
        template_loader)

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
        template_loader, webkit_database, type_registry, renamer,
        metadata)
    backend_factory = lambda interface:\
        Dart2JSBackend(interface, backend_options)

    dart_output_dir = os.path.join(dart2js_output_dir, 'dart')
    dart_libraries = DartLibraries(
        HTML_LIBRARY_NAMES, template_loader, 'dart2js', dart2js_output_dir)

    RunGenerator(dart_libraries, dart_output_dir,
        template_loader, backend_factory)

  if dartium_output_dir:
    template_paths = ['html/dartium', 'html/impl', 'html/interface', '']
    template_loader = TemplateLoader(template_dir,
                                     template_paths,
                                     {'DARTIUM': True, 'DART2JS': False})
    backend_options = GeneratorOptions(
        template_loader, webkit_database, type_registry, renamer,
        metadata)
    cpp_output_dir = os.path.join(dartium_output_dir, 'cpp')
    cpp_library_emitter = CPPLibraryEmitter(emitters, cpp_output_dir)
    dart_output_dir = os.path.join(dartium_output_dir, 'dart')
    native_library_emitter = \
        GetNativeLibraryEmitter(emitters, template_loader,
                                dartium_output_dir, dart_output_dir,
                                auxiliary_dir)
    backend_factory = lambda interface:\
        DartiumBackend(interface, native_library_emitter,
                       cpp_library_emitter, backend_options)
    dart_libraries = DartLibraries(
        HTML_LIBRARY_NAMES, template_loader, 'dartium', dartium_output_dir)
    RunGenerator(dart_libraries, dart_output_dir,
                 template_loader, backend_factory)
    cpp_library_emitter.EmitDerivedSources(
        template_loader.Load('cpp_derived_sources.template'),
        dartium_output_dir)
    cpp_library_emitter.EmitResolver(
        template_loader.Load('cpp_resolver.template'), dartium_output_dir)
    cpp_library_emitter.EmitClassIdTable(
        webkit_database, dartium_output_dir, type_registry, renamer)
    emitters.Flush()

  if update_dom_metadata:
    metadata.Flush()

  monitored.FinishMonitoring(dart2js_output_dir)

def GenerateSingleFile(library_path, output_dir, generated_output_dir=None):
  library_dir = os.path.dirname(library_path)
  library_filename = os.path.basename(library_path)
  copy_dart_script = os.path.relpath('../../copy_dart.py',
      library_dir)
  output_dir = os.path.relpath(output_dir, library_dir)
  command = ' '.join(['cd', library_dir, ';',
                      copy_dart_script, output_dir, library_filename])
  subprocess.call([command], shell=True)

def UpdateCssProperties():
  """Regenerate the CssStyleDeclaration template file with the current CSS
  properties."""
  _logger.info('Updating Css Properties.')
  css_code_generator.GenerateCssTemplateFile()

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
  parser.add_option('--update-dom-metadata', dest='update_dom_metadata',
                    action='store_true',
                    default=False,
                    help='''Update the metadata list of DOM APIs''')
  (options, args) = parser.parse_args()

  current_dir = os.path.dirname(__file__)
  database_dir = os.path.join(current_dir, '..', 'database')
  logging.config.fileConfig(os.path.join(current_dir, 'logging.conf'))
  systems = options.systems.split(',')

  output_dir = options.output_dir or os.path.join(
      current_dir, '..', '..', utils.GetBuildDir(utils.GuessOS()),
      'generated')

  dart2js_output_dir = None
  if 'htmldart2js' in systems:
    dart2js_output_dir = os.path.join(output_dir, 'dart2js')
  dartium_output_dir = None
  if 'htmldartium' in systems:
    dartium_output_dir = os.path.join(output_dir, 'dartium')

  UpdateCssProperties()
  if options.rebuild:
    # Parse the IDL and create the database.
    database = fremontcutbuilder.main(options.parallel)
  else:
    # Load the previously generated database.
    database = LoadDatabase(database_dir, options.use_database_cache)
  GenerateFromDatabase(database, dart2js_output_dir, dartium_output_dir,
      options.update_dom_metadata)

  if 'htmldart2js' in systems:
    _logger.info('Generating dart2js single files.')
    for library_name in HTML_LIBRARY_NAMES:
      GenerateSingleFile(
          os.path.join(dart2js_output_dir, '%s_dart2js.dart' % library_name),
          os.path.join('..', '..', '..', 'sdk', 'lib', library_name, 'dart2js'))
  if 'htmldartium' in systems:
    _logger.info('Generating dartium single files.')
    for library_name in HTML_LIBRARY_NAMES:
      GenerateSingleFile(
          os.path.join(dartium_output_dir, '%s_dartium.dart' % library_name),
          os.path.join('..', '..', '..', 'sdk', 'lib', library_name, 'dartium'))
    GenerateSingleFile(
        os.path.join(dartium_output_dir, '_blink_dartium.dart'),
        os.path.join('..', '..', '..', 'sdk', 'lib', '_blink', 'dartium'))

if __name__ == '__main__':
  sys.exit(main())
