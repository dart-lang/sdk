#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides shared functionality for the system to generate
Dart:html APIs from the IDL database."""

import os
from generator import *
from systembase import *
from systemfrog import *
from systeminterface import *

# Members from the standard dom that should not be exposed publicly in dart:html
# but need to be exposed internally to implement dart:html on top of a standard
# browser.
_private_html_members = {
  'Element': set(['clientLeft', 'clientTop', 'clientWidth', 'clientHeight',
      'offsetLeft', 'offsetTop', 'offsetWidth', 'offsetHeight',
      'scrollLeft', 'scrollTop', 'scrollWidth', 'scrollHeight',
      'childElementCount', 'firstElementChild', 'hasAttribute', 
      'getAttribute', 'removeAttribute', 'setAttribute', 'className',
      'children']),
  'Node' : set(['appendChild', 'removeChild', 'replaceChild', 'attributes',
      'childNodes']),
  # TODO(jacobr): other direct translate methods on node such as
  # textContext->text
  'Document': set(['createElement', 'createEvent']),
  'Window': set(['getComputedStyle']),
  'EventTarget': set(['removeEventListener', 'addEventListener',
      'dispatchEvent']),
  'Event': set(['initEvent', 'target', 'srcElement', 'currentTarget'])
}

# Members from the standard dom that exist in the dart:html library with
# identical functionality but with cleaner names.
html_library_renames = {
    'Document.createTextNode': 'Text.Text',
    'Document.get:defaultView': 'Document.get:window',
    'DocumentFragment.querySelector': 'Element.query',
    'Element.querySelector': 'Element.query',
    'Document.querySelector': 'Element.query',
    'DocumentFragment.querySelectorAll': 'Element.queryAll',
    'DocumentFragment.querySelectorAll': 'Element.queryAll',
    'Element.querySelectorAll': 'Element.queryAll',
    'Element.scrollIntoViewIfNeeded': 'Element.scrollIntoView',
    'Node.cloneNode': 'Node.clone',
    'Node.get:nextSibling': 'Node.get:nextNode',
    'Node.get:ownerDocument': 'Node.get:document',
    'Node.get:parentNode': 'Node.get:parent',
    'Node.get:previousSibling': 'Node.get:previousNode',
}

# Members and classes from the dom that should be removed completelly from
# dart:html.  These could be expressed in the IDL instead but expressing this
# as a simple table instead is more concise.
# TODO(jacobr): cleanup and augment this list.
_html_library_remove = set([
    'Window.get:document', # Removed as we have a custom implementation.
    'NodeList.item',
    "Attr.*",
#    "BarProp.*",
#    "BarInfo.*",
#    "Blob.webkitSlice",
#    "CDATASection.*",
#    "Comment.*",
#    "DOMImplementation.*",
    # TODO(jacobr): listing title here is a temporary hack due to a frog bug
    # involving when an interface inherits from another interface and defines
    # the same field. BUG(1633)
    "Document.get:title",
    "Document.set:title",
    "Element.get:title",
    "Element.set:title",
    "Document.get:documentElement",
    "Document.get:forms",
#    "Document.get:selectedStylesheetSet",
#    "Document.set:selectedStylesheetSet",
#    "Document.get:preferredStylesheetSet",
    "Document.get:links",
    "Document.getElementsByTagName",
    "Document.set:domain",
    "Document.get:implementation",
    "Document.createAttributeNS",
    "Document.get:inputEncoding",
    "Document.getElementsByClassName",
    "Document.get:compatMode",
    "Document.importNode",
    "Document.evaluate",
    "Document.get:images",
    "Document.querySelector",
    "Document.createExpression",
    "Document.getOverrideStyle",
    "Document.get:xmlStandalone",
    "Document.set:xmlStandalone",
    "Document.createComment",
    "Document.adoptNode",
    "Document.get:characterSet",
    "Document.createAttribute",
    "Document.querySelectorAll",
    "Document.get:URL",
    "Document.createElementNS",
    "Document.createEntityReference",
    "Document.get:documentURI",
    "Document.set:documentURI",
    "Document.createNodeIterator",
    "Document.createProcessingInstruction",
    "Document.get:doctype",
    "Document.getElementsByName",
    "Document.createTreeWalker",
    "Document.get:location",
    "Document.set:location",
    "Document.createNSResolver",
    "Document.get:xmlEncoding",
    "Document.get:defaultCharset",
    "Document.get:applets",
    "Document.getSelection",
    "Document.get:xmlVersion",
    "Document.set:xmlVersion",
    "Document.get:anchors",
    "Document.getElementsByTagNameNS",
    "DocumentType.*",
    "Element.hasAttributeNS",
    "Element.getAttributeNS",
    "Element.setAttributeNode",
    "Element.getAttributeNode",
    "Element.removeAttributeNode",
    "Element.removeAttributeNS",
    "Element.setAttributeNodeNS",
    "Element.getAttributeNodeNS",
    "Element.setAttributeNS",
#    "EventSource.get:url",
# TODO(jacobr): should these be removed?
    "Document.close",
    "Document.hasFocus",

    "Document.get:vlinkColor",
    "Document.set:vlinkColor",
    "Document.captureEvents",
    "Document.releaseEvents",
    "Document.get:compatMode",
    "Document.get:designMode",
    "Document.set:designMode",
    "Document.get:dir",
    "Document.set:dir",
    "Document.get:all",
    "Document.set:all",
    "Document.write",
    "Document.get:fgColor",
    "Document.set:fgColor",
    "Document.get:bgColor",
    "Document.set:bgColor",
    "Document.get:plugins",
    "Document.get:alinkColor",
    "Document.set:alinkColor",
    "Document.get:embeds",
    "Document.open",
    "Document.clear",
    "Document.get:scripts",
    "Document.writeln",
    "Document.get:linkColor",
    "Document.set:linkColor",
    "Element.get:itemRef",
    "Element.set:className",
    "Element.get:outerText",
    "Element.set:outerText",
    "Element.get:accessKey",
    "Element.set:accessKey",
    "Element.get:itemType",
    "Element.get:innerText",
    "Element.set:innerText",
    "Element.set:outerHTML",
    "Element.get:itemScope",
    "Element.set:itemScope",
    "Element.get:itemValue",
    "Element.set:itemValue",
    "Element.get:itemId",
    "Element.set:itemId",
    "Element.get:itemProp",
    "EmbedElement.getSVGDocument",
    "FormElement.get:elements",
    "HTMLFrameElement.*",
    "HTMLFrameSetElement.*",
    "HTMLHtmlElement.get:version",
    "HTMLHtmlElement.set:version",
#    "IFrameElement.getSVGDocument",  #TODO(jacobr): should this be removed
    "InputElement.get:dirName",
    "InputElement.set:dirName",
    "HTMLIsIndexElement.*",
    "ObjectElement.getSVGDocument",
    "HTMLOptionsCollection.*",
    "HTMLPropertiesCollection.*",
    "SelectElement.remove",
    "TextAreaElement.get:dirName",
    "TextAreaElement.set:dirName",
    "NamedNodeMap.*",
    "Node.isEqualNode",
    "Node.get:TEXT_NODE",
    "Node.hasAttributes",
    "Node.get:DOCUMENT_TYPE_NODE",
    "Node.get:DOCUMENT_POSITION_FOLLOWING",
    "Node.get:childNodes",
    "Node.lookupNamespaceURI",
    "Node.get:ELEMENT_NODE",
    "Node.get:namespaceURI",
    "Node.get:DOCUMENT_FRAGMENT_NODE",
    "Node.get:localName",
    "Node.dispatchEvent",
    "Node.isDefaultNamespace",
    "Node.compareDocumentPosition",
    "Node.get:baseURI",
    "Node.isSameNode",
    "Node.get:DOCUMENT_POSITION_DISCONNECTED",
    "Node.get:DOCUMENT_NODE",
    "Node.get:DOCUMENT_POSITION_CONTAINS",
    "Node.get:COMMENT_NODE",
    "Node.get:ENTITY_REFERENCE_NODE",
    "Node.isSupported",
    "Node.get:firstChild",
    "Node.get:DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC",
    "Node.get:lastChild",
    "Node.get:attributes",
    "Node.get:NOTATION_NODE",
    "Node.normalize",
    "Node.get:parentElement",
    "Node.get:ATTRIBUTE_NODE",
    "Node.get:ENTITY_NODE",
    "Node.get:DOCUMENT_POSITION_CONTAINED_BY",
    "Node.get:prefix",
    "Node.set:prefix",
    "Node.get:DOCUMENT_POSITION_PRECEDING",
    "Node.get:nodeType",
    "Node.removeEventListener",
    "Node.get:nodeValue",
    "Node.set:nodeValue",
    "Node.get:CDATA_SECTION_NODE",
    "Node.get:nodeName",
    "Node.addEventListener",
    "Node.lookupPrefix",
    "Node.get:PROCESSING_INSTRUCTION_NODE",
    "Notification.dispatchEvent",
    "Notification.addEventListener",
    "Notification.removeEventListener"])

# Events without onEventName attributes in the  IDL we want to support.
# We can automatically extract most event event names by checking for
# onEventName methods in the IDL but some events aren't listed so we need
# to manually add them here so that they are easy for users to find.
_html_manual_events = {
  'Element': ['touchleave', 'webkitTransitionEnd'],
  'Window': ['DOMContentLoaded']
}

# These event names must be camel case when attaching event listeners
# using addEventListener even though the onEventName properties in the DOM for
# them are not camel case.
_on_attribute_to_event_name_mapping = {
  'webkitanimationend': 'webkitAnimationEnd',
  'webkitanimationiteration': 'webkitAnimationIteration',
  'webkitanimationstart': 'webkitAnimationStart',
  'webkitfullscreenchange': 'webkitFullScreenChange',
  'webkitfullscreenerror': 'webkitFullScreenError',
  'webkitspeechchange': 'webkitSpeechChange',
  'webkittransitionend': 'webkitTransitionEnd',
}

# Mapping from raw event names to the pretty camelCase event names exposed as
# properties in dart:html.  If the DOM exposes a new event name, you will need
# to add the lower case to camel case conversion for that event name here.
_html_event_names = {
  'DOMContentLoaded': 'contentLoaded',
  'touchleave': 'touchLeave',
  'abort': 'abort',
  'beforecopy': 'beforeCopy',
  'beforecut': 'beforeCut',
  'beforepaste': 'beforePaste',
  'beforeunload': 'beforeUnload',
  'blur': 'blur',
  'cached': 'cached',
  'canplay': 'canPlay',
  'canplaythrough': 'canPlayThrough',
  'change': 'change',
  'checking': 'checking',
  'click': 'click',
  'close': 'close',
  'contextmenu': 'contextMenu',
  'copy': 'copy',
  'cut': 'cut',
  'dblclick': 'doubleClick',
  'devicemotion': 'deviceMotion',
  'deviceorientation': 'deviceOrientation',
  'display': 'display',
  'downloading': 'downloading',
  'drag': 'drag',
  'dragend': 'dragEnd',
  'dragenter': 'dragEnter',
  'dragleave': 'dragLeave',
  'dragover': 'dragOver',
  'dragstart': 'dragStart',
  'drop': 'drop',
  'durationchange': 'durationChange',
  'emptied': 'emptied',
  'ended': 'ended',
  'error': 'error',
  'focus': 'focus',
  'hashchange': 'hashChange',
  'input': 'input',
  'invalid': 'invalid',
  'keydown': 'keyDown',
  'keypress': 'keyPress',
  'keyup': 'keyUp',
  'load': 'load',
  'loadeddata': 'loadedData',
  'loadedmetadata': 'loadedMetadata',
  'loadend': 'loadEnd',
  'loadstart': 'loadStart',
  'message': 'message',
  'mousedown': 'mouseDown',
  'mousemove': 'mouseMove',
  'mouseout': 'mouseOut',
  'mouseover': 'mouseOver',
  'mouseup': 'mouseUp',
  'mousewheel': 'mouseWheel',
  'noupdate': 'noUpdate',
  'obsolete': 'obsolete',
  'offline': 'offline',
  'online': 'online',
  'open': 'open',
  'pagehide': 'pageHide',
  'pageshow': 'pageShow',
  'paste': 'paste',
  'pause': 'pause',
  'play': 'play',
  'playing': 'playing',
  'popstate': 'popState',
  'progress': 'progress',
  'ratechange': 'rateChange',
  'readystatechange': 'readyStateChange',
  'reset': 'reset',
  'resize': 'resize',
  'scroll': 'scroll',
  'search': 'search',
  'seeked': 'seeked',
  'seeking': 'seeking',
  'select': 'select',
  'selectionchange': 'selectionChange',
  'selectstart': 'selectStart',
  'show': 'show',
  'stalled': 'stalled',
  'storage': 'storage',
  'submit': 'submit',
  'suspend': 'suspend',
  'timeupdate': 'timeUpdate',
  'touchcancel': 'touchCancel',
  'touchend': 'touchEnd',
  'touchmove': 'touchMove',
  'touchstart': 'touchStart',
  'unload': 'unload',
  'updateready': 'updateReady',
  'volumechange': 'volumeChange',
  'waiting': 'waiting',
  'webkitAnimationEnd': 'animationEnd',
  'webkitAnimationIteration': 'animationIteration',
  'webkitAnimationStart': 'animationStart',
  'webkitFullScreenChange': 'fullScreenChange',
  'webkitFullScreenError': 'fullScreenError',
  'webkitSpeechChange': 'speechChange',
  'webkitTransitionEnd': 'transitionEnd'
}

def _OnAttributeToEventName(on_method):
  event_name = on_method.id[2:]
  if event_name in _on_attribute_to_event_name_mapping:
    return _on_attribute_to_event_name_mapping[event_name]
  else:
    return event_name

def _DomToHtmlEvents(interface_id, events):
  event_names = set(map(_OnAttributeToEventName, events)) 
  if interface_id in _html_manual_events:
    for manual_event_name in _html_manual_events[interface_id]:
      event_names.add(manual_event_name)

  return sorted(event_names, key=lambda name: _html_event_names[name])

# ------------------------------------------------------------------------------

class HtmlSystem(System):

  def __init__(self, templates, database, emitters, output_dir, generator):
    super(HtmlSystem, self).__init__(
        templates, database, emitters, output_dir)
    self._event_classes = set()
    self._seen_event_names = {}
    self._generator = generator

  def _AllowInHtmlLibrary(self, interface, member):
    if self._PrivateInHtmlLibrary(interface, member):
      return False
    for interface_name in ([interface.id] +
        self._generator._AllImplementedInterfaces(interface)):
      if interface.id + '.' + member in _html_library_remove:
        return False
    return True

  def _PrivateInHtmlLibrary(self, interface, member):
    for interface_name in ([interface.id] +
        self._generator._AllImplementedInterfaces(interface)):
      if (interface_name in _private_html_members and 
          member in _private_html_members[interface_name]):
        return True
    return False

  # TODO(jacobr): this already exists
  def _TraverseParents(self, interface, callback):
    for parent in interface.parents:
      parent_id = parent.type.id
      if self._database.HasInterface(parent_id):
        parent_interface = self._database.GetInterface(parent_id)
        callback(parent_interface)
        self._TraverseParents(parent_interface, callback)

  # TODO(jacobr): this isn't quite right.... 
  def _GetParentsEventsClasses(self, interface):
    # Ugly hack as we don't specify that Document inherits from Element
    # in our IDL.
    if interface.id == 'Document':
      return ['ElementEvents']

    interfaces_with_events = set()
    def visit(parent):
      if parent.id in self._event_classes:
        interfaces_with_events.add(parent)

    self._TraverseParents(interface, visit)
    if len(interfaces_with_events) == 0:
      return ['Events']
    else:
      names = []
      for interface in interfaces_with_events:
        names.append(interface.id + 'Events')
      return names

class HtmlInterfacesSystem(HtmlSystem):

  def __init__(self, templates, database, emitters, output_dir, generator):
    super(HtmlInterfacesSystem, self).__init__(
        templates, database, emitters, output_dir, generator)
    self._dart_interface_file_paths = []

  def InterfaceGenerator(self,
                         interface,
                         common_prefix,
                         super_interface_name,
                         source_filter):
    """."""
    interface_name = interface.id
    dart_interface_file_path = self._FilePathForDartInterface(interface_name)

    self._dart_interface_file_paths.append(dart_interface_file_path)

    dart_interface_code = self._emitters.FileEmitter(dart_interface_file_path)

    template_file = 'interface_%s.darttemplate' % interface_name
    template = self._templates.TryLoad(template_file)
    if not template:
      template = self._templates.Load('interface.darttemplate')

    return HtmlDartInterfaceGenerator(
        interface, dart_interface_code,
        template,
        common_prefix, super_interface_name,
        source_filter, self)

  def ProcessCallback(self, interface, info):
    """Generates a typedef for the callback interface."""
    interface_name = interface.id
    file_path = self._FilePathForDartInterface(interface_name)
    self._ProcessCallback(interface, info, file_path)

  def GenerateLibraries(self, lib_dir):
    pass


  def _FilePathForDartInterface(self, interface_name):
    """Returns the file path of the Dart interface definition."""
    # TODO(jmesserly): is this the right path
    return os.path.join(self._output_dir, 'html', 'interface',
                        '%s.dart' % interface_name)

# ------------------------------------------------------------------------------

# TODO(jmesserly): inheritance is probably not the right way to factor this long
# term, but it makes merging better for now.
class HtmlDartInterfaceGenerator(DartInterfaceGenerator):
  """Generates Dart Interface definition for one DOM IDL interface."""

  def __init__(self, interface, emitter, template,
               common_prefix, super_interface, source_filter, system):
    super(HtmlDartInterfaceGenerator, self).__init__(interface,
      emitter, template, common_prefix, super_interface, source_filter)
    self._system = system

  def StartInterface(self):
    typename = self._interface.id

    extends = []
    suppressed_extends = []

    for parent in self._interface.parents:
      # TODO(vsm): Remove source_filter.
      if MatchSourceFilter(self._source_filter, parent):
        # Parent is a DOM type.
        extends.append(DartType(parent.type.id))
      elif '<' in parent.type.id:
        # Parent is a Dart collection type.
        # TODO(vsm): Make this check more robust.
        extends.append(parent.type.id)
      else:
        suppressed_extends.append('%s.%s' %
                                  (self._common_prefix, parent.type.id))

    comment = ' extends'
    extends_str = ''
    if extends:
      extends_str += ' extends ' + ', '.join(extends)
      comment = ','
    if suppressed_extends:
      extends_str += ' /*%s %s */' % (comment, ', '.join(suppressed_extends))

    if typename in interface_factories:
      extends_str += ' default ' + interface_factories[typename]

    # TODO(vsm): Add appropriate package / namespace syntax.
    (self._members_emitter,
     self._top_level_emitter) = self._emitter.Emit(
         self._template + '$!TOP_LEVEL',
         ID=typename,
         EXTENDS=extends_str)

    element_type = MaybeTypedArrayElementType(self._interface)
    if element_type:
      self._members_emitter.Emit(
          '\n'
          '  $CTOR(int length);\n'
          '\n'
          '  $CTOR.fromList(List<$TYPE> list);\n'
          '\n'
          '  $CTOR.fromBuffer(ArrayBuffer buffer);\n',
        CTOR=self._interface.id,
        TYPE=DartType(element_type))

  def AddAttribute(self, getter, setter):
    if getter and not self._system._AllowInHtmlLibrary(self._interface,
        'get:' + getter.id):
      getter = None
    if setter and not self._system._AllowInHtmlLibrary(self._interface,
        'set:' + setter.id):
      setter = None
    if not getter and not setter:
      return
    if getter and setter and DartType(getter.type.id) == DartType(setter.type.id):
      self._members_emitter.Emit('\n  $TYPE $NAME;\n',
                                 NAME=getter.id, TYPE=DartType(getter.type.id));
      return
    if getter and not setter:
      self._members_emitter.Emit('\n  final $TYPE $NAME;\n',
                                 NAME=getter.id, TYPE=DartType(getter.type.id));
      return
    raise Exception('Unexpected getter/setter combination %s %s' %
                    (getter, setter))

  def AddOperation(self, info):
    """
    Arguments:
      operations - contains the overloads, one or more operations with the same
        name.
    """
    if self._system._AllowInHtmlLibrary(self._interface, info.name):
      self._members_emitter.Emit('\n'
                                 '  $TYPE $NAME($PARAMS);\n',
                                 TYPE=info.type_name,
                                 NAME=info.name,
                                 PARAMS=info.ParametersInterfaceDeclaration())

  def FinishInterface(self):
    pass

  def AddConstant(self, constant):
    self._EmitConstant(self._members_emitter, constant)

  def AddEventAttributes(self, event_attrs):
    event_attrs = _DomToHtmlEvents(self._interface.id, event_attrs)
    self._system._event_classes.add(self._interface.id)
    events_interface = self._interface.id + 'Events'
    self._members_emitter.Emit('\n  $TYPE get on();\n',
                               TYPE=events_interface)
    events_members = self._emitter.Emit(
        '\ninterface $INTERFACE extends $PARENTS {\n$!MEMBERS}\n',
        INTERFACE=events_interface,
        PARENTS=', '.join(
            self._system._GetParentsEventsClasses(self._interface)))

    for event_name in event_attrs:
      if event_name in _html_event_names:
        events_members.Emit('\n  EventListenerList get $NAME();\n',
          NAME=_html_event_names[event_name])
      else:
        raise Exception('No known html even name for event: ' + event_name)

# ------------------------------------------------------------------------------

# TODO(jmesserly): inheritance is probably not the right way to factor this long
# term, but it makes merging better for now.
class HtmlFrogClassGenerator(FrogInterfaceGenerator):
  """Generates a Frog class for the dart:html library from a DOM IDL
  interface.
  """

  def __init__(self, system, interface, template, super_interface, dart_code):
    super(HtmlFrogClassGenerator, self).__init__(
        system, interface, template, super_interface, dart_code)


  def StartInterface(self):
    interface = self._interface
    interface_name = interface.id

    self._class_name = self._ImplClassName(interface_name)

    base = None
    if interface.parents:
      supertype = interface.parents[0].type.id
      # FIXME: We're currently injecting List<..> and EventTarget as
      # supertypes in dart.idl. We should annotate/preserve as
      # attributes instead.  For now, this hack lets the interfaces
      # inherit, but not the classes.
      if (not IsDartListType(supertype) and
          not supertype == 'EventTarget'):
        base = self._ImplClassName(supertype)
      if IsDartCollectionType(supertype):
        # List methods are injected in AddIndexer.
        pass
      elif supertype == 'EventTarget':
        # Most implementors of EventTarget specify the EventListener operations
        # again.  If the operations are not specified, try to inherit from the
        # EventTarget implementation.
        #
        # Applies to MessagePort.
        if not [op for op in interface.operations if op.id == 'addEventListener']:
          base = self._ImplClassName(supertype)
      else:
        base = self._ImplClassName(supertype)

    native_spec = MakeNativeSpec(interface.javascript_binding_name)

    extends = ' extends ' + base if base else ''

    # TODO: Include all implemented interfaces, including other Lists.
    implements = [interface_name]
    element_type = MaybeTypedArrayElementType(self._interface)
    if element_type:
      implements.append('List<%s>' % DartType(element_type))

    self._members_emitter = self._dart_code.Emit(
        self._template,
        #class $CLASSNAME$EXTENDS$IMPLEMENTS$NATIVESPEC {
        #$!MEMBERS
        #}
        CLASSNAME=self._class_name,
        EXTENDS=extends,
        IMPLEMENTS=' implements ' + ', '.join(implements),
        NATIVESPEC=' native "' + native_spec + '"')

    element_type = MaybeTypedArrayElementType(interface)
    if element_type:
      self.AddTypedArrayConstructors(element_type)

  def AddAttribute(self, getter, setter):
  
    if self._system._PrivateInHtmlLibrary(self._interface, getter.id):
      if getter:
        self._AddGetter(getter, True)
      if setter:
        self._AddSetter(setter, True)
      return
    if getter and not self._system._AllowInHtmlLibrary(self._interface,
        'get:' + getter.id):
      getter = None
    if setter and not self._system._AllowInHtmlLibrary(self._interface,
        'set:' + setter.id):
      setter = None
    if not getter and not setter:
      return
    # If the (getter, setter) pair is shadowing, we can't generate a shadowing
    # field (Issue 1633).
    (super_getter, super_getter_interface) = self._FindShadowedAttribute(getter)
    (super_setter, super_setter_interface) = self._FindShadowedAttribute(setter)
    if super_getter or super_setter:
      if getter and not setter and super_getter and not super_setter:
        if getter.type.id == super_getter.type.id:
          # Compatible getter, use the superclass property.  This works because
          # JavaScript will do its own dynamic dispatch.
          output_type = getter and self._NarrowOutputType(getter.type.id)
          self._members_emitter.Emit(
              '\n'
              '  // Use implementation from $SUPER.\n'
              '  // final $TYPE $NAME;\n',
              SUPER=super_getter_interface.id,
              NAME=getter.id, TYPE=output_type)
          return

      self._members_emitter.Emit('\n  // Shadowing definition.')
      if getter:
        self._AddGetter(getter, False)
      if setter:
        self._AddSetter(setter, False)
      return

    if self._interface.id != 'Document':
      output_type = getter and self._NarrowOutputType(getter.type.id)
      input_type = setter and self._NarrowInputType(setter.type.id)
      if getter and setter and input_type == output_type:
        self._members_emitter.Emit(
            '\n  $TYPE $NAME;\n',
            NAME=getter.id, TYPE=output_type)
        return
      if getter and not setter:
        self._members_emitter.Emit(
            '\n  final $TYPE $NAME;\n',
            NAME=getter.id, TYPE=output_type)
        return
    self._AddAttributeUsingProperties(getter, setter, False)

  def _AddAttributeUsingProperties(self, getter, setter, private):
    if getter:
      self._AddGetter(getter, private)
    if setter:
      self._AddSetter(setter, private)

  def _AddGetter(self, attr, private):
    # TODO(sra): Remove native body when Issue 829 fixed.
    self._members_emitter.Emit(
        '\n  $TYPE get $PRIVATE$NAME() native "return $THIS.$NAME;";\n',
        NAME=attr.id, TYPE=self._NarrowOutputType(attr.type.id),
        PRIVATE='_' if private else '',
        THIS='this.parentNode' if self._interface.id == 'Document' else 'this' 
        )

  def _AddSetter(self, attr, private):
    # TODO(sra): Remove native body when Issue 829 fixed.
    self._members_emitter.Emit(
        '\n  void set $PRIVATE$NAME($TYPE value)'
        ' native "$THIS.$NAME = value;";\n',
        NAME=attr.id, TYPE=self._NarrowInputType(attr.type.id),
        PRIVATE='_' if private else '',
        THIS='this.parentNode' if self._interface.id == 'Document' else 'this')

  def AddOperation(self, info):
    """
    Arguments:
      info: An OperationInfo object.
    """
    private_in_html = self._system._PrivateInHtmlLibrary(self._interface,
        info.name)
    if private_in_html or self._interface.id == 'Document':
      # TODO(vsm): Handle overloads.
      # TODO(jacobr): handle document more efficiently for cases where any
      # document is fine.  For example: use window.document instead of
      # this.parentNode.
      return_type = self._NarrowOutputType(info.type_name)
      self._members_emitter.Emit(
          '\n'
          '  $TYPE $PRIVATE$NAME($PARAMS)'
          ' native "$(RETURN)$(THIS).$NAME($PARAMNAMES);";\n',
          TYPE=return_type,
          RETURN='' if return_type == 'void' else 'return ',
          NAME=info.name,
          PRIVATE='_' if private_in_html else '',
          THIS='this.parentNode' if self._interface.id == 'Document'
              else 'this',
          PARAMNAMES=info.ParametersAsArgumentList(),
          PARAMS=info.ParametersImplementationDeclaration(
              lambda type_name: self._NarrowInputType(type_name)))
    elif self._system._AllowInHtmlLibrary(self._interface, info.name):
      # TODO(jacobr): this is duplicated from the parent class.
      self._members_emitter.Emit(
          '\n'
          '  $TYPE $NAME($PARAMS) native;\n',
          TYPE=self._NarrowOutputType(info.type_name),
          NAME=info.name,
          PARAMS=info.ParametersImplementationDeclaration(
              lambda type_name: self._NarrowInputType(type_name)))

  def AddEventAttributes(self, event_attrs):
    event_attrs = _DomToHtmlEvents(self._interface.id, event_attrs)
    events_class = '_' + self._interface.id + 'EventsImpl'
    events_interface = self._interface.id + 'Events'
    self._members_emitter.Emit(
        '\n  $TYPE get on() =>\n    new $TYPE($EVENTTARGET);\n',
        TYPE=events_class,
        EVENTTARGET='_jsDocument' if self._interface.id == 'Document'
            else 'this')

    self._system._event_classes.add(self._interface.id)

    parent_event_classes = self._system._GetParentsEventsClasses(
        self._interface)
    if len(parent_event_classes) != 1:
      raise Exception('Only one parent event class allowed '
          + self._interface.id)

    # TODO(jacobr): specify the type of _ptr as EventTarget
    events_members = self._dart_code.Emit(
        '\n'
        'class $CLASSNAME extends $SUPER implements $INTERFACE {\n'
        '  $CLASSNAME(_ptr) : super(_ptr);\n'
        '$!MEMBERS}\n',
        TARGETCLASS=self._NarrowOutputType(self._interface.id),
        CLASSNAME=events_class,
        INTERFACE=events_interface,
        SUPER='_' + parent_event_classes[0] + 'Impl')

    for event_name in event_attrs:
      if event_name in _html_event_names:
        events_members.Emit(
            "\n"
            "  EventListenerList get $NAME() => _get('$RAWNAME');\n",
            RAWNAME=event_name,
            NAME=_html_event_names[event_name])
      else:
        raise Exception('No known html even name for event: ' + event_name)

# ------------------------------------------------------------------------------

class HtmlFrogSystem(HtmlSystem):

  def __init__(self, templates, database, emitters, output_dir, generator):
    super(HtmlFrogSystem, self).__init__(
        templates, database, emitters, output_dir, generator)
    self._dart_frog_file_paths = []


  def InterfaceGenerator(self,
                         interface,
                         common_prefix,
                         super_interface_name,
                         source_filter):
    """."""
    dart_frog_file_path = self._FilePathForFrogImpl(interface.id)
    self._dart_frog_file_paths.append(dart_frog_file_path)

    template_file = 'impl_%s.darttemplate' % interface.id
    template = self._templates.TryLoad(template_file)
    if not template:
      template = self._templates.Load('frog_impl.darttemplate')

    dart_code = self._emitters.FileEmitter(dart_frog_file_path)
    return HtmlFrogClassGenerator(self, interface, template,
                                  super_interface_name, dart_code)

  def GenerateLibraries(self, lib_dir):
    self._GenerateLibFile(
        'html_frog.darttemplate',
        os.path.join(lib_dir, 'html_frog.dart'),
        (self._interface_system._dart_interface_file_paths +
         self._interface_system._dart_callback_file_paths +
         self._dart_frog_file_paths))

  def Finish(self):
    pass

  def _FilePathForFrogImpl(self, interface_name):
    """Returns the file path of the Frog implementation."""
    # TODO(jmesserly): is this the right path
    return os.path.join(self._output_dir, 'html', 'frog',
                        '%s.dart' % interface_name)

# ------------------------------------------------------------------------------

class WrappingInterfaceGenerator(object):
  """Generates Dart and JS implementation for one DOM IDL interface."""

  def __init__(self, interface, super_interface, dart_code, base_members):
    """Generates Dart and JS code for the given interface.

    Args:

      interface: an IDLInterface instance. It is assumed that all types have
          been converted to Dart types (e.g. int, String), unless they are in
          the same package as the interface.
      super_interface: A string or None, the name of the common interface that
         this interface implements, if any.
      dart_code: an Emitter for the file containing the Dart implementation
          class.
      base_members: a set of names of members defined in a base class.  This is
          used to avoid static member 'overriding' in the generated Dart code.
    """
    self._interface = interface
    self._super_interface = super_interface
    self._dart_code = dart_code
    self._base_members = base_members
    self._current_secondary_parent = None


  def StartInterface(self):
    interface = self._interface
    interface_name = interface.id

    self._class_name = self._ImplClassName(interface_name)

    base = self._BaseClassName(interface)

    (self._members_emitter,
     self._top_level_emitter) = self._dart_code.Emit(
        '\n'
        'class $CLASS extends $BASE implements $INTERFACE {\n'
        '  $CLASS() : super() {}\n'
        '\n'
        '  static create_$CLASS() native {\n'
        '    return new $CLASS();\n'
        '  }\n'
        '$!MEMBERS'
        '\n'
        '  String get typeName() { return "$INTERFACE"; }\n'
        '}\n'
        '$!TOP_LEVEL',
        CLASS=self._class_name, BASE=base, INTERFACE=interface_name)

  def _ImplClassName(self, type_name):
    return '_' + type_name + 'WrappingImplementation'

  def _BaseClassName(self, interface):
    if not interface.parents:
      return 'DOMWrapperBase'

    supertype = interface.parents[0].type.id

    # FIXME: We're currently injecting List<..> and EventTarget as
    # supertypes in dart.idl. We should annotate/preserve as
    # attributes instead.  For now, this hack lets the interfaces
    # inherit, but not the classes.
    # List methods are injected in AddIndexer.
    if IsDartListType(supertype) or IsDartCollectionType(supertype):
      return 'DOMWrapperBase'

    if supertype == 'EventTarget':
      # Most implementors of EventTarget specify the EventListener operations
      # again.  If the operations are not specified, try to inherit from the
      # EventTarget implementation.
      #
      # Applies to MessagePort.
      if not [op for op in interface.operations if op.id == 'addEventListener']:
        return self._ImplClassName(supertype)
      return 'DOMWrapperBase'

    return self._ImplClassName(supertype)

  def FinishInterface(self):
    """."""
    pass

  def AddConstant(self, constant):
    # Constants are already defined on the interface.
    pass

  def _MethodName(self, prefix, name):
    method_name = prefix + name
    if name in self._base_members:  # Avoid illegal Dart 'static override'.
      method_name = method_name + '_' + self._interface.id
    return method_name

  def AddAttribute(self, getter, setter):
    if getter:
      self._AddGetter(getter)
    if setter:
      self._AddSetter(setter)

  def _AddGetter(self, attr):
    # FIXME: Instead of injecting the interface name into the method when it is
    # also implemented in the base class, suppress the method altogether if it
    # has the same signature.  I.e., let the JS do the virtual dispatch instead.
    method_name = self._MethodName('_get_', attr.id)
    self._members_emitter.Emit(
        '\n'
        '  $TYPE get $NAME() { return $METHOD(this); }\n'
        '  static $TYPE $METHOD(var _this) native;\n',
        NAME=attr.id, TYPE=attr.type.id, METHOD=method_name)

  def _AddSetter(self, attr):
    # FIXME: See comment on getter.
    method_name = self._MethodName('_set_', attr.id)
    self._members_emitter.Emit(
        '\n'
        '  void set $NAME($TYPE value) { $METHOD(this, value); }\n'
        '  static void $METHOD(var _this, $TYPE value) native;\n',
        NAME=attr.id, TYPE=attr.type.id, METHOD=method_name)

  def AddSecondaryAttribute(self, interface, getter, setter):
    self._SecondaryContext(interface)
    self.AddAttribute(getter, setter)

  def AddSecondaryOperation(self, interface, info):
    self._SecondaryContext(interface)
    self.AddOperation(info)

  def AddEventAttributes(self, event_attrs):
    pass

  def _SecondaryContext(self, interface):
    if interface is not self._current_secondary_parent:
      self._current_secondary_parent = interface
      self._members_emitter.Emit('\n  // From $WHERE\n', WHERE=interface.id)

  def AddIndexer(self, element_type):
    """Adds all the methods required to complete implementation of List."""
    # We would like to simply inherit the implementation of everything except
    # get length(), [], and maybe []=.  It is possible to extend from a base
    # array implementation class only when there is no other implementation
    # inheritance.  There might be no implementation inheritance other than
    # DOMBaseWrapper for many classes, but there might be some where the
    # array-ness is introduced by a non-root interface:
    #
    #   interface Y extends X, List<T> ...
    #
    # In the non-root case we have to choose between:
    #
    #   class YImpl extends XImpl { add List<T> methods; }
    #
    # and
    #
    #   class YImpl extends ListBase<T> { copies of transitive XImpl methods; }
    #
    if self._HasNativeIndexGetter(self._interface):
      self._EmitNativeIndexGetter(self._interface, element_type)
    else:
      self._members_emitter.Emit(
          '\n'
          '  $TYPE operator[](int index) {\n'
          '    return item(index);\n'
          '  }\n',
          TYPE=DartType(element_type))

    if self._HasNativeIndexSetter(self._interface):
      self._EmitNativeIndexSetter(self._interface, element_type)
    else:
      self._members_emitter.Emit(
          '\n'
          '  void operator[]=(int index, $TYPE value) {\n'
          '    throw new UnsupportedOperationException("Cannot assign element of immutable List.");\n'
          '  }\n',
          TYPE=element_type)

    self._members_emitter.Emit(
        '\n'
        '  void add($TYPE value) {\n'
        '    throw new UnsupportedOperationException("Cannot add to immutable List.");\n'
        '  }\n'
        '\n'
        '  void addLast($TYPE value) {\n'
        '    throw new UnsupportedOperationException("Cannot add to immutable List.");\n'
        '  }\n'
        '\n'
        '  void addAll(Collection<$TYPE> collection) {\n'
        '    throw new UnsupportedOperationException("Cannot add to immutable List.");\n'
        '  }\n'
        '\n'
        '  void sort(int compare($TYPE a, $TYPE b)) {\n'
        '    throw new UnsupportedOperationException("Cannot sort immutable List.");\n'
        '  }\n'
        '\n'
        '  void copyFrom(List<Object> src, int srcStart, '
        'int dstStart, int count) {\n'
        '    throw new UnsupportedOperationException("This object is immutable.");\n'
        '  }\n'
        '\n'
        '  int indexOf($TYPE element, [int start = 0]) {\n'
        '    return _Lists.indexOf(this, element, start, this.length);\n'
        '  }\n'
        '\n'
        '  int lastIndexOf($TYPE element, [int start = null]) {\n'
        '    if (start === null) start = length - 1;\n'
        '    return _Lists.lastIndexOf(this, element, start);\n'
        '  }\n'
        '\n'
        '  int clear() {\n'
        '    throw new UnsupportedOperationException("Cannot clear immutable List.");\n'
        '  }\n'
        '\n'
        '  $TYPE removeLast() {\n'
        '    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");\n'
        '  }\n'
        '\n'
        '  $TYPE last() {\n'
        '    return this[length - 1];\n'
        '  }\n'
        '\n'
        '  void forEach(void f($TYPE element)) {\n'
        '    _Collections.forEach(this, f);\n'
        '  }\n'
        '\n'
        '  Collection map(f($TYPE element)) {\n'
        '    return _Collections.map(this, [], f);\n'
        '  }\n'
        '\n'
        '  Collection<$TYPE> filter(bool f($TYPE element)) {\n'
        '    return _Collections.filter(this, new List<$TYPE>(), f);\n'
        '  }\n'
        '\n'
        '  bool every(bool f($TYPE element)) {\n'
        '    return _Collections.every(this, f);\n'
        '  }\n'
        '\n'
        '  bool some(bool f($TYPE element)) {\n'
        '    return _Collections.some(this, f);\n'
        '  }\n'
        '\n'
        '  void setRange(int start, int length, List<$TYPE> from, [int startFrom]) {\n'
        '    throw new UnsupportedOperationException("Cannot setRange on immutable List.");\n'
        '  }\n'
        '\n'
        '  void removeRange(int start, int length) {\n'
        '    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");\n'
        '  }\n'
        '\n'
        '  void insertRange(int start, int length, [$TYPE initialValue]) {\n'
        '    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");\n'
        '  }\n'
        '\n'
        '  List<$TYPE> getRange(int start, int length) {\n'
        '    throw new NotImplementedException();\n'
        '  }\n'
        '\n'
        '  bool isEmpty() {\n'
        '    return length == 0;\n'
        '  }\n'
        '\n'
        '  Iterator<$TYPE> iterator() {\n'
        '    return new _FixedSizeListIterator<$TYPE>(this);\n'
        '  }\n',
        TYPE=element_type)

  def _HasNativeIndexGetter(self, interface):
    return ('HasIndexGetter' in interface.ext_attrs or
            'HasNumericIndexGetter' in interface.ext_attrs)

  def _EmitNativeIndexGetter(self, interface, element_type):
    method_name = '_index'
    self._members_emitter.Emit(
        '\n'
        '  $TYPE operator[](int index) { return $METHOD(this, index); }\n'
        '  static $TYPE $METHOD(var _this, int index) native;\n',
        TYPE=element_type, METHOD=method_name)

  def _HasNativeIndexSetter(self, interface):
    return 'HasCustomIndexSetter' in interface.ext_attrs

  def _EmitNativeIndexSetter(self, interface, element_type):
    method_name = '_set_index'
    self._members_emitter.Emit(
        '\n'
        '  void operator[]=(int index, $TYPE value) {\n'
        '    return $METHOD(this, index, value);\n'
        '  }\n'
        '  static $METHOD(_this, index, value) native;\n',
        TYPE=element_type, METHOD=method_name)

  def AddOperation(self, info):
    """
    Arguments:
      info: An OperationInfo object.
    """
    body = self._members_emitter.Emit(
        '\n'
        '  $TYPE $NAME($PARAMS) {\n'
        '$!BODY'
        '  }\n',
        TYPE=info.type_name,
        NAME=info.name,
        PARAMS=info.ParametersImplementationDeclaration())

    # Process in order of ascending number of arguments to ensure missing
    # optional arguments are processed early.
    overloads = sorted(info.overloads,
                       key=lambda overload: len(overload.arguments))
    self._native_version = 0
    fallthrough = self.GenerateDispatch(body, info, '    ', 0, overloads)
    if fallthrough:
      body.Emit('    throw "Incorrect number or type of arguments";\n');

  def GenerateSingleOperation(self,  emitter, info, indent, operation):
    """Generates a call to a single operation.

    Arguments:
      emitter: an Emitter for the body of a block of code.
      info: the compound information about the operation and its overloads.
      indent: an indentation string for generated code.
      operation: the IDLOperation to call.
    """
    # TODO(sra): Do we need to distinguish calling with missing optional
    # arguments from passing 'null' which is represented as 'undefined'?
    def UnwrapArgExpression(name, type):
      # TODO: Type specific unwrapping.
      return '__dom_unwrap(%s)' % (name)

    def ArgNameAndUnwrapper(arg_info, overload_arg):
      (name, type, value) = arg_info
      return (name, UnwrapArgExpression(name, type))

    names_and_unwrappers = [ArgNameAndUnwrapper(info.arg_infos[i], arg)
                            for (i, arg) in enumerate(operation.arguments)]
    unwrap_args = [unwrap_arg for (_, unwrap_arg) in names_and_unwrappers]
    arg_names = [name for (name, _) in names_and_unwrappers]

    self._native_version += 1
    native_name = self._MethodName('_', info.name)
    if self._native_version > 1:
      native_name = '%s_%s' % (native_name, self._native_version)

    argument_expressions = ', '.join(['this'] + arg_names)
    if info.type_name != 'void':
      emitter.Emit('$(INDENT)return $NATIVENAME($ARGS);\n',
                   INDENT=indent,
                   NATIVENAME=native_name,
                   ARGS=argument_expressions)
    else:
      emitter.Emit('$(INDENT)$NATIVENAME($ARGS);\n'
                   '$(INDENT)return;\n',
                   INDENT=indent,
                   NATIVENAME=native_name,
                   ARGS=argument_expressions)

    self._members_emitter.Emit('  static $TYPE $NAME($PARAMS) native;\n',
                               NAME=native_name,
                               TYPE=info.type_name,
                               PARAMS=', '.join(['receiver'] + arg_names) )


  def GenerateDispatch(self, emitter, info, indent, position, overloads):
    """Generates a dispatch to one of the overloads.

    Arguments:
      emitter: an Emitter for the body of a block of code.
      info: the compound information about the operation and its overloads.
      indent: an indentation string for generated code.
      position: the index of the parameter to dispatch on.
      overloads: a list of the remaining IDLOperations to dispatch.

    Returns True if the dispatch can fall through on failure, False if the code
    always dispatches.
    """

    def NullCheck(name):
      return '%s === null' % name

    def TypeCheck(name, type):
      return '%s is %s' % (name, type)

    if position == len(info.arg_infos):
      if len(overloads) > 1:
        raise Exception('Duplicate operations ' + str(overloads))
      operation = overloads[0]
      self.GenerateSingleOperation(emitter, info, indent, operation)
      return False

    # FIXME: Consider a simpler dispatch that iterates over the
    # overloads and generates an overload specific check.  Revisit
    # when we move to named optional arguments.

    # Partition the overloads to divide and conquer on the dispatch.
    positive = []
    negative = []
    first_overload = overloads[0]
    (param_name, param_type, param_default) = info.arg_infos[position]

    if position < len(first_overload.arguments):
      # FIXME: This will not work if the second overload has a more
      # precise type than the first.  E.g.,
      # void foo(Node x);
      # void foo(Element x);
      type = first_overload.arguments[position].type.id
      test = TypeCheck(param_name, type)
      pred = lambda op: len(op.arguments) > position and op.arguments[position].type.id == type
    else:
      type = None
      test = NullCheck(param_name)
      pred = lambda op: position >= len(op.arguments)

    for overload in overloads:
      if pred(overload):
        positive.append(overload)
      else:
        negative.append(overload)

    if positive and negative:
      (true_code, false_code) = emitter.Emit(
          '$(INDENT)if ($COND) {\n'
          '$!TRUE'
          '$(INDENT)} else {\n'
          '$!FALSE'
          '$(INDENT)}\n',
          COND=test, INDENT=indent)
      fallthrough1 = self.GenerateDispatch(
          true_code, info, indent + '  ', position + 1, positive)
      fallthrough2 = self.GenerateDispatch(
          false_code, info, indent + '  ', position, negative)
      return fallthrough1 or fallthrough2

    if negative:
      raise Exception('Internal error, must be all positive')

    # All overloads require the same test.  Do we bother?

    # If the test is the same as the method's formal parameter then checked mode
    # will have done the test already. (It could be null too but we ignore that
    # case since all the overload behave the same and we don't know which types
    # in the IDL are not nullable.)
    if type == param_type:
      return self.GenerateDispatch(
          emitter, info, indent, position + 1, positive)

    # Otherwise the overloads have the same type but the type is a substype of
    # the method's synthesized formal parameter. e.g we have overloads f(X) and
    # f(Y), implemented by the synthesized method f(Z) where X<Z and Y<Z. The
    # dispatch has removed f(X), leaving only f(Y), but there is no guarantee
    # that Y = Z-X, so we need to check for Y.
    true_code = emitter.Emit(
        '$(INDENT)if ($COND) {\n'
        '$!TRUE'
        '$(INDENT)}\n',
        COND=test, INDENT=indent)
    self.GenerateDispatch(
        true_code, info, indent + '  ', position + 1, positive)
    return True
