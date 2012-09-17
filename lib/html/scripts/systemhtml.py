#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides shared functionality for the system to generate
Dart:html APIs from the IDL database."""

import emitter

from systemdart2js import *
from systeminterface import *

_js_custom_members = set([
    'Element.insertAdjacentElement',
    'Element.insertAdjacentHTML',
    'Element.insertAdjacentText',
    'IDBDatabase.transaction',
    'IFrameElement.contentWindow',
    'MouseEvent.offsetX',
    'MouseEvent.offsetY',
    'Window.document',
    'Window.top',
    'Window.location',
    'Window.open',
    ])

# This map controls merging of interfaces in dart:html library.
# All constants, attributes, and operations of merged interface (key) are
# added to target interface (value). All references to the merged interface
# (e.g. parameter types, return types, parent interfaces) are replaced with
# target interface. There are two important restrictions:
# 1) Merged and target interfaces shouldn't have common members, otherwise there
# would be duplicated declarations in generated Dart code.
# 2) Merged interface should be direct child of target interface, so the
# children of merged interface are not affected by the merge.
# As a consequence, target interface implementation and its direct children
# interface implementations should implement merged attribute accessors and
# operations. For example, SVGElement and Element implementation classes should
# implement HTMLElement.insertAdjacentElement(), HTMLElement.innerHTML, etc.
_merged_html_interfaces = {
   'HTMLDocument': 'Document',
   'HTMLElement': 'Element'
}

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
  'icecandidate': 'iceCandidate',
  'icechange': 'iceChange',
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
  'mute': 'mute',
  'negotationneeded': 'negotationNeeded',
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
  'removetrack': 'removeTrack',
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
  'upgradeneeded': 'upgradeNeeded',
  'unmute': 'unmute',
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
  'webkitpointerlockchange': 'pointerLockChange',
  'webkitpointerlockerror': 'pointerLockError',
  'webkitSpeechChange': 'speechChange',
  'webkitsourceclose': 'sourceClose',
  'webkitsourceended': 'sourceEnded',
  'webkitsourceopen': 'sourceOpen',
  'webkitTransitionEnd': 'transitionEnd',
  'write': 'write',
  'writeend': 'writeEnd',
  'writestart': 'writeStart'
}



# Information for generating element constructors.
#
# TODO(sra): maybe remove all the argument complexity and use cascades.
#
#   var c = new CanvasElement(width: 100, height: 70);
#   var c = new CanvasElement()..width = 100..height = 70;
#
class ElementConstructorInfo(object):
  def __init__(self, name=None, tag=None,
               params=[], opt_params=[],
               factory_provider_name='_Elements'):
    self.name = name          # The constructor name 'h1' in 'HeadingElement.h1'
    self.tag = tag or name    # The HTML tag
    self.params = params
    self.opt_params = opt_params
    self.factory_provider_name = factory_provider_name

  def ConstructorInfo(self, interface_name):
    info = OperationInfo()
    info.overloads = None
    info.declared_name = interface_name
    info.name = interface_name
    info.constructor_name = self.name
    info.js_name = None
    info.type_name = interface_name
    info.param_infos = map(lambda tXn: ParamInfo(tXn[1], None, tXn[0], 'null'),
                           self.opt_params)
    return info

_html_element_constructors = {
  'AnchorElement' :
    ElementConstructorInfo(tag='a', opt_params=[('String', 'href')]),
  'AreaElement': 'area',
  'ButtonElement': 'button',
  'BRElement': 'br',
  'BaseElement': 'base',
  'BodyElement': 'body',
  'ButtonElement': 'button',
  'CanvasElement':
    ElementConstructorInfo(tag='canvas',
                           opt_params=[('int', 'width'), ('int', 'height')]),
  'DataListElement': 'datalist',
  'DListElement': 'dl',
  'DetailsElement': 'details',
  'DivElement': 'div',
  'EmbedElement': 'embed',
  'FieldSetElement': 'fieldset',
  'FormElement': 'form',
  'HRElement': 'hr',
  'HeadElement': 'head',
  'HeadingElement': [ElementConstructorInfo('h1'),
                     ElementConstructorInfo('h2'),
                     ElementConstructorInfo('h3'),
                     ElementConstructorInfo('h4'),
                     ElementConstructorInfo('h5'),
                     ElementConstructorInfo('h6')],
  'HtmlElement': 'html',
  'IFrameElement': 'iframe',
  'ImageElement':
    ElementConstructorInfo(tag='img',
                           opt_params=[('String', 'src'),
                                       ('int', 'width'), ('int', 'height')]),
  'InputElement':
    ElementConstructorInfo(tag='input', opt_params=[('String', 'type')]),
  'KeygenElement': 'keygen',
  'LIElement': 'li',
  'LabelElement': 'label',
  'LegendElement': 'legend',
  'LinkElement': 'link',
  'MapElement': 'map',
  'MenuElement': 'menu',
  'MeterElement': 'meter',
  'OListElement': 'ol',
  'ObjectElement': 'object',
  'OptGroupElement': 'optgroup',
  'OutputElement': 'output',
  'ParagraphElement': 'p',
  'ParamElement': 'param',
  'PreElement': 'pre',
  'ProgressElement': 'progress',
  'ScriptElement': 'script',
  'SelectElement': 'select',
  'SourceElement': 'source',
  'SpanElement': 'span',
  'StyleElement': 'style',
  'TableCaptionElement': 'caption',
  'TableCellElement': 'td',
  'TableColElement': 'col',
  'TableElement': 'table',
  'TableRowElement': 'tr',
  #'TableSectionElement'  <thead> <tbody> <tfoot>
  'TextAreaElement': 'textarea',
  'TitleElement': 'title',
  'TrackElement': 'track',
  'UListElement': 'ul',
  'VideoElement': 'video'
}

def HtmlElementConstructorInfos(typename):
  """Returns list of ElementConstructorInfos about the convenience constructors
  for an Element."""
  # TODO(sra): Handle multiple and named constructors.
  if typename not in _html_element_constructors:
    return []
  infos = _html_element_constructors[typename]
  if isinstance(infos, str):
    infos = ElementConstructorInfo(tag=infos)
  if not isinstance(infos, list):
    infos = [infos]
  return infos

def EmitHtmlElementFactoryConstructors(emitter, infos, typename, class_name):
  for info in infos:
    constructor_info = info.ConstructorInfo(typename)
    inits = emitter.Emit(
        '\n'
        '  factory $CONSTRUCTOR($PARAMS) {\n'
        '    $CLASS _e = _document.$dom_createElement("$TAG");\n'
        '$!INITS'
        '    return _e;\n'
        '  }\n',
        CONSTRUCTOR=constructor_info.ConstructorFullName(),
        CLASS=class_name,
        TAG=info.tag,
        PARAMS=constructor_info.ParametersInterfaceDeclaration(DartType))
    for param in constructor_info.param_infos:
      inits.Emit('    if ($E != null) _e.$E = $E;\n', E=param.name)


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

def DomToHtmlEvents(interface_id, events):
  event_names = set(map(_OnAttributeToEventName, events))
  if interface_id in _html_manual_events:
    for manual_event_name in _html_manual_events[interface_id]:
      event_names.add(manual_event_name)

  return sorted(event_names, key=lambda name: _html_event_names[name])

def DomToHtmlEvent(event_name):
  assert event_name in _html_event_names, \
         'No known html event name for event: ' + event_name
  return _html_event_names[event_name]

# ------------------------------------------------------------------------------
class HtmlSystemShared(object):

  def __init__(self, context):
    self._event_classes = set()
    self._seen_event_names = {}
    self._database = context.database

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


class HtmlInterfacesSystem(System):
  def __init__(self, options, backend):
    super(HtmlInterfacesSystem, self).__init__(options)
    self._backend = backend
    self._shared = HtmlSystemShared(options)
    self._dart_file_paths = []
    self._elements_factory_emitter = None

  def ProcessInterface(self, interface):
    HtmlDartInterfaceGenerator(self, interface).Generate()

  def ProcessCallback(self, interface, info):
    """Generates a typedef for the callback interface."""
    code = self._CreateEmitter('%s.dart' % interface.id)
    code.Emit(self._templates.Load('callback.darttemplate'))
    code.Emit('typedef $TYPE $NAME($PARAMS);\n',
              NAME=interface.id,
              TYPE=DartType(info.type_name),
              PARAMS=info.ParametersImplementationDeclaration(DartType))
    self._backend.ProcessCallback(interface, info)

  def GenerateLibraries(self):
    self._backend.GenerateLibraries(self._dart_file_paths)

  def _CreateEmitter(self, filename):
    path = os.path.join(self._output_dir, 'dart', filename)
    self._dart_file_paths.append(path)
    return self._emitters.FileEmitter(path)

# ------------------------------------------------------------------------------

class HtmlDartInterfaceGenerator(BaseGenerator):
  """Generates dart interface and implementation for the DOM IDL interface."""

  def __init__(self, system, interface):
    super(HtmlDartInterfaceGenerator, self).__init__(
        system._database, interface)
    self._system = system
    self._shared = system._shared
    self._html_interface_name = system._renamer.RenameInterface(self._interface)
    self._backend = system._backend.ImplementationGenerator(self._interface)

  def StartInterface(self):
    if not self._interface.id in _merged_html_interfaces:
      path = '%s.dart' % self._html_interface_name
      self._interface_emitter = self._system._CreateEmitter(path)
    else:
      self._interface_emitter = emitter.Emitter()

    template_file = 'interface_%s.darttemplate' % self._html_interface_name
    interface_template = (self._system._templates.TryLoad(template_file) or
                          self._system._templates.Load('interface.darttemplate'))

    typename = self._html_interface_name

    extends = []
    suppressed_extends = []

    for parent in self._interface.parents:
      # TODO(vsm): Remove source_filter.
      if MatchSourceFilter(parent):
        # Parent is a DOM type.
        extends.append(self._DartType(parent.type.id))
      elif '<' in parent.type.id:
        # Parent is a Dart collection type.
        # TODO(vsm): Make this check more robust.
        extends.append(self._DartType(parent.type.id))
      else:
        suppressed_extends.append('%s.%s' %
            (self._common_prefix, self._DartType(parent.type.id)))

    comment = ' extends'
    extends_str = ''
    if extends:
      extends_str += ' extends ' + ', '.join(extends)
      comment = ','
    if suppressed_extends:
      extends_str += ' /*%s %s */' % (comment, ', '.join(suppressed_extends))

    factory_provider = None
    if typename in interface_factories:
      factory_provider = interface_factories[typename]

    constructors = []
    constructor_info = AnalyzeConstructor(self._interface)
    if constructor_info:
      constructors.append(constructor_info)
      factory_provider = '_' + typename + 'FactoryProvider'
      factory_provider_emitter = self._system._CreateEmitter(
          '_%sFactoryProvider.dart' % self._html_interface_name)
      self._backend.EmitFactoryProvider(
          constructor_info, factory_provider, factory_provider_emitter)

    infos = HtmlElementConstructorInfos(typename)
    if infos:
      if not self._system._elements_factory_emitter:
        file_emitter = self._system._CreateEmitter('_Elements.dart')
        template = self._system._templates.Load(
            'factoryprovider_Elements.darttemplate')
        self._system._elements_factory_emitter = file_emitter.Emit(template)
      EmitHtmlElementFactoryConstructors(
          self._system._elements_factory_emitter,
          infos,
          self._html_interface_name,
          self._backend.ImplementationClassName())

    for info in infos:
      constructors.append(info.ConstructorInfo(typename))
      if factory_provider:
        assert factory_provider == info.factory_provider_name
      else:
        factory_provider = info.factory_provider_name

    if factory_provider:
      extends_str += ' default ' + factory_provider

    # TODO(vsm): Add appropriate package / namespace syntax.
    (self._type_comment_emitter,
     self._members_emitter,
     self._top_level_emitter) = self._interface_emitter.Emit(
         interface_template + '$!TOP_LEVEL',
         ID=typename,
         EXTENDS=extends_str)

    self._type_comment_emitter.Emit("/// @domName $DOMNAME",
        DOMNAME=self._interface.doc_js_name)

    if self._backend.HasImplementation():
      if not self._interface.id in _merged_html_interfaces:
        filename = '%sImpl.dart' % self._html_interface_name
      else:
        filename = '%sImpl.dart' % self._interface.id
      self._implementation_emitter = self._system._CreateEmitter(filename)
    else:
      self._implementation_emitter = emitter.Emitter()
    self._backend.SetImplementationEmitter(self._implementation_emitter)
    self._implementation_members_emitter = self._backend.StartInterface()

    for constructor_info in constructors:
      self._members_emitter.Emit(
          '\n'
          '  $CTOR($PARAMS);\n',
          CTOR=self._DartType(constructor_info.ConstructorFullName()),
          PARAMS=constructor_info.ParametersInterfaceDeclaration(self._DartType))

    element_type = MaybeTypedArrayElementTypeInHierarchy(
        self._interface, self._system._database)
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
        TYPE=self._DartType(element_type))

    self._GenerateEvents()

    old_backend = self._backend
    if not self._backend.ImplementsMergedMembers():
      self._backend = HtmlGeneratorDummyBackend()
    for merged_interface in _merged_html_interfaces:
      if _merged_html_interfaces[merged_interface] == self._interface.id:
        merged_interface = self._database.GetInterface(merged_interface)
        self.AddMembers(merged_interface)
    self._backend = old_backend

  def AddIndexer(self, element_type):
    self._backend.AddIndexer(element_type)

  def AmendIndexer(self, element_type):
    self._backend.AmendIndexer(element_type)

  def AddAttribute(self, attribute, is_secondary=False):
    dom_name = DartDomNameOfAttribute(attribute)
    html_name = self._system._renamer.RenameMember(
      self._interface.id, dom_name, 'get:')
    if not html_name or self._shared.IsPrivate(html_name):
      return


    html_setter_name = self._system._renamer.RenameMember(
        self._interface.id, dom_name, 'set:')
    read_only = IsReadOnly(attribute) or not html_setter_name

    # We don't yet handle inconsistent renames of the getter and setter yet.
    assert(not html_setter_name or html_name == html_setter_name)

    if not is_secondary:
      self._members_emitter.Emit('\n  /** @domName $DOMINTERFACE.$DOMNAME */',
          DOMINTERFACE=attribute.doc_js_interface_name,
          DOMNAME=dom_name)
      modifier = 'final ' if read_only else ''
      self._members_emitter.Emit('\n  $MODIFIER$TYPE $NAME;\n',
                                 MODIFIER=modifier,
                                 NAME=html_name,
                                 TYPE=self._DartType(attribute.type.id))
    self._backend.AddAttribute(attribute, html_name, read_only)

  def AddSecondaryAttribute(self, interface, attribute):
    self._backend.SecondaryContext(interface)
    self.AddAttribute(attribute, True)

  def AddOperation(self, info, skip_declaration=False):
    """
    Arguments:
      operations - contains the overloads, one or more operations with the same
        name.
    """
    html_name = self._system._renamer.RenameMember(self._interface.id, info.name)
    if not html_name:
      if info.name == 'item':
        # FIXME: item should be renamed to operator[], not removed.
        self._backend.AddOperation(info, '_item')
      return

    if not self._shared.IsPrivate(html_name) and not skip_declaration:
      self._members_emitter.Emit('\n  /** @domName $DOMINTERFACE.$DOMNAME */',
          DOMINTERFACE=info.overloads[0].doc_js_interface_name,
          DOMNAME=info.name)

      self._members_emitter.Emit('\n'
                                 '  $TYPE $NAME($PARAMS);\n',
                                 TYPE=self._DartType(info.type_name),
                                 NAME=html_name,
                                 PARAMS=info.ParametersInterfaceDeclaration(self._DartType))
    self._backend.AddOperation(info, html_name)

  def AddStaticOperation(self, info):
    self.AddOperation(info, True)

  def AddSecondaryOperation(self, interface, info):
    self._backend.SecondaryContext(interface)
    self.AddOperation(info, True)

  def FinishInterface(self):
    self._backend.FinishInterface()

  def AddConstant(self, constant):
    type = TypeOrNothing(self._DartType(constant.type.id), constant.type.id)
    self._members_emitter.Emit('\n  static const $TYPE$NAME = $VALUE;\n',
                               NAME=constant.id,
                               TYPE=type,
                               VALUE=constant.value)
    self._backend.AddConstant(constant)

  def _GenerateEvents(self):
    emit_events, event_attrs = self._shared.GetEventAttributes(self._interface)
    if not emit_events:
      return

    self._shared._event_classes.add(self._interface.id)
    events_interface = self._html_interface_name + 'Events'
    events_class = '_%sImpl' % events_interface
    parent_events_interface = self._shared.GetParentEventsClass(self._interface)
    parent_events_class = '_%sImpl' % parent_events_interface

    if not event_attrs:
      self._EmitEventGetter(parent_events_interface, parent_events_class)
      return

    self._EmitEventGetter(events_interface, events_class)

    events_members = self._interface_emitter.Emit(
        '\ninterface $INTERFACE extends $PARENTS {\n$!MEMBERS}\n',
        INTERFACE=events_interface,
        PARENTS=', '.join(
            self._shared.GetParentsEventsClasses(self._interface)))

    # TODO(jacobr): specify the type of _ptr as EventTarget
    implementation_events_members = self._implementation_emitter.Emit(
        '\n'
        'class $CLASSNAME extends $SUPER implements $INTERFACE {\n'
        '  $CLASSNAME(_ptr) : super(_ptr);\n'
        '$!MEMBERS}\n',
        CLASSNAME=events_class,
        INTERFACE=events_interface,
        SUPER=parent_events_class)

    event_attrs = DomToHtmlEvents(self._html_interface_name, event_attrs)
    for event_name in event_attrs:
      if event_name in _html_event_names:
        events_members.Emit('\n  EventListenerList get $NAME;\n',
          NAME=_html_event_names[event_name])
        implementation_events_members.Emit(
            "\n"
            "  EventListenerList get $NAME => this['$DOM_NAME'];\n",
            NAME=_html_event_names[event_name],
            DOM_NAME=event_name)
      else:
        raise Exception('No known html even name for event: ' + event_name)

  def _EmitEventGetter(self, events_interface, events_class):
    self._members_emitter.Emit(
        '\n  /**'
        '\n   * @domName EventTarget.addEventListener, '
        'EventTarget.removeEventListener, EventTarget.dispatchEvent'
        '\n   */'
        '\n  $TYPE get on;\n',
        TYPE=events_interface)

    self._implementation_members_emitter.Emit(
        '\n  $TYPE get on =>\n    new $TYPE(this);\n',
        TYPE=events_class)


class HtmlGeneratorDummyBackend(object):
  def AddAttribute(self, attribute, html_name, read_only):
    pass

  def AddOperation(self, info, html_name):
    pass


# ------------------------------------------------------------------------------

# TODO(jmesserly): inheritance is probably not the right way to factor this long
# term, but it makes merging better for now.
class HtmlDart2JSClassGenerator(Dart2JSInterfaceGenerator):
  """Generates a dart2js class for the dart:html library from a DOM IDL
  interface.
  """

  def __init__(self, system, interface):
    super(HtmlDart2JSClassGenerator, self).__init__(
        system, interface, None, None)
    self._html_interface_name = system._renamer.RenameInterface(self._interface)

  def HasImplementation(self):
    return not (IsPureInterface(self._interface.id) or
                self._interface.id in _merged_html_interfaces)

  def ImplementationClassName(self):
    return self._ImplClassName(self._html_interface_name)

  def SetImplementationEmitter(self, implementation_emitter):
    self._dart_code = implementation_emitter

  def ImplementsMergedMembers(self):
    return True

  def _ImplClassName(self, type_name):
    return '_%sImpl' % type_name

  def StartInterface(self):
    interface = self._interface
    interface_name = interface.id

    self._class_name = self._ImplClassName(self._html_interface_name)

    base = None
    if interface.parents:
      supertype = interface.parents[0].type.id
      if IsDartCollectionType(supertype):
        # List methods are injected in AddIndexer.
        pass
      elif IsPureInterface(supertype):
        pass
      else:
        base = self._ImplClassName(self._DartType(supertype))

    native_spec = MakeNativeSpec(interface.javascript_binding_name)

    extends = ' extends ' + base if base else ''

    # TODO: Include all implemented interfaces, including other Lists.
    implements = [self._html_interface_name]
    element_type = MaybeTypedArrayElementType(self._interface)
    if element_type:
      implements.append('List<%s>' % self._DartType(element_type))

    if self._HasJavaScriptIndexingBehaviour():
      implements.append('JavaScriptIndexingBehavior')

    template_file = 'impl_%s.darttemplate' % self._html_interface_name
    template = (self._system._templates.TryLoad(template_file) or
                self._system._templates.Load('dart2js_impl.darttemplate'))
    self._members_emitter = self._dart_code.Emit(
        template,
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

    return self._members_emitter

  def EmitFactoryProvider(self, constructor_info, factory_provider, emitter):
    template_file = ('factoryprovider_%s.darttemplate' %
                     self._html_interface_name)
    template = self._system._templates.TryLoad(template_file)
    if not template:
      template = self._system._templates.Load('factoryprovider.darttemplate')

    emitter.Emit(
        template,
        FACTORYPROVIDER=factory_provider,
        CONSTRUCTOR=self._html_interface_name,
        PARAMETERS=constructor_info.ParametersImplementationDeclaration(self._DartType),
        NAMED_CONSTRUCTOR=constructor_info.name or self._html_interface_name,
        ARGUMENTS=constructor_info.ParametersAsArgumentList())

  def AddIndexer(self, element_type):
    """Adds all the methods required to complete implementation of List."""
    # We would like to simply inherit the implementation of everything except
    # length, [], and maybe []=.  It is possible to extend from a base
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
      self._members_emitter.Emit(template, E=self._DartType(element_type))

  def AddAttribute(self, attribute, html_name, read_only):
    if self._HasCustomImplementation(attribute.id):
      return

    if attribute.id != html_name:
      self._AddAttributeUsingProperties(attribute, html_name, read_only)
      return

    # If the attribute is shadowing, we can't generate a shadowing
    # field (Issue 1633).
    # TODO(sra): _FindShadowedAttribute does not take into account the html
    #  renaming.  we should be looking for another attribute that has the same
    #  html_name.  Two attributes with the same IDL name might not match if one
    #  is renamed.
    (super_attribute, super_attribute_interface) = self._FindShadowedAttribute(
        attribute, _merged_html_interfaces)
    if super_attribute:
      if read_only:
        if attribute.type.id == super_attribute.type.id:
          # Compatible attribute, use the superclass property.  This works
          # because JavaScript will do its own dynamic dispatch.
          self._members_emitter.Emit(
              '\n'
              '  // Use implementation from $SUPER.\n'
              '  // final $TYPE $NAME;\n',
              SUPER=super_attribute_interface,
              NAME=DartDomNameOfAttribute(attribute),
              TYPE=self._NarrowOutputType(attribute.type.id))
          return
      self._members_emitter.Emit('\n  // Shadowing definition.')
      self._AddAttributeUsingProperties(attribute, html_name, read_only)
      return

    # If the type has a conversion we need a getter or setter to contain the
    # conversion code.
    if (self._OutputConversion(attribute.type.id, attribute.id) or
        self._InputConversion(attribute.type.id, attribute.id)):
      self._AddAttributeUsingProperties(attribute, html_name, read_only)
      return

    output_type = self._NarrowOutputType(attribute.type.id)
    input_type = self._NarrowInputType(attribute.type.id)
    if not read_only:
      self._members_emitter.Emit(
          '\n  $TYPE $NAME;\n',
          NAME=DartDomNameOfAttribute(attribute),
          TYPE=output_type)
    else:
      self._members_emitter.Emit(
          '\n  final $TYPE $NAME;\n',
          NAME=DartDomNameOfAttribute(attribute),
          TYPE=output_type)

  def _AddAttributeUsingProperties(self, attribute, html_name, read_only):
    self._AddRenamingGetter(attribute, html_name)
    if not read_only:
      self._AddRenamingSetter(attribute, html_name)

  def _AddRenamingGetter(self, attr, html_name):
    conversion = self._OutputConversion(attr.type.id, attr.id)
    if conversion:
      return self._AddConvertingGetter(attr, html_name, conversion)
    return_type = self._NarrowOutputType(attr.type.id)
    self._members_emitter.Emit(
        '\n  $TYPE get $HTML_NAME() native "return this.$NAME;";\n',
        HTML_NAME=html_name,
        NAME=attr.id,
        TYPE=return_type)

  def _AddRenamingSetter(self, attr, html_name):
    conversion = self._InputConversion(attr.type.id, attr.id)
    if conversion:
      return self._AddConvertingSetter(attr, html_name, conversion)
    self._members_emitter.Emit(
        '\n  void set $HTML_NAME($TYPE value)'
        ' native "this.$NAME = value;";\n',
        HTML_NAME=html_name,
        NAME=attr.id,
        TYPE=self._NarrowInputType(attr.type.id))

  def _AddConvertingGetter(self, attr, html_name, conversion):
    self._members_emitter.Emit(
        '\n  $RETURN_TYPE get $HTML_NAME => $CONVERT(this._$(HTML_NAME));'
        '\n  $NATIVE_TYPE get _$HTML_NAME() native "return this.$NAME;";'
        '\n',
        CONVERT=conversion.function_name,
        HTML_NAME=html_name,
        NAME=attr.id,
        RETURN_TYPE=conversion.output_type,
        NATIVE_TYPE=conversion.input_type)

  def _AddConvertingSetter(self, attr, html_name, conversion):
    self._members_emitter.Emit(
        '\n  void set $HTML_NAME($INPUT_TYPE value) {'
        ' this._$HTML_NAME = $CONVERT(value); }'
        '\n  void set _$HTML_NAME(/*$NATIVE_TYPE*/ value)'
        ' native "this.$NAME = value;";'
        '\n',
        CONVERT=conversion.function_name,
        HTML_NAME=html_name,
        NAME=attr.id,
        INPUT_TYPE=conversion.input_type,
        NATIVE_TYPE=conversion.output_type)


  def AddOperation(self, info, html_name):
    """
    Arguments:
      info: An OperationInfo object.
    """
    if self._HasCustomImplementation(info.name):
      return

    # FIXME: support static operations.
    if info.IsStatic():
      return

    # Any conversions needed?
    if any(self._OperationRequiresConversions(op) for op in info.overloads):
      self._AddOperationWithConversions(info, html_name)
    else:
      self._AddDirectNativeOperation(info, html_name)

  def _AddDirectNativeOperation(self, info, html_name):
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
          #'  // @native("$NAME")\n;'
          '  $TYPE $(HTML_NAME)($PARAMS) native "$NAME";\n')
    else:
      self._members_emitter.Emit(
          '\n'
          '  $TYPE $NAME($PARAMS) native;\n',
          TYPE=self._NarrowOutputType(info.type_name),
          NAME=info.name,
          PARAMS=info.ParametersImplementationDeclaration(
              lambda type_name: self._NarrowInputType(type_name)))

  def _AddOperationWithConversions(self, info, html_name):
    # Assert all operations have same return type.
    assert len(set([op.type.id for op in info.operations])) == 1
    info = info.CopyAndWidenDefaultParameters()
    output_conversion = self._OutputConversion(info.type_name,
                                               info.declared_name)
    if output_conversion:
      return_type = output_conversion.output_type
      native_return_type = output_conversion.input_type
    else:
      return_type = self._NarrowInputType(info.type_name)
      native_return_type = return_type

    def InputType(type_name):
      conversion = self._InputConversion(type_name, info.declared_name)
      if conversion:
        return conversion.input_type
      else:
        return self._NarrowInputType(type_name)

    body = self._members_emitter.Emit(
        '\n'
        '  $TYPE $(HTML_NAME)($PARAMS) {\n'
        '$!BODY'
        '  }\n',
        TYPE=return_type,
        HTML_NAME=html_name,
        PARAMS=info.ParametersImplementationDeclaration(InputType))

    parameter_names = [param_info.name for param_info in info.param_infos]
    parameter_types = [InputType(param_info.dart_type)
                       for param_info in info.param_infos]
    operations = info.operations

    method_version = [0]
    temp_version = [0]

    def GenerateCall(operation, argument_count, checks):
      checks = filter(lambda e: e != 'true', checks)
      if checks:
        (stmts_emitter, call_emitter) = body.Emit(
            '    if ($CHECKS) {\n$!STMTS$!CALL    }\n',
            INDENT='      ',
            CHECKS=' &&\n        '.join(checks))
      else:
        (stmts_emitter, call_emitter) = body.Emit('$!A$!B', INDENT='    ');

      method_version[0] += 1
      target = '_%s_%d' % (html_name, method_version[0])
      arguments = []
      target_parameters = []
      for position, arg in enumerate(operation.arguments[:argument_count]):
        conversion = self._InputConversion(arg.type.id, operation.id)
        param_name = operation.arguments[position].id
        if conversion:
          temp_version[0] += 1
          temp_name = '%s_%s' % (param_name, temp_version[0])
          temp_type = conversion.output_type
          stmts_emitter.Emit(
              '$(INDENT)$TYPE $NAME = $CONVERT($ARG);\n',
              TYPE=TypeOrVar(temp_type),
              NAME=temp_name,
              CONVERT=conversion.function_name,
              ARG=parameter_names[position])
          arguments.append(temp_name)
          param_type = temp_type
          verified_type = temp_type  # verified by assignment in checked mode.
        else:
          arguments.append(parameter_names[position])
          param_type = self._NarrowInputType(DartType(arg.type.id))
          # Verified by argument checking on entry to the dispatcher.
          verified_type = InputType(info.param_infos[position].dart_type)

        # The native method does not need an argument type if we know the type.
        # But we do need the native methods to have correct function types, so
        # be conservative.
        if param_type == verified_type:
          if param_type in ['String', 'num', 'int', 'double', 'bool', 'Object']:
            param_type = 'Dynamic'
        target_parameters.append(
            '%s%s' % (TypeOrNothing(param_type), param_name))

      argument_list = ', '.join(arguments)
      # TODO(sra): If the native method has zero type checks, we can 'inline' is
      # and call it directly with a JS-expression.
      call = '%s(%s)' % (target, argument_list)

      if output_conversion:
        call = '%s(%s)' % (output_conversion.function_name, call)

      if operation.type.id == 'void':
        call_emitter.Emit('$(INDENT)$CALL;\n$(INDENT)return;\n',
                          CALL=call)
      else:
        call_emitter.Emit('$(INDENT)return $CALL;\n', CALL=call)

      self._members_emitter.Emit(
          '  $TYPE$TARGET($PARAMS) native "$NATIVE";\n',
          TYPE=TypeOrNothing(native_return_type),
          TARGET=target,
          PARAMS=', '.join(target_parameters),
          NATIVE=info.declared_name)

    def GenerateChecksAndCall(operation, argument_count):
      checks = ['!?%s' % name for name in parameter_names]
      for i in range(0, argument_count):
        argument = operation.arguments[i]
        parameter_name = parameter_names[i]
        test_type = self._DartType(argument.type.id)
        if test_type in ['Dynamic', 'Object']:
          checks[i] = '?%s' % parameter_name
        elif test_type == parameter_types[i]:
          checks[i] = 'true'
        else:
          checks[i] = '(%s is %s || %s === null)' % (
              parameter_name, test_type, parameter_name)
      # There can be multiple presence checks.  We need them all since a later
      # optional argument could have been passed by name, leaving 'holes'.
      GenerateCall(operation, argument_count, checks)

    # TODO: Optimize the dispatch to avoid repeated checks.
    if len(operations) > 1:
      for operation in operations:
        for position, argument in enumerate(operation.arguments):
          if self._IsOptional(operation, argument):
            GenerateChecksAndCall(operation, position)
        GenerateChecksAndCall(operation, len(operation.arguments))
      body.Emit(
          '    throw const Exception("Incorrect number or type of arguments");'
          '\n');
    else:
      operation = operations[0]
      argument_count = len(operation.arguments)
      for position, argument in list(enumerate(operation.arguments))[::-1]:
        if self._IsOptional(operation, argument):
          check = '?%s' % parameter_names[position]
          GenerateCall(operation, position + 1, [check])
          argument_count = position
      GenerateCall(operation, argument_count, [])


  def _IsOptional(self, operation, argument):
    return IsOptional(argument)


  def _OperationRequiresConversions(self, operation):
    return (self._OperationRequiresOutputConversion(operation) or
            self._OperationRequiresInputConversions(operation))

  def _OperationRequiresOutputConversion(self, operation):
    return self._OutputConversion(operation.type.id, operation.id)

  def _OperationRequiresInputConversions(self, operation):
    return any(self._InputConversion(arg.type.id, operation.id)
               for arg in operation.arguments)

  def _OutputConversion(self, idl_type, member):
    return FindConversion(idl_type, 'get', self._interface.id, member)

  def _InputConversion(self, idl_type, member):
    return FindConversion(idl_type, 'set', self._interface.id, member)

  def _HasCustomImplementation(self, member_name):
    member_name = '%s.%s' % (self._html_interface_name, member_name)
    return member_name in _js_custom_members

  def _HasJavaScriptIndexingBehaviour(self):
    """Returns True if the native object has an indexer and length property."""
    (element_type, requires_indexer) = ListImplementationInfo(
        self._interface, self._database)
    if element_type and requires_indexer: return True
    return False

# ------------------------------------------------------------------------------

class HtmlDart2JSSystem(System):

  def __init__(self, options):
    super(HtmlDart2JSSystem, self).__init__(options)

  def ImplementationGenerator(self, interface):
    return HtmlDart2JSClassGenerator(self, interface)

  def GenerateLibraries(self, dart_files):
    self._GenerateLibFile(
        'html_dart2js.darttemplate',
        os.path.join(self._output_dir, 'html_dart2js.dart'),
        dart_files)

  def Finish(self):
    pass
