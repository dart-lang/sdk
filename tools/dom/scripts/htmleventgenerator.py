#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides functionality to generate dart:html event classes."""

import logging
from generator import GetAnnotationsAndComments, FormatAnnotationsAndComments

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

_html_event_types = {
  '*.abort': ('abort', 'Event'),
  '*.beforecopy': ('beforeCopy', 'Event'),
  '*.beforecut': ('beforeCut', 'Event'),
  '*.beforepaste': ('beforePaste', 'Event'),
  '*.beforeunload': ('beforeUnload', 'Event'),
  '*.blur': ('blur', 'Event'),
  '*.canplay': ('canPlay', 'Event'),
  '*.canplaythrough': ('canPlayThrough', 'Event'),
  '*.change': ('change', 'Event'),
  '*.click': ('click', 'MouseEvent'),
  '*.contextmenu': ('contextMenu', 'MouseEvent'),
  '*.copy': ('copy', 'Event'),
  '*.cut': ('cut', 'Event'),
  '*.dblclick': ('doubleClick', 'Event'),
  '*.drag': ('drag', 'MouseEvent'),
  '*.dragend': ('dragEnd', 'MouseEvent'),
  '*.dragenter': ('dragEnter', 'MouseEvent'),
  '*.dragleave': ('dragLeave', 'MouseEvent'),
  '*.dragover': ('dragOver', 'MouseEvent'),
  '*.dragstart': ('dragStart', 'MouseEvent'),
  '*.drop': ('drop', 'MouseEvent'),
  '*.durationchange': ('durationChange', 'Event'),
  '*.emptied': ('emptied', 'Event'),
  '*.ended': ('ended', 'Event'),
  '*.error': ('error', 'Event'),
  '*.focus': ('focus', 'Event'),
  # Should be HashChangeEvent, but IE does not support it.
  '*.hashchange': ('hashChange', 'Event'),
  '*.input': ('input', 'Event'),
  '*.invalid': ('invalid', 'Event'),
  '*.keydown': ('keyDown', 'KeyboardEvent'),
  '*.keypress': ('keyPress', 'KeyboardEvent'),
  '*.keyup': ('keyUp', 'KeyboardEvent'),
  '*.load': ('load', 'Event'),
  '*.loadeddata': ('loadedData', 'Event'),
  '*.loadedmetadata': ('loadedMetadata', 'Event'),
  '*.message': ('message', 'MessageEvent'),
  '*.mousedown': ('mouseDown', 'MouseEvent'),
  '*.mousemove': ('mouseMove', 'MouseEvent'),
  '*.mouseout': ('mouseOut', 'MouseEvent'),
  '*.mouseover': ('mouseOver', 'MouseEvent'),
  '*.mouseup': ('mouseUp', 'MouseEvent'),
  '*.mousewheel': ('mouseWheel', 'WheelEvent'),
  '*.offline': ('offline', 'Event'),
  '*.online': ('online', 'Event'),
  '*.paste': ('paste', 'Event'),
  '*.pause': ('pause', 'Event'),
  '*.play': ('play', 'Event'),
  '*.playing': ('playing', 'Event'),
  '*.popstate': ('popState', 'PopStateEvent'),
  '*.ratechange': ('rateChange', 'Event'),
  '*.reset': ('reset', 'Event'),
  '*.resize': ('resize', 'Event'),
  '*.scroll': ('scroll', 'Event'),
  '*.search': ('search', 'Event'),
  '*.seeked': ('seeked', 'Event'),
  '*.seeking': ('seeking', 'Event'),
  '*.select': ('select', 'Event'),
  '*.selectstart': ('selectStart', 'Event'),
  '*.stalled': ('stalled', 'Event'),
  '*.storage': ('storage', 'StorageEvent'),
  '*.submit': ('submit', 'Event'),
  '*.suspend': ('suspend', 'Event'),
  '*.timeupdate': ('timeUpdate', 'Event'),
  '*.touchcancel': ('touchCancel', 'TouchEvent'),
  '*.touchend': ('touchEnd', 'TouchEvent'),
  '*.touchenter': ('touchEnter', 'TouchEvent'),
  '*.touchleave': ('touchLeave', 'TouchEvent'),
  '*.touchmove': ('touchMove', 'TouchEvent'),
  '*.touchstart': ('touchStart', 'TouchEvent'),
  '*.unload': ('unload', 'Event'),
  '*.volumechange': ('volumeChange', 'Event'),
  '*.waiting': ('waiting', 'Event'),
  '*.webkitAnimationEnd': ('animationEnd', 'AnimationEvent'),
  '*.webkitAnimationIteration': ('animationIteration', 'AnimationEvent'),
  '*.webkitAnimationStart': ('animationStart', 'AnimationEvent'),
  '*.webkitTransitionEnd': ('transitionEnd', 'TransitionEvent'),
  '*.webkitfullscreenchange': ('fullscreenChange', 'Event'),
  '*.webkitfullscreenerror': ('fullscreenError', 'Event'),
  'AudioContext.complete': ('complete', 'Event'),
  'BatteryManager.chargingchange': ('chargingChange', 'Event'),
  'BatteryManager.chargingtimechange': ('chargingTimeChange', 'Event'),
  'BatteryManager.dischargingtimechange': ('dischargingTimeChange', 'Event'),
  'BatteryManager.levelchange': ('levelChange', 'Event'),
  'DOMApplicationCache.cached': ('cached', 'Event'),
  'DOMApplicationCache.checking': ('checking', 'Event'),
  'DOMApplicationCache.downloading': ('downloading', 'Event'),
  'DOMApplicationCache.noupdate': ('noUpdate', 'Event'),
  'DOMApplicationCache.obsolete': ('obsolete', 'Event'),
  'DOMApplicationCache.progress': ('progress', 'Event'),
  'DOMApplicationCache.updateready': ('updateReady', 'Event'),
  'Document.cuechange': ('cueChange', 'Event'),
  'Document.readystatechange': ('readyStateChange', 'Event'),
  'Document.selectionchange': ('selectionChange', 'Event'),
  'Document.webkitpointerlockchange': ('pointerLockChange', 'Event'),
  'Document.webkitpointerlockerror': ('pointerLockError', 'Event'),
  'Element.cuechange': ('cueChange', 'Event'),
  'EventSource.open': ('open', 'Event'),
  'FileReader.abort': ('abort', 'ProgressEvent'),
  'FileReader.load': ('load', 'ProgressEvent'),
  'FileReader.loadend': ('loadEnd', 'ProgressEvent'),
  'FileReader.loadstart': ('loadStart', 'ProgressEvent'),
  'FileReader.progress': ('progress', 'ProgressEvent'),
  'FileWriter.abort': ('abort', 'ProgressEvent'),
  'FileWriter.progress': ('progress', 'ProgressEvent'),
  'FileWriter.write': ('write', 'ProgressEvent'),
  'FileWriter.writeend': ('writeEnd', 'ProgressEvent'),
  'FileWriter.writestart': ('writeStart', 'ProgressEvent'),
  'HTMLBodyElement.storage': ('storage', 'StorageEvent'),
  'HTMLInputElement.webkitSpeechChange': ('speechChange', 'Event'),
  'HTMLMediaElement.loadstart': ('loadStart', 'Event'),
  'HTMLMediaElement.progress': ('progress', 'Event'),
  'HTMLMediaElement.show': ('show', 'Event'),
  'HTMLMediaElement.webkitkeyadded': ('keyAdded', 'MediaKeyEvent'),
  'HTMLMediaElement.webkitkeyerror': ('keyError', 'MediaKeyEvent'),
  'HTMLMediaElement.webkitkeymessage': ('keyMessage', 'MediaKeyEvent'),
  'HTMLMediaElement.webkitneedkey': ('needKey', 'MediaKeyEvent'),
  'IDBDatabase.versionchange': ('versionChange', 'UpgradeNeededEvent'),
  'IDBOpenDBRequest.blocked': ('blocked', 'Event'),
  'IDBOpenDBRequest.upgradeneeded': ('upgradeNeeded', 'VersionChangeEvent'),
  'IDBRequest.success': ('success', 'Event'),
  'IDBTransaction.complete': ('complete', 'Event'),
  'IDBVersionChangeRequest.blocked': ('blocked', 'Event'),
  'MediaController.play': ('play', 'Event'),
  'MediaStreamTrack.mute': ('mute', 'Event'),
  'MediaStreamTrack.unmute': ('unmute', 'Event'),
  'MediaStreamTrackList.addtrack': ('addTrack', 'MediaStreamTrackEvent'),
  'MediaStreamTrackList.removetrack': ('removeTrack', 'MediaStreamTrackEvent'),
  'Notification.click': ('click', 'Event'),
  'Notification.close': ('close', 'Event'),
  'Notification.display': ('display', 'Event'),
  'Notification.show': ('show', 'Event'),
  'RTCDataChannel.close': ('close', 'Event'),
  'RTCDataChannel.open': ('open', 'Event'),
  'RTCPeerConnection.addstream': ('addStream', 'MediaStreamEvent'),
  'RTCPeerConnection.connecting': ('connecting', 'MediaStreamEvent'),
  'RTCPeerConnection.datachannel': ('dataChannel', 'RtcDataChannelEvent'),
  'RTCPeerConnection.icecandidate': ('iceCandidate', 'RtcIceCandidateEvent'),
  'RTCPeerConnection.icechange': ('iceChange', 'Event'),
  'RTCPeerConnection.negotiationneeded': ('negotiationNeeded', 'Event'),
  'RTCPeerConnection.open': ('open', 'Event'),
  'RTCPeerConnection.removestream': ('removeStream', 'MediaStreamEvent'),
  'RTCPeerConnection.statechange': ('stateChange', 'Event'),
  'ScriptProcessorNode.audioprocess': ('audioProcess', 'AudioProcessingEvent'),
  'SharedWorkerContext.connect': ('connect', 'Event'),
  'SpeechRecognition.audioend': ('audioEnd', 'Event'),
  'SpeechRecognition.audiostart': ('audioStart', 'Event'),
  'SpeechRecognition.end': ('end', 'Event'),
  'SpeechRecognition.error': ('error', 'SpeechRecognitionError'),
  'SpeechRecognition.nomatch': ('noMatch', 'SpeechRecognitionEvent'),
  'SpeechRecognition.result': ('result', 'SpeechRecognitionEvent'),
  'SpeechRecognition.soundend': ('soundEnd', 'Event'),
  'SpeechRecognition.soundstart': ('soundStart', 'Event'),
  'SpeechRecognition.speechend': ('speechEnd', 'Event'),
  'SpeechRecognition.speechstart': ('speechStart', 'Event'),
  'SpeechRecognition.start': ('start', 'Event'),
  'TextTrack.cuechange': ('cueChange', 'Event'),
  'TextTrackCue.enter': ('enter', 'Event'),
  'TextTrackCue.exit': ('exit', 'Event'),
  'TextTrackList.addtrack': ('addTrack', 'TrackEvent'),
  'WebSocket.close': ('close', 'CloseEvent'),
  'WebSocket.open': ('open', 'Event'), # should be OpenEvent, but not exposed.
  'Window.DOMContentLoaded': ('contentLoaded', 'Event'),
  'Window.cuechange': ('cueChange', 'Event'),
  'Window.devicemotion': ('deviceMotion', 'DeviceMotionEvent'),
  'Window.deviceorientation': ('deviceOrientation', 'DeviceOrientationEvent'),
  'Window.loadstart': ('loadStart', 'Event'),
  'Window.pagehide': ('pageHide', 'Event'),
  'Window.pageshow': ('pageShow', 'Event'),
  'Window.progress': ('progress', 'Event'),
  'XMLHttpRequest.abort': ('abort', 'ProgressEvent'),
  'XMLHttpRequest.error': ('error', 'ProgressEvent'),
  'XMLHttpRequest.load': ('load', 'ProgressEvent'),
  'XMLHttpRequest.loadend': ('loadEnd', 'ProgressEvent'),
  'XMLHttpRequest.loadstart': ('loadStart', 'ProgressEvent'),
  'XMLHttpRequest.progress': ('progress', 'ProgressEvent'),
  'XMLHttpRequest.readystatechange': ('readyStateChange', 'ProgressEvent'),
  'XMLHttpRequestUpload.abort': ('abort', 'ProgressEvent'),
  'XMLHttpRequestUpload.error': ('error', 'ProgressEvent'),
  'XMLHttpRequestUpload.load': ('load', 'ProgressEvent'),
  'XMLHttpRequestUpload.loadend': ('loadEnd', 'ProgressEvent'),
  'XMLHttpRequestUpload.loadstart': ('loadStart', 'ProgressEvent'),
  'XMLHttpRequestUpload.progress': ('progress', 'ProgressEvent'),
}

