#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import copy
import database
import idlparser
import logging
import multiprocessing
import os
import os.path
import re
import sys
import tempfile
import time
import traceback

import idl_validator

import compiler
import compute_interfaces_info_individual
from compute_interfaces_info_individual import compute_info_individual, info_individual
import compute_interfaces_info_overall
from compute_interfaces_info_overall import compute_interfaces_info_overall, interfaces_info
import idl_definitions

from idlnode import *

_logger = logging.getLogger('databasebuilder')

# Used in source annotations to specify the parent interface declaring
# a displaced declaration. The 'via' attribute specifies the parent interface
# which implements a displaced declaration.
_VIA_ANNOTATION_ATTR_NAME = 'via'


class DatabaseBuilderOptions(object):
  """Used in specifying options when importing new interfaces"""

  def __init__(self,
      idl_syntax=idlparser.WEBIDL_SYNTAX,
      idl_defines=[],
      source=None, source_attributes={},
      rename_operation_arguments_on_merge=False,
      add_new_interfaces=True,
      obsolete_old_declarations=False,
      logging_level=logging.WARNING):
    """Constructor.
    Args:
      idl_syntax -- the syntax of the IDL file that is imported.
      idl_defines -- list of definitions for the idl gcc pre-processor
      source -- the origin of the IDL file, used for annotating the
        database.
      source_attributes -- this map of attributes is used as
        annotation attributes.
      rename_operation_arguments_on_merge -- if True, will rename
        operation arguments when merging using the new name rather
        than the old.
      add_new_interfaces -- when False, if an interface is a new
        addition, it will be ignored.
      obsolete_old_declarations -- when True, if a declaration
        from a certain source is not re-declared, it will be removed.
    """
    self.source = source
    self.source_attributes = source_attributes
    self.idl_syntax = idl_syntax
    self.idl_defines = idl_defines
    self.rename_operation_arguments_on_merge = \
        rename_operation_arguments_on_merge
    self.add_new_interfaces = add_new_interfaces
    self.obsolete_old_declarations = obsolete_old_declarations
    _logger.setLevel(logging_level)


def _load_idl_file(build, file_name, import_options):
  """Loads an IDL file into memory"""
  idl_parser = idlparser.IDLParser(import_options.idl_syntax)

  try:
    f = open(file_name, 'r')
    content = f.read()
    f.close()

    idl_ast = idl_parser.parse(content)

    return IDLFile(idl_ast, file_name)
  except SyntaxError, e:
    raise RuntimeError('Failed to load file %s: %s: Content: %s[end]'
                       % (file_name, e, content))


def format_exception(e):
    exception_list = traceback.format_stack()
    exception_list = exception_list[:-2]
    exception_list.extend(traceback.format_tb(sys.exc_info()[2]))
    exception_list.extend(traceback.format_exception_only(sys.exc_info()[0], sys.exc_info()[1]))

    exception_str = "Traceback (most recent call last):\n"
    exception_str += "".join(exception_list)
    # Removing the last \n
    exception_str = exception_str[:-1]

    return exception_str


# Compile IDL using Blink's IDL compiler.
def _new_compile_idl_file(build, file_name, import_options):
  try:
    idl_file_fullpath = os.path.realpath(file_name)
    idl_definition = build.idl_compiler.compile_file(idl_file_fullpath)
    return idl_definition
  except Exception as err:
    print 'ERROR: idl_compiler.py: ' + os.path.basename(file_name)
    print err
    print
    print 'Stack Dump:'
    print format_exception(err)

  return 1


# Create the Model (IDLFile) from the new AST of the compiled IDL file.
def _new_load_idl_file(build, file_name, import_options):
  try:
    # Compute interface name from IDL filename (it's one for one in WebKit).
    name = os.path.splitext(os.path.basename(file_name))[0]

    idl_definition = new_asts[name]
    return IDLFile(idl_definition, file_name)
  except Exception as err:
    print 'ERROR: loading AST from cache: ' + os.path.basename(file_name)
    print err
    print
    print 'Stack Dump:'
    print format_exception(err)

  return 1


