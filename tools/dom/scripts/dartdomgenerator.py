#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This is the entry point to create Dart APIs from the IDL database."""

import css_code_generator
import os
import sys

# Setup all paths to find our PYTHON code

# dart_dir is the location of dart's enlistment dartium (dartium-git/src/dart)
# and Dart (dart-git/dart).
dart_dir = os.path.abspath(os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..', '..')))
sys.path.insert(1, os.path.join(dart_dir, 'tools/dom/new_scripts'))
sys.path.insert(1, os.path.join(dart_dir, 'third_party/WebCore/bindings/scripts'))

# Dartium's third_party directory location is dartium-git/src/third_party
# and Dart's third_party directory location is dart-git/dart/third_party.
third_party_dir = os.path.join(dart_dir, 'third_party')

ply_dir = os.path.join(third_party_dir, 'ply')
# If ply directory found then we're a Dart enlistment; third_party location
# is dart-git/dart/third_party
if not os.path.exists(ply_dir):
  # For Dartium (ply directory is dartium-git/src/third_party/ply) third_party
  # location is dartium-git/src/third_party
  third_party_dir = os.path.join(dart_dir, '..', 'third_party')
  assert(os.path.exists(third_party_dir))
else:
  # It's Dart we need to make sure that tools in injected in our search path
  # because this is where idl_parser is located for a Dart enlistment.  Dartium
  # can figure out the tools directory because of the location of where the
  # scripts blink scripts are located.
  tools_dir = os.path.join(dart_dir, 'tools')
  sys.path.insert(1, tools_dir)

sys.path.insert(1, third_party_dir)

sys.path.insert(1, os.path.join(dart_dir, 'tools/dom/scripts'))

import dartgenerator
import database
import fremontcutbuilder
import logging
import monitored
import multiemitter
import optparse
import shutil
import subprocess
import time
from dartmetadata import DartMetadata
from generator import TypeRegistry
from generate_blink_file import Generate_Blink
from htmleventgenerator import HtmlEventGenerator
from htmlrenamer import HtmlRenamer
from systemhtml import DartLibraryEmitter, Dart2JSBackend,\
                       HtmlDartInterfaceGenerator, DartLibrary, DartLibraries,\
                       HTML_LIBRARY_NAMES
from systemnative import CPPLibraryEmitter, DartiumBackend
from templateloader import TemplateLoader

sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))

import utils


_logger = logging.getLogger('dartdomgenerator')

class GeneratorOptions(object):
  def __init__(self, templates, database, type_registry, renamer,
      metadata, dart_js_interop):
    self.templates = templates
    self.database = database
    self.type_registry = type_registry
    self.renamer = renamer
    self.metadata = metadata;
    self.dart_js_interop = dart_js_interop

def LoadDatabase(database_dir, use_database_cache):
  common_database = database.Database(database_dir)
  if use_database_cache:
    common_database.LoadFromCache()
  else:
    common_database.Load()
  return common_database

