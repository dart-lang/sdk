// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of swarmlib;

// TODO(jacobr): there is a lot of dead code in this class. Checking is as is
// and then doing a large pass to remove functionality that doesn't make sense
// given the UI layout.

/**
 * Front page of Swarm.
 */
// TODO(jacobr): this code now needs a large refactoring.
// Suggested refactorings:
//  Move animation specific code into helper classes.
class FrontView extends CompositeView {
  final Swarm swarm;

  /** View containing all UI anchored to the top of the page. */
  CompositeView topView;
  /** View containing all UI anchored to the left side of the page. */
  CompositeView bottomView;
  HeaderView headerView;
  SliderMenu sliderMenu;

  /**
   * When the user is viewing a story, the data source for that story is
   * detached from the section and shown at the bottom of the screen. This keeps
   * track of that so we can restore it later.
   */
  DataSourceView detachedView;

  /**
   * Map from section title to the View that shows this section.  This
   * is populated lazily.
   */
  StoryContentView storyView;
  bool nextPrevShown;

  ConveyorView sections;

  /**
   * The set of keys that produce a given behavior (going down one story,
   * navigating to the column to the right, etc).
   */
  //TODO(jmesserly): we need a key code enumeration
  final Set downKeyPresses;
  final Set upKeyPresses;
  final Set rightKeyPresses;
  final Set leftKeyPresses;
  final Set openKeyPresses;
  final Set backKeyPresses;
  final Set nextPageKeyPresses;
  final Set previousPageKeyPresses;

  FrontView(this.swarm)
      : super('front-view fullpage'),
        downKeyPresses = new Set.from([74 /*j*/, 40 /*down*/]),
        upKeyPresses = new Set.from([75 /*k*/, 38 /*up*/]),
        rightKeyPresses = new Set.from([39 /*right*/, 68 /*d*/, 76 /*l*/]),
        leftKeyPresses = new Set.from([37 /*left*/, 65 /*a*/, 72 /*h*/]),
        openKeyPresses = new Set.from([13 /*enter*/, 79 /*o*/]),
        backKeyPresses = new Set.from([8 /*delete*/, 27 /*escape*/]),
        nextPageKeyPresses = new Set.from([78 /*n*/]),
        previousPageKeyPresses = new Set.from([80 /*p*/]),
        nextPrevShown = false {
    topView = new CompositeView('top-view', false, false, false);

    headerView = new HeaderView(swarm);
    topView.addChild(headerView);

    sliderMenu = new SliderMenu(swarm.sections.sectionTitles, (sectionTitle) {
      swarm.state.moveToNewSection(sectionTitle);
      _onSectionSelected(sectionTitle);
      // Start with no articles selected.
      swarm.state.selectedArticle.value = null;
    });
    topView.addChild(sliderMenu);
    addChild(topView);

    bottomView = new CompositeView('bottom-view', false, false, false);
    addChild(bottomView);

    sections = new ConveyorView();
    sections.viewSelected = _onSectionTransitionEnded;
  }

  SectionView get currentSection {
    var view = sections.selectedView;
    // TODO(jmesserly): this code works around a bug in the DartC --optimize
    if (view == null) {
      view = sections.childViews[0];
      sections.selectView(view);
    }
    return view;
  }

  void afterRender(Element node) {
    _createSectionViews();
    attachWatch(swarm.state.currentArticle, (e) {
      _refreshCurrentArticle();
    });
    attachWatch(swarm.state.storyMaximized, (e) {
      _refreshMaximized();
    });
  }

  void _refreshCurrentArticle() {
    if (!swarm.state.inMainView) {
      _animateToStory(swarm.state.currentArticle.value);
    } else {
      _animateToMainView();
    }
  }

  /**
   * Animates back from the story view to the main grid view.
   */
  void _animateToMainView() {
    sliderMenu.removeClass('hidden');
    storyView.addClass('hidden-story');
    currentSection.storyMode = false;

    headerView.startTransitionToMainView();

    currentSection.dataSourceView
        .reattachSubview(detachedView.source, detachedView, true);

    storyView.node.onTransitionEnd.first.then((e) {
      currentSection.hidden = false;
      // TODO(rnystrom): Should move this "mode" into SwarmState and have
      // header view respond to change events itself.
      removeChild(storyView);
      storyView = null;
      detachedView.removeClass('sel');
      detachedView = null;
    });
  }

