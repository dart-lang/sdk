#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides base functionality for systems to generate
Dart APIs from the IDL database."""

import os
#import re
import generator

def MassagePath(path):
  # The most robust way to emit path separators is to use / always.
  return path.replace('\\', '/')

class System(object):
  """A System generates all the files for one implementation.

  This is a base class for all the specific systems.
  The life-cycle of a System is:
  - construction (__init__)
  - (InterfaceGenerator | ProcessCallback)*  # for each IDL interface
  - GenerateLibraries
  - Finish
  """

  def __init__(self, templates, database, emitters, output_dir):
    self._templates = templates
    self._database = database
    self._emitters = emitters
    self._output_dir = output_dir
    self._dart_callback_file_paths = []

  def InterfaceGenerator(self,
                         interface,
                         common_prefix,
                         super_interface_name,
                         source_filter):
    """Returns an interface generator for |interface|.

    Called once for each interface that is not a callback function.
    """
    return None

  def ProcessCallback(self, interface, info):
    """Processes an interface that is a callback function."""
    pass

  def GenerateLibraries(self, lib_dir):
    pass

  def Finish(self):
    pass


  # Helper methods used by several systems.

  def _ProcessCallback(self, interface, info, file_path):
    """Generates a typedef for the callback interface."""
    self._dart_callback_file_paths.append(file_path)
    code = self._emitters.FileEmitter(file_path)

    code.Emit(self._templates.Load('callback.darttemplate'))
    code.Emit('typedef $TYPE $NAME($PARAMS);\n',
              NAME=interface.id,
              TYPE=info.type_name,
              PARAMS=info.ParametersImplementationDeclaration())


  def _GenerateLibFile(self, lib_template, lib_file_path, file_paths,
                       **template_args):
    """Generates a lib file from a template and a list of files.

    Additional keyword arguments are passed to the template.
    Typically called from self.GenerateLibraries.
    """
    # Load template.
    template = self._templates.Load(lib_template)
    # Generate the .lib file.
    lib_file_contents = self._emitters.FileEmitter(lib_file_path)

    # Emit the list of #source directives.
    list_emitter = lib_file_contents.Emit(template, **template_args)
    lib_file_dir = os.path.dirname(lib_file_path)
    for path in sorted(file_paths):
      relpath = os.path.relpath(path, lib_file_dir)
      list_emitter.Emit("#source('$PATH');\n", PATH=MassagePath(relpath))


  def _BaseDefines(self, interface):
    """Returns a set of names (strings) for members defined in a base class.
    """
    def WalkParentChain(interface):
      if interface.parents:
        # Only consider primary parent, secondary parents are not on the
        # implementation class inheritance chain.
        parent = interface.parents[0]
        if generator.IsDartCollectionType(parent.type.id):
          return
        if self._database.HasInterface(parent.type.id):
          parent_interface = self._database.GetInterface(parent.type.id)
          for attr in parent_interface.attributes:
            result.add(attr.id)
          for op in parent_interface.operations:
            result.add(op.id)
          WalkParentChain(parent_interface)

    result = set()
    WalkParentChain(interface)
    return result;
