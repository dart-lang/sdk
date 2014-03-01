timing_test(function() {
  at(0, function() {
    assert_styles(".anim", [
      {'transform':'none'},
      {'transform':'matrix(0.5, 0, 0, 0.5, 0, 0)'},
      {'transform':'matrix(0.7071, 0.7071, -0.7071, 0.7071, 0, 0)'},
      {'transform':'matrix(0.7071, 0.7071, -0.7071, 0.7071, 70.7107, 70.7107)'},
      {'transform':'matrix(1.4142, 1.4142, -1.4142, 1.4142, 141.4214, 141.4214)'},
    ]);
  });
  at(0.4, function() {
    assert_styles(".anim", [
      {'transform':'matrix(1, 0, 0, 1, 20, 0)'},
      {'transform':'matrix(0.6, 0, 0, 0.6, 20, 0)'},
      {'transform':'matrix(0.809, 0.5878, -0.5878, 0.809, 20, 0)'},
      {'transform':'matrix(0.7071, 0.7071, -0.7071, 0.7071, 76.5685, 56.5685)'},
      {'transform':'matrix(1.3023, 1.0927, -1.0927, 1.3023, 133.1371, 113.1371)'},
    ]);
  });
  at(0.8, function() {
    assert_styles(".anim", [
      {'transform':'matrix(1, 0, 0, 1, 40, 0)'},
      {'transform':'matrix(0.7, 0, 0, 0.7, 40, 0)'},
      {'transform':'matrix(0.891, 0.454, -0.454, 0.891, 40, 0)'},
      {'transform':'matrix(0.7071, 0.7071, -0.7071, 0.7071, 82.4264, 42.4264)'},
      {'transform':'matrix(1.1468, 0.803, -0.803, 1.1468, 124.8528, 84.8528)'},
    ]);
  });
  at(1.2000000000000002, function() {
    assert_styles(".anim", [
      {'transform':'matrix(1, 0, 0, 1, 60, 0)'},
      {'transform':'matrix(0.8, 0, 0, 0.8, 60, 0)'},
      {'transform':'matrix(0.9511, 0.309, -0.309, 0.9511, 60, 0)'},
      {'transform':'matrix(0.7071, 0.7071, -0.7071, 0.7071, 88.2843, 28.2843)'},
      {'transform':'matrix(0.9526, 0.55, -0.55, 0.9526, 116.5685, 56.5685)'},
    ]);
  });
  at(1.6, function() {
    assert_styles(".anim", [
      {'transform':'matrix(1, 0, 0, 1, 80, 0)'},
      {'transform':'matrix(0.9, 0, 0, 0.9, 80, 0)'},
      {'transform':'matrix(0.9877, 0.1564, -0.1564, 0.9877, 80, 0)'},
      {'transform':'matrix(0.7071, 0.7071, -0.7071, 0.7071, 94.1421, 14.1421)'},
      {'transform':'matrix(0.725, 0.3381, -0.3381, 0.725, 108.2843, 28.2843)'},
    ]);
  });
  at(2, function() {
    assert_styles(".anim", [
      {'transform':'matrix(1, 0, 0, 1, 100, 0)'},
      {'transform':'matrix(1, 0, 0, 1, 100, 0)'},
      {'transform':'matrix(1, 0, 0, 1, 100, 0)'},
      {'transform':'matrix(0.7071067811865476, 0.7071067811865475, -0.7071067811865475, 0.7071067811865476, 100, 0)'},
      {'transform':'matrix(0.4698463103929542, 0.17101007166283436, -0.17101007166283436, 0.4698463103929542, 100, 0)'},
    ]);
  });
}, "Auto generated tests");