# New IDL parser builder.
class Build():
    def __init__(self, provider):
        # TODO(terry): Consider using the generator to do the work today we're
        #              driven by the databasebuilder.  Blink compiler requires
        #              an output directory even though we don't use (yet). Might
        #              use the code generator portion of the new IDL compiler
        #              then we'd have a real output directory. Today we use the
        #              compiler to only create an AST.
        self.output_directory = tempfile.mkdtemp()
        attrib_file = os.path.join('Source', idl_validator.EXTENDED_ATTRIBUTES_FILENAME)
        # Create compiler.
        self.idl_compiler = compiler.IdlCompilerDart(self.output_directory,
                                            attrib_file,
                                            interfaces_info=interfaces_info,
                                            only_if_changed=True)

    def format_exception(self, e):
        exception_list = traceback.format_stack()
        exception_list = exception_list[:-2]
        exception_list.extend(traceback.format_tb(sys.exc_info()[2]))
        exception_list.extend(traceback.format_exception_only(sys.exc_info()[0], sys.exc_info()[1]))

        exception_str = "Traceback (most recent call last):\n"
        exception_str += "".join(exception_list)
        # Removing the last \n
        exception_str = exception_str[:-1]

        return exception_str

    def generate_from_idl(self, idl_file):
        try:
            idl_file_fullpath = os.path.realpath(idl_file)
            self.idl_compiler.compile_file(idl_file_fullpath)
        except Exception as err:
            print 'ERROR: idl_compiler.py: ' + os.path.basename(idl_file)
            print err
            print
            print 'Stack Dump:'
            print self.format_exception(err)

            return 1

        return IDLFile(idl_ast, file_name)


