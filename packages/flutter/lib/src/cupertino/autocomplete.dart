// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/widgets.dart';

import 'text_field.dart';

class AutocompleteDividedCupertino<T> extends StatelessWidget {
  const AutocompleteDividedCupertino({
    @required this.autocompleteController,
    this.buildField,
    this.buildResults,
  }) : assert(autocompleteController != null);

  final AutocompleteController<T> autocompleteController;
  final ResultsBuilder<T> buildResults;
  final FieldBuilder buildField;

  static Widget _buildField<T>(BuildContext context, TextEditingController controller) {
    return AutocompleteDividedCupertinoField<T>(
      controller: controller,
    );
  }

  static Widget _buildResults<T>(BuildContext context, List<T> results, OnSelected<T> onSelected) {
    return AutocompleteDividedCupertinoResults<T>(
      onSelected: onSelected,
      results: results,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AutocompleteDivided<T>(
      autocompleteController: autocompleteController,
      buildField: buildField ?? _buildField,
      buildResults: buildResults ?? _buildResults,
    );
  }
}

class AutocompleteDividedCupertinoField<T> extends StatelessWidget {
  AutocompleteDividedCupertinoField({
    Key key,
    this.controller,
  }) : super(key: key);

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
    );
  }
}

class AutocompleteDividedCupertinoResults<T> extends StatelessWidget {
  AutocompleteDividedCupertinoResults({
    Key key,
    @required this.onSelected,
    @required this.results,
  }) : assert(onSelected != null),
       assert(results != null),
       super(key: key);

  final List<T> results;
  final OnSelected<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        children: results.map((T result) => GestureDetector(
          onTap: () {
            onSelected(result);
          },
          // TODO(justinmc): This is really ugly.
          child: Container(
            child: Text(result.toString()),
          ),
        )).toList(),
      ),
    );
  }
}
