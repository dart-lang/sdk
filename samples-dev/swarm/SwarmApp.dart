// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of swarmlib;

/**
 * A simple news reader in Dart.
 */
class Swarm extends App {
  /**
   * Flag to insure the onLoad isn't called when callback from initializeFromUrl
   * could occur before the document's onload event.
   */
  bool onLoadFired;

  /** Collections of datafeeds to show per page. */
  Sections sections;

  /** The front page of the app. */
  FrontView frontView;

  /** Observable UI state. */
  SwarmState state;

  Swarm({bool useCannedData: false})
      : super(),
        onLoadFired = false {
    Sections.initializeFromUrl(useCannedData, (currSections) {
      sections = currSections;
      state = new SwarmState(sections);
      setupApp();
    });
    // Catch user keypresses and decide whether to use them for the
    // Streams app or pass them on to the browser.
    document.onKeyUp.listen((e) {
      if (frontView != null) {
        frontView.processKeyEvent(e);
      }
    });
  }

  /**
   * Tells each data source to check the server for the latest data.
   */
  void refresh() {
    sections.refresh();

    // Hook up listeners about any data source additions or deletions.  We don't
    // differentiate additions or deletions just the fact that data feeds have
    // changed.  We might want more fidelity later.
    sections.sectionTitles.forEach((title) {
      Section section = sections.findSection(title);
      // TODO(terry): addChangeListener needs to return an id so previous
      //              listener can be removed, otherwise anonymous functions
      //              can't easily be used.  See b/5063673
      section.feeds.addChangeListener((data) {
        // TODO(jacobr): implement this.
        print("Refresh sections not impl yet.");
      });
    });
  }

  /** The page load event handler. */
  void onLoad() {
    onLoadFired = true;
    super.onLoad();
    setupApp();
  }

  /**
   * Setup the application's world.
   */
  void setupApp() {
    // TODO(terry): Should be able to spinup the app w/o waiting for data.
    // If the document is already loaded so we can setup the app anytime.
    // Otherwise, we'll wait to setup the world until the document is ready
    // to render.
    if (onLoadFired && state != null) {
      render();
      // This call loads the initial data.
      refresh();
      eraseSplashScreen();
    }
  }

  void render() {
    frontView = new FrontView(this);
    frontView.addToDocument(document.body);
  }
}
