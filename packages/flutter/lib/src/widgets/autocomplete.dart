// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'editable_text.dart';
import 'framework.dart';

// 1. Take a TextEditingController.
// 2. When textEditingController changes value, search.
// 3. User can provide their own search method, sync or async.
typedef List<T> SearchFunction<T>(String query);

// TODO(justinmc): Rename if we keep this?
typedef void OnSelected<T>(T result);

typedef Widget ResultsBuilder<T>(
  BuildContext context,
  List<T> results,
  OnSelected<T> onSelected,
);

typedef Widget FieldBuilder(
  BuildContext context,
  TextEditingController textEditingController,
);

class AutocompleteController<T> {
  /// Create an instance of AutocompleteController.
  AutocompleteController({
    this.options,
    this.search,
    // TODO(justinmc): Is it possible to make this a string valuenotifier? That
    // would enable the support of querying using something other than a text
    // field. Maybe that's not a common scenario though.
    TextEditingController textEditingController,
  }) : assert(search != null || options != null, "If a search function isn't specified, Autocomplete will search by string on the given options."),
       textEditingController = textEditingController ?? TextEditingController() {
    this.textEditingController.addListener(_onQueryChanged);
  }

  final List<T> options;
  final TextEditingController textEditingController;
  final SearchFunction<T> search;
  final ValueNotifier<List<T>> results = ValueNotifier<List<T>>(<T>[]);

  // Called when textEditingController reports a change in its value.
  void _onQueryChanged() {
    final List<T> resultsValue = search == null
        ? _searchByString(textEditingController.value.text)
        : search(textEditingController.value.text);
    assert(resultsValue != null);
    results.value = resultsValue;
  }

  // The default search function, if one wasn't supplied.
  List<T> _searchByString(String query) {
    return options
        .where((T option) => option.toString().contains(query))
        .toList();
  }

  void dispose() {
    textEditingController.removeListener(_onQueryChanged);
    textEditingController.dispose();
  }
}

class AutocompleteDivided<T> extends StatefulWidget {
  AutocompleteDivided({
    @required this.autocompleteController,
    @required this.buildField,
    @required this.buildResults,
  }) : assert(autocompleteController != null),
       assert(buildField != null),
       assert(buildResults != null);

  final AutocompleteController<T> autocompleteController;
  final FieldBuilder buildField;
  final ResultsBuilder<T> buildResults;

  @override
  AutocompleteDividedState<T> createState() =>
      AutocompleteDividedState<T>();
}

class AutocompleteDividedState<T> extends State<AutocompleteDivided<T>> {
  T _selection;

  void _onChangeResults() {
    setState(() {});
  }

  void _onChangeQuery() {
    if (widget.autocompleteController.textEditingController.value.text == _selection) {
      return;
    }
    setState(() {
      _selection = null;
    });
  }

  void onSelected (T result) {
    setState(() {
      _selection = result;
      widget.autocompleteController.textEditingController.text = result.toString();
    });
  }

  void _listenToController(AutocompleteController<T> autocompleteController) {
    autocompleteController.results.addListener(_onChangeResults);
    autocompleteController.textEditingController.addListener(_onChangeQuery);
  }

  void _unlistenToController(AutocompleteController<T> autocompleteController) {
    autocompleteController.results.removeListener(_onChangeResults);
    autocompleteController.textEditingController.removeListener(_onChangeQuery);
  }

  @override
  void initState() {
    super.initState();
    _listenToController(widget.autocompleteController);
  }

  @override
  void didUpdateWidget(AutocompleteDivided<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autocompleteController != oldWidget.autocompleteController) {
      _unlistenToController(oldWidget.autocompleteController);
      _listenToController(widget.autocompleteController);
    }
  }

  @override
  void dispose() {
    _unlistenToController(widget.autocompleteController);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        widget.buildField(
          context,
          widget.autocompleteController.textEditingController,
        ),
        widget.buildResults(
          context,
          widget.autocompleteController.results.value,
          onSelected,
        ),
      ],
    );
  }
}
