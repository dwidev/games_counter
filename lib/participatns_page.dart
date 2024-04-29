import 'dart:convert';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:games_counter/add_with_history_player_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'context_ext.dart';
import 'member_model.dart';

class PlayersListPage extends StatefulWidget {
  const PlayersListPage({super.key});

  static const keyPlayerGames = "games-player";

  @override
  State<PlayersListPage> createState() => _PlayersListPageState();
}

class _PlayersListPageState extends State<PlayersListPage> {
  late AppLifecycleListener appLifecycleListener;
  late ConfettiController confettiController;

  final players = <PlayerModel>[];

  @override
  void initState() {
    confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    appLifecycleListener = AppLifecycleListener(
      onDetach: () => saveTheGame(),
      onHide: () => saveTheGame(),
      onPause: () => saveTheGame(),
      onInactive: () => saveTheGame(),
      onRestart: () => saveTheGame(),
    );
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      continueTheGame();
    });
  }

  @override
  void dispose() {
    confettiController.dispose();
    appLifecycleListener.dispose();
    super.dispose();
  }

  Future<void> saveTheGame() async {
    final pref = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(players.map((e) => e.toJson()).toList());
    await pref.setString(PlayersListPage.keyPlayerGames, jsonData);
  }

  Future<void> continueTheGame() async {
    final pref = await SharedPreferences.getInstance();
    final jsonGame = pref.getString(PlayersListPage.keyPlayerGames) ?? "";
    if (jsonGame.isNotEmpty) {
      final model = jsonDecode(jsonGame) as List;
      if (model.isEmpty) return;

      continueGame(
        context,
        onContinue: () async {
          final res = model.map((e) => PlayerModel.fromJson(e)).toList();
          setState(() {
            players.addAll(res);
          });
          Navigator.pop(context);
        },
      );
    }
  }

  Future<void> runTheGame() async {
    players.clear();
    final pref = await SharedPreferences.getInstance();
    final jsonGame = pref.getString(PlayersListPage.keyPlayerGames) ?? "";
    if (jsonGame.isNotEmpty) {
      final model = jsonDecode(jsonGame) as List;
      if (model.isEmpty) return;
      final res = model.map((e) => PlayerModel.fromJson(e)).toList();
      setState(() {
        players.addAll(res);
      });
    }
  }

  void onAddMember(PlayerModel player) {
    if (player.id.isEmpty) {
      final newPlayer = player.copyWith(id: "player${Random().nextInt(10000)}");
      setState(() {
        players.add(newPlayer);
      });
    } else {
      final index = players.indexWhere((e) => e.id == player.id);
      setState(() {
        players.replaceRange(index, index + 1, [player]);
      });
    }
  }

  void boom(String playerId) {
    final player = players.where((e) => e.id == playerId).first;
    final index = players.indexWhere((element) => element.id == playerId);
    final updated = player.copyWith(count: player.count + 2);
    players.replaceRange(index, index + 1, [updated]);
    setState(() {});
    confettiController.play();
  }

  void increment(String playerId) {
    final player = players.where((e) => e.id == playerId).first;
    final index = players.indexWhere((element) => element.id == playerId);
    var updated = player.copyWith(count: player.count + 1);

    if (updated.count >= 10) {
      updated = updated.copyWith(isChampion: true);
      players.replaceRange(index, index + 1, [updated]);
      finishToChampion(updated);
      return;
    }

    players.replaceRange(index, index + 1, [updated]);
    setState(() {});
  }

  void finishToChampion(PlayerModel champion) {
    confettiController.play();
    final newPlayers = <PlayerModel>[];
    for (var player in players) {
      if (champion.id != player.id) {
        player = player.copyWith(isChampion: false);
      }

      newPlayers.add(player.copyWith(count: 0));
    }
    setState(() {
      players.clear();
      players.addAll(newPlayers);
    });
  }

  void decrement(String playerId) {
    final player = players.where((e) => e.id == playerId).first;
    final index = players.indexWhere((element) => element.id == playerId);
    final updated = player.copyWith(count: player.count - 1);
    players.replaceRange(index, index + 1, [updated]);
    setState(() {});
  }

  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }

  Future<void> endGame() async {
    players.clear();
    final pref = await SharedPreferences.getInstance();
    await pref.remove(PlayersListPage.keyPlayerGames);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Games counter"),
        actions: [
          TextButton(
            onPressed: () {
              confirmEndGame(
                context,
                onEndGame: () async {
                  endGame();
                },
              );
            },
            child: Text("End"),
          )
        ],
      ),
      floatingActionButton: ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return AddWithHistoryPlayerPage();
              },
            )).then((value) {
              runTheGame();
            });
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.add,
                size: 20,
              ),
              Text("New player"),
            ],
          )),
      body: players.isEmpty
          ? const Center(
              child: Text("Not yet a player, please add a player"),
            )
          : Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: ConfettiWidget(
                    confettiController: confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple
                    ],
                    createParticlePath: drawStar,
                  ),
                ),
                ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players.reversed.toList()[index];
                    return Slidable(
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        children: [
                          // SlidableAction(
                          //   onPressed: (context) {
                          //     addPlayerDialog(
                          //       context,
                          //       onAdd: onAddMember,
                          //       updatedPlayer: player,
                          //     );
                          //   },
                          //   backgroundColor: Colors.blueAccent.shade100,
                          //   foregroundColor: Colors.white,
                          //   icon: CupertinoIcons.pencil,
                          //   label: 'Update',
                          // ),
                          SlidableAction(
                            onPressed: (context) => boom(player.id),
                            backgroundColor: Colors.red.shade500,
                            foregroundColor: Colors.white,
                            icon: CupertinoIcons.exclamationmark_triangle,
                            label: 'Boom',
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                "${player.name} ${player.isChampion ? '👑' : ''} "),
                            Row(
                              children: [
                                SizedBox(
                                  width: 25,
                                  height: 25,
                                  child: IconButton(
                                    style: ButtonStyle(
                                      padding: const MaterialStatePropertyAll(
                                          EdgeInsets.zero),
                                      backgroundColor: MaterialStatePropertyAll(
                                        Colors.redAccent.shade200,
                                      ),
                                    ),
                                    onPressed: () => decrement(player.id),
                                    icon: const Icon(
                                      CupertinoIcons.minus,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Text(
                                  "${player.count}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                SizedBox(
                                  width: 25,
                                  height: 25,
                                  child: IconButton(
                                    style: ButtonStyle(
                                      padding: const MaterialStatePropertyAll(
                                          EdgeInsets.zero),
                                      backgroundColor: MaterialStatePropertyAll(
                                          Colors.blueAccent.shade200),
                                    ),
                                    onPressed: () => increment(player.id),
                                    icon: const Icon(
                                      CupertinoIcons.add,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

Future<void> addPlayerDialog(
  BuildContext context, {
  required Function(PlayerModel palyerName) onAdd,
  PlayerModel? updatedPlayer,
}) async {
  await showGeneralDialog(
    barrierDismissible: true,
    barrierLabel: 'Exit',
    context: context,
    pageBuilder: (context, a, s) {
      return NewPlayerForm(
        onAdd: onAdd,
        updatedPlayer: updatedPlayer,
      );
    },
  );
}

class NewPlayerForm extends StatefulWidget {
  final Function(PlayerModel palyerName) onAdd;
  final PlayerModel? updatedPlayer;

  const NewPlayerForm({
    super.key,
    required this.onAdd,
    this.updatedPlayer,
  });

  @override
  State<NewPlayerForm> createState() => _NewPlayerFormState();
}

class _NewPlayerFormState extends State<NewPlayerForm> {
  String playerName = '';

  @override
  void initState() {
    playerName = widget.updatedPlayer?.name ?? "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: context.width / 1.5,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Add new player",
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              TextFormField(
                initialValue: playerName,
                decoration: const InputDecoration(
                  hintText: "new player name",
                ),
                onChanged: (value) {
                  setState(() {
                    playerName = value;
                  });
                },
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  if (playerName.isEmpty) {
                    Navigator.pop(context);
                    return;
                  }

                  Navigator.pop(context);

                  late PlayerModel playerModel;
                  final player = widget.updatedPlayer;
                  if (player != null) {
                    playerModel = player.copyWith(name: playerName);
                  } else {
                    playerModel = PlayerModel(
                      isChampion: false,
                      id: "",
                      name: playerName,
                      count: 0,
                    );
                  }
                  widget.onAdd(playerModel);
                },
                child: const Text("Add"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> continueGame(
  BuildContext context, {
  required Future<void> Function() onContinue,
}) async {
  await showGeneralDialog(
    barrierDismissible: true,
    barrierLabel: 'Exit',
    context: context,
    pageBuilder: (context, a, s) {
      return Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            width: context.width / 1.5,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Continue game?",
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "The previous data game will be load if you're pressed the continue button",
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () async {
                    await onContinue();
                  },
                  child: Text(
                    "Continue",
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () async {
                    final pref = await SharedPreferences.getInstance();
                    pref.remove("game");
                    Navigator.pop(context);
                  },
                  child: Text(
                    "new game",
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: Colors.redAccent.shade200,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> confirmEndGame(
  BuildContext context, {
  required Future<void> Function() onEndGame,
}) async {
  await showGeneralDialog(
    barrierDismissible: true,
    barrierLabel: 'Exit',
    context: context,
    pageBuilder: (context, a, s) {
      return Material(
        type: MaterialType.transparency,
        child: Center(
          child: Container(
            width: context.width / 1.5,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "End game?",
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "The current data game will removed when you pressed the End button",
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade400,
                  ),
                  onPressed: () async {
                    await onEndGame();
                    Navigator.pop(context);
                  },
                  child: Text(
                    "End!",
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
