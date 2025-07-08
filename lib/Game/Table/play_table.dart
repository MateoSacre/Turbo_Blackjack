import 'package:flutter/material.dart';
import 'package:turbo_blackjack/Game/Logic/deck_logic.dart';

class PlayTable extends StatefulWidget {
  const PlayTable({super.key});

  @override
  PlayTableState createState() => PlayTableState();
}

class PlayTableState extends State<PlayTable> {
  PlayTableState() {
    Decklogic.resetDeck();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