def GenerateFromDatabase(common_database,
                         dart2js_output_dir, dartium_output_dir, blink_output_dir,
                         update_dom_metadata=False,
                         logging_level=logging.WARNING, dart_js_interop=False):
  print '\n ----- Accessing DOM using %s -----\n' % ('dart:js' if dart_js_interop else 'C++')

  start_time = time.time()

  current_dir = os.path.dirname(__file__)
  auxiliary_dir = os.path.join(current_dir, '..', 'src')
  template_dir = os.path.join(current_dir, '..', 'templates')

  _logger.setLevel(logging_level)

  generator = dartgenerator.DartGenerator(logging_level)
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
  generator.CleanupOperationArguments(webkit_database)

  emitters = multiemitter.MultiEmitter(logging_level)
  metadata = DartMetadata(
      os.path.join(current_dir, '..', 'dom.json'),
      os.path.join(current_dir, '..', 'docs', 'docs.json'),
      logging_level)
  renamer = HtmlRenamer(webkit_database, metadata)
  type_registry = TypeRegistry(webkit_database, renamer)

  print 'GenerateFromDatabase %s seconds' % round((time.time() - start_time), 2)

  def RunGenerator(dart_libraries, dart_output_dir,
                   template_loader, backend_factory, dart_js_interop):
    options = GeneratorOptions(
        template_loader, webkit_database, type_registry, renamer,
        metadata, dart_js_interop)
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

    dart_library_emitter.EmitLibraries(auxiliary_dir, dart_js_interop)

  if dart2js_output_dir:
    template_paths = ['html/dart2js', 'html/impl', 'html/interface', '']
    template_loader = TemplateLoader(template_dir,
                                     template_paths,
                                     {'DARTIUM': False,
                                      'DART2JS': True,
                                      'JSINTEROP': False})
    backend_options = GeneratorOptions(
        template_loader, webkit_database, type_registry, renamer,
        metadata, dart_js_interop)
    backend_factory = lambda interface:\
        Dart2JSBackend(interface, backend_options, logging_level)

    dart_output_dir = os.path.join(dart2js_output_dir, 'dart')
    dart_libraries = DartLibraries(
        HTML_LIBRARY_NAMES, template_loader, 'dart2js', dart2js_output_dir, dart_js_interop)

    print '\nGenerating dart2js:\n'
    start_time = time.time()

    RunGenerator(dart_libraries, dart_output_dir, template_loader,
                 backend_factory, dart_js_interop)

    print 'Generated dart2js in %s seconds' % round(time.time() - start_time, 2)

  if dartium_output_dir:
    template_paths = ['html/dartium', 'html/impl', 'html/interface', '']
    template_loader = TemplateLoader(template_dir,
                                     template_paths,
                                     {'DARTIUM': True,
                                      'DART2JS': False,
                                      'JSINTEROP': dart_js_interop})
    backend_options = GeneratorOptions(
        template_loader, webkit_database, type_registry, renamer,
        metadata, dart_js_interop)
    cpp_output_dir = os.path.join(dartium_output_dir, 'cpp')
    cpp_library_emitter = CPPLibraryEmitter(emitters, cpp_output_dir)
    dart_output_dir = os.path.join(dartium_output_dir, 'dart')
    backend_factory = lambda interface:\
        DartiumBackend(interface, cpp_library_emitter, backend_options, _logger)
    dart_libraries = DartLibraries(
        HTML_LIBRARY_NAMES, template_loader, 'dartium', dartium_output_dir, dart_js_interop)

    print '\nGenerating dartium:\n'
    start_time = time.time()

    RunGenerator(dart_libraries, dart_output_dir, template_loader,
                 backend_factory, dart_js_interop)
    print 'Generated dartium in %s seconds' % round(time.time() - start_time, 2)

    cpp_library_emitter.EmitDerivedSources(
        template_loader.Load('cpp_derived_sources.template'),
        dartium_output_dir)
    cpp_library_emitter.EmitResolver(
        template_loader.Load('cpp_resolver.template'), dartium_output_dir)
    cpp_library_emitter.EmitClassIdTable(
        webkit_database, dartium_output_dir, type_registry, renamer)
    emitters.Flush()

  if blink_output_dir:
    print '\nGenerating _blink:\n'
    start_time = time.time()

    Generate_Blink(blink_output_dir, webkit_database, type_registry)

    print 'Generated _blink in %s seconds' % round(time.time() - start_time, 2)

  if update_dom_metadata:
    metadata.Flush()

  monitored.FinishMonitoring(dart2js_output_dir, _logger)

def GenerateSingleFile(library_path, output_dir, generated_output_dir=None):
  library_dir = os.path.dirname(library_path)
  library_filename = os.path.basename(library_path)
  copy_dart_script = os.path.relpath('../../copy_dart.py',
      library_dir)
  output_dir = os.path.relpath(output_dir, library_dir)
  command = ' '.join(['cd', library_dir, ';',
                      copy_dart_script, output_dir, library_filename])
  subprocess.call([command], shell=True)
  prebuilt_dartfmt = os.path.join(utils.CheckedInSdkPath(), 'bin', 'dartfmt')
  sdk_file = os.path.join(library_dir, output_dir, library_filename)
  formatCommand = ' '.join([prebuilt_dartfmt, '-w', sdk_file])
  subprocess.call([formatCommand], shell=True)

