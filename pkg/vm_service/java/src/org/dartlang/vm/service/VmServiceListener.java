/*
 * Copyright (c) 2015, the Dart project authors.
 *
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
package org.dartlang.vm.service;

import org.dartlang.vm.service.element.Event;

/**
 * Interface used by {@link VmService} to notify others of VM events.
 */
public interface VmServiceListener {
  void connectionOpened();

  /**
   * Called when a VM event has been received.
   *
   * @param streamId the stream identifier (e.g. {@link VmService#DEBUG_STREAM_ID}
   * @param event    the event
   */
  void received(String streamId, Event event);

  void connectionClosed();
}