  void _animateToStory(Article item) {
    final source = item.dataSource;

    if (detachedView != null && detachedView.source != source) {
      // Ignore spurious item selection clicks that occur while a data source
      // is already selected.  These are likely clicks that occur while an
      // animation is in progress.
      return;
    }

    if (storyView != null) {
      // Remove the old story. This happens if we're already in the Story View
      // and the user has clicked to see a new story.
      removeChild(storyView);

      // Create the new story view and place in the frame.
      storyView = addChild(new StoryContentView(swarm, item));
    } else {
      // We are animating from the main view to the story view.
      // TODO(jmesserly): make this code better
      final view = currentSection.findView(source);

      final newPosition =
          FxUtil.computeRelativePosition(view.node, bottomView.node);
      currentSection.dataSourceView.detachSubview(view.source);
      detachedView = view;

      FxUtil.setPosition(view.node, newPosition);
      bottomView.addChild(view);
      view.addClass('sel');
      currentSection.storyMode = true;

      // Create the new story view.
      storyView = new StoryContentView(swarm, item);
      new Timer(const Duration(milliseconds: 0), () {
        _animateDataSourceToMinimized();

        sliderMenu.addClass('hidden');
        // Make the fancy sliding into the window animation.
        new Timer(const Duration(milliseconds: 0), () {
          storyView.addClass('hidden-story');
          addChild(storyView);
          new Timer(const Duration(milliseconds: 0), () {
            storyView.removeClass('hidden-story');
          });
          headerView.endTransitionToStoryView();
        });
      });
    }
  }

  void _refreshMaximized() {
    if (swarm.state.storyMaximized.value) {
      _animateDataSourceToMaximized();
    } else {
      _animateDataSourceToMinimized();
    }
  }

  void _animateDataSourceToMaximized() {
    FxUtil.setWebkitTransform(topView.node, 0, -HeaderView.HEIGHT);
    if (detachedView != null) {
      FxUtil.setWebkitTransform(
          detachedView.node, 0, -DataSourceView.TAB_ONLY_HEIGHT);
    }
  }

  void _animateDataSourceToMinimized() {
    if (detachedView != null) {
      FxUtil.setWebkitTransform(detachedView.node, 0, 0);
      FxUtil.setWebkitTransform(topView.node, 0, 0);
    }
  }

  /**
   * Called when the animation to switch to a section has completed.
   */
  void _onSectionTransitionEnded(SectionView selectedView) {
    // Show the section and hide the others.
    for (SectionView view in sections.childViews) {
      if (view == selectedView) {
        // Always refresh the sources in case they've changed.
        view.showSources();
      } else {
        // Only show the current view for performance.
        view.hideSources();
      }
    }
  }

  /**
   * Called when the user chooses a section on the SliderMenu.  Hides
   * all views except the one they want to see.
   */
  void _onSectionSelected(String sectionTitle) {
    final section = swarm.sections.findSection(sectionTitle);
    // Find the view for this section.
    for (SectionView view in sections.childViews) {
      if (view.section == section) {
        // Have the conveyor show it.
        sections.selectView(view);
        break;
      }
    }
  }

  /**
   * Create SectionViews for each Section in the app and add them to the
   * conveyor. Note that the SectionViews won't actually populate or load data
   * sources until they are shown in response to [:_onSectionSelected():].
   */
  void _createSectionViews() {
    for (final section in swarm.sections) {
      final viewFactory = new DataSourceViewFactory(swarm);
      final sectionView = new SectionView(swarm, section, viewFactory);

      // TODO(rnystrom): Hack temp. Access node to make sure SectionView has
      // rendered and created scroller. This can go away when event registration
      // is being deferred.
      sectionView.node;

      sections.addChild(sectionView);
    }
    addChild(sections);
  }

