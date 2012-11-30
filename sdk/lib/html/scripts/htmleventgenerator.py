#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides functionality to generate dart:html event classes."""

import logging

_logger = logging.getLogger('dartgenerator')

# Events without onEventName attributes in the  IDL we want to support.
# We can automatically extract most event names by checking for
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
  'negotiationneeded': 'negotiationNeeded',
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

# These classes require an explicit declaration for the "on" method even though
# they don't declare any unique events, because the concrete class hierarchy
# doesn't match the interface hierarchy.
_html_explicit_event_classes = set(['DocumentFragment'])

class HtmlEventGenerator(object):

  def __init__(self, database, template_loader):
    self._event_classes = set()
    self._database = database
    self._template_loader = template_loader

  def ProcessInterface(self, interface, html_interface_name, custom_events,
                       events_implementation_emitter):
    event_names = set([attr.id[2:] for attr in interface.attributes
                  if attr.type.id == 'EventListener'])

    # Document and DocumentFragment actually derive from Element, so omit
    # any events which are duplicated with that.
    if interface.id == 'Document' or interface.id == 'DocumentFragment':
      element_interface = self._database.GetInterface('Element')
      for attr in element_interface.attributes:
        if attr.type.id == 'EventListener' and attr.id[2:] in event_names:
          event_names.remove(attr.id[2:])

    if not event_names and interface.id not in _html_explicit_event_classes:
      return None

    self._event_classes.add(interface.id)
    events_class_name = html_interface_name + 'Events'
    parent_events_class_name = self._GetParentEventsClassName(interface)

    if not event_names:
      return parent_events_class_name

    template_file = 'impl_%s.darttemplate' % events_class_name
    template = (self._template_loader.TryLoad(template_file) or
        '\n'
        'class $CLASSNAME extends $SUPER {\n'
        '  $CLASSNAME(EventTarget _ptr) : super(_ptr);\n'
        '$!MEMBERS}\n')

    # TODO(jacobr): specify the type of _ptr as EventTarget
    implementation_events_members = events_implementation_emitter.Emit(
        template,
        CLASSNAME=events_class_name,
        SUPER='%s' % parent_events_class_name)

    dom_event_names = set()
    for event in event_names:
      dom_name = event
      dom_name = _on_attribute_to_event_name_mapping.get(dom_name, dom_name)
      dom_event_names.add(dom_name)
    if html_interface_name in _html_manual_events:
      dom_event_names.update(_html_manual_events[html_interface_name])
    for dom_name in sorted(dom_event_names):
      if dom_name not in _html_event_names:
        _logger.warn('omitting %s event as there is no HTML name for it' % dom_name)
        continue

      html_name = _html_event_names[dom_name]
      full_event_name = '%sEvents.%s' % (html_interface_name, html_name)
      if not full_event_name in custom_events:
        implementation_events_members.Emit(
            "\n"
            "  EventListenerList get $NAME => this['$DOM_NAME'];\n",
          NAME=html_name,
            DOM_NAME=dom_name)

    return events_class_name

  # TODO(jacobr): this isn't quite right....
  def _GetParentEventsClassName(self, interface):
    # Ugly hack as we don't specify that Document and DocumentFragment inherit
    # from Element in our IDL.
    if interface.id == 'Document' or interface.id == 'DocumentFragment':
      return 'ElementEvents'

    parent_events_class_name = 'Events'
    interfaces_with_events = set()
    for parent in self._database.Hierarchy(interface):
      if parent != interface and parent.id in self._event_classes:
        parent_events_class_name = parent.id + 'Events'
        interfaces_with_events.add(parent)
    if len(interfaces_with_events) > 1:
      raise Exception('Only one parent event class allowed ' + interface.id)
    return parent_events_class_name
