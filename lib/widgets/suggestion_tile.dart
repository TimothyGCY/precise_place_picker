import 'package:flutter/material.dart';
import 'package:precise_place_picker/models/auto_complete_item.dart';

class SuggestionTile extends StatelessWidget {
  const SuggestionTile(this.tileItem, this.onTap, {Key? key}) : super(key: key);

  final VoidCallback onTap;
  final AutoCompleteItem tileItem;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: RichText(text: TextSpan(children: getStyledText(context))),
      ),
    );
  }

  List<TextSpan> getStyledText(BuildContext context) {
    final List<TextSpan> result = [];
    const style = TextStyle(color: Colors.grey, fontSize: 15);

    final startText = tileItem.text!.substring(0, tileItem.offset);
    if (startText.isNotEmpty) {
      result.add(TextSpan(text: startText, style: style));
    }

    final boldText = tileItem.text!
        .substring(tileItem.offset!, tileItem.offset! + tileItem.length!);
    result.add(
      TextSpan(
          text: boldText,
          style: style.copyWith(
              color: Theme.of(context).textTheme.bodyText1!.color)),
    );

    final remainingText =
        tileItem.text!.substring(tileItem.offset! + tileItem.length!);
    result.add(TextSpan(text: remainingText, style: style));

    return result;
  }
}
