// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of swarmlib;

/**
 * The top-level class for the UI state. UI state is essentially a "model" from
 * the view's perspective but whose data just describes the UI itself. It
 * contains data like the currently selected story, etc.
 */
// TODO(jimhug): Split the two classes here into framework and app-specific.
class SwarmState extends UIState {
  /** Core data source for the app. */
  final Sections _dataModel;

  /**
   * Which article the user is currently viewing, or null if they aren't
   * viewing an Article.
   */
  final ObservableValue<Article> currentArticle;
  /**
   * Which article the user currently has selected (for traversing articles
   * via keyboard shortcuts).
   */
  final ObservableValue<Article> selectedArticle;

  /**
   * True if the story view is maximized and the top and bottom UI elements
   * are hidden.
   */
  final ObservableValue<bool> storyMaximized;

  /**
   * True if the maximized story, if any, is being displayed in text mode
   * rather than as an embedded web-page.
   */
  final ObservableValue<bool> storyTextMode;

  /**
   * Which article the user currently has selected (by keyboard shortcuts),
   * or null if an article isn't selected by the keyboard.
   */
  BiIterator<Article> _articleIterator;

  /**
   * Which feed is currently selected (for keyboard shortcuts).
   */
  BiIterator<Feed> _feedIterator;

  /**
   * Which section is currently selected (for keyboard shortcuts).
   */
  BiIterator<Section> _sectionIterator;

  SwarmState(this._dataModel)
      : super(),
        currentArticle = new ObservableValue<Article>(null),
        selectedArticle = new ObservableValue<Article>(null),
        storyMaximized = new ObservableValue<bool>(false),
        storyTextMode = new ObservableValue<bool>(true) {
    startHistoryTracking();
    // TODO(efortuna): consider having this class just hold observable
    // currentIndecies instead of iterators with observablevalues..
    _sectionIterator = new BiIterator<Section>(_dataModel.sections);
    _feedIterator = new BiIterator<Feed>(_sectionIterator.current.feeds);
    _articleIterator = new BiIterator<Article>(_feedIterator.current.articles);

    currentArticle.addChangeListener((e) {
      _articleIterator.jumpToValue(currentArticle.value);
    });
  }

  /**
   * Registers an event to fire on any state change
   *
   * TODO(jmesserly): fix this so we don't have to enumerate all of our fields
   * again. One idea here is UIState becomes Observable, Observables have
   * parents and notifications bubble up the parent chain.
   */
  void addChangeListener(ChangeListener listener) {
    _sectionIterator.currentIndex.addChangeListener(listener);
    _feedIterator.currentIndex.addChangeListener(listener);
    _articleIterator.currentIndex.addChangeListener(listener);
    currentArticle.addChangeListener(listener);
  }

  Map<String, String> toHistory() {
    final data = {};
    data['section'] = currentSection.id;
    data['feed'] = currentFeed.id;
    if (currentArticle.value != null) {
      data['article'] = currentArticle.value.id;
    }
    return data;
  }

  void loadFromHistory(Map values) {
    // TODO(jimhug): There's a better way of doing this...
    if (values['section'] != null) {
      _sectionIterator
          .jumpToValue(_dataModel.findSectionById(values['section']));
    } else {
      _sectionIterator = new BiIterator<Section>(_dataModel.sections);
    }
    if (values['feed'] != null && currentSection != null) {
      _feedIterator.jumpToValue(currentSection.findFeed(values['feed']));
    } else {
      _feedIterator = new BiIterator<Feed>(_sectionIterator.current.feeds);
    }
    if (values['article'] != null && currentFeed != null) {
      currentArticle.value = currentFeed.findArticle(values['article']);
      _articleIterator.jumpToValue(currentArticle.value);
    } else {
      _articleIterator =
          new BiIterator<Article>(_feedIterator.current.articles);
      currentArticle.value = null;
    }

    storyMaximized.value = false;
  }

  /**
   * Move the currentArticle pointer to the next item in the Feed.
   */
  void goToNextArticle() {
    currentArticle.value = _articleIterator.next();
    selectedArticle.value = _articleIterator.current;
  }

  /**
   * Move the currentArticle pointer to the previous item in the Feed.
   */
  void goToPreviousArticle() {
    currentArticle.value = _articleIterator.previous();
    selectedArticle.value = _articleIterator.current;
  }

  /**
   * Move the selectedArticle pointer to the next item in the Feed.
   */
  void goToNextSelectedArticle() {
    selectedArticle.value = _articleIterator.next();
  }

  /**
   * Move the selectedArticle pointer to the previous item in the Feed.
   */
  void goToPreviousSelectedArticle() {
    selectedArticle.value = _articleIterator.previous();
  }

