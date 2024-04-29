import 'dart:convert';
import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:games_counter/member_model.dart';
import 'package:games_counter/participatns_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddWithHistoryPlayerPage extends StatefulWidget {
  const AddWithHistoryPlayerPage({super.key});

  static const keyPlayersHistory = "player-history";

  @override
  State<AddWithHistoryPlayerPage> createState() =>
      AddWith_HistoryPlayerPageState();
}

class AddWith_HistoryPlayerPageState extends State<AddWithHistoryPlayerPage> {
  final newPlayers = <PlayerModel>[];
  final playershistory = <PlayerModel>[];

  static const keyPlayersHistory = AddWithHistoryPlayerPage.keyPlayersHistory;

  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final playershistory = await getHistoryPlayers();

      setState(() {
        this.playershistory.addAll(playershistory);
      });
    });
  }

  Future<List<PlayerModel>> getHistoryPlayers() async {
    final pref = await SharedPreferences.getInstance();
    final jsonGame = pref.getString(keyPlayersHistory) ?? "";
    if (jsonGame.isNotEmpty) {
      final model = jsonDecode(jsonGame) as List;
      if (model.isEmpty) return [];

      final res =
          model.map((e) => PlayerModel.fromJson(e)).toList().reversed.toList();
      return res;
    } else {
      return [];
    }
  }

  Future<void> onAddMember(PlayerModel player) async {
    final newPlayer = player.copyWith(id: "player${Random().nextInt(10000)}");
    setState(() {
      newPlayers.add(newPlayer);
      playershistory.add(newPlayer);
    });
    await setToHistory(newPlayer);
  }

  Future<void> setToHistory(PlayerModel player) async {
    final historyPlayers = await getHistoryPlayers();

    historyPlayers.add(player);

    final pref = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(historyPlayers.map((e) => e.toJson()).toList());

    await pref.setString(keyPlayersHistory, jsonData);
  }

  void onAddMemberFromHistory(PlayerModel player) {
    final exists =
        newPlayers.where((element) => element.id == player.id).isNotEmpty;
    if (exists) return;

    setState(() {
      newPlayers.add(player);
    });
  }

  void onRemoveNewPlayers(String playerId) {
    newPlayers.removeWhere((element) => element.id == playerId);
    setState(() {});
  }

  Future<void> startTheGame() async {
    final pref = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(newPlayers.map((e) => e.toJson()).toList());
    await pref.remove(PlayersListPage.keyPlayerGames);
    await pref.setString(PlayersListPage.keyPlayerGames, jsonData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Add new player"),
        actions: [
          TextButton(
            onPressed: () {
              addPlayerDialog(context, onAdd: onAddMember);
            },
            child: Text("New"),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (newPlayers.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Wrap(
                children: List.generate(
                  newPlayers.length,
                  (index) {
                    final player = newPlayers[index];
                    return Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      margin: EdgeInsets.only(right: 5, top: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Color(
                          (math.Random().nextDouble() * 0xf232DD23).toInt(),
                        ).withOpacity(1.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            player.name,
                            style: textTheme.bodyLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          IconButton(
                            onPressed: () {
                              onRemoveNewPlayers(player.id);
                            },
                            icon: Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 10,
            ),
            child: Text(
              "History player",
              style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: playershistory.length,
              itemBuilder: (context, index) {
                final player = playershistory[index];
                return InkWell(
                  onTap: () {
                    onAddMemberFromHistory(player);
                  },
                  child: ListTile(
                    title: Text(
                      player.name,
                      style: textTheme.bodyMedium?.copyWith(),
                    ),
                    trailing: Container(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Text("Add"),
                          Icon(
                            Icons.add,
                            color: Colors.pinkAccent.shade100,
                            size: 25,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: newPlayers.isNotEmpty
          ? ElevatedButton(
              onPressed: () {
                startTheGame();
              },
              child: Text(
                "Start game",
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
