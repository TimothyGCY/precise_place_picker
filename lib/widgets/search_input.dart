import 'dart:async';

import 'package:flutter/material.dart';
import 'package:precise_place_picker/models/localization_item.dart';

class SearchInput extends StatefulWidget {
  final ValueChanged<String> onSearchInput;
  final LocalizationItem localizationItem;
  const SearchInput(this.onSearchInput, this.localizationItem, {Key? key})
      : super(key: key);

  @override
  SearchInputState createState() => SearchInputState();
}

class SearchInputState extends State<SearchInput> {
  TextEditingController editController = TextEditingController();

  Timer? debouncer;

  bool hasSearchEntry = false;

  SearchInputState();

  @override
  void initState() {
    super.initState();
    editController.addListener(onSearchInputChange);
  }

  @override
  void dispose() {
    editController.removeListener(onSearchInputChange);
    editController.dispose();

    super.dispose();
  }

  void onSearchInputChange() {
    if (editController.text.isEmpty) {
      debouncer?.cancel();
      widget.onSearchInput(editController.text);
      return;
    }

    if (debouncer?.isActive ?? false) {
      debouncer!.cancel();
    }

    debouncer = Timer(const Duration(milliseconds: 500), () {
      widget.onSearchInput(editController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: <Widget>[
          Icon(Icons.search,
              color: Theme.of(context).textTheme.bodyText1!.color),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                  hintText: widget.localizationItem.searchHint,
                  border: InputBorder.none),
              controller: editController,
              onChanged: (value) {
                setState(() {
                  hasSearchEntry = value.isNotEmpty;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          if (hasSearchEntry)
            GestureDetector(
              child: const Icon(Icons.clear),
              onTap: () {
                editController.clear();
                setState(() {
                  hasSearchEntry = false;
                });
              },
            ),
        ],
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).canvasColor,
      ),
    );
  }
}
