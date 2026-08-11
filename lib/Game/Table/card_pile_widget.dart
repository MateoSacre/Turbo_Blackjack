import 'package:flutter/material.dart';

import '../../Settings/settings_global_values.dart';

// A top-down view of a pile: small card silhouettes staggered diagonally,
// like looking straight down at a stack. More cards means more (and more
// widely spread) layers, giving a rough at-a-glance sense of how full the
// pile is - deliberately not an exact count, so it reads as a table
// fixture rather than a counting aid that does the counting for you.
class CardPileWidget extends StatelessWidget {
  static const double aspectRatio = 0.68; // width / height, matches a card face
  static const int maxLayers = 54;
  static const double stepFraction = 0.01; // per-layer offset, as a fraction of cardWidth

  final int count;
  final int maxCount;
  final String label;
  final double cardWidth;

  const CardPileWidget({
    super.key,
    required this.count,
    required this.maxCount,
    required this.label,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    final double cardHeight = cardWidth / aspectRatio;
    final double step = cardWidth * stepFraction;
    final double fraction =
        maxCount <= 0 ? 0.0 : (count / maxCount).clamp(0.0, 1.0);
    final int layers =
        count <= 0 ? 0 : (1 + (fraction * (maxLayers - 1)).round());

    // Layers only offset vertically (bottom:), so the box only needs to be
    // as wide as a single card - reserving horizontal room here left the
    // (left-pinned) stack sitting in a sliver of a wider, empty box.
    final double footprintWidth = cardWidth;
    final double footprintHeight = cardHeight + step * (maxLayers - 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                color: SettingsGlobalValues.neutralColor.withValues(alpha: .8),
                fontSize: SettingsGlobalValues.getFontSize(context) * 0.6)),
        const SizedBox(height: 4),
        SizedBox(
          width: footprintWidth,
          height: footprintHeight,
          child: layers <= 0
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: _emptyOutline(cardWidth, cardHeight),
                )
              : Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    for (int i = 0; i < layers; i++)
                      Positioned(
                        bottom: step * i,
                        child: _cardLayer(cardWidth, cardHeight),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _emptyOutline(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.14),
        border: Border.all(
            color: SettingsGlobalValues.neutralColor.withValues(alpha: .3)),
      ),
    );
  }

  Widget _cardLayer(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: SettingsGlobalValues.activeColor,
        borderRadius: BorderRadius.circular(width * 0.14),
        border: Border.all(color: SettingsGlobalValues.goldColor, width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x40000000), blurRadius: 2, offset: Offset(1, 1)),
        ],
      ),
    );
  }
}
