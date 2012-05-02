#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides shared functionality for the system to generate
Dart:html APIs from the IDL database."""

from systemfrog import *
from systeminterface import *

# Members from the standard dom that should not be exposed publicly in dart:html
# but need to be exposed internally to implement dart:html on top of a standard
# browser.
_private_html_members = set([
  'Document.createElement',
  'Document.createElementNS',
  'Document.createEvent',
  'Document.createTextNode',
  'Document.createTouchList',
  'Document.getElementById',
  'Document.getElementsByClassName',
  'Document.getElementsByName',
  'Document.getElementsByTagName',
  'Document.querySelectorAll',
  'DocumentFragment.querySelectorAll',
  'Element.childElementCount',
  'Element.children',
  'Element.className',
  'Element.clientHeight',
  'Element.clientLeft',
  'Element.clientTop',
  'Element.clientWidth',
  'Element.firstElementChild',
  'Element.getAttribute',
  'Element.getBoundingClientRect',
  'Element.getClientRects',
  'Element.getElementsByClassName',
  'Element.getElementsByTagName',
  'Element.hasAttribute',
  'Element.lastElementChild',
  'Element.offsetHeight',
  'Element.offsetLeft',
  'Element.offsetTop',
  'Element.offsetWidth',
  'Element.querySelectorAll',
  'Element.removeAttribute',
  'Element.scrollHeight',
  'Element.scrollLeft',
  'Element.scrollTop',
  'Element.scrollWidth',
  'Element.setAttribute',
  'Event.initEvent',
  'EventTarget.addEventListener',
  'EventTarget.dispatchEvent',
  'EventTarget.removeEventListener',
  'MouseEvent.initMouseEvent',
  'Node.appendChild',
  'Node.attributes',
  'Node.childNodes',
  'Node.firstChild',
  'Node.lastChild',
  "Node.nodeType",
  'Node.removeChild',
  'Node.replaceChild',
  'NodeSelector.querySelectorAll',
  'Storage.length',
  'Storage.clear',
  'Storage.getItem',
  'Storage.key',
  'Storage.removeItem',
  'Storage.setItem',
  'Window.getComputedStyle',
])

_manually_generated_html_members = set([
  'Document.querySelectorAll',
  'Document.querySelector',
])

# Members from the standard dom that exist in the dart:html library with
# identical functionality but with cleaner names.
_html_library_renames = {
    'Document.defaultView': 'window',
    'DocumentFragment.querySelector': 'query',
    'NodeSelector.querySelector': 'query',
    'Element.querySelector': 'query',
    'Element.webkitMatchesSelector' : 'matchesSelector',
    'Element.scrollIntoViewIfNeeded': 'scrollIntoView',
    'Node.cloneNode': 'clone',
    'Node.nextSibling': 'nextNode',
    'Node.ownerDocument': 'document',
    'Node.parentNode': 'parent',
    'Node.previousSibling': 'previousNode',
    'Node.textContent': 'text',
    'SVGElement.className': '$dom_svgClassName',
    'SVGAnimatedString.className': '$dom_svgClassName',
    'SVGStylable.className': '$dom_svgClassName',
}

#TODO(jacobr): inject annotations into the interfaces based on this table and
# on _html_library_renames.
_injected_doc_fragments = {
    'Element.query': '  /** @domName Element.querySelector, Document.getElementById */',
}
# Members and classes from the dom that should be removed completelly from
# dart:html.  These could be expressed in the IDL instead but expressing this
# as a simple table instead is more concise.
# Syntax is: ClassName.(get\.|set\.)?MemberName
# Using get: and set: is optional and should only be used when a getter needs
# to be suppressed but not the setter, etc. 
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
    "Document.get:forms",
#    "Document.get:selectedStylesheetSet",
#    "Document.set:selectedStylesheetSet",
#    "Document.get:preferredStylesheetSet",
    "Document.get:links",
    "Document.set:domain",
    "Document.get:implementation",
    "Document.createAttributeNS",
    "Document.get:inputEncoding",
    "Document.get:height",
    "Document.get:width",
    "Element.getElementsByTagNameNS",
    "Document.get:compatMode",
    "Document.importNode",
    "Document.evaluate",
    "Document.get:images",
    "Document.createExpression",
    "Document.getOverrideStyle",
    "Document.xmlStandalone",
    "Document.createComment",
    "Document.adoptNode",
    "Document.get:characterSet",
    "Document.createAttribute",
    "Document.get:URL",
    "Document.createEntityReference",
    "Document.get:documentURI",
    "Document.set:documentURI",
    "Document.createNodeIterator",
    "Document.createProcessingInstruction",
    "Document.get:doctype",
    "Document.createTreeWalker",
    "Document.location",
    "Document.createNSResolver",
    "Document.get:xmlEncoding",
    "Document.get:defaultCharset",
    "Document.get:applets",
    "Document.getSelection",
    "Document.xmlVersion",
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
    "BodyElement.text",
    "AnchorElement.text",
    "OptionElement.text",
    "ScriptElement.text",
    "TitleElement.text",
#    "EventSource.get:url",
# TODO(jacobr): should these be removed?
    "Document.close",
    "Document.hasFocus",

    "Document.vlinkColor",
    "Document.captureEvents",
    "Document.releaseEvents",
    "Document.get:compatMode",
    "Document.designMode",
    "Document.dir",
    "Document.all",
    "Document.write",
    "Document.fgColor",
    "Document.bgColor",
    "Document.get:plugins",
    "Document.alinkColor",
    "Document.get:embeds",
    "Document.open",
    "Document.clear",
    "Document.get:scripts",
    "Document.writeln",
    "Document.linkColor",
    "Element.get:itemRef",
    "Element.outerText",
    "Element.accessKey",
    "Element.get:itemType",
    "Element.innerText",
    "Element.set:outerHTML",
    "Element.itemScope",
    "Element.itemValue",
    "Element.itemId",
    "Element.get:itemProp",
    'Element.scrollIntoView',
    'Element.get:classList',
    "EmbedElement.getSVGDocument",
    "FormElement.get:elements",
    "HTMLFrameElement.*",
    "HTMLFrameSetElement.*",
    "HtmlElement.version",
    "HtmlElement.manifest",
    "Document.version",
    "Document.manifest",
#    "IFrameElement.getSVGDocument",  #TODO(jacobr): should this be removed
    "InputElement.dirName",
    "HTMLIsIndexElement.*",
    "ObjectElement.getSVGDocument",
    "HTMLOptionsCollection.*",
    "HTMLPropertiesCollection.*",
    "SelectElement.remove",
    "TextAreaElement.dirName",
    "NamedNodeMap.*",
    "Node.isEqualNode",
    "Node.get:TEXT_NODE",
    "Node.hasAttributes",
    "Node.get:DOCUMENT_TYPE_NODE",
    "Node.get:DOCUMENT_POSITION_FOLLOWING",
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
    "Node.get:DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC",
    "Node.get:NOTATION_NODE",
    "Node.normalize",
    "Node.get:parentElement",
    "Node.get:ATTRIBUTE_NODE",
    "Node.get:ENTITY_NODE",
    "Node.get:DOCUMENT_POSITION_CONTAINED_BY",
    "Node.get:prefix",
    "Node.set:prefix",
    "Node.get:DOCUMENT_POSITION_PRECEDING",
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
  'Element': ['touchleave', 'touchenter', 'webkitTransitionEnd'],
  'Window': ['DOMContentLoaded']
}

# These event names must be camel case when attaching event listeners
# using addEventListener even though the onEventName properties in the DOM for
# them are not camel case.
_on_attribute_to_event_name_mapping = {
  'webkitanimationend': 'webkitAnimationEnd',
  'webkitanimationiteration': 'webkitAnimationIteration',
  'webkitanimationstart': 'webkitAnimationStart',
  'webkitspeechchange': 'webkitSpeechChange',
  'webkittransitionend': 'webkitTransitionEnd',
}

# Mapping from raw event names to the pretty camelCase event names exposed as
# properties in dart:html.  If the DOM exposes a new event name, you will need
# to add the lower case to camel case conversion for that event name here.
_html_event_names = {
  'DOMContentLoaded': 'contentLoaded',
  'abort': 'abort',
  'addstream': 'addStream',
  'addtrack': 'addTrack',
  'audioend': 'audioEnd',
  'audioprocess': 'audioProcess',
  'audiostart': 'audioStart',
  'beforecopy': 'beforeCopy',
  'beforecut': 'beforeCut',
  'beforepaste': 'beforePaste',
  'beforeunload': 'beforeUnload',
  'blocked': 'blocked',
  'blur': 'blur',
  'cached': 'cached',
  'canplay': 'canPlay',
  'canplaythrough': 'canPlayThrough',
  'change': 'change',
  'chargingchange': 'chargingChange',
  'chargingtimechange': 'chargingTimeChange',
  'checking': 'checking',
  'click': 'click',
  'close': 'close',
  'complete': 'complete',
  'connect': 'connect',
  'connecting': 'connecting',
  'contextmenu': 'contextMenu',
  'copy': 'copy',
  'cuechange': 'cueChange',
  'cut': 'cut',
  'dblclick': 'doubleClick',
  'devicemotion': 'deviceMotion',
  'deviceorientation': 'deviceOrientation',
  'dischargingtimechange': 'dischargingTimeChange',
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
  'end': 'end',
  'ended': 'ended',
  'enter': 'enter',
  'error': 'error',
  'exit': 'exit',
  'focus': 'focus',
  'hashchange': 'hashChange',
  'input': 'input',
  'invalid': 'invalid',
  'keydown': 'keyDown',
  'keypress': 'keyPress',
  'keyup': 'keyUp',
  'levelchange': 'levelChange',
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
  'nomatch': 'noMatch',
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
  'removestream': 'removeStream',
  'reset': 'reset',
  'resize': 'resize',
  'result': 'result',
  'resultdeleted': 'resultDeleted',
  'scroll': 'scroll',
  'search': 'search',
  'seeked': 'seeked',
  'seeking': 'seeking',
  'select': 'select',
  'selectionchange': 'selectionChange',
  'selectstart': 'selectStart',
  'show': 'show',
  'soundend': 'soundEnd',
  'soundstart': 'soundStart',
  'speechend': 'speechEnd',
  'speechstart': 'speechStart',
  'stalled': 'stalled',
  'start': 'start',
  'statechange': 'stateChange',
  'storage': 'storage',
  'submit': 'submit',
  'success': 'success',
  'suspend': 'suspend',
  'timeupdate': 'timeUpdate',
  'touchcancel': 'touchCancel',
  'touchend': 'touchEnd',
  'touchenter': 'touchEnter',
  'touchleave': 'touchLeave',
  'touchmove': 'touchMove',
  'touchstart': 'touchStart',
  'unload': 'unload',
  'updateready': 'updateReady',
  'versionchange': 'versionChange',
  'volumechange': 'volumeChange',
  'waiting': 'waiting',
  'webkitAnimationEnd': 'animationEnd',
  'webkitAnimationIteration': 'animationIteration',
  'webkitAnimationStart': 'animationStart',
  'webkitfullscreenchange': 'fullscreenChange',
  'webkitfullscreenerror': 'fullscreenError',
  'webkitkeyadded': 'keyAdded',
  'webkitkeyerror': 'keyError',
  'webkitkeymessage': 'keyMessage',
  'webkitneedkey': 'needKey',
  'webkitSpeechChange': 'speechChange',
  'webkitTransitionEnd': 'transitionEnd',
  'write': 'write',
  'writeend': 'writeEnd',
  'writestart': 'writeStart'
}

# These classes require an explicit declaration for the "on" method even though
# they don't declare any unique events, because the concrete class hierarchy
# doesn't match the interface hierarchy.
_html_explicit_event_classes = set(['DocumentFragment'])

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
class HtmlSystemShared(object):

  def __init__(self, database, generator):
    self._event_classes = set()
    self._seen_event_names = {}
    self._database = database
    self._generator = generator

  def _AllowInHtmlLibrary(self, interface, member, member_prefix):
    return not self._Matches(interface, member, member_prefix,
        _html_library_remove)

  def _Matches(self, interface, member, member_prefix, candidates):
    for interface_name in self._AllAncestorInterfaces(interface):
      if (DartType(interface_name) + '.' + member in candidates or
          DartType(interface_name) + '.' + member_prefix + member in candidates):
        return True
    return False

  def _AllAncestorInterfaces(self, interface):
    interfaces = ([interface.id] +
        self._generator._AllImplementedInterfaces(interface))
    return interfaces

  def RenameInHtmlLibrary(self, interface, member, member_prefix='',
                          implementation_class=False):
    """
    Returns the name of the member in the HTML library or None if the member is
    suppressed in the HTML library
    """
    if not self._AllowInHtmlLibrary(interface, member, member_prefix):
      return None

    target_name = member
    for interface_name in self._AllAncestorInterfaces(interface):
      name = interface_name + '.' + member
      if name in _html_library_renames:
        target_name = _html_library_renames[name]
      name = interface.id + '.' + member_prefix + member
      if name in _html_library_renames:
        target_name = _html_library_renames[name]

    if not target_name.startswith('_'):
      if self._PrivateInHtmlLibrary(interface, member, member_prefix):
        if not target_name.startswith('$dom_'):  # e.g. $dom_svgClassName
          target_name = '$dom_' + target_name
      elif implementation_class and self._ManuallyGeneratedInHtmlLibrary(
          interface, member, member_prefix):
        target_name = '_' + target_name

    # No rename required
    return target_name

  def _PrivateInHtmlLibrary(self, interface, member, member_prefix):
    return self._Matches(interface, member, member_prefix,
        _private_html_members)

  def _ManuallyGeneratedInHtmlLibrary(self, interface, member, member_prefix):
    return self._Matches(interface, member, member_prefix,
        _manually_generated_html_members)

  # TODO(jacobr): this already exists
  def _TraverseParents(self, interface, callback):
    for parent in interface.parents:
      parent_id = parent.type.id
      if self._database.HasInterface(parent_id):
        parent_interface = self._database.GetInterface(parent_id)
        callback(parent_interface)
        self._TraverseParents(parent_interface, callback)

  # TODO(jacobr): this isn't quite right.... 
  def GetParentsEventsClasses(self, interface):
    # Ugly hack as we don't specify that Document and DocumentFragment inherit
    # from Element in our IDL.
    if interface.id == 'Document' or interface.id == 'DocumentFragment':
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

  def GetParentEventsClass(self, interface):
    parent_event_classes = self.GetParentsEventsClasses(interface)
    if len(parent_event_classes) != 1:
      raise Exception('Only one parent event class allowed ' + interface.id)
    return parent_event_classes[0]

  def _ImplClassName(self, type_name):
    return '_' + type_name + 'Impl'

  # This returns two values: the first is whether or not an "on" property should
  # be generated for the interface, and the second is the event attributes to
  # generate if it should.
  def GetEventAttributes(self, interface):
    events =  set([attr for attr in interface.attributes
                   if attr.type.id == 'EventListener'])

    if events or interface.id in _html_explicit_event_classes:
      return True, events
    else:
      return False, None

  def IsPrivate(self, name):
    return name.startswith('_')

class HtmlSystem(System):

  def __init__(self, templates, database, emitters, output_dir, generator):
    super(HtmlSystem, self).__init__(
        templates, database, emitters, output_dir)
    self._shared = HtmlSystemShared(database, generator)

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
        source_filter, self, self._shared)

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
               common_prefix, super_interface, source_filter, system, shared):
    super(HtmlDartInterfaceGenerator, self).__init__(interface,
      emitter, template, common_prefix, super_interface, source_filter)
    self._system = system
    self._shared = shared

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
        extends.append(DartType(parent.type.id))
      else:
        suppressed_extends.append('%s.%s' %
            (self._common_prefix, DartType(parent.type.id)))

    comment = ' extends'
    extends_str = ''
    if extends:
      extends_str += ' extends ' + ', '.join(extends)
      comment = ','
    if suppressed_extends:
      extends_str += ' /*%s %s */' % (comment, ', '.join(suppressed_extends))

    factory_provider = None
    constructor_info = AnalyzeConstructor(self._interface)
    if constructor_info:
      factory_provider = '_' + typename + 'FactoryProvider';

    if typename in interface_factories:
      factory_provider = interface_factories[typename]

    if factory_provider:
      extends_str += ' default ' + factory_provider

    # TODO(vsm): Add appropriate package / namespace syntax.
    (self._type_comment_emitter,
     self._members_emitter,
     self._top_level_emitter) = self._emitter.Emit(
         self._template + '$!TOP_LEVEL',
         ID=typename,
         EXTENDS=extends_str)

    self._type_comment_emitter.Emit("/// @domName $DOMNAME",
        DOMNAME=self._interface.doc_js_name)

    if constructor_info:
      self._members_emitter.Emit(
          '\n'
          '  $CTOR($PARAMS);\n',
          CTOR=typename,
          PARAMS=constructor_info.ParametersInterfaceDeclaration());

    element_type = MaybeTypedArrayElementType(self._interface)
    if element_type:
      self._members_emitter.Emit(
          '\n'
          '  $CTOR(int length);\n'
          '\n'
          '  $CTOR.fromList(List<$TYPE> list);\n'
          '\n'
          '  $CTOR.fromBuffer(ArrayBuffer buffer,'
                            ' [int byteOffset, int length]);\n',
        CTOR=self._interface.id,
        TYPE=DartType(element_type))

    emit_events, events = self._shared.GetEventAttributes(self._interface)
    if not emit_events:
      return
    elif events:
      self.AddEventAttributes(events)
    else:
      self._EmitEventGetter(self._shared.GetParentEventsClass(self._interface))

  def AddAttribute(self, getter, setter):
    dom_name = DartDomNameOfAttribute(getter)
    html_getter_name = self._shared.RenameInHtmlLibrary(
      self._interface, dom_name, 'get:')
    html_setter_name = self._shared.RenameInHtmlLibrary(
      self._interface, dom_name, 'set:')

    if not html_getter_name or self._shared.IsPrivate(html_getter_name):
      getter = None
    if not html_setter_name or self._shared.IsPrivate(html_setter_name):
      setter = None
    if not getter and not setter:
      return

    # We don't yet handle inconsistent renames of the getter and setter yet.
    if html_getter_name and html_setter_name:
      assert html_getter_name == html_setter_name

    self._members_emitter.Emit('\n  /** @domName $DOMINTERFACE.$DOMNAME */',
        DOMINTERFACE=getter.doc_js_interface_name,
        DOMNAME=dom_name)
    if (getter and setter and
        DartType(getter.type.id) == DartType(setter.type.id)):
      self._members_emitter.Emit('\n  $TYPE $NAME;\n',
                                 NAME=html_getter_name,
                                 TYPE=DartType(getter.type.id));
      return
    if getter and not setter:
      self._members_emitter.Emit('\n  final $TYPE $NAME;\n',
                                 NAME=html_getter_name,
                                 TYPE=DartType(getter.type.id));
      return
    raise Exception('Unexpected getter/setter combination %s %s' %
                    (getter, setter))

  def AddOperation(self, info):
    """
    Arguments:
      operations - contains the overloads, one or more operations with the same
        name.
    """
    html_name = self._shared.RenameInHtmlLibrary(
        self._interface, info.name)
    if html_name and not self._shared.IsPrivate(html_name):
      self._members_emitter.Emit('\n  /** @domName $DOMINTERFACE.$DOMNAME */',
          DOMINTERFACE=info.overloads[0].doc_js_interface_name,
          DOMNAME=info.name)

      self._members_emitter.Emit('\n'
                                 '  $TYPE $NAME($PARAMS);\n',
                                 TYPE=info.type_name,         
                                 NAME=html_name,
                                 PARAMS=info.ParametersInterfaceDeclaration())

  def FinishInterface(self):
    pass

  def AddConstant(self, constant):
    self._EmitConstant(self._members_emitter, constant)

  def AddEventAttributes(self, event_attrs):
    event_attrs = _DomToHtmlEvents(self._interface.id, event_attrs)
    self._shared._event_classes.add(self._interface.id)
    events_interface = self._interface.id + 'Events'
    self._EmitEventGetter(events_interface)

    events_members = self._emitter.Emit(
        '\ninterface $INTERFACE extends $PARENTS {\n$!MEMBERS}\n',
        INTERFACE=events_interface,
        PARENTS=', '.join(
            self._shared.GetParentsEventsClasses(self._interface)))

    for event_name in event_attrs:
      if event_name in _html_event_names:
        events_members.Emit('\n  EventListenerList get $NAME();\n',
          NAME=_html_event_names[event_name])
      else:
        raise Exception('No known html even name for event: ' + event_name)

  def _EmitEventGetter(self, events_interface):
    self._members_emitter.Emit(
        '\n  /**'
        '\n   * @domName EventTarget.addEventListener, '
        'EventTarget.removeEventListener, EventTarget.dispatchEvent'
        '\n   */'
        '\n  $TYPE get on();\n',
        TYPE=events_interface)

# ------------------------------------------------------------------------------

# TODO(jmesserly): inheritance is probably not the right way to factor this long
# term, but it makes merging better for now.
class HtmlFrogClassGenerator(FrogInterfaceGenerator):
  """Generates a Frog class for the dart:html library from a DOM IDL
  interface.
  """

  def __init__(self, system, interface, template, super_interface, dart_code,
      shared):
    super(HtmlFrogClassGenerator, self).__init__(
        system, interface, template, super_interface, dart_code)
    self._shared = shared

  def _ImplClassName(self, type_name):
    return self._shared._ImplClassName(type_name)

  def StartInterface(self):
    interface = self._interface
    interface_name = interface.id

    self._class_name = self._ImplClassName(interface_name)

    base = None
    if interface.parents:
      supertype = interface.parents[0].type.id
      if IsDartCollectionType(supertype):
        # List methods are injected in AddIndexer.
        pass
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
    if self._members_emitter == None:
      raise Exception("Class %s doesn't use the $!MEMBERS variable" %
                      self._class_name)

    # Emit a factory provider class for the constructor.
    constructor_info = AnalyzeConstructor(interface)
    if constructor_info:
      self._EmitFactoryProvider(interface_name, constructor_info)

    emit_events, events = self._shared.GetEventAttributes(self._interface)
    if not emit_events:
      return
    elif events:
      self.AddEventAttributes(events)
    else:
      parent_events_class = self._shared.GetParentEventsClass(self._interface)
      self._EmitEventGetter('_' + parent_events_class + 'Impl')

  def _EmitFactoryProvider(self, interface_name, constructor_info):
    template_file = 'factoryprovider_%s.darttemplate' % interface_name
    template = self._system._templates.TryLoad(template_file)
    if not template:
      template = self._system._templates.Load('factoryprovider.darttemplate')

    factory_provider = '_' + interface_name + 'FactoryProvider'
    emitter = self._system._ImplFileEmitter(factory_provider)
    emitter.Emit(
        template,
        FACTORYPROVIDER=factory_provider,
        CONSTRUCTOR=interface_name,
        PARAMETERS=constructor_info.ParametersImplementationDeclaration(),
        NAMED_CONSTRUCTOR=constructor_info.name or interface_name,
        ARGUMENTS=constructor_info.ParametersAsArgumentList())

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
    self._members_emitter.Emit(
        '\n'
        '  $TYPE operator[](int index) native "return this[index];";\n',
        TYPE=self._NarrowOutputType(element_type))

    if 'CustomIndexedSetter' in self._interface.ext_attrs:
      self._members_emitter.Emit(
          '\n'
          '  void operator[]=(int index, $TYPE value) native "this[index] = value";\n',
          TYPE=self._NarrowInputType(element_type))
    else:
      # The HTML library implementation of NodeList has a custom indexed setter
      # implementation that uses the parent node the NodeList is associated
      # with if one is available.
      if self._interface.id != 'NodeList':
        self._members_emitter.Emit(
            '\n'
            '  void operator[]=(int index, $TYPE value) {\n'
            '    throw new UnsupportedOperationException("Cannot assign element of immutable List.");\n'
            '  }\n',
            TYPE=self._NarrowInputType(element_type))

    # TODO(sra): Use separate mixins for mutable implementations of List<T>.
    # TODO(sra): Use separate mixins for typed array implementations of List<T>.
    if self._interface.id != 'NodeList':
      template_file = 'immutable_list_mixin.darttemplate'
      template = self._system._templates.Load(template_file)
      self._members_emitter.Emit(template, E=DartType(element_type))

  def AddAttribute(self, getter, setter):
  
    html_getter_name = self._shared.RenameInHtmlLibrary(
      self._interface, DartDomNameOfAttribute(getter), 'get:',
          implementation_class=True)
    html_setter_name = self._shared.RenameInHtmlLibrary(
      self._interface, DartDomNameOfAttribute(getter), 'set:',
          implementation_class=True)

    if not html_getter_name:
      getter = None
    if not html_setter_name:
      setter = None

    if not getter and not setter:
      return

    if ((getter and html_getter_name != getter.id) or
        (setter and html_setter_name != setter.id)):
      if getter:
        self._AddRenamingGetter(getter, html_getter_name)
      if setter:
        self._AddRenamingSetter(setter, html_setter_name)
      return

    # If the (getter, setter) pair is shadowing, we can't generate a shadowing
    # field (Issue 1633).
    (super_getter, super_getter_interface) = self._FindShadowedAttribute(getter)
    (super_setter, super_setter_interface) = self._FindShadowedAttribute(setter)
    if super_getter or super_setter:
      if getter and not setter and super_getter and not super_setter:
        if DartType(getter.type.id) == DartType(super_getter.type.id):
          # Compatible getter, use the superclass property.  This works because
          # JavaScript will do its own dynamic dispatch.
          output_type = getter and self._NarrowOutputType(getter.type.id)
          self._members_emitter.Emit(
              '\n'
              '  // Use implementation from $SUPER.\n'
              '  // final $TYPE $NAME;\n',
              SUPER=super_getter_interface.id,
              NAME=DartDomNameOfAttribute(getter),
              TYPE=output_type)
          return

      self._members_emitter.Emit('\n  // Shadowing definition.')
      self._AddAttributeUsingProperties(getter, setter)
      return

    output_type = getter and self._NarrowOutputType(getter.type.id)
    input_type = setter and self._NarrowInputType(setter.type.id)
    if getter and setter and input_type == output_type:
      self._members_emitter.Emit(
          '\n  $TYPE $NAME;\n',
          NAME=DartDomNameOfAttribute(getter),
          TYPE=output_type)
      return
    if getter and not setter:
      self._members_emitter.Emit(
          '\n  final $TYPE $NAME;\n',
          NAME=DartDomNameOfAttribute(getter),
          TYPE=output_type)
      return
    self._AddAttributeUsingProperties(getter, setter)

  def _AddAttributeUsingProperties(self, getter, setter):
    if getter:
      self._AddGetter(getter)
    if setter:
      self._AddSetter(setter)

  def _AddGetter(self, attr):
    self._AddRenamingGetter(attr, DartDomNameOfAttribute(attr))

  def _AddSetter(self, attr):
    self._AddRenamingSetter(attr, DartDomNameOfAttribute(attr))

  def _AddRenamingGetter(self, attr, html_name):
    return_type = self._NarrowOutputType(attr.type.id)
    self._members_emitter.Emit(
        '\n  $TYPE get $(HTML_NAME)() native "return this.$NAME;";\n',
        HTML_NAME=html_name,
        NAME=attr.id,
        TYPE=return_type)

  def _AddRenamingSetter(self, attr, html_name):
    self._members_emitter.Emit(
        '\n  void set $HTML_NAME($TYPE value)'
        ' native "this.$NAME = value;";\n',
        HTML_NAME=html_name,
        NAME=attr.id,
        TYPE=self._NarrowInputType(attr.type.id))

  def AddOperation(self, info):
    """
    Arguments:
      info: An OperationInfo object.
    """
    html_name = self._shared.RenameInHtmlLibrary(
        self._interface, info.name, implementation_class=True)
    if not html_name:
      return

    # Do we need a native body?
    if html_name != info.declared_name:
      return_type = self._NarrowOutputType(info.type_name)
      
      operation_emitter = self._members_emitter.Emit('$!SCOPE',
          TYPE=return_type,
          HTML_NAME=html_name,
          NAME=info.declared_name,
          PARAMS=info.ParametersImplementationDeclaration(
              lambda type_name: self._NarrowInputType(type_name)))

      operation_emitter.Emit(
          '\n'
          '  $TYPE $(HTML_NAME)($PARAMS) native "$NAME";\n')
    else:
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
    self._EmitEventGetter(events_class)

    self._shared._event_classes.add(self._interface.id)

    parent_event_class = self._shared.GetParentEventsClass(self._interface)

    # TODO(jacobr): specify the type of _ptr as EventTarget
    events_members = self._dart_code.Emit(
        '\n'
        'class $CLASSNAME extends $SUPER implements $INTERFACE {\n'
        '  $CLASSNAME(_ptr) : super(_ptr);\n'
        '$!MEMBERS}\n',
        CLASSNAME=events_class,
        INTERFACE=events_interface,
        SUPER='_' + parent_event_class + 'Impl')

    for event_name in event_attrs:
      if event_name in _html_event_names:
        events_members.Emit(
            "\n"
            "  EventListenerList get $NAME() => _get('$RAWNAME');\n",
            RAWNAME=event_name,
            NAME=_html_event_names[event_name])
      else:
        raise Exception('No known html even name for event: ' + event_name)

  def _EmitEventGetter(self, events_class):
    self._members_emitter.Emit(
        '\n  $TYPE get on() =>\n    new $TYPE(this);\n',
        TYPE=events_class)

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
    template_file = 'impl_%s.darttemplate' % interface.id
    template = self._templates.TryLoad(template_file)
    if not template:
      template = self._templates.Load('frog_impl.darttemplate')

    dart_code = self._ImplFileEmitter(interface.id)
    return HtmlFrogClassGenerator(self, interface, template,
                                  super_interface_name, dart_code, self._shared)

  def GenerateLibraries(self, lib_dir):
    self._GenerateLibFile(
        'html_frog.darttemplate',
        os.path.join(lib_dir, 'html_frog.dart'),
        (self._interface_system._dart_interface_file_paths +
         self._interface_system._dart_callback_file_paths +
         self._dart_frog_file_paths))

  def Finish(self):
    pass

  def _ImplFileEmitter(self, name):
    """Returns the file emitter of the Frog implementation file."""
    # TODO(jmesserly): is this the right path
    path = os.path.join(self._output_dir, 'html', 'frog', '%s.dart' % name)
    self._dart_frog_file_paths.append(path)
    return self._emitters.FileEmitter(path)

# -----------------------------------------------------------------------------

class HtmlDartiumSystem(HtmlSystem):

  def __init__(self, templates, database, emitters, auxiliary_dir, output_dir,
               generator):
    """Prepared for generating wrapping implementation.

    - Creates emitter for Dart code.
    """
    super(HtmlDartiumSystem, self).__init__(
        templates, database, emitters, output_dir, generator)
    self._auxiliary_dir = auxiliary_dir
    self._shared = HtmlSystemShared(database, generator)
    self._dart_dartium_file_paths = []
    self._wrap_cases = []

  def InterfaceGenerator(self,
                         interface,
                         common_prefix,
                         super_interface_name,
                         source_filter):
    """."""
    template_file = 'impl_%s.darttemplate' % interface.id
    template = self._templates.TryLoad(template_file)
    # TODO(jacobr): change this name as it is confusing.
    if not template:
      template = self._templates.Load('frog_impl.darttemplate')

    dart_code = self._ImplFileEmitter(interface.id)
    return HtmlDartiumInterfaceGenerator(self, interface, template,
        super_interface_name, dart_code, self._BaseDefines(interface),
        self._shared)

  def _ImplFileEmitter(self, name):
    """Returns the file emitter of the Dartium implementation file."""
    path = os.path.join(self._output_dir, 'html', 'dartium', '%s.dart' % name)
    self._dart_dartium_file_paths.append(path)
    return self._emitters.FileEmitter(path);

  def ProcessCallback(self, interface, info):
    pass

  def GenerateLibraries(self, lib_dir):
    # Library generated for implementation.
    auxiliary_dir = os.path.relpath(self._auxiliary_dir, self._output_dir)

    self._GenerateLibFile(
        'html_dartium.darttemplate',
        os.path.join(lib_dir, 'html_dartium.dart'),
        (self._interface_system._dart_interface_file_paths +
         self._interface_system._dart_callback_file_paths +
         self._dart_dartium_file_paths
         ),
        AUXILIARY_DIR=MassagePath(auxiliary_dir),
        WRAPCASES='\n'.join(self._wrap_cases))

  def Finish(self):
    pass

# ------------------------------------------------------------------------------

# TODO(jacobr): there is far too much duplicated code between these bindings
# and the Frog bindings.  A larger scale refactoring needs to be performed to
# reduce the duplicated logic.
class HtmlDartiumInterfaceGenerator(object):
  """Generates a wrapper based implementation fo the HTML library that works
  on Dartium.  This is not intended to be the final solution for implementing
  dart:html on Dartium.  Eventually we should generate direct wrapperless
  dart:html bindings that work on dartium."""

  def __init__(self, system, interface, template, super_interface, dart_code,
      base_members, shared):
    """Generates Dart wrapper code for the given interface.

    Args:
      system: system that is executing this generator.
      template: template that output is generated into.
      interface: an IDLInterface instance. It is assumed that all types have
          been converted to Dart types (e.g. int, String), unless they are in
          the same package as the interface.
      super_interface: A string or None, the name of the common interface that
         this interface implements, if any.
      dart_code: an Emitter for the file containing the Dart implementation
          class.
      base_members: a set of names of members defined in a base class.  This is
          used to avoid static member 'overriding' in the generated Dart code.
      shared: functionaly shared across all Html generators. 
    """
    self._system = system
    self._interface = interface
    self._super_interface = super_interface
    self._dart_code = dart_code
    self._base_members = base_members
    self._current_secondary_parent = None
    self._shared = shared
    self._template = template

  def DomObjectName(self):
    return '_ptr'

  # TODO(jacobr): these 3 methods are duplicated.
  def _NarrowToImplementationType(self, type_name):
    # TODO(sra): Move into the 'system' and cache the result.
    if type_name == 'EventListener':
      # Callbacks are typedef functions so don't have a class.
      return type_name
    if self._system._database.HasInterface(type_name):
      interface = self._system._database.GetInterface(type_name)
      if RecognizeCallback(interface):
        # Callbacks are typedef functions so don't have a class.
        return type_name
      else:
        return self._ImplClassName(type_name)
    return type_name

  def _NarrowInputType(self, type_name):
    return self._NarrowToImplementationType(type_name)

  def _NarrowOutputType(self, type_name):
    return self._NarrowToImplementationType(type_name)

  def StartInterface(self):

    interface = self._interface
    interface_name = interface.id
    self._class_name = self._ImplClassName(interface_name)

    base = None
    if interface.parents:
      supertype = interface.parents[0].type.id
      if not IsDartListType(supertype):
        base = self._ImplClassName(supertype)
      if IsDartCollectionType(supertype):
        # List methods are injected in AddIndexer.
        pass
      else:
        base = self._ImplClassName(supertype)
   
    # TODO(jacobr): this is fragile. There isn't a guarantee that dart:dom
    # will continue to exactly match the IDL names.
    dom_name = interface.javascript_binding_name
    self._system._wrap_cases.append(
        "    case '%s': return new %s._wrap(domObject);" %
        (dom_name, self._class_name))

    extends = ' extends ' + base if base else ' extends _DOMTypeBase'

    # TODO: Include all implemented interfaces, including other Lists.
    implements = [interface_name]
    element_type = MaybeTypedArrayElementType(self._interface)
    if element_type:
      implements.append('List<' + DartType(element_type) + '>')
    implements_str = ', '.join(implements)

    (self._members_emitter,
     self._top_level_emitter) = self._dart_code.Emit(
        self._template + '$!TOP_LEVEL',
        #class $CLASSNAME$EXTENDS$IMPLEMENTS$NATIVESPEC {
        #$!MEMBERS
        #}
        NATIVESPEC='', # hack to make reusing the same templates work.
        CLASSNAME=self._class_name,
        EXTENDS=extends,
        IMPLEMENTS=' implements ' + implements_str)

    self._members_emitter.Emit(
        '  $(CLASSNAME)._wrap(ptr) : super._wrap(ptr);\n',
        CLASSNAME=self._class_name)

    # Emit a factory provider class for the constructor.
    constructor_info = AnalyzeConstructor(interface)
    if constructor_info:
      self._EmitFactoryProvider(interface_name, constructor_info)

    emit_events, events = self._shared.GetEventAttributes(self._interface)
    if not emit_events:
      return
    elif events:
      self.AddEventAttributes(events)
    else:
      parent_events_class = self._shared.GetParentEventsClass(self._interface)
      self._EmitEventGetter('_' + parent_events_class + 'Impl')

  def _EmitFactoryProvider(self, interface_name, constructor_info):
    template_file = 'factoryprovider_%s.darttemplate' % interface_name
    template = self._system._templates.TryLoad(template_file)
    if not template:
      template = self._system._templates.Load('factoryprovider.darttemplate')

    factory_provider = '_' + interface_name + 'FactoryProvider'
    emitter = self._system._ImplFileEmitter(factory_provider)
    emitter.Emit(
        template,
        FACTORYPROVIDER=factory_provider,
        CONSTRUCTOR=interface_name,
        PARAMETERS=constructor_info.ParametersImplementationDeclaration(),
        NAMED_CONSTRUCTOR=constructor_info.name or interface_name,
        ARGUMENTS=self._UnwrappedParameters(constructor_info,
                                            len(constructor_info.param_infos)))

  def _UnwrappedParameters(self, operation_info, length):
    """Returns string for an argument list that unwraps first |length|
    parameters."""
    def UnwrapParamInfo(param_info):
      # TODO(sra): Type dependent unwrapping.
      return '_unwrap(%s)' % param_info.name

    return ', '.join(map(UnwrapParamInfo, operation_info.param_infos[:length]))

  def _BaseClassName(self, interface):
    if not interface.parents:
      return '_DOMTypeBase'

    supertype = DartType(interface.parents[0].type.id)

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

  def _ImplClassName(self, type_name):
    return self._shared._ImplClassName(type_name)

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
    dom_name = DartDomNameOfAttribute(getter or setter)
    html_getter_name = self._shared.RenameInHtmlLibrary(
        self._interface, dom_name, 'get:', implementation_class=True)
    html_setter_name = self._shared.RenameInHtmlLibrary(
        self._interface, dom_name, 'set:', implementation_class=True)

    if getter and html_getter_name:
      self._AddGetter(getter, html_getter_name)
    if setter and html_setter_name:
      self._AddSetter(setter, html_setter_name)

  def _AddGetter(self, attr, html_name):
    self._members_emitter.Emit(
      '\n'
      '  $TYPE get $(HTML_NAME)() => _wrap($(THIS).$DOM_NAME);\n',
      HTML_NAME=html_name,
      DOM_NAME=DartDomNameOfAttribute(attr),
      TYPE=DartType(attr.type.id),
      THIS=self.DomObjectName())

  def _AddSetter(self, attr, html_name):
    self._members_emitter.Emit(
        '\n'
        '  void set $(HTML_NAME)($TYPE value) { '
        '$(THIS).$DOM_NAME = _unwrap(value); }\n',
        HTML_NAME=html_name,
        DOM_NAME=DartDomNameOfAttribute(attr),
        TYPE=DartType(attr.type.id),
        THIS=self.DomObjectName())

  def AddSecondaryAttribute(self, interface, getter, setter):
    self._SecondaryContext(interface)
    self.AddAttribute(getter, setter)

  def AddSecondaryOperation(self, interface, info):
    self._SecondaryContext(interface)
    self.AddOperation(info)

  def AddEventAttributes(self, event_attrs):
    event_attrs = _DomToHtmlEvents(self._interface.id, event_attrs)
    events_class = '_' + self._interface.id + 'EventsImpl'
    events_interface = self._interface.id + 'Events'
    self._EmitEventGetter(events_class)

    self._shared._event_classes.add(self._interface.id)

    parent_event_class = self._shared.GetParentEventsClass(self._interface)

    # TODO(jacobr): specify the type of _ptr as EventTarget
    events_members = self._dart_code.Emit(
        '\n'
        'class $CLASSNAME extends $SUPER implements $INTERFACE {\n'
        '  $CLASSNAME(_ptr) : super(_ptr);\n'
        '$!MEMBERS}\n',
        CLASSNAME=events_class,
        INTERFACE=events_interface,
        SUPER='_' + parent_event_class + 'Impl')

    for event_name in event_attrs:
      if event_name in _html_event_names:
        events_members.Emit(
            "\n"
            "  EventListenerList get $NAME() => _get('$RAWNAME');\n",
            RAWNAME=event_name,
            NAME=_html_event_names[event_name])
      else:
        raise Exception('No known html even name for event: ' + event_name)

  def _EmitEventGetter(self, events_class):
    self._members_emitter.Emit(
        '\n'
        '  $TYPE get on() {\n'
        '    if (_on == null) _on = new $TYPE(this);\n'
        '    return _on;\n'
        '  }\n',
        TYPE=events_class)

  def _SecondaryContext(self, interface):
    if interface is not self._current_secondary_parent:
      self._current_secondary_parent = interface
      self._members_emitter.Emit('\n  // From $WHERE\n', WHERE=interface.id)

  # TODO(jacobr): change this to more directly match the frog version.
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
          '  $TYPE operator[](int index) => _wrap($(THIS)[index]);\n'
          '\n',
          THIS=self.DomObjectName(),
          TYPE=DartType(element_type))

    if self._HasNativeIndexSetter(self._interface):
      self._EmitNativeIndexSetter(self._interface, element_type)
    else:
      # The HTML library implementation of NodeList has a custom indexed setter
      # implementation that uses the parent node the NodeList is associated
      # with if one is available.
      if self._interface.id != 'NodeList':
        self._members_emitter.Emit(
            '\n'
            '  void operator[]=(int index, $TYPE value) {\n'
            '    throw new UnsupportedOperationException("Cannot assign element of immutable List.");\n'
            '  }\n',
            TYPE=DartType(element_type))

    # The list interface for this class is manually generated.
    if self._interface.id == 'NodeList':
      return

    # TODO(sra): Use separate mixins for mutable implementations of List<T>.
    # TODO(sra): Use separate mixins for typed array implementations of List<T>.
    template_file = 'immutable_list_mixin.darttemplate'
    template = self._system._templates.Load(template_file)
    self._members_emitter.Emit(template, E=DartType(element_type))

  def _HasNativeIndexGetter(self, interface):
    return ('IndexedGetter' in interface.ext_attrs or
            'NumericIndexedGetter' in interface.ext_attrs)

  def _EmitNativeIndexGetter(self, interface, element_type):
    method_name = '_index'
    self._members_emitter.Emit(
        '\n  $TYPE operator[](int index) => _wrap($(THIS)[index]);\n',
        TYPE=DartType(element_type),
        THIS=self.DomObjectName(),
        METHOD=method_name)

  def _HasNativeIndexSetter(self, interface):
    return 'CustomIndexedSetter' in interface.ext_attrs

  def _EmitNativeIndexSetter(self, interface, element_type):
    method_name = '_set_index'
    self._members_emitter.Emit(
        '\n'
        '  void operator[]=(int index, $TYPE value) {\n'
        '    return $(THIS)[index] = _unwrap(value);\n'
        '  }\n',
        THIS=self.DomObjectName(),
        TYPE=DartType(element_type),
        METHOD=method_name)

  def AddOperation(self, info):
    """
    Arguments:
      info: An OperationInfo object.
    """
    html_name = self._shared.RenameInHtmlLibrary(
        self._interface, info.name, implementation_class=True)

    if not html_name:
      return

    body = self._members_emitter.Emit(
        '\n'
        '  $TYPE $HTML_NAME($PARAMS) {\n'
        '$!BODY'
        '  }\n',
        TYPE=info.type_name,
        HTML_NAME=html_name,
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
    argument_expressions = self._UnwrappedParameters(
        info,
        len(operation.arguments))  # Just the parameters this far.

    if info.type_name != 'void':
      # We could place the logic for handling Document directly in _wrap
      # but we chose to place it here so that bugs in the wrapper and
      # wrapperless implementations are more consistent. 
      emitter.Emit('$(INDENT)return _wrap($(THIS).$NAME($ARGS));\n',
                   INDENT=indent,
                   THIS=self.DomObjectName(),
                   NAME=info.name,
                   ARGS=argument_expressions)
    else:
      emitter.Emit('$(INDENT)$(THIS).$NAME($ARGS);\n'
                   '$(INDENT)return;\n',
                   INDENT=indent,
                   THIS=self.DomObjectName(),
                   NAME=info.name,
                   ARGS=argument_expressions)

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

    if position == len(info.param_infos):
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
    param = info.param_infos[position]

    if position < len(first_overload.arguments):
      # FIXME: This will not work if the second overload has a more
      # precise type than the first.  E.g.,
      # void foo(Node x);
      # void foo(Element x);
      type = DartType(first_overload.arguments[position].type.id)
      test = TypeCheck(param.name, type)
      pred = lambda op: (len(op.arguments) > position and
          DartType(op.arguments[position].type.id) == type)
    else:
      type = None
      test = NullCheck(param.name)
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
    if type == param.dart_type:
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
