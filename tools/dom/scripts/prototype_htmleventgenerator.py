#!/usr/bin/env python3
# Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Generates the dart:html event providers and getters for the prototype."""

import monitored
import subprocess

OUTPUT_FILE = 'prototype_events.dart'

_custom_events = set(['mouseWheel', 'transitionEnd', 'visibilityChange'])

_type_specific_events = set(['doubleClick', 'error'])

_deprecated_event_interfaces = set([
    'AccessibleNode', 'AccessibleNodeList', 'ApplicationCache', 'FileWriter',
    'VRSession'
])
_deprecated_event_types = set(['ForeignFetchEvent', 'MediaStreamEvent'])

_non_html_types = monitored.Dict(
    'prototype_htmleventgenerator._non_html_events', {
        'ContextEvent': 'web_gl',
        'Database': 'indexed_db',
        'OpenDBRequest': 'indexed_db',
        'Request': 'indexed_db',
        'SvgElement': 'svg',
        'Transaction': 'indexed_db',
        'VersionChangeEvent': 'indexed_db'
    })


class Prototype_HtmlEventGenerator(object):

    def __init__(self, database, renamer, metadata, htmleventgenerator):
        self._database = database
        self._renamer = renamer
        self._metadata = metadata
        self._html_event_generator = htmleventgenerator
        self._all_event_providers = {}
        self._all_event_getters = {}

    # Gather all EventStreamProviders for the given interface type.
    def CollectStreamProviders(self, interface, custom_events, library_name):

        events = self._html_event_generator.GetEvents(interface, custom_events)
        if not events:
            return

        for event_info in events:
            (dom_name, html_name, event_type) = event_info
            # Skip custom events that are added to glue code separately
            if html_name in _custom_events:
                continue
            annotation_name = dom_name + 'Event'

            annotations = self._metadata.FormatMetadata(
                self._metadata.GetMetadata(library_name, interface,
                                           annotation_name, 'on' + dom_name),
                '  ')

            # Strip comment from annotations
            if '/**' in annotations:
                annotations = annotations[annotations.index('*/') + 2:]
            event_type = self._formatEventType(event_type)
            html_name = (html_name if html_name not in _type_specific_events
                         else html_name + interface.doc_js_name)

            self._all_event_providers.update(
                {html_name: [annotations, dom_name, event_type]})

    # Gather all getters `onFooEvent` for the given interface type.
    def CollectStreamGetters(self, interface, custom_events, library_name):
        events = self._html_event_generator.GetEvents(interface, custom_events)
        if not events:
            return
        interface_events = {}
        for event_info in events:
            (dom_name, html_name, event_type) = event_info
            # Skip custom events that are added to glue code separately
            if html_name in _custom_events:
                continue
            getter_name = 'on%s%s' % (html_name[:1].upper(), html_name[1:])
            annotation_name = 'on' + dom_name

            annotations = self._metadata.GetFormattedMetadata(
                library_name, interface, annotation_name, '  ')

            # Strip comment from annotations
            if '///' in annotations:
                annotations = annotations[annotations.index('\n') + 1:]

            event_type = self._formatEventType(event_type)
            html_name = (html_name if html_name not in _type_specific_events
                         else html_name + interface.doc_js_name)
            provider = html_name + 'Event'

            interface_events.update(
                {getter_name: [annotations, event_type, provider]})
        self._all_event_getters.update({interface: interface_events})

    # Returns whether the given interface has `Element` as a supertype.
    def _isElement(self, interface):
        for parent in self._database.Hierarchy(interface):
            if parent.id == 'Element':
                return True
        return False

    # Formats event_type by stripping other namespace prefixing.
    def _formatEventType(self, event_type):
        if '.' in event_type:
            event_type = event_type[event_type.index('.') + 1:]
        return event_type

    # Output Providers and Event Getters to the output file.
    def WriteFile(self, dart_bin):
        output_file = open(OUTPUT_FILE, 'w')
        output_file.write("""
/// Exposing the Streams of events for legacy dart:html.
library dart.html_events;

import 'dart:html' as html;
import 'dart:html_common';
import 'dart:indexed_db' as indexed_db;
import 'dart:event_stream' show ElementStream, EventStreamProvider;
import 'dart:svg' as svg;
import 'dart:web_gl' as web_gl;

""")
        self._writeProviders(output_file)
        self._writeEventGetters(output_file)
        output_file.close()
        formatCommand = ' '.join([dart_bin, 'format', OUTPUT_FILE])
        subprocess.call([formatCommand], shell=True)

    # Output all EventstreamProviders.
    def _writeProviders(self, output_file):
        output_file.write("""
/// Statically accessible `EventStreamProvider`s for all event types.
class EventStreamProviders {
""")
        for html_name, info in sorted(self._all_event_providers.items()):
            (annotations, dom_name, event_type) = info
            if event_type in _deprecated_event_types:
                continue
            event_prefix = ('html' if event_type not in _non_html_types else
                            _non_html_types[event_type])
            output_file.write("""
  %sstatic const EventStreamProvider<%s.%s> %sEvent = 
  const EventStreamProvider<%s.%s>('%s');
""" % (annotations, event_prefix, event_type, html_name, event_prefix,
            event_type, dom_name))
        output_file.write("""\n}\n""")

    # Output all onFooEvent getters in extensions.
    def _writeEventGetters(self, output_file):
        for interface, events in self._all_event_getters.items():
            isElement = self._isElement(interface)
            interface_name = interface.doc_js_name
            if interface_name in _deprecated_event_interfaces:
                continue
            interface_name = self._renamer.RenameInterface(interface)
            interface_prefix = ('html' if interface_name not in _non_html_types
                                else _non_html_types[interface_name])
            output_file.write("""

/// Additional Event getters for [%s].
extension %sEventGetters on %s.%s {
""" % (interface_name, interface_name, interface_prefix, interface_name))
            for getter_name, info in sorted(events.items()):
                (annotations, event_type, provider) = info
                if event_type in _deprecated_event_types:
                    continue
                event_prefix = ('html' if event_type not in _non_html_types else
                                _non_html_types[event_type])
                output_file.write("""
%s
%sStream<%s.%s> get %s => EventStreamProviders.%s.%s(this);
""" % (annotations, 'Element' if isElement else '', event_prefix, event_type,
                getter_name, provider, 'forElement' if isElement else 'forTarget'))
            output_file.write("""\n}\n""")