# These classes require an explicit declaration for the "on" method even though
# they don't declare any unique events, because the concrete class hierarchy
# doesn't match the interface hierarchy.
_html_explicit_event_classes = set(['DocumentFragment'])

class HtmlEventGenerator(object):

  def __init__(self, database, renamer, template_loader):
    self._event_classes = set()
    self._database = database
    self._renamer = renamer
    self._template_loader = template_loader

  def EmitStreamProviders(self, interface, custom_events,
      members_emitter, library_name):
    events = self._GetEvents(interface, custom_events)
    if not events:
      return

    for event_info in events:
      (dom_name, html_name, event_type) = event_info

      # If we're using a different provider, then don't declare one.
      if self._GetEventRedirection(interface, html_name, event_type):
        continue

      annotations = FormatAnnotationsAndComments(
          GetAnnotationsAndComments(interface.id, dom_name, library_name), '  ')

      members_emitter.Emit(
          "\n"
          "  $(ANNOTATIONS)static const EventStreamProvider<$TYPE> "
          "$(NAME)Event = const EventStreamProvider<$TYPE>('$DOM_NAME');\n",
          ANNOTATIONS=annotations,
          NAME=html_name,
          DOM_NAME=dom_name,
          TYPE=event_type)

  def EmitStreamGetters(self, interface, custom_events,
      members_emitter, library_name):
    events = self._GetEvents(interface, custom_events)
    if not events:
      return

    for event_info in events:
      (dom_name, html_name, event_type) = event_info
      getter_name = 'on%s%s' % (html_name[:1].upper(), html_name[1:])

      # If the provider is declared elsewhere, point to that.
      redirection = self._GetEventRedirection(interface, html_name, event_type)
      if redirection:
        provider = '%s.%sEvent' % (redirection, html_name)
      else:
        provider = html_name + 'Event'

      annotations = FormatAnnotationsAndComments(
          GetAnnotationsAndComments(interface.id, dom_name, library_name), '  ')

      members_emitter.Emit(
          "\n"
          "  $(ANNOTATIONS)Stream<$TYPE> get $(NAME) => "
          "$PROVIDER.forTarget(this);\n",
          ANNOTATIONS=annotations,
          NAME=getter_name,
          PROVIDER=provider,
          TYPE=event_type)

  def _GetEvents(self, interface, custom_events):
    """ Gets a list of all of the events for the specified interface.
    """
    events = set([attr for attr in interface.attributes
                  if attr.type.id == 'EventListener'])
    if not events and interface.id not in _html_explicit_event_classes:
      return None

    html_interface_name = interface.doc_js_name

    dom_event_names = set()
    for event in events:
      dom_name = event.id[2:]
      dom_name = _on_attribute_to_event_name_mapping.get(dom_name, dom_name)
      dom_event_names.add(dom_name)
    if html_interface_name in _html_manual_events:
      dom_event_names.update(_html_manual_events[html_interface_name])

    events = []
    for dom_name in sorted(dom_event_names):
      event_info = self._FindEventInfo(html_interface_name, dom_name)
      if not event_info:
        continue

      (html_name, event_type) = event_info
      if self._IsEventSuppressed(interface, html_name, event_type):
        continue

      full_event_name = '%sEvents.%s' % (html_interface_name, html_name)
      if not full_event_name in custom_events:
        events.append((dom_name, html_name, event_type))
    return events

  def _HasEvent(self, events, event_name, event_type):
    """ Checks if the event is declared in the list of events (from _GetEvents),
    with the same event type.
    """
    for (dom_name, html_name, found_type) in events:
      if html_name == event_name and event_type == found_type:
        return True
    return False

  def _IsEventSuppressed(self, interface, event_name, event_type):
    """ Checks if the event should not be emitted.
    """
    if self._renamer.ShouldSuppressMember(interface, event_name, 'on:'):
      return True

    if interface.doc_js_name == 'Window':
      media_interface = self._database.GetInterface('HTMLMediaElement')
      media_events = self._GetEvents(media_interface, [])
      if self._HasEvent(media_events, event_name, event_type):
        return True

  def _GetEventRedirection(self, interface, event_name, event_type):
    """ For events which are declared in one place, but exposed elsewhere,
    this gets the source of the event (where the provider is declared)
    """
    if interface.doc_js_name == 'Window' or interface.doc_js_name == 'Document':
      element_interface = self._database.GetInterface('Element')
      element_events = self._GetEvents(element_interface, [])
      if self._HasEvent(element_events, event_name, event_type):
        return 'Element'
    return None

  def _FindEventInfo(self, html_interface_name, dom_event_name):
    """ Finds the event info (event name and type).
    """
    key = '%s.%s' % (html_interface_name, dom_event_name)
    if key in _html_event_types:
      return _html_event_types[key]
    key = '*.%s' % dom_event_name
    if key in _html_event_types:
      return _html_event_types[key]
    _logger.warn('Cannot resolve event type for %s.%s' %
        (html_interface_name, dom_event_name))
    return None

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
        '@DocsEditable\n'
        '@deprecated\n'
        'class $CLASSNAME extends $SUPER {\n'
        '  @DocsEditable\n'
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
            "  @DocsEditable\n"
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
        parent_name = self._renamer.RenameInterface(parent)
        parent_events_class_name = parent_name + 'Events'
        interfaces_with_events.add(parent)
    if len(interfaces_with_events) > 1:
      raise Exception('Only one parent event class allowed ' + interface.id)
    return parent_events_class_name