  /**
   * Controls the logic of how to respond to keypresses and then update the
   * UI accordingly.
   */
  void processKeyEvent(KeyboardEvent e) {
    int code = e.keyCode;
    if (swarm.state.inMainView) {
      // Option 1: We're in the Main Grid mode.
      if (!swarm.state.hasArticleSelected) {
        // Then a key has been pressed. Select the first item in the
        // top left corner.
        swarm.state.goToFirstArticleInSection();
      } else if (rightKeyPresses.contains(code)) {
        // Store original state that is needed if we need to move
        // to the next section.
        swarm.state.goToNextFeed();
      } else if (leftKeyPresses.contains(code)) {
        // Store original state that is needed if we need to move
        // to the next section.
        swarm.state.goToPreviousFeed();
      } else if (downKeyPresses.contains(code)) {
        swarm.state.goToNextSelectedArticle();
      } else if (upKeyPresses.contains(code)) {
        swarm.state.goToPreviousSelectedArticle();
      } else if (openKeyPresses.contains(code)) {
        // View a story in the larger Story View.
        swarm.state.selectStoryAsCurrent();
      } else if (nextPageKeyPresses.contains(code)) {
        swarm.state.goToNextSection(sliderMenu);
      } else if (previousPageKeyPresses.contains(code)) {
        swarm.state.goToPreviousSection(sliderMenu);
      }
    } else {
      // Option 2: We're in Story Mode. In this mode, the user can move up
      // and down through stories, which automatically loads the next story.
      if (downKeyPresses.contains(code)) {
        swarm.state.goToNextArticle();
      } else if (upKeyPresses.contains(code)) {
        swarm.state.goToPreviousArticle();
      } else if (backKeyPresses.contains(code)) {
        // Move back to the main grid view.
        swarm.state.clearCurrentArticle();
      }
    }
  }
}

/** Transitions the app back to the main screen. */
void _backToMain(SwarmState state) {
  if (state.currentArticle.value != null) {
    state.clearCurrentArticle();
    state.storyTextMode.value = true;
    state.pushToHistory();
  }
}

/** A back button that sends the user back to the front page. */
class SwarmBackButton extends View {
  Swarm swarm;

  SwarmBackButton(this.swarm) : super();

  Element render() => new Element.html('<div class="back-arrow button"></div>');

  void afterRender(Element node) {
    addOnClick((e) {
      _backToMain(swarm.state);
    });
  }
}

/** Top view constaining the title and standard buttons. */
class HeaderView extends CompositeView {
  // TODO(jacobr): make this value be coupled with the CSS file.
  static const HEIGHT = 80;
  Swarm swarm;

  View _title;
  View _infoButton;
  View _configButton;
  View _refreshButton;
  SwarmBackButton _backButton;
  View _infoDialog;
  View _configDialog;

  // For (text/web) article view controls
  View _webBackButton;
  View _webForwardButton;
  View _newWindowButton;

  HeaderView(this.swarm) : super('header-view') {
    _backButton = addChild(new SwarmBackButton(swarm));
    _title = addChild(View.div('app-title', 'Swarm'));
    _configButton = addChild(View.div('config button'));
    _refreshButton = addChild(View.div('refresh button'));
    _infoButton = addChild(View.div('info-button button'));

    // TODO(rnystrom): No more web/text mode (it's just text) so get rid of
    // these.
    _webBackButton = addChild(new WebBackButton());
    _webForwardButton = addChild(new WebForwardButton());
    _newWindowButton = addChild(View.div('new-window-button button'));
  }