class DatabaseBuilder(object):
  def __init__(self, database):
    """DatabaseBuilder is used for importing and merging interfaces into
    the Database"""
    self._database = database
    self._imported_interfaces = []
    self._impl_stmts = []
    self.conditionals_met = set()

    # Spin up the new IDL parser.
    self.build = Build(None)

  def _resolve_type_defs(self, idl_file):
    type_def_map = {}
    # build map
    for type_def in idl_file.typeDefs:
      if type_def.type.id != type_def.id: # sanity check
        type_def_map[type_def.id] = type_def.type.id
    # use the map
    for type_node in idl_file.all(IDLType):
      while type_node.id in type_def_map:
        type_node.id = type_def_map[type_node.id]

  def _strip_ext_attributes(self, idl_file):
    """Strips unuseful extended attributes."""
    for ext_attrs in idl_file.all(IDLExtAttrs):
      # TODO: Decide which attributes are uninteresting.
      pass

  def _rename_types(self, idl_file, import_options):
    """Rename interface and type names with names provided in the
    options. Also clears scopes from scoped names"""

    strip_modules = lambda name: name.split('::')[-1]

    def rename_node(idl_node):
      idl_node.reset_id(strip_modules(idl_node.id))

    def rename_ext_attrs(ext_attrs_node):
      for type_valued_attribute_name in ['DartSupplemental']:
        if type_valued_attribute_name in ext_attrs_node:
          value = ext_attrs_node[type_valued_attribute_name]
          if isinstance(value, str):
            ext_attrs_node[type_valued_attribute_name] = strip_modules(value)

    map(rename_node, idl_file.all(IDLInterface))
    map(rename_node, idl_file.all(IDLType))
    map(rename_ext_attrs, idl_file.all(IDLExtAttrs))

  def _annotate(self, interface, import_options):
    """Adds @ annotations based on the source and source_attributes
    members of import_options."""

    source = import_options.source
    if not source:
      return

    def add_source_annotation(idl_node):
      annotation = IDLAnnotation(
        copy.deepcopy(import_options.source_attributes))
      idl_node.annotations[source] = annotation
      if ((isinstance(idl_node, IDLInterface) or
           isinstance(idl_node, IDLMember)) and
          idl_node.is_fc_suppressed):
        annotation['suppressed'] = None

    add_source_annotation(interface)

    map(add_source_annotation, interface.parents)
    map(add_source_annotation, interface.constants)
    map(add_source_annotation, interface.attributes)
    map(add_source_annotation, interface.operations)

  def _sign(self, node):
    """Computes a unique signature for the node, for merging purposed, by
    concatenating types and names in the declaration."""
    if isinstance(node, IDLType):
      res = node.id
      if res.startswith('unsigned '):
        res = res[len('unsigned '):]
      return res

    res = []
    if isinstance(node, IDLInterface):
      res = ['interface', node.id]
    elif isinstance(node, IDLParentInterface):
      res = ['parent', self._sign(node.type)]
    elif isinstance(node, IDLOperation):
      res = ['op']
      for special in node.specials:
        res.append(special)
      if node.id is not None:
        res.append(node.id)
      for arg in node.arguments:
        res.append(self._sign(arg.type))
      res.append(self._sign(node.type))
    elif isinstance(node, IDLAttribute):
      res = []
      if node.is_read_only:
        res.append('readonly')
      res.append(node.id)
      res.append(self._sign(node.type))
    elif isinstance(node, IDLConstant):
      res = []
      res.append('const')
      res.append(node.id)
      res.append(node.value)
      res.append(self._sign(node.type))
    else:
      raise TypeError("Can't sign input of type %s" % type(node))
    return ':'.join(res)

  def _build_signatures_map(self, idl_node_list):
    """Creates a hash table mapping signatures to idl_nodes for the
    given list of nodes"""
    res = {}
    for idl_node in idl_node_list:
      sig = self._sign(idl_node)
      if sig is None:
        continue
      if sig in res:
        op = res[sig]
        # Only report if the the operations that match are either both suppressed
        # or both not suppressed.  Optional args aren't part of type signature
        # for this routine. Suppressing a non-optional type and supplementing
        # with an optional type appear the same.
        if idl_node.is_fc_suppressed == op.is_fc_suppressed:
          raise RuntimeError('Warning: Multiple members have the same '
                           '  signature: "%s"' % sig)
      res[sig] = idl_node
    return res

  def _get_parent_interfaces(self, interface):
    """Return a list of all the parent interfaces of a given interface"""
    res = []

    def recurse(current_interface):
      if current_interface in res:
        return
      res.append(current_interface)
      for parent in current_interface.parents:
        parent_name = parent.type.id
        if self._database.HasInterface(parent_name):
          recurse(self._database.GetInterface(parent_name))

    recurse(interface)
    return res[1:]

  def _merge_ext_attrs(self, old_attrs, new_attrs):
    """Merges two sets of extended attributes.

    Returns: True if old_attrs has changed.
    """
    changed = False
    for (name, value) in new_attrs.items():
      if name in old_attrs and old_attrs[name] == value:
        pass # Identical
      else:
        if name == 'ImplementedAs' and name in old_attrs:
          continue
        old_attrs[name] = value
        changed = True
    return changed

  def _merge_nodes(self, old_list, new_list, import_options):
    """Merges two lists of nodes. Annotates nodes with the source of each
    node.

    Returns:
      True if the old_list has changed.

    Args:
      old_list -- the list to merge into.
      new_list -- list containing more nodes.
      import_options -- controls how merging is done.
    """
    changed = False

    source = import_options.source

    old_signatures_map = self._build_signatures_map(old_list)
    new_signatures_map = self._build_signatures_map(new_list)

    # Merge new items
    for (sig, new_node) in new_signatures_map.items():
      if sig not in old_signatures_map:
        # New node:
        old_list.append(new_node)
        changed = True
      else:
        # Merge old and new nodes:
        old_node = old_signatures_map[sig]
        if (source not in old_node.annotations
            and source in new_node.annotations):
          old_node.annotations[source] = new_node.annotations[source]
          changed = True
        # Maybe rename arguments:
        if isinstance(old_node, IDLOperation):
          for i in range(0, len(old_node.arguments)):
            old_arg = old_node.arguments[i]
            new_arg = new_node.arguments[i]

            old_arg_name = old_arg.id
            new_arg_name = new_arg.id
            if (old_arg_name != new_arg_name
                and (old_arg_name == 'arg'
                     or old_arg_name.endswith('Arg')
                     or import_options.rename_operation_arguments_on_merge)):
              old_node.arguments[i].id = new_arg_name
              changed = True

            if self._merge_ext_attrs(old_arg.ext_attrs, new_arg.ext_attrs):
              changed = True
        # Maybe merge annotations:
        if (isinstance(old_node, IDLAttribute) or
            isinstance(old_node, IDLOperation)):
          if self._merge_ext_attrs(old_node.ext_attrs, new_node.ext_attrs):
            changed = True

    # Remove annotations on obsolete items from the same source
    if import_options.obsolete_old_declarations:
      for (sig, old_node) in old_signatures_map.items():
        if (source in old_node.annotations
            and sig not in new_signatures_map):
          _logger.warn('%s not available in %s anymore' %
            (sig, source))
          del old_node.annotations[source]
          changed = True

    return changed

  def _merge_interfaces(self, old_interface, new_interface, import_options):
    """Merges the new_interface into the old_interface, annotating the
    interface with the sources of each change."""

    changed = False

    source = import_options.source
    if (source and source not in old_interface.annotations and
        source in new_interface.annotations and
        not new_interface.is_supplemental):
      old_interface.annotations[source] = new_interface.annotations[source]
      changed = True

    def merge_list(what):
      old_list = old_interface.__dict__[what]
      new_list = new_interface.__dict__[what]

      if what != 'parents' and old_interface.id != new_interface.id:
        for node in new_list:
          node.doc_js_interface_name = old_interface.id
          node.ext_attrs['ImplementedBy'] = new_interface.id

      changed = self._merge_nodes(old_list, new_list, import_options)

      # Delete list items with zero remaining annotations.
      if changed and import_options.obsolete_old_declarations:

        def has_annotations(idl_node):
          return len(idl_node.annotations)

        old_interface.__dict__[what] = filter(has_annotations, old_list)

      return changed

    # Smartly merge various declarations:
    if merge_list('parents'):
      changed = True
    if merge_list('constants'):
      changed = True
    if merge_list('attributes'):
      changed = True
    if merge_list('operations'):
      changed = True

    if self._merge_ext_attrs(old_interface.ext_attrs, new_interface.ext_attrs):
      changed = True

    _logger.info('merged interface %s (changed=%s, supplemental=%s)' %
      (old_interface.id, changed, new_interface.is_supplemental))

    return changed

  def _merge_impl_stmt(self, impl_stmt, import_options):
    """Applies "X implements Y" statemetns on the proper places in the
    database"""
    implementor_name = impl_stmt.implementor.id
    implemented_name = impl_stmt.implemented.id
    _logger.info('merging impl stmt %s implements %s' %
                 (implementor_name, implemented_name))

    source = import_options.source
    if self._database.HasInterface(implementor_name):
      interface = self._database.GetInterface(implementor_name)
      if interface.parents is None:
        interface.parents = []
      for parent in interface.parents:
        if parent.type.id == implemented_name:
          if source and source not in parent.annotations:
            parent.annotations[source] = IDLAnnotation(
                import_options.source_attributes)
          return
      # not found, so add new one
      parent = IDLParentInterface(None)
      parent.type = IDLType(implemented_name)
      if source:
        parent.annotations[source] = IDLAnnotation(
            import_options.source_attributes)
      interface.parents.append(parent)

  def merge_imported_interfaces(self, blink_parser):
    """Merges all imported interfaces and loads them into the DB."""
    imported_interfaces = self._imported_interfaces

    # Step 1: Pre process imported interfaces
