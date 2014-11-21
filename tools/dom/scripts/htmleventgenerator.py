#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides functionality to generate dart:html event classes."""

import logging
import monitored

_logger = logging.getLogger('dartgenerator')

# Events without onEventName attributes in the  IDL we want to support.
# We can automatically extract most event names by checking for
# onEventName methods in the IDL but some events aren't listed so we need
# to manually add them here so that they are easy for users to find.
_html_manual_events = monitored.Dict('htmleventgenerator._html_manual_events', {
  'Element': ['ontouchleave', 'ontouchenter', 'ontransitionend'],
  'HTMLCanvasElement': ['onwebglcontextlost', 'onwebglcontextrestored'],
  'Window': ['onDOMContentLoaded']
})

# These event names must be camel case when attaching event listeners
# using addEventListener even though the onEventName properties in the DOM for
# them are not camel case.
_on_attribute_to_event_name_mapping = monitored.Dict(
    'htmleventgenerator._on_attribute_to_event_name_mapping', {
  'webkitanimationend': 'webkitAnimationEnd',
  'webkitanimationiteration': 'webkitAnimationIteration',
  'webkitanimationstart': 'webkitAnimationStart',
  'webkitspeechchange': 'webkitSpeechChange',
})

_html_event_types = monitored.Dict('htmleventgenerator._html_event_types', {
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
  '*.mouseenter': ('mouseEnter', 'MouseEvent'),
  '*.mouseleave': ('mouseLeave', 'MouseEvent'),
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
  '*.transitionend': ('transitionEnd', 'TransitionEvent'),
  '*.webkitfullscreenchange': ('fullscreenChange', 'Event'),
  '*.webkitfullscreenerror': ('fullscreenError', 'Event'),
  '*.wheel': ('wheel', 'WheelEvent'),
  'AbstractWorker.error': ('error', 'ErrorEvent'),
  'AudioContext.complete': ('complete', 'Event'),
  'ApplicationCache.cached': ('cached', 'Event'),
  'ApplicationCache.checking': ('checking', 'Event'),
  'ApplicationCache.downloading': ('downloading', 'Event'),
  'ApplicationCache.noupdate': ('noUpdate', 'Event'),
  'ApplicationCache.obsolete': ('obsolete', 'Event'),
  'ApplicationCache.progress': ('progress', 'ProgressEvent'),
  'ApplicationCache.updateready': ('updateReady', 'Event'),
  'Document.readystatechange': ('readyStateChange', 'Event'),
  'Document.securitypolicyviolation': ('securityPolicyViolation', 'SecurityPolicyViolationEvent'),
  'Document.selectionchange': ('selectionChange', 'Event'),
  'Document.pointerlockchange': ('pointerLockChange', 'Event'),
  'Document.pointerlockerror': ('pointerLockError', 'Event'),
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
  'FontLoader.load': ('load', 'CssFontFaceLoadEvent'),
  'FontLoader.loading': ('loading', 'CssFontFaceLoadEvent'),
  'FontLoader.loadingdone': ('loadingDone', 'CssFontFaceLoadEvent'),
  'FontLoader.loadstart': ('loadStart', 'CssFontFaceLoadEvent'),
  'HTMLBodyElement.storage': ('storage', 'StorageEvent'),
  'HTMLCanvasElement.webglcontextlost': ('webGlContextLost', 'gl.ContextEvent'),
  'HTMLCanvasElement.webglcontextrestored': ('webGlContextRestored', 'gl.ContextEvent'),
  'HTMLInputElement.webkitSpeechChange': ('speechChange', 'Event'),
  'HTMLFormElement.autocomplete': ('autocomplete', 'Event'),
  'HTMLFormElement.autocompleteerror': ('autocompleteError', 'AutocompleteErrorEvent'),
  'HTMLMediaElement.loadstart': ('loadStart', 'Event'),
  'HTMLMediaElement.progress': ('progress', 'Event'),
  'HTMLMediaElement.show': ('show', 'Event'),
  'HTMLMediaElement.webkitkeyadded': ('keyAdded', 'MediaKeyEvent'),
  'HTMLMediaElement.webkitkeyerror': ('keyError', 'MediaKeyEvent'),
  'HTMLMediaElement.webkitkeymessage': ('keyMessage', 'MediaKeyEvent'),
  'HTMLMediaElement.webkitneedkey': ('needKey', 'MediaKeyEvent'),
  'IDBDatabase.close': ('close', 'Event'),
  'IDBDatabase.versionchange': ('versionChange', 'VersionChangeEvent'),
  'IDBOpenDBRequest.blocked': ('blocked', 'Event'),
  'IDBOpenDBRequest.upgradeneeded': ('upgradeNeeded', 'VersionChangeEvent'),
  'IDBRequest.success': ('success', 'Event'),
  'IDBTransaction.complete': ('complete', 'Event'),
  'MediaKeySession.webkitkeyadded': ('keyAdded', 'MediaKeyEvent'),
  'MediaKeySession.webkitkeyerror': ('keyError', 'MediaKeyEvent'),
  'MediaKeySession.webkitkeymessage': ('keyMessage', 'MediaKeyEvent'),
  'MediaStream.addtrack': ('addTrack', 'Event'),
  'MediaStream.removetrack': ('removeTrack', 'Event'),
  'MediaStreamTrack.mute': ('mute', 'Event'),
  'MediaStreamTrack.unmute': ('unmute', 'Event'),
  'MIDIAccess.connect': ('connect', 'MidiConnectionEvent'),
  'MIDIAccess.disconnect': ('disconnect', 'MidiConnectionEvent'),
  'MIDIInput.midimessage': ('midiMessage', 'MidiMessageEvent'),
  'MIDIPort.disconnect': ('disconnect', 'MidiConnectionEvent'),
  'Notification.click': ('click', 'Event'),
  'Notification.close': ('close', 'Event'),
  'Notification.display': ('display', 'Event'),
  'Notification.show': ('show', 'Event'),
  'Performance.webkitresourcetimingbufferfull':
      ('resourceTimingBufferFull', 'Event'),
  'RTCDTMFSender.tonechange': ('toneChange', 'RtcDtmfToneChangeEvent'),
  'RTCDataChannel.close': ('close', 'Event'),
  'RTCDataChannel.open': ('open', 'Event'),
  'RTCPeerConnection.addstream': ('addStream', 'MediaStreamEvent'),
  'RTCPeerConnection.datachannel': ('dataChannel', 'RtcDataChannelEvent'),
  'RTCPeerConnection.icecandidate': ('iceCandidate', 'RtcIceCandidateEvent'),
  'RTCPeerConnection.iceconnectionstatechange': ('iceConnectionStateChange', 'Event'),
  'RTCPeerConnection.negotiationneeded': ('negotiationNeeded', 'Event'),
  'RTCPeerConnection.removestream': ('removeStream', 'MediaStreamEvent'),
  'RTCPeerConnection.signalingstatechange': ('signalingStateChange', 'Event'),
  'ScriptProcessorNode.audioprocess': ('audioProcess', 'AudioProcessingEvent'),
  'SharedWorkerGlobalScope.connect': ('connect', 'Event'),
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
  'SpeechSynthesisUtterance.boundary': ('boundary', 'SpeechSynthesisEvent'),
  'SpeechSynthesisUtterance.end': ('end', 'SpeechSynthesisEvent'),
  'SpeechSynthesisUtterance.mark': ('mark', 'SpeechSynthesisEvent'),
  'SpeechSynthesisUtterance.resume': ('resume', 'SpeechSynthesisEvent'),
  'SpeechSynthesisUtterance.start': ('start', 'SpeechSynthesisEvent'),
  'TextTrack.cuechange': ('cueChange', 'Event'),
  'TextTrackCue.enter': ('enter', 'Event'),
  'TextTrackCue.exit': ('exit', 'Event'),
  'TextTrackList.addtrack': ('addTrack', 'TrackEvent'),
  'WebSocket.close': ('close', 'CloseEvent'),
  'WebSocket.open': ('open', 'Event'), # should be OpenEvent, but not exposed.
  'Window.DOMContentLoaded': ('contentLoaded', 'Event'),
  'Window.devicemotion': ('deviceMotion', 'DeviceMotionEvent'),
  'Window.deviceorientation': ('deviceOrientation', 'DeviceOrientationEvent'),
  'Window.loadstart': ('loadStart', 'Event'),
  'Window.pagehide': ('pageHide', 'Event'),
  'Window.pageshow': ('pageShow', 'Event'),
  'Window.progress': ('progress', 'Event'),
  'Window.webkittransitionend': ('webkitTransitionEnd', 'TransitionEvent'),
  'XMLHttpRequestEventTarget.abort': ('abort', 'ProgressEvent'),
  'XMLHttpRequestEventTarget.error': ('error', 'ProgressEvent'),
  'XMLHttpRequestEventTarget.load': ('load', 'ProgressEvent'),
  'XMLHttpRequestEventTarget.loadend': ('loadEnd', 'ProgressEvent'),
  'XMLHttpRequestEventTarget.loadstart': ('loadStart', 'ProgressEvent'),
  'XMLHttpRequestEventTarget.progress': ('progress', 'ProgressEvent'),
  'XMLHttpRequestEventTarget.timeout': ('timeout', 'ProgressEvent'),
  'XMLHttpRequest.readystatechange': ('readyStateChange', 'ProgressEvent'),
})

