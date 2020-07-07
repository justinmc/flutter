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
  Autocomplete({
    this.getItems,
  });

  final ItemsGetter<T> getItems;

  @override
  _AutocompleteState<T> createState() => _AutocompleteState<T>();
}

class _AutocompleteState<T> extends State<Autocomplete<T>> {
  final TextEditingController _controller = TextEditingController();
  List<T> _items = <T>[];
  bool _loading = false;

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
          decoration: InputDecoration(
            hintText: 'Search here!',
          ),
          onChanged: (String value) {
            setState(() {
              _loading = true;
            });
            // TODO(justinmc): For example, debouncing should be done by
            // default, but the user should be able to disable it, do their own
            // debouncing, etc.  Ideally this wouldn't be done with lots of
            // different config parameters.
            Debounce(
              duration: const Duration(seconds: 1),
              callback: () async {
                // TODO(justinmc): Error handling.
                final List<T> items = await widget.getItems(value);
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
                    subtitle: Text('\$${item.toString()}'),
                  ),
                )).toList(),
          ),
        ),
      ],
    );
  }
}
