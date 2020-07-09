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
  }) : assert(debounceDuration != null);

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
          controller: _controller,
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

class AutocompleteController<T> {
  /// Create an instance of AutocompleteController.
  AutocompleteController({
    TextEditingController textEditingController,
    List<T> results,
  }) : this.textEditingController = textEditingController ?? TextEditingController(),
       this.results = <T>[];

  final TextEditingController textEditingController;
  final List<T> results;
}