#    for interface, import_options in imported_interfaces.iteritems():
    for interface, import_options in imported_interfaces:
      self._annotate(interface, import_options)

    # Step 2: Add all new interfaces and merge overlapping ones
    for interface, import_options in imported_interfaces:
      if not interface.is_supplemental:
        if self._database.HasInterface(interface.id):
          old_interface = self._database.GetInterface(interface.id)
          self._merge_interfaces(old_interface, interface, import_options)
        else:
          if import_options.add_new_interfaces:
            self._database.AddInterface(interface)

    # Step 3: Merge in supplemental interfaces
    for interface, import_options in imported_interfaces:
      if interface.is_supplemental:
        target = interface.id
        if self._database.HasInterface(target):
          old_interface = self._database.GetInterface(target)
          self._merge_interfaces(old_interface, interface, import_options)
        else:
          _logger.warning("Supplemental target '%s' not found", target)

    # Step 4: Resolve 'implements' statements
    for impl_stmt, import_options in self._impl_stmts:
      self._merge_impl_stmt(impl_stmt, import_options)

    self._impl_stmts = []
    self._imported_interfaces = []

  # Compile the IDL file with the Blink compiler and remember each AST for the
  # IDL.
  def _blink_compile_idl_files(self, file_paths, import_options, parallel, is_dart_idl):
    if not(is_dart_idl):
      start_time = time.time()

      # 2-stage computation: individual, then overall
      for file_path in file_paths:
        filename = os.path.splitext(os.path.basename(file_path))[0]
        compute_info_individual(file_path, 'dart')
      info_individuals = [info_individual()]
      compute_interfaces_info_overall(info_individuals)

      end_time = time.time()
      print 'Compute dependencies %s seconds' % round((end_time - start_time),
                                                      2)

    # use --parallel for async on a pool.  Look at doing it like Blink
    blink_compiler = _new_compile_idl_file
    process_ast = self._process_ast

    if parallel:
      # Parse the IDL files in parallel.
      pool = multiprocessing.Pool()
      try:
        for file_path in file_paths:
          pool.apply_async(blink_compiler,
                           [ self.build, file_path, import_options],
                           callback = lambda new_ast: process_ast(new_ast, True))
        pool.close()
        pool.join()
      except:
        pool.terminate()
        raise
    else:
      # Parse the IDL files serially.
      start_time = time.time()

      for file_path in file_paths:
        file_path = os.path.normpath(file_path)
        ast = blink_compiler(self.build, file_path, import_options)
        process_ast(os.path.splitext(os.path.basename(file_path))[0], ast, True)

      end_time = time.time()
      print 'Compiled %s IDL files in %s seconds' % (len(file_paths),
                                                    round((end_time - start_time), 2))

  def _process_ast(self, filename, ast, blink_parser = False):
    if blink_parser:
      new_asts[filename] = ast
    else:
      for name in ast.interfaces:
        # Index by filename some files are partial on another interface (e.g.,
        # DocumentFontFaceSet.idl).
        new_asts[filename] = ast.interfaces

  def import_idl_files(self, file_paths, import_options, parallel, blink_parser, is_dart_idl):
    if blink_parser:
      self._blink_compile_idl_files(file_paths, import_options, parallel, is_dart_idl)

    # use --parallel for async on a pool.  Look at doing it like Blink
    idl_loader = _new_load_idl_file if blink_parser else _load_idl_file

    if parallel:
      # Parse the IDL files in parallel.
      pool = multiprocessing.Pool()
      try:
        for file_path in file_paths:
          pool.apply_async(idl_loader,
                           [ self.build, file_path, import_options],
                           callback = lambda idl_file:
                             self._process_idl_file(idl_file, import_options))
        pool.close()
        pool.join()
      except:
        pool.terminate()
        raise
    else:
      start_time = time.time()

      # Parse the IDL files in serial.
      for file_path in file_paths:
        file_path = os.path.normpath(file_path)
        idl_file = idl_loader(self.build, file_path, import_options)
        _logger.info('Processing %s' % os.path.splitext(os.path.basename(file_path))[0])
        self._process_idl_file(idl_file, import_options, is_dart_idl)

      end_time = time.time()

      print 'Total %s files %sprocessed in databasebuilder in %s seconds' % \
      (len(file_paths), '' if blink_parser else 'compiled/', \
       round((end_time - start_time), 2))

  def _process_idl_file(self, idl_file, import_options, dart_idl = False):
    # TODO(terry): strip_ext_attributes on an idl_file does nothing.
    #self._strip_ext_attributes(idl_file)
    self._resolve_type_defs(idl_file)
    self._rename_types(idl_file, import_options)

    def enabled(idl_node):
      return self._is_node_enabled(idl_node, import_options.idl_defines)

    for interface in idl_file.interfaces:
      if not self._is_node_enabled(interface, import_options.idl_defines):
        _logger.info('skipping interface %s (source=%s)'
          % (interface.id, import_options.source))
        continue

      _logger.info('importing interface %s (source=%s file=%s)'
        % (interface.id, import_options.source, os.path.basename(idl_file.filename)))

      interface.attributes = filter(enabled, interface.attributes)
      interface.operations = filter(enabled, interface.operations)
      self._imported_interfaces.append((interface, import_options))

    for implStmt in idl_file.implementsStatements:
      self._impl_stmts.append((implStmt, import_options))

    for enum in idl_file.enums:
      self._database.AddEnum(enum)


  def _is_node_enabled(self, node, idl_defines):
    if not 'Conditional' in node.ext_attrs:
      return True

    def enabled(condition):
      return 'ENABLE_%s' % condition in idl_defines

    conditional = node.ext_attrs['Conditional']
    if conditional.find('&') != -1:
      for condition in conditional.split('&'):
        condition = condition.strip()
        self.conditionals_met.add(condition)
        if not enabled(condition):
          return False
      return True

    for condition in conditional.split('|'):
      condition = condition.strip()
      self.conditionals_met.add(condition)
      if enabled(condition):
        return True
    return False

  def fix_displacements(self, source):
    """E.g. In W3C, something is declared on HTMLDocument but in WebKit
    its on Document, so we need to mark that something in HTMLDocument
    with @WebKit(via=Document). The 'via' attribute specifies the
    parent interface that has the declaration."""

    for interface in self._database.GetInterfaces():
      changed = False

      _logger.info('fixing displacements in %s' % interface.id)

      for parent_interface in self._get_parent_interfaces(interface):
        _logger.info('scanning parent %s of %s' %
          (parent_interface.id, interface.id))

        def fix_nodes(local_list, parent_list):
          changed = False
          parent_signatures_map = self._build_signatures_map(
            parent_list)
          for idl_node in local_list:
            sig = self._sign(idl_node)
            if sig in parent_signatures_map:
              parent_member = parent_signatures_map[sig]
              if (source in parent_member.annotations
                  and source not in idl_node.annotations
                  and _VIA_ANNOTATION_ATTR_NAME
                      not in parent_member.annotations[source]):
                idl_node.annotations[source] = IDLAnnotation(
                    {_VIA_ANNOTATION_ATTR_NAME: parent_interface.id})
                changed = True
          return changed

        changed = fix_nodes(interface.constants,
                  parent_interface.constants) or changed
        changed = fix_nodes(interface.attributes,
                  parent_interface.attributes) or changed
        changed = fix_nodes(interface.operations,
                  parent_interface.operations) or changed
      if changed:
        _logger.info('fixed displaced declarations in %s' %
          interface.id)

  def normalize_annotations(self, sources):
    """Makes the IDLs less verbose by removing annotation attributes
    that are identical to the ones defined at the interface level.

    Args:
      sources -- list of source names to normalize."""
    for interface in self._database.GetInterfaces():
      _logger.debug('normalizing annotations for %s' % interface.id)
      for source in sources:
        if (source not in interface.annotations or
            not interface.annotations[source]):
          continue
        top_level_annotation = interface.annotations[source]

        def normalize(idl_node):
          if (source in idl_node.annotations
              and idl_node.annotations[source]):
            annotation = idl_node.annotations[source]
            for name, value in annotation.items():
              if (name in top_level_annotation
                  and value == top_level_annotation[name]):
                del annotation[name]

        map(normalize, interface.parents)
        map(normalize, interface.constants)
        map(normalize, interface.attributes)
        map(normalize, interface.operations)

  def fetch_constructor_data(self, options):
    window_interface = self._database.GetInterface('Window')
    for attr in window_interface.attributes:
      type = attr.type.id
      if not type.endswith('Constructor'):
        continue
      type = re.sub('(Constructor)+$', '', type)
      # TODO(antonm): Ideally we'd like to have pristine copy of WebKit IDLs and fetch
      # this information directly from it.  Unfortunately right now database is massaged
      # a lot so it's difficult to maintain necessary information on Window itself.
      interface = self._database.GetInterface(type)
      if 'V8EnabledPerContext' in attr.ext_attrs:
        interface.ext_attrs['synthesizedV8EnabledPerContext'] = \
            attr.ext_attrs['V8EnabledPerContext']
      if 'V8EnabledAtRuntime' in attr.ext_attrs:
        interface.ext_attrs['synthesizedV8EnabledAtRuntime'] = \
            attr.ext_attrs['V8EnabledAtRuntime'] or attr.id
