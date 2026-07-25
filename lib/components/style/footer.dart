import 'package:flutter/material.dart';
import 'package:hotel_pos_system/components/linkify.dart';
import 'package:hotel_pos_system/components/meta_block.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: .center,
      crossAxisAlignment: .center,
      children: [
        TextButton(onPressed: _links[0].launch, child: Text(_links[0].text)),
        const Text(MetaBlock.string),
        TextButton(onPressed: _links[1].launch, child: Text(_links[1].text)),
      ],
    );
  }
}

const _links = <LinkifyData>[
  LinkifyData('Privacy Policy', 'https://yourname.github.io/hotel-pos-system/PRIVACY_POLICY/'),
  LinkifyData('License', 'https://yourname.github.io/hotel-pos-system/LICENSE/'),
];