  /**
   * Move the pointers for selectedArticle to point to the next
   * Feed.
   */
  void goToNextFeed() {
    var newFeed = _feedIterator.next();
    int oldIndex = _articleIterator.currentIndex.value;

    _articleIterator = new BiIterator<Article>(
        newFeed.articles, _articleIterator.currentIndex.listeners);

    _articleIterator.currentIndex.value = oldIndex;
    selectedArticle.value = _articleIterator.current;
  }

  /**
   * Move the pointers for selectedArticle to point to the previous
   * DataSource.
   */
  void goToPreviousFeed() {
    var newFeed = _feedIterator.previous();
    int oldIndex = _articleIterator.currentIndex.value;

    _articleIterator = new BiIterator<Article>(
        newFeed.articles, _articleIterator.currentIndex.listeners);
    _articleIterator.currentIndex.value = oldIndex;
    selectedArticle.value = _articleIterator.current;
  }

  /**
   * Move to the next section (page) of feeds in the UI.
   * @param index the previous index (how far down in a given feed)
   * from the Source we are moving from.
   * This method takes sliderMenu in the event that it needs to move
   * to a previous section, it can notify the UI to update.
   */
  void goToNextSection(SliderMenu sliderMenu) {
    //TODO(efortuna): move sections?
    var oldSection = currentSection;
    int oldIndex = _articleIterator.currentIndex.value;
    sliderMenu.selectNext(true);
    // This check prevents our selector from wrapping around when we try to
    // go to the "next section", but we're already at the last section.
    if (oldSection != _sectionIterator.current) {
      _feedIterator = new BiIterator<Feed>(
          _sectionIterator.current.feeds, _feedIterator.currentIndex.listeners);
      _articleIterator = new BiIterator<Article>(_feedIterator.current.articles,
          _articleIterator.currentIndex.listeners);
      _articleIterator.currentIndex.value = oldIndex;
      selectedArticle.value = _articleIterator.current;
    }
  }

  /**
   * Move to the previous section (page) of feeds in the UI.
   * @param index the previous index (how far down in a given feed)
   * from the Source we are moving from.
   * @param oldSection the original starting section (before the slider
   * menu moved)
   * This method takes sliderMenu in the event that it needs to move
   * to a previous section, it can notify the UI to update.
   */
  void goToPreviousSection(SliderMenu sliderMenu) {
    //TODO(efortuna): don't pass sliderMenu here. Just update in view!
    var oldSection = currentSection;
    int oldIndex = _articleIterator.currentIndex.value;
    sliderMenu.selectPrevious(true);

    // This check prevents our selector from wrapping around when we try to
    // go to the "previous section", but we're already at the first section.
    if (oldSection != _sectionIterator.current) {
      _feedIterator = new BiIterator<Feed>(
          _sectionIterator.current.feeds, _feedIterator.currentIndex.listeners);
      // Jump to back of feed set if we are moving backwards through sections.
      _feedIterator.currentIndex.value = _feedIterator.list.length - 1;
      _articleIterator = new BiIterator<Article>(_feedIterator.current.articles,
          _articleIterator.currentIndex.listeners);
      _articleIterator.currentIndex.value = oldIndex;
      selectedArticle.value = _articleIterator.current;
    }
  }

  /**
   * Set the selected story as the current story (for viewing in the larger
   * Story View.)
   */
  void selectStoryAsCurrent() {
    currentArticle.value = _articleIterator.current;
    selectedArticle.value = _articleIterator.current;
  }

  /**
   * Remove our currentArticle selection, to move back to the Main Grid view.
   */
  void clearCurrentArticle() {
    currentArticle.value = null;
  }

  /**
   * Set the selectedArticle as the first item in that section (UI page).
   */
  void goToFirstArticleInSection() {
    selectedArticle.value = _articleIterator.current;
  }

  /**
   * Returns true if the UI is currently in the Story View state.
   */
  bool get inMainView => currentArticle.value == null;

  /**
   * Returns true if we currently have an Article selected (for keyboard
   * shortcuts browsing).
   */
  bool get hasArticleSelected => selectedArticle.value != null;

  /**
   * Mark the current article as read
   */
  bool markCurrentAsRead() {
    currentArticle.value.unread.value = false;
  }

  /**
   * The user has moved to a new section (page). This can occur either
   * if the user clicked on a section page, or used keyboard shortcuts.
   * The default behavior is to move to the first article in the first
   * column. The location of the selected item depends on the previous
   * selected item location if the user used keyboard shortcuts. These
   * are manipulated in goToPrevious/NextSection().
   */
  void moveToNewSection(String sectionTitle) {
    _sectionIterator.currentIndex.value =
        _dataModel.findSectionIndex(sectionTitle);
    _feedIterator = new BiIterator<Feed>(
        _sectionIterator.current.feeds, _feedIterator.currentIndex.listeners);
    _articleIterator = new BiIterator<Article>(_feedIterator.current.articles,
        _articleIterator.currentIndex.listeners);
  }

  Section get currentSection => _sectionIterator.current;
  Feed get currentFeed => _feedIterator.current;
}
