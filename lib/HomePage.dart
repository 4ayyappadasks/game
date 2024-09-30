import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'GameController.dart';

class HomePage extends StatelessWidget {
  final GameController controller = Get.put(GameController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Multiplayer Game'),
        actions: [
          ElevatedButton(
            onPressed: controller.exitGame,
            child: Text('Exit Game'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: Obx(() {
                return DropdownButton<String>(
                  isExpanded: true,
                  hint: Text('Select Game Set'),
                  value: controller.selectedSet.value.isEmpty
                      ? null
                      : controller.selectedSet.value,
                  items: controller.availableSets
                      .map((set) => DropdownMenuItem(
                            child: Text(set, style: TextStyle(fontSize: 16)),
                            value: set,
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedSet.value = value;
                    }
                  },
                );
              }),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: controller.generateNewSet,
                  child: Text('Generate New Set'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (controller.selectedSet.value.isNotEmpty) {
                      controller.joinSelectedSet();
                    } else {
                      Get.snackbar('Error', 'Please select a game set.',
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  },
                  child: Text('Join Game'),
                ),
              ],
            ),
            Divider(height: 30, thickness: 2),
            Obx(() => Text(
                  'Game Set: ${controller.gameSetName.value}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                )),
            Obx(() => Text(
                'Your Symbol: ${controller.playerSymbol.value} | Current Player: ${controller.currentPlayer.value}',
                style: TextStyle(fontSize: 16))),
            Obx(() {
              if (controller.currentPlayer.value ==
                  controller.playerSymbol.value) {
                return Text('It\'s your turn!',
                    style: TextStyle(color: Colors.green, fontSize: 20));
              } else {
                return Text('Waiting for opponent...',
                    style: TextStyle(color: Colors.red, fontSize: 20));
              }
            }),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4.0,
                  crossAxisSpacing: 4.0,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  return Obx(() => GestureDetector(
                        onTap: () => controller.makeMove(index),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              controller.board[index],
                              style: TextStyle(
                                  fontSize: 32,
                                  color: controller.board[index] == 'X'
                                      ? Colors.red
                                      : Colors.blue),
                            ),
                          ),
                        ),
                      ));
                },
              ),
            ),
            Obx(() {
              if (controller.isGameOver.value) {
                return Column(
                  children: [
                    Text(
                      controller.winner.value.isEmpty
                          ? 'It\'s a Draw!'
                          : 'Winner: ${controller.winner.value}',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: controller.resetGame,
                      child: Text('Play Again'),
                    ),
                  ],
                );
              } else {
                return Container();
              }
            }),
            Divider(height: 30, thickness: 2),
            Text(
              'Scoreboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('Player X: ${controller.playerXScore.value}',
                        style: TextStyle(fontSize: 16)),
                    Text('Draws: ${controller.draws.value}',
                        style: TextStyle(fontSize: 16)),
                    Text('Player O: ${controller.playerOScore.value}',
                        style: TextStyle(fontSize: 16)),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