def UpdateCssProperties():
  """Regenerate the CssStyleDeclaration template file with the current CSS
  properties."""
  _logger.info('Updating Css Properties.')
  css_code_generator.GenerateCssTemplateFile()

CACHED_PATCHES = """
// START_OF_CACHED_PATCHES
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT GENERATED FILE.

library cached_patches;

var cached_patches = {
    /********************************************************
     *****                                              *****
     *****  MUST RUN tools/dartium/generate_patches.sh  *****
     *****                                              *****
     ********************************************************/
};
"""

def main():
  parser = optparse.OptionParser()
  parser.add_option('--parallel', dest='parallel',
                    action='store_true', default=False,
                    help='Use fremontcut in parallel mode.')
  parser.add_option('--systems', dest='systems',
                    action='store', type='string',
                    default='htmldart2js,htmldartium,_blink',
                    help='Systems to generate (htmldart2js, htmldartium, _blink)')
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
  parser.add_option('--verbose', dest='logging_level',
                    action='store_false', default=logging.WARNING,
                    help='Output all informational messages')
  parser.add_option('--examine', dest='examine_idls',
                    action='store_true', default=None,
                    help='Analyze IDL files')
  parser.add_option('--logging', dest='logging', type='int',
                    action='store', default=logging.NOTSET,
                    help='Level of logging 20 is Info, 30 is Warnings, 40 is Errors')
  parser.add_option('--gen-interop', dest='dart_js_interop',
                    action='store_true', default=False,
                    help='Use Javascript objects (dart:js) accessing the DOM in _blink')
  parser.add_option('--no-cached-patches', dest='no_cached_patches',
                    action='store_true', default=False,
                    help='Do not generate the sdk/lib/js/cached_patches.dart file')

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
  blink_output_dir = None
  if '_blink' in systems:
    blink_output_dir = os.path.join(output_dir, 'dartium')

  logging_level = options.logging_level \
    if options.logging == logging.NOTSET else options.logging

  start_time = time.time()

  UpdateCssProperties()

  # Parse the IDL and create the database.
  database = fremontcutbuilder.main(options.parallel, logging_level=logging_level, examine_idls=options.examine_idls)

  GenerateFromDatabase(database,
                       dart2js_output_dir,
                       dartium_output_dir,
                       blink_output_dir,
                       options.update_dom_metadata,
                       logging_level,
                       options.dart_js_interop)

  file_generation_start_time = time.time()

  if 'htmldart2js' in systems:
    _logger.info('Generating dart2js single files.')

    for library_name in HTML_LIBRARY_NAMES:
      GenerateSingleFile(
          os.path.join(dart2js_output_dir, '%s_dart2js.dart' % library_name),
          os.path.join('..', '..', '..', 'sdk', 'lib', library_name, 'dart2js'))

  if 'htmldartium' in systems:
    _logger.info('Generating dartium single files.')
    file_generation_start_time = time.time()

    for library_name in HTML_LIBRARY_NAMES:
      GenerateSingleFile(
          os.path.join(dartium_output_dir, '%s_dartium.dart' % library_name),
          os.path.join('..', '..', '..', 'sdk', 'lib', library_name, 'dartium'))

    if (not(options.no_cached_patches)):
      # Blow away the cached_patches.dart needs to be re-generated for Dartium
      # see tools/dartium/generate_patches.sh
      cached_patches_filename = os.path.join('..', '..', '..', 'sdk', 'lib', 'js', 'dartium',
                                             'cached_patches.dart')
      cached_patches = open(cached_patches_filename, 'w')
      cached_patches.write(CACHED_PATCHES);
      cached_patches.close()

  if '_blink' in systems:
    _logger.info('Generating dartium _blink file.')
    file_generation_start_time = time.time()

    GenerateSingleFile(
        os.path.join(dartium_output_dir, '%s_dartium.dart' % '_blink'),
        os.path.join('..', '..', '..', 'sdk', 'lib', '_blink', 'dartium'))

  print '\nGenerating single file %s seconds' % round(time.time() - file_generation_start_time, 2)

  end_time = time.time()

  print '\nDone (dartdomgenerator) %s seconds' % round(end_time - start_time, 2)

if __name__ == '__main__':
  sys.exit(main())
