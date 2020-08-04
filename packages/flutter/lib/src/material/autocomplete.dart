// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'input_decorator.dart';
import 'list_tile.dart';
import 'text_form_field.dart';

// TODO(justinmc): A real debounce class should maybe operate on a per-callback
// basis.
class Debounce {
  Debounce({
    VoidCallback callback,
    Duration duration,
  }) : assert(callback != null),
       assert(duration != null) {
    if (timer != null) {
      timer.cancel();
    }
    timer = Timer(duration, () {
      timer.cancel();
      callback();
    });
  }

  static Timer timer;

  static void dispose() {
    if (timer != null) {
      timer.cancel();
      timer = null;
    }
  }
}

// TODO(justinmc): Should be FutureOr for synchronous support.
typedef Future<List<T>> ItemsGetter<T>(String query);

// TODO(justinmc): By default, do things like debouncing, displaying everything
// nicely, etc. BUT allow any of it to be replaced by the user.
// TODO(justinmc): Check all parameters taken by flutter_typeahead and see if
// they might be useful to add here.
// TODO(justinmc): Make sure this could actually be used as a simple form field
// in a larger form.
/// A widget that allows the selection of an item based on an optional typed
/// query.
class Autocomplete<T> extends StatefulWidget {
  /// Create an instance of Autocomplete.
  const Autocomplete({
    // TODO(justinmc): Do I really want this parameter? What about throttling?
    // What if the user wants to do this themselves?
    this.debounceDuration = Duration.zero,
    this.onSearch,
    this.items,
    this.autocompleteController,
  }) : assert(debounceDuration != null);

  final AutocompleteController autocompleteController;

  final Duration debounceDuration;

  final ItemsGetter<T> onSearch;

  /// A static list of options.
  final List<T> items;

  @override
  _AutocompleteState<T> createState() => _AutocompleteState<T>();
}

class _AutocompleteState<T> extends State<Autocomplete<T>> {
  final TextEditingController _controller = TextEditingController();
  List<T> _items = <T>[];
  bool _loading = false;

  // TODO(justinmc): Dynamic, or not static and use T?
  static List<dynamic> search(List<dynamic> items, String query) {
    return items.where((dynamic item) {
      return item.toString().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    Debounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextFormField(
          controller: widget.autocompleteController.textEditingController,
          decoration: const InputDecoration(
            hintText: 'Search here!',
          ),
          onChanged: (String value) {
            if (widget.items == null) {
              setState(() {
                _loading = true;
              });
            }
            // TODO(justinmc): Could this speed up by calling at leading edge?
            Debounce(
              duration: widget.debounceDuration,
              callback: () async {
                if (widget.items != null) {
                  setState(() {
                    _items = search(widget.items, value) as List<T>;
                  });
                  return;
                }

                // TODO(justinmc): Error handling.
                // TODO(justinmc): It shouldn't be possible to have multiple
                // searches happening at the same time. Autocomplete's
                // responsibility or not?
                final List<T> items = await widget.onSearch(value);
                if (mounted) {
                  setState(() {
                    _loading = false;
                    _items = items;
                  });
                }
              },
            );
          },
        ),
        Expanded(
          child: ListView(
            children: _loading
                ? <Widget>[const Text('Loading!')]
                : _items.map((T item) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _items = <T>[];
                      // TODO(justinmc): Builder.
                      _controller.text = item.toString();
                    });
                  },
                  child: ListTile(
                    title: Text(item.toString()),
                  ),
                )).toList(),
          ),
        ),
      ],
    );
  }
}

/*
   What if it's actually a class with several notifiers?
class AutocompleteController extends ValueNotifier<String> {
  /// Create an instance of AutocompleteController whose initial value is the
  /// given String.
  AutocompleteController([String value]) : super(value);
}
*/

// The simplest Autocomplete.
class AutocompleteBasicOwnController<T> extends StatefulWidget {
  AutocompleteBasicOwnController({
    Key key,
    this.options,
  }) : super(key: key);

  final List<T> options;

  @override
  AutocompleteBasicOwnControllerState<T> createState() => AutocompleteBasicOwnControllerState<T>();
}

class AutocompleteBasicOwnControllerState<T> extends State<AutocompleteBasicOwnController<T>> {
  AutocompleteController _autocompleteController;
  List<T> _results = <T>[];
  T _selection;

  void _onChangeResults() {
    setState(() {});
  }