  void afterRender(Element node) {
    // Respond to changes to whether the story is being shown as text or web.
    attachWatch(swarm.state.storyTextMode, (e) {
      refreshWebStoryButtons();
    });

    _title.addOnClick((e) {
      _backToMain(swarm.state);
    });

    // Wire up the events.
    _configButton.addOnClick((e) {
      // Bring up the config dialog.
      if (this._configDialog == null) {
        // TODO(terry): Cleanup, HeaderView shouldn't be tangled with main view.
        this._configDialog = new ConfigHintDialog(swarm.frontView, () {
          swarm.frontView.removeChild(this._configDialog);
          this._configDialog = null;

          // TODO: Need to push these to the server on a per-user basis.
          // Update the storage now.
          swarm.sections.refresh();
        });

        swarm.frontView.addChild(this._configDialog);
      }
      // TODO(jimhug): Graceful redirection to reader.
    });

    // On click of the refresh button, refresh the swarm.
    _refreshButton.addOnClick(EventBatch.wrap((e) {
      swarm.refresh();
    }));

    // On click of the info button, show Dart info page in new window/tab.
    _infoButton.addOnClick((e) {
      // Bring up the config dialog.
      if (this._infoDialog == null) {
        // TODO(terry): Cleanup, HeaderView shouldn't be tangled with main view.
        this._infoDialog = new HelpDialog(swarm.frontView, () {
          swarm.frontView.removeChild(this._infoDialog);
          this._infoDialog = null;

          swarm.sections.refresh();
        });

        swarm.frontView.addChild(this._infoDialog);
      }
    });

    // On click of the new window button, show web article in new window/tab.
    _newWindowButton.addOnClick((e) {
      String currentArticleSrcUrl = swarm.state.currentArticle.value.srcUrl;
      window.open(currentArticleSrcUrl, '_blank');
    });

    startTransitionToMainView();
  }

  /**
   * Refreshes whether or not the buttons specific to the display of a story in
   * the web perspective are visible.
   */
  void refreshWebStoryButtons() {
    bool webButtonsHidden = true;

    if (swarm.state.currentArticle.value != null) {
      // Set if web buttons are hidden
      webButtonsHidden = swarm.state.storyTextMode.value;
    }

    _webBackButton.hidden = webButtonsHidden;
    _webForwardButton.hidden = webButtonsHidden;
    _newWindowButton.hidden = webButtonsHidden;
  }

  void startTransitionToMainView() {
    _title.removeClass('in-story');
    _backButton.removeClass('in-story');

    _configButton.removeClass('in-story');
    _refreshButton.removeClass('in-story');
    _infoButton.removeClass('in-story');

    refreshWebStoryButtons();
  }

  void endTransitionToStoryView() {
    _title.addClass('in-story');
    _backButton.addClass('in-story');

    _configButton.addClass('in-story');
    _refreshButton.addClass('in-story');
    _infoButton.addClass('in-story');
  }
}

/** A back button for the web view of a story that is equivalent to clicking
 * "back" in the browser. */
// TODO(rnystrom): We have nearly identical versions of this littered through
// the sample apps. Should consolidate into one.
class WebBackButton extends View {
  WebBackButton() : super();

  Element render() {
    return new Element.html('<div class="web-back-button button"></div>');
  }

  void afterRender(Element node) {
    addOnClick((e) {
      back();
    });
  }

  /** Equivalent to [window.history.back] */
  static void back() {
    window.history.back();
  }
}

/** A back button for the web view of a story that is equivalent to clicking
 * "forward" in the browser. */
// TODO(rnystrom): We have nearly identical versions of this littered through
// the sample apps. Should consolidate into one.
class WebForwardButton extends View {
  WebForwardButton() : super();

  Element render() {
    return new Element.html('<div class="web-forward-button button"></div>');
  }

  void afterRender(Element node) {
    addOnClick((e) {
      forward();
    });
  }

  /** Equivalent to [window.history.forward] */
  static void forward() {
    window.history.forward();
  }
}

/**
 * A factory that creates a view for data sources.
 */
class DataSourceViewFactory implements ViewFactory<Feed> {
  Swarm swarm;

  DataSourceViewFactory(this.swarm) {}

  View newView(Feed data) => new DataSourceView(data, swarm);

  int get width => ArticleViewLayout.getSingleton().width;
  int get height => null; // Width for this view isn't known.
}

/**
 * A view for the items from a single data source.
 * Shows a title and a list of items.
 */
class DataSourceView extends CompositeView {
  // TODO(jacobr): make this value be coupled with the CSS file.
  static const TAB_ONLY_HEIGHT = 34;

  final Feed source;
  VariableSizeListView<Article> itemsView;