# These classes require an explicit declaration for the "on" method even though
# they don't declare any unique events, because the concrete class hierarchy
# doesn't match the interface hierarchy.
_html_explicit_event_classes = set(['DocumentFragment'])

class HtmlEventGenerator(object):

  def __init__(self, database, renamer, metadata, template_loader):
    self._event_classes = set()
    self._database = database
    self._renamer = renamer
    self._metadata = metadata
    self._template_loader = template_loader
    self._media_events = None

  def EmitStreamProviders(self, interface, custom_events,
      members_emitter, library_name):
    events = self._GetEvents(interface, custom_events)
    if not events:
      return

    for event_info in events:
      (dom_name, html_name, event_type) = event_info
      annotation_name = dom_name + 'Event'

      # If we're using a different provider, then don't declare one.
      if self._GetEventRedirection(interface, html_name, event_type):
        continue

      annotations = self._metadata.FormatMetadata(
          self._metadata.GetMetadata(library_name, interface,
              annotation_name, 'on' + dom_name), '  ')

      members_emitter.Emit(
          "\n"
          "  $(ANNOTATIONS)static const EventStreamProvider<$TYPE> "
          "$(NAME)Event = const EventStreamProvider<$TYPE>('$DOM_NAME');\n",
          ANNOTATIONS=annotations,
          NAME=html_name,
          DOM_NAME=dom_name,
          TYPE=event_type)

  def EmitStreamGetters(self, interface, custom_events,
      members_emitter, library_name, stream_getter_signatures_emitter=None,
      element_stream_getters_emitter=None):
    events = self._GetEvents(interface, custom_events)
    if not events:
      return

    for event_info in events:
      (dom_name, html_name, event_type) = event_info
      getter_name = 'on%s%s' % (html_name[:1].upper(), html_name[1:])
      annotation_name = 'on' + dom_name

      # If the provider is declared elsewhere, point to that.
      redirection = self._GetEventRedirection(interface, html_name, event_type)
      if redirection:
        provider = '%s.%sEvent' % (redirection, html_name)
      else:
        provider = html_name + 'Event'

      annotations = self._metadata.GetFormattedMetadata(
          library_name, interface, annotation_name, '  ')

      isElement = False
      for parent in self._database.Hierarchy(interface):
        if parent.id == 'Element':
          isElement = True
      # We add the same event stream getters Element, ElementList, and
      # _FrozenElementList. So, in impl_Element.darttemplate, we have two
      # additional emitters to add the correct variation of the stream getter
      # for that context.
      for emitter in [members_emitter, stream_getter_signatures_emitter,
          element_stream_getters_emitter]:
        if emitter == None:
          continue
        elem_type = 'Element' if isElement else ''
        call_name = 'forElement' if isElement else 'forTarget'
        if emitter == element_stream_getters_emitter:
          call_name = '_forElementList'
        emitter.Emit(
            "\n"
            "  $(ANNOTATIONS)$(ELEM_TYPE)Stream<$TYPE> get $(NAME)$BODY;\n",
            ANNOTATIONS=annotations,
            ELEM_TYPE=elem_type,
            NAME=getter_name,
            BODY = ('' if emitter == stream_getter_signatures_emitter else
                ' => %s.%s(this)' % (((''
                if emitter != element_stream_getters_emitter else 'Element.')
                  + provider), call_name)),
            TYPE=event_type)

  def _GetRawEvents(self, interface):
    all_interfaces = ([ interface ] +
                      self._database.TransitiveSecondaryParents(interface,
                                                                False))
    events = set([])
    for super_interface in all_interfaces:
      events = events.union(
        set([attr.id for attr in super_interface.attributes
             if (attr.type.id == 'EventHandler'
              or attr.type.id == 'EventListener')]))
    return events

  def _GetEvents(self, interface, custom_events):
    """ Gets a list of all of the events for the specified interface.
    """
    html_interface_name = interface.doc_js_name

    events = self._GetRawEvents(interface)

    if html_interface_name in _html_manual_events:
      events.update(_html_manual_events[html_interface_name])

    if not events and interface.id not in _html_explicit_event_classes :
      return None

    dom_event_names = set()
    for event in events:
      dom_name = event[2:]
      dom_name = _on_attribute_to_event_name_mapping.get(dom_name, dom_name)
      dom_event_names.add(dom_name)

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

    if (interface.doc_js_name == 'Window' or
        interface.doc_js_name == 'Element' or
        interface.doc_js_name == 'Document' or
        interface.doc_js_name == 'GlobalEventHandlers'):
      media_interface = self._database.GetInterface('HTMLMediaElement')
      if not self._media_events:
        self._media_events = self._GetEvents(media_interface, [])
      if self._HasEvent(self._media_events, event_name, event_type):
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