  void _onChangeQuery() {
    if (_autocompleteController.textEditingController.value.text != _selection) {
      setState(() {
        _selection = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _autocompleteController = AutocompleteController<T>(
      options: widget.options,
      textEditingController: TextEditingController(),
    );
    _autocompleteController.textEditingController.addListener(_onChangeQuery);
    _autocompleteController.results.addListener(_onChangeResults);
  }

  @override
  void dispose() {
    _autocompleteController.textEditingController.removeListener(_onChangeQuery);
    _autocompleteController.results.removeListener(_onChangeResults);
    _autocompleteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Query field.
        TextFormField(
          controller: _autocompleteController.textEditingController,
        ),
        // Results list.
        if (_selection == null)
          Expanded(
            child: ListView(
              children: _results.map((T result) => GestureDetector(
                onTap: () {
                  setState(() {
                    _selection = result;
                    _autocompleteController.textEditingController.text = result.toString();
                  });
                },
                child: ListTile(
                  title: Text(result.toString()),
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }
}

/*
class AutocompleteFullyCustomizable<T> extends StatefulWidget {
  AutocompleteFullyCustomizable({
    @required this.autocompleteController,
    this.buildField,
    this.buildResults,
  }) : assert(autocompleteController != null);

  AutocompleteFullyCustomizable.floatingResults({
    @required this.autocompleteController,
    this.buildField,
  }) : assert(autocompleteController != null),
       buildResults = _buildFloatingResults;

  AutocompleteFullyCustomizable.cupertino({
    @required this.autocompleteController,
    this.buildResults,
  }) : assert(autocompleteController != null),
       buildField = _buildCupertinoField;

  final AutocompleteController<T> autocompleteController;
  final _FieldBuilder buildField;
  final _ResultsBuilder<T> buildResults;

  static Widget _buildFloatingResults<T>(
    BuildContext context,
    List<T> results,
    OnSelected onSelected,
  ) {
    return _AutocompleteResultsFloating<T>(
      onSelected: onSelected,
      results: results,
    );
  }

  static Widget _buildCupertinoField<T>(BuildContext context, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        hintText: 'Pretend this is Cupertino',
      ),
    );
  }

  @override
  AutocompleteFullyCustomizableState<T> createState() =>
      AutocompleteFullyCustomizableState<T>();
}

class AutocompleteFullyCustomizableState<T> extends State<AutocompleteFullyCustomizable<T>> {
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
  void didUpdateWidget(AutocompleteFullyCustomizable<T> oldWidget) {
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
        // Query field.
        if (widget.buildField == null)
          _AutocompleteField(
            controller: widget.autocompleteController.textEditingController,
          ),
        if (widget.buildField != null)
          widget.buildField(context, widget.autocompleteController.textEditingController),
        // Results list.
        if (_selection == null)
          Expanded(
            child: widget.buildResults == null
              ? _AutocompleteResults<T>(
                onSelected: onSelected,
                results: widget.autocompleteController.results.value,
              )
            : widget.buildResults(
                context,
                widget.autocompleteController.results.value,
                onSelected,
              ),
          ),
      ],
    );
  }
}
*/

class AutocompleteDividedMaterial<T> extends StatefulWidget {
  AutocompleteDividedMaterial({
    @required this.autocompleteController,
    this.buildField,
    this.buildResults,
  }) : assert(autocompleteController != null);

  AutocompleteDividedMaterial.floatingResults({
    @required this.autocompleteController,
    this.buildField,
  }) : assert(autocompleteController != null),
       buildResults = _buildFloatingResults;

  AutocompleteDividedMaterial.cupertino({
    @required this.autocompleteController,
    this.buildResults,
  }) : assert(autocompleteController != null),
       buildField = _buildCupertinoField;

  final AutocompleteController<T> autocompleteController;
  final FieldBuilder buildField;
  final ResultsBuilder<T> buildResults;

  static Widget _buildFloatingResults<T>(
    BuildContext context,
    List<T> results,
    OnSelected<T> onSelected,
  ) {
    return _AutocompleteResultsFloating<T>(
      onSelected: onSelected,
      results: results,
    );
  }

  static Widget _buildCupertinoField<T>(BuildContext context, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        hintText: 'Pretend this is Cupertino',
      ),
    );
  }

  @override
  AutocompleteDividedMaterialState<T> createState() =>
      AutocompleteDividedMaterialState<T>();
}

class AutocompleteDividedMaterialState<T> extends State<AutocompleteDividedMaterial<T>> {
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

  void _listenToController(AutocompleteController<T> autocompleteController) {
    autocompleteController.results.addListener(_onChangeResults);
    autocompleteController.textEditingController.addListener(_onChangeQuery);
  }

  void _unlistenToController(AutocompleteController<T> autocompleteController) {
    autocompleteController.results.removeListener(_onChangeResults);
    autocompleteController.textEditingController.removeListener(_onChangeQuery);
  }

  void onSelected (T result) {
    setState(() {
      _selection = result;
      widget.autocompleteController.textEditingController.text = result.toString();
    });
  }

  @override
  void initState() {
    super.initState();
    _listenToController(widget.autocompleteController);
  }

  @override
  void didUpdateWidget(AutocompleteDividedMaterial<T> oldWidget) {
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
        // Query field.
        if (widget.buildField == null)
          _AutocompleteField(
            controller: widget.autocompleteController.textEditingController,
          ),
        if (widget.buildField != null)
          widget.buildField(context, widget.autocompleteController.textEditingController),
        // Results list.
        if (_selection == null)
          Expanded(
            child: widget.buildResults == null
              ? _AutocompleteResults<T>(
                onSelected: onSelected,
                results: widget.autocompleteController.results.value,
              )
            : widget.buildResults(
                context,
                widget.autocompleteController.results.value,
                onSelected,
              ),
          ),
      ],
    );
  }
}

// The field in which the user enters the query.
class _AutocompleteField extends StatelessWidget {
  _AutocompleteField({
    @required this.controller,
    Key key,
  }) : assert(controller != null),
       super(key: key);

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
    );
  }
}

// The list of results to choose from.
class _AutocompleteResults<T> extends StatelessWidget {
  _AutocompleteResults({
    this.onSelected,
    this.results,
  });

  final List<T> results;
  final OnSelected<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: results.map((T result) => GestureDetector(
        onTap: () {
          onSelected(result);
        },
        child: ListTile(
          title: Text(result.toString()),
        ),
      )).toList(),
    );
  }
}

class _AutocompleteResultsFloating<T> extends StatelessWidget {
  _AutocompleteResultsFloating({
    this.onSelected,
    this.results,
  });

  final List<T> results;
  final OnSelected<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: results.map((T result) => GestureDetector(
        onTap: () {
          onSelected(result);
        },
        child: ListTile(
          title: Text(result.toString()),
          subtitle: const Text('We should be floating!'),
        ),
      )).toList(),
    );
  }
}