  DataSourceView(this.source, Swarm swarm) : super('query') {
    // TODO(jacobr): make the title a view or decide it is sane for a subclass
    // of component view to manually add some DOM cruft.
    node.nodes.add(new Element.html('<h2>${source.title}</h2>'));

    // TODO(jacobr): use named arguments when available.
    itemsView = addChild(new VariableSizeListView<Article>(
        source.articles,
        new ArticleViewFactory(swarm),
        true,
        /* scrollable */
        true,
        /* vertical */
        swarm.state.currentArticle,
        /* selectedItem */
        !Device.supportsTouch /* snapToArticles */,
        false /* paginate */,
        true /* removeClippedViews */,
        !Device.supportsTouch /* showScrollbar */));
    itemsView.addClass('story-section');

    node.nodes.add(new Element.html('<div class="query-name-shadow"></div>'));

    // Clicking the view (i.e. its title area) unmaximizes to show the entire
    // view.
    node.onMouseDown.listen((e) {
      swarm.state.storyMaximized.value = false;
    });
  }
}

/** A button that toggles between states. */
class ToggleButton extends View {
  EventListeners onChanged;
  List<String> states;

  ToggleButton(this.states)
      : super(),
        onChanged = new EventListeners();

  Element render() => new Element.tag('button');

  void afterRender(Element node) {
    state = states[0];
    node.onClick.listen((event) {
      toggle();
    });
  }

  String get state {
    final currentState = node.innerHtml;
    assert(states.indexOf(currentState, 0) >= 0);
    return currentState;
  }

  void set state(String state) {
    assert(states.indexOf(state, 0) >= 0);
    node.innerHtml = state;
    onChanged.fire(null);
  }

  void toggle() {
    final oldState = state;
    int index = states.indexOf(oldState, 0);
    index = (index + 1) % states.length;
    state = states[index];
  }
}

/**
 * A factory that creates a view for generic items.
 */
class ArticleViewFactory implements VariableSizeViewFactory<Article> {
  Swarm swarm;

  ArticleViewLayout layout;
  ArticleViewFactory(this.swarm) : layout = ArticleViewLayout.getSingleton();

  View newView(Article item) => new ArticleView(item, swarm, layout);

  int getWidth(Article item) => layout.width;
  int getHeight(Article item) => layout.computeHeight(item);
}

class ArticleViewMetrics {
  final int height;
  final int titleLines;
  final int bodyLines;

  const ArticleViewMetrics(this.height, this.titleLines, this.bodyLines);
}

class ArticleViewLayout {
  // TODO(terry): clean this up once we have a framework for sharing constants
  // between JS and CSS. See bug #5405307.
  static const IPAD_WIDTH = 257;
  static const DESKTOP_WIDTH = 297;
  static const CHROME_OS_WIDTH = 317;
  static const TITLE_MARGIN_LEFT = 257 - 150;
  static const BODY_MARGIN_LEFT = 257 - 221;
  static const LINE_HEIGHT = 18;
  static const TITLE_FONT = 'bold 13px arial,sans-serif';
  static const BODY_FONT = '13px arial,sans-serif';
  static const TOTAL_MARGIN = 16 * 2 + 70;
  static const MIN_TITLE_HEIGHT = 36;
  static const MAX_TITLE_LINES = 2;
  static const MAX_BODY_LINES = 4;

  MeasureText measureTitleText;
  MeasureText measureBodyText;

  int width;
  static ArticleViewLayout _singleton;
  ArticleViewLayout()
      : measureBodyText = new MeasureText(BODY_FONT),
        measureTitleText = new MeasureText(TITLE_FONT) {
    num screenWidth = window.screen.width;
    width = DESKTOP_WIDTH;
  }

  static ArticleViewLayout getSingleton() {
    if (_singleton == null) {
      _singleton = new ArticleViewLayout();
    }
    return _singleton;
  }

  int computeHeight(Article item) {
    if (item == null) {
      // TODO(jacobr): find out why this is happening..
      print('Null item encountered.');
      return 0;
    }

    return computeLayout(item, null, null).height;
  }

  /**
   * titleContainer and snippetContainer may be null in which case the size is
   * computed but no actual layout is performed.
   */
  ArticleViewMetrics computeLayout(
      Article item, StringBuffer titleBuffer, StringBuffer snippetBuffer) {
    int titleWidth = width - BODY_MARGIN_LEFT;

    if (item.hasThumbnail) {
      titleWidth = width - TITLE_MARGIN_LEFT;
    }

    final titleLines = measureTitleText.addLineBrokenText(
        titleBuffer, item.title, titleWidth, MAX_TITLE_LINES);
    final bodyLines = measureBodyText.addLineBrokenText(
        snippetBuffer, item.textBody, width - BODY_MARGIN_LEFT, MAX_BODY_LINES);

    int height = bodyLines * LINE_HEIGHT + TOTAL_MARGIN;

    if (bodyLines == 0) {
      height = 92;
    }

    return new ArticleViewMetrics(height, titleLines, bodyLines);
  }
}

