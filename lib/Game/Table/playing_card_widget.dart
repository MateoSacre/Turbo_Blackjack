import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../Settings/settings_global_values.dart';
import '../Data/card.dart' as card_model;

// Small vector-drawn playing card (rank + suit in opposite corners, big
// suit glyph centered) used to render a hand as a fan of real cards
// instead of a plain "A♥ 10♠" text string. Can also render a face-down
// back (see [faceDown]) for cards that must stay hidden from the player.
class PlayingCardWidget extends StatelessWidget {
  static const double aspectRatio = 0.68; // width / height

  final card_model.Card card;
  final double width;
  final double height;
  final bool faceDown;

  const PlayingCardWidget({
    super.key,
    required this.card,
    required this.width,
    required this.height,
    this.faceDown = false,
  });

  @override
  Widget build(BuildContext context) {
    if (faceDown) {
      return _buildBack();
    }

    final bool isRed = card.color == card_model.Color.heart ||
        card.color == card_model.Color.diamond;
    final Color suitColor =
        isRed ? const Color(0xFFD2222D) : const Color(0xFF1A1A1A);
    final String rank = card.getCardValue();
    final String symbol = card.color.symbol;
    final double cornerFontSize = math.max(height * 0.22, 8.0);
    final double centerFontSize = math.max(height * 0.4, 12.0);

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.14),
        border: Border.all(color: const Color(0xFFC9C9C9), width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x40000000), blurRadius: 3, offset: Offset(1, 2)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: width * 0.08,
            top: height * 0.04,
            child: _corner(rank, symbol, suitColor, cornerFontSize),
          ),
          Center(
            child: Text(
              symbol,
              style: TextStyle(
                  color: suitColor, fontSize: centerFontSize, height: 1),
            ),
          ),
          Positioned(
            right: width * 0.08,
            bottom: height * 0.04,
            child: Transform.rotate(
              angle: math.pi,
              child: _corner(rank, symbol, suitColor, cornerFontSize),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: SettingsGlobalValues.activeColor,
        borderRadius: BorderRadius.circular(width * 0.14),
        border: Border.all(color: SettingsGlobalValues.goldColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x40000000), blurRadius: 3, offset: Offset(1, 2)),
        ],
      ),
      child: Center(
        child: Container(
          width: width * 0.6,
          height: height * 0.6,
          decoration: BoxDecoration(
            border:
                Border.all(color: SettingsGlobalValues.goldColor, width: 1),
            borderRadius: BorderRadius.circular(width * 0.08),
          ),
          child: Center(
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: width * 0.26,
                height: width * 0.26,
                decoration: BoxDecoration(
                  color: SettingsGlobalValues.goldColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _corner(String rank, String symbol, Color color, double fontSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(rank,
            style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                height: 1)),
        Text(symbol,
            style: TextStyle(color: color, fontSize: fontSize * 0.75, height: 1)),
      ],
    );
  }
}
