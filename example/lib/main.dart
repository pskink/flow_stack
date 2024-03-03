import 'dart:math';
import 'dart:ui';

import 'package:flow_stack/flow_stack.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

part 'overview.dart';
part 'delegates.dart';
part 'clock.dart';
part 'page_turn.dart';

final demos = [
  ('overview', '_FlowStackOverview()', _FlowStackOverview()),
  ('delegates', '_FlowStackDelegates()', _FlowStackDelegates()),
  ('clock', '_FlowStackClock()', _FlowStackClock()),
  ('page turn', '_FlowStackPageTurn()', _FlowStackPageTurn()),
];

main() {
  runApp(MaterialApp(
    scrollBehavior: const MaterialScrollBehavior().copyWith(
      dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
    ),
    theme: ThemeData.light(useMaterial3: false),
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return ListView(
            children: [
              for (final (title, subtitle, body) in demos)
                ListTile(
                  title: Text('[$title]'),
                  subtitle: Text(subtitle),
                  onTap: () {
                    final route = MaterialPageRoute(builder: (ctx) => Scaffold(
                      appBar: AppBar(),
                      body: body,
                    ));
                    Navigator.of(context).push(route);
                  },
                ),
            ],
          );
        },
      ),
    ),
  ));
}
