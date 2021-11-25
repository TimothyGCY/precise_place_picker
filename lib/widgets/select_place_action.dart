import 'package:flutter/material.dart';

class SelectPlaceAction extends StatelessWidget {
  const SelectPlaceAction(
      this.locationName, this.tapToSelectActionText, this.onTap,
      {Key? key})
      : super(key: key);

  final String locationName;
  final String tapToSelectActionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(locationName, style: const TextStyle(fontSize: 16)),
                  Text(tapToSelectActionText,
                      style: const TextStyle(color: Colors.grey, fontSize: 15)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward)
          ],
        ),
      ),
    );
  }
}
