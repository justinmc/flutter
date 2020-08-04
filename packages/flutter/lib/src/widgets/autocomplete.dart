// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'container.dart';
import 'editable_text.dart';
import 'framework.dart';

typedef FutureOr<List<T>> SearchFunction<T>(String query);

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
  void _onQueryChanged() async {
    // TODO(justinmc): Probably also need a value to indicate that we're loading
    // when search is async. Maybe a value notifier.
    final List<T> resultsValue = search == null
        ? _searchByString(textEditingController.value.text)
        : await search(textEditingController.value.text);
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

  // TODO(justinmc): Should be in core.
  AutocompleteDivided.floatingResults({
    @required this.autocompleteController,
    @required this.buildField,
    @required ResultsBuilder<T> buildResults,
  }) : assert(autocompleteController != null),
       assert(buildField != null),
       assert(buildResults != null),
       buildResults = floatBuildResults<T>(buildResults);

  final AutocompleteController<T> autocompleteController;
  final FieldBuilder buildField;
  final ResultsBuilder<T> buildResults;

  // TODO(justinmc): Is this the best way of doing this?
  static ResultsBuilder<T> floatBuildResults<T>(ResultsBuilder<T> buildResults) {
    return (BuildContext context, List<T> results, OnSelected<T> onSelected) =>
      _AutocompleteResultsFloatingWrapper<T>(
        child: buildResults(context, results, onSelected),
      );
  }

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
        if (_selection == null)
          // TODO(justinmc): should this expanded be here?
          Expanded(
            child: widget.buildResults(
              context,
              widget.autocompleteController.results.value,
              onSelected,
            ),
          ),
      ],
    );
  }
}

class _AutocompleteResultsFloatingWrapper<T> extends StatelessWidget {
  const _AutocompleteResultsFloatingWrapper({
    Key key,
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO(justinmc): Not really floating.
    return Container(
      color: Color(0xffabcdef),
      width: 200.0,
      padding: EdgeInsets.all(12.0),
      child: child,
    );
  }
}