/**
 * A view for a generic item.
 */
class ArticleView extends View {
  // Set to false to make inspecting the HTML more pleasant...
  static const SAVE_IMAGES = false;

  final Article item;
  final Swarm swarm;
  final ArticleViewLayout articleLayout;

  ArticleView(this.item, this.swarm, this.articleLayout) : super();

  Element render() {
    Element node;

    final byline = item.author.length > 0 ? item.author : item.dataSource.title;
    final date = DateUtils.toRecentTimeString(item.date);

    String storyClass = 'story no-thumb';
    String thumbnail = '';

    if (item.hasThumbnail) {
      storyClass = 'story';
      thumbnail = '<img src="${item.thumbUrl}"></img>';
    }

    final title = new StringBuffer();
    final snippet = new StringBuffer();

    // Note: also populates title and snippet elements.
    final metrics = articleLayout.computeLayout(item, title, snippet);

    node = new Element.html('''
<div class="$storyClass">
  $thumbnail
  <div class="title">$title</div>
  <div class="byline">$byline</div>
  <div class="dateline">$date</div>
  <div class="snippet">$snippet</div>
</div>''');

    // Remove the snippet entirely if it's empty. This keeps it from taking up
    // space and pushing the padding down.
    if ((item.textBody == null) || (item.textBody.trim() == '')) {
      node.querySelector('.snippet').remove();
    }

    return node;
  }

  void afterRender(Element node) {
    // Select this view's item.
    addOnClick((e) {
      // Mark the item as read, so it shows as read in other views
      item.unread.value = false;

      final oldArticle = swarm.state.currentArticle.value;
      swarm.state.currentArticle.value = item;
      swarm.state.storyTextMode.value = true;
      if (oldArticle == null) {
        swarm.state.pushToHistory();
      }
    });

    watch(swarm.state.currentArticle, (e) {
      if (!swarm.state.inMainView) {
        swarm.state.markCurrentAsRead();
      }
      _refreshSelected(swarm.state.currentArticle);
      //TODO(efortuna): add in history stuff while reading articles?
    });

    watch(swarm.state.selectedArticle, (e) {
      _refreshSelected(swarm.state.selectedArticle);
      _updateViewForSelectedArticle();
    });

    watch(item.unread, (e) {
      // TODO(rnystrom): Would be nice to do:
      //     node.classes.set('story-unread', item.unread.value)
      if (item.unread.value) {
        node.classes.add('story-unread');
      } else {
        node.classes.remove('story-unread');
      }
    });
  }

  /**
   * Notify the view to jump to a different area if we are selecting an
   * article that is currently outside of the visible area.
   */
  void _updateViewForSelectedArticle() {
    Article selArticle = swarm.state.selectedArticle.value;
    if (swarm.state.hasArticleSelected) {
      // Ensure that the selected article is visible in the view.
      if (!swarm.state.inMainView) {
        // Story View.
        swarm.frontView.detachedView.itemsView.showView(selArticle);
      } else {
        if (swarm.frontView.currentSection.inCurrentView(selArticle)) {
          // Scroll horizontally if needed.
          swarm.frontView.currentSection.dataSourceView
              .showView(selArticle.dataSource);
          DataSourceView dataView =
              swarm.frontView.currentSection.findView(selArticle.dataSource);
          if (dataView != null) {
            dataView.itemsView.showView(selArticle);
          }
        }
      }
    }
  }

  String getDataUriForImage(final img) {
    // TODO(hiltonc,jimhug) eval perf of this vs. reusing one canvas element
    final CanvasElement canvas =
        new CanvasElement(height: img.height, width: img.width);

    final CanvasRenderingContext2D ctx = canvas.getContext("2d");
    ctx.drawImage(img, 0, 0, img.width, img.height);

    return canvas.toDataUrl("image/png");
  }

