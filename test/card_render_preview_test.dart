import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turbo_blackjack/Game/Data/card.dart' as card_model;
import 'package:turbo_blackjack/Game/Table/playing_card_widget.dart';

void main() {
  testWidgets('render a fanned stack of cards to a png for visual review',
      (tester) async {
    final key = GlobalKey();

    final cards = [
      card_model.Card(1, card_model.Color.spade),
      card_model.Card(11, card_model.Color.heart),
      card_model.Card(5, card_model.Color.diamond),
      card_model.Card(13, card_model.Color.clubs),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF475B63),
        body: Center(
          child: RepaintBoundary(
            key: key,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF475B63),
              child: SizedBox(
                width: 200,
                height: 130,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (int i = 0; i < cards.length; i++)
                      Positioned(
                        left: i * 45.0,
                        top: 0,
                        child: PlayingCardWidget(
                          card: cards[i],
                          width: 70,
                          height: 100,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    final file = File(
        'C:/Users/mateoS/AppData/Local/Temp/claude/C--Users-mateoS-Documents-Dawn-turbo-blackjack/f8c0a3c6-bcf7-4263-89ad-0a8c217cceed/scratchpad/card_stack_preview.png');
    await file.writeAsBytes(pngBytes);
  });
}
