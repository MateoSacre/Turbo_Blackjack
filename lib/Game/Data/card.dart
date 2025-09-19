class Card {
  final int value;
  final Color color;

  Card(this.value, this.color);

  Map<String, dynamic> toJson() {
    return {'value': value, 'color': color.index};
  }

  static Card fromJson(Map<String, dynamic> json) {
    return Card(json['value'], Color.values[json['color']]);
  }

  getCardValue() {
    switch (value) {
      case 1:
        return "A";
      case 11:
        return "J";
      case 12:
        return "Q";
      case 13:
        return "K";
      default:
        return value.toString();
    }
  }

  int getTrueValue() {
    if (value > 10) {
      return 10;
    }
    return value;
  }

  int getCountValue() {
    if (value < 7) {
      return 1;
    }
    if (value > 9) {
      return -1;
    }
    return 0;
  }

  @override
  toString() {
    return "${getCardValue()}${color.symbol}";
  }
}

enum Color {
  heart,
  diamond,
  spade,
  clubs;

  String get symbol {
    switch (this) {
      case Color.heart:
        return '♥';
      case Color.diamond:
        return '♦';
      case Color.spade:
        return '♠';
      case Color.clubs:
        return '♣';
    }
  }
}