  /**
   * Update this view's selected appearance based on the currently selected
   * Article.
   */
  void _refreshSelected(curItem) {
    if (curItem.value == item) {
      addClass('sel');
    } else {
      removeClass('sel');
    }
  }

  void _saveToStorage(String thumbUrl, ImageElement img) {
    // TODO(jimhug): Reimplement caching of images.
  }
}

/**
 * An internal view of a story as text. In other words, the article is shown
 * in-place as opposed to as an embedded web-page.
 */
class StoryContentView extends View {
  final Swarm swarm;
  final Article item;

  View _pagedStory;

  StoryContentView(this.swarm, this.item) : super();

  get childViews => [_pagedStory];

  Element render() {
    final storyContent =
        new Element.html('<div class="story-content">${item.htmlBody}</div>');
    for (Element element in storyContent.querySelectorAll(
        "iframe, script, style, object, embed, frameset, frame")) {
      element.remove();
    }
    _pagedStory = new PagedContentView(new View.fromNode(storyContent));

    // Modify all links to open in new windows....
    // TODO(jacobr): would it be better to add an event listener on click that
    // intercepts these instead?
    for (AnchorElement anchor in storyContent.querySelectorAll('a')) {
      anchor.target = '_blank';
    }

    final date = DateUtils.toRecentTimeString(item.date);
    final container = new Element.html('''
      <div class="story-view">
        <div class="story-text-view">
          <div class="story-header">
            <a class="story-title" href="${item.srcUrl}" target="_blank">
              ${item.title}</a>
            <div class="story-byline">
              ${item.author} - ${item.dataSource.title}
            </div>
            <div class="story-dateline">$date</div>
          </div>
          <div class="paged-story"></div>
          <div class="spacer"></div>
        </div>
      </div>''');

    container.querySelector('.paged-story').replaceWith(_pagedStory.node);

    return container;
  }
}

class SectionView extends CompositeView {
  final Section section;
  final Swarm swarm;
  final DataSourceViewFactory _viewFactory;
  final View loadingText;
  ListView<Feed> dataSourceView;
  PageNumberView pageNumberView;
  final PageState pageState;

  SectionView(this.swarm, this.section, this._viewFactory)
      : super('section-view'),
        loadingText = new View.html('<div class="loading-section"></div>'),
        pageState = new PageState() {
    addChild(loadingText);
  }

  /**
   * Hides the loading text, reloads the data sources, and shows them.
   */
  void showSources() {
    loadingText.node.style.display = 'none';

    // Lazy initialize the data source view.
    if (dataSourceView == null) {
      // TODO(jacobr): use named arguments when available.
      dataSourceView = new ListView<Feed>(
          section.feeds,
          _viewFactory,
          true /* scrollable */,
          false /* vertical */,
          null /* selectedItem */,
          true /* snapToItems */,
          true /* paginate */,
          true /* removeClippedViews */,
          false,
          /* showScrollbar */
          pageState);
      dataSourceView.addClass("data-source-view");
      addChild(dataSourceView);

      pageNumberView = addChild(new PageNumberView(pageState));

      node.style.opacity = '1';
    } else {
      addChild(dataSourceView);
      addChild(pageNumberView);
      node.style.opacity = '1';
    }

    // TODO(jacobr): get rid of this call to reconfigure when it is not needed.
    dataSourceView.scroller.reconfigure(() {});
  }

  /**
   * Hides the data sources and shows the loading text.
   */
  void hideSources() {
    if (dataSourceView != null) {
      node.style.opacity = '0.6';
      removeChild(dataSourceView);
      removeChild(pageNumberView);
    }

    loadingText.node.style.display = 'block';
  }

  set storyMode(bool inStoryMode) {
    if (inStoryMode) {
      addClass('hide-all-queries');
    } else {
      removeClass('hide-all-queries');
    }
  }

  /**
   * Find the [DataSourceView] in this SectionView that's displaying the given
   * [Feed].
   */
  DataSourceView findView(Feed dataSource) {
    return dataSourceView.getSubview(dataSourceView.findIndex(dataSource));
  }

  bool inCurrentView(Article article) {
    return dataSourceView.findIndex(article.dataSource) != null;
  }
}
