# Copyright (C) 2013 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""Generate Blink C++ bindings (.h and .cpp files) for use by Dart:HTML.

If run itself, caches Jinja templates (and creates dummy file for build,
since cache filenames are unpredictable and opaque).

This module is *not* concurrency-safe without care: bytecode caching creates
a race condition on cache *write* (crashes if one process tries to read a
partially-written cache). However, if you pre-cache the templates (by running
the module itself), then you can parallelize compiling individual files, since
cache *reading* is safe.

Input: An object of class IdlDefinitions, containing an IDL interface X
Output: DartX.h and DartX.cpp

Design doc: http://www.chromium.org/developers/design-documents/idl-compiler
"""

import os
import cPickle as pickle
import re
import sys


# Path handling for libraries and templates
# Paths have to be normalized because Jinja uses the exact template path to
# determine the hash used in the cache filename, and we need a pre-caching step
# to be concurrency-safe. Use absolute path because __file__ is absolute if
# module is imported, and relative if executed directly.
# If paths differ between pre-caching and individual file compilation, the cache
# is regenerated, which causes a race condition and breaks concurrent build,
# since some compile processes will try to read the partially written cache.
module_path, module_filename = os.path.split(os.path.realpath(__file__))
third_party_dir = os.path.normpath(os.path.join(
    module_path, os.pardir, os.pardir, os.pardir, os.pardir, os.pardir))
templates_dir = os.path.normpath(os.path.join(module_path, 'templates'))

# Make sure extension is .py, not .pyc or .pyo, so doesn't depend on caching
module_pyname = os.path.splitext(module_filename)[0] + '.py'

# jinja2 is in chromium's third_party directory.
# Insert at 1 so at front to override system libraries, and
# after path[0] == invoking script dir
sys.path.insert(1, third_party_dir)

# Add the base compiler scripts to the path here as in compiler.py
dart_script_path = os.path.dirname(os.path.abspath(__file__))
script_path = os.path.join(os.path.dirname(os.path.dirname(dart_script_path)),
                          'scripts')
sys.path.extend([script_path])

import jinja2

import idl_types
from idl_types import IdlType
from utilities import write_pickle_file
from v8_globals import includes, interfaces
from dart_utilities import DartUtilities


# TODO(jacobr): remove this hacked together list.
INTERFACES_WITHOUT_RESOLVERS = frozenset([
    'TypeConversions',
    'GCObservation',
    'InternalProfilers',
    'InternalRuntimeFlags',
    'InternalSettings',
    'InternalSettingsGenerated',
    'Internals',
    'LayerRect',
    'LayerRectList',
    'MallocStatistics',
    'TypeConversions'])

class CodeGeneratorDart(object):
    def __init__(self, interfaces_info, cache_dir):
        interfaces_info = interfaces_info or {}
        self.interfaces_info = interfaces_info
        self.jinja_env = initialize_jinja_env(cache_dir)

        # Set global type info
        idl_types.set_ancestors(dict(
            (interface_name, interface_info['ancestors'])
            for interface_name, interface_info in interfaces_info.iteritems()
            if interface_info['ancestors']))
        IdlType.set_callback_interfaces(set(
            interface_name
            for interface_name, interface_info in interfaces_info.iteritems()
            if interface_info['is_callback_interface']))
        IdlType.set_implemented_as_interfaces(dict(
            (interface_name, interface_info['implemented_as'])
            for interface_name, interface_info in interfaces_info.iteritems()
            if interface_info['implemented_as']))
        IdlType.set_garbage_collected_types(set(
            interface_name
            for interface_name, interface_info in interfaces_info.iteritems()
            if 'GarbageCollected' in interface_info['inherited_extended_attributes']))
        IdlType.set_will_be_garbage_collected_types(set(
            interface_name
            for interface_name, interface_info in interfaces_info.iteritems()
            if 'WillBeGarbageCollected' in interface_info['inherited_extended_attributes']))

    def generate_code(self, definitions, interface_name, idl_pickle_filename,
                      only_if_changed):
        """Returns .h/.cpp code as (header_text, cpp_text)."""
        try:
            interface = definitions.interfaces[interface_name]
        except KeyError:
            raise Exception('%s not in IDL definitions' % interface_name)

        # Store other interfaces for introspection
        interfaces.update(definitions.interfaces)

        # Set local type info
        IdlType.set_callback_functions(definitions.callback_functions.keys())
        IdlType.set_enums((enum.name, enum.values)
                          for enum in definitions.enumerations.values())

        # Select appropriate Jinja template and contents function
        if interface.is_callback:
            header_template_filename = 'callback_interface_h.template'
            cpp_template_filename = 'callback_interface_cpp.template'
            generate_contents = dart_callback_interface.generate_callback_interface
        else:
            header_template_filename = 'interface_h.template'
            cpp_template_filename = 'interface_cpp.template'
            generate_contents = dart_interface.generate_interface
        header_template = self.jinja_env.get_template(header_template_filename)
        cpp_template = self.jinja_env.get_template(cpp_template_filename)

        # Generate contents (input parameters for Jinja)
        template_contents = generate_contents(interface)
        template_contents['code_generator'] = module_pyname

        # Add includes for interface itself and any dependencies
        interface_info = self.interfaces_info[interface_name]
        template_contents['header_includes'].add(interface_info['include_path'])
        template_contents['header_includes'] = sorted(template_contents['header_includes'])
        includes.update(interface_info.get('dependencies_include_paths', []))

        # Remove includes that are not needed for Dart and trigger fatal
        # compile warnings if included. These IDL files need to be
        # imported by Dart to generate the list of events but the
        # associated header files do not contain any code used by Dart.
        includes.discard('core/dom/GlobalEventHandlers.h')
        includes.discard('core/frame/DOMWindowEventHandlers.h')

        template_contents['cpp_includes'] = sorted(includes)

        idl_world = {'interface': None, 'callback': None}

        # Load the pickle file for this IDL.
        if os.path.isfile(idl_pickle_filename):
            with open(idl_pickle_filename) as idl_pickle_file:
                idl_global_data = pickle.load(idl_pickle_file)
                idl_pickle_file.close()
            idl_world['interface'] = idl_global_data['interface']
            idl_world['callback'] = idl_global_data['callback']

        if 'interface_name' in template_contents:
            interface_global = {'name': template_contents['interface_name'],
                                'parent_interface': template_contents['parent_interface'],
                                'is_active_dom_object': template_contents['is_active_dom_object'],
                                'is_event_target': template_contents['is_event_target'],
                                'has_resolver': template_contents['interface_name'] not in INTERFACES_WITHOUT_RESOLVERS,
                                'is_node': template_contents['is_node'],
                                'conditional_string': template_contents['conditional_string'],
                               }
            idl_world['interface'] = interface_global
        else:
            callback_global = {'name': template_contents['cpp_class']}
            idl_world['callback'] = callback_global

        write_pickle_file(idl_pickle_filename,  idl_world, only_if_changed)

        # Render Jinja templates
        header_text = header_template.render(template_contents)
        cpp_text = cpp_template.render(template_contents)
        return header_text, cpp_text

    # Generates global file for all interfaces.
    def generate_globals(self, output_directory):
        header_template_filename = 'global_h.template'
        cpp_template_filename = 'global_cpp.template'

        # Delete the global pickle file we'll rebuild from each pickle generated
        # for each IDL file '(%s_globals.pickle) % interface_name'.
        global_pickle_filename = os.path.join(output_directory, 'global.pickle')
        if os.path.isfile(global_pickle_filename):
            os.remove(global_pickle_filename)

        # List of all interfaces and callbacks for global code generation.
        world = {'interfaces': [], 'callbacks': []}

        # Load all pickled data for each interface.
        listing = os.listdir(output_directory)
        for filename in listing:
            if filename.endswith('_globals.pickle'):
                idl_filename = os.path.join(output_directory, filename)
                with open(idl_filename) as idl_pickle_file:
                    idl_world = pickle.load(idl_pickle_file)
                    if 'interface' in idl_world:
                        # FIXME: Why are some of these None?
                        if idl_world['interface']:
                            world['interfaces'].append(idl_world['interface'])
                    if 'callbacks' in idl_world:
                        # FIXME: Why are some of these None?
                        if idl_world['callbacks']:
                            world['callbacks'].append(idl_world['callback'])
                    idl_pickle_file.close()

        world['interfaces'] = sorted(world['interfaces'], key=lambda (x): x['name'])
        world['callbacks'] = sorted(world['callbacks'], key=lambda (x): x['name'])

        template_contents = world
        template_contents['code_generator'] = module_pyname

        header_template = self.jinja_env.get_template(header_template_filename)
        header_text = header_template.render(template_contents)

        cpp_template = self.jinja_env.get_template(cpp_template_filename)
        cpp_text = cpp_template.render(template_contents)
        return header_text, cpp_text


def initialize_jinja_env(cache_dir):
    jinja_env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(templates_dir),
        # Bytecode cache is not concurrency-safe unless pre-cached:
        # if pre-cached this is read-only, but writing creates a race condition.
        bytecode_cache=jinja2.FileSystemBytecodeCache(cache_dir),
        keep_trailing_newline=True,  # newline-terminate generated files
        lstrip_blocks=True,  # so can indent control flow tags
        trim_blocks=True)
    jinja_env.filters.update({
        'blink_capitalize': DartUtilities.capitalize,
        'conditional': conditional_if_endif,
        'runtime_enabled': runtime_enabled_if,
        })
    return jinja_env


# [Conditional]
def conditional_if_endif(code, conditional_string):
    # Jinja2 filter to generate if/endif directive blocks
    if not conditional_string:
        return code
    return ('#if %s\n' % conditional_string +
            code +
            '#endif // %s\n' % conditional_string)


# [RuntimeEnabled]
def runtime_enabled_if(code, runtime_enabled_function_name):
    if not runtime_enabled_function_name:
        return code
    # Indent if statement to level of original code
    indent = re.match(' *', code).group(0)
    return ('%sif (%s())\n' % (indent, runtime_enabled_function_name) +
            '    %s' % code)


################################################################################

def main(argv):
    # If file itself executed, cache templates
    try:
        cache_dir = argv[1]
        dummy_filename = argv[2]
    except IndexError as err:
        print 'Usage: %s OUTPUT_DIR DUMMY_FILENAME' % argv[0]
        return 1

    # Cache templates
    jinja_env = initialize_jinja_env(cache_dir)
    template_filenames = [filename for filename in os.listdir(templates_dir)
                          # Skip .svn, directories, etc.
                          if filename.endswith(('.cpp', '.h', '.template'))]
    for template_filename in template_filenames:
        jinja_env.get_template(template_filename)

    # Create a dummy file as output for the build system,
    # since filenames of individual cache files are unpredictable and opaque
    # (they are hashes of the template path, which varies based on environment)
    with open(dummy_filename, 'w') as dummy_file:
        pass  # |open| creates or touches the file


if __name__ == '__main__':
    sys.exit(main(sys.argv))
