import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class GameController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var availableSets = <String>[].obs;
  var selectedSet = ''.obs;
  var playerSymbol = ''.obs;
  var board = List.filled(9, '').obs;
  var currentPlayer = 'X'.obs;
  var gameId = ''.obs;
  var isGameOver = false.obs;
  var winner = ''.obs;
  var gameSetName = ''.obs;

  var playerXScore = 0.obs;
  var playerOScore = 0.obs;
  var draws = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _listenToAvailableSets(); // Real-time listener for available sets
  }

  // Listen to real-time updates for game sets in Firestore
  void _listenToAvailableSets() {
    _firestore
        .collection('games')
        .where('isGameFull', isEqualTo: false)
        .snapshots()
        .listen((querySnapshot) {
      availableSets.clear();
      for (var doc in querySnapshot.docs) {
        final setName = doc['setName'];
        if (!availableSets.contains(setName)) {
          availableSets.add(setName);
        }
      }

      // Ensure selectedSet is valid
      if (selectedSet.value.isNotEmpty &&
          !availableSets.contains(selectedSet.value)) {
        selectedSet.value = ''; // Reset if the selected set is invalid
      }
    });
  }

  Future<void> generateNewSet() async {
    final gameSetName = 'Game Set ${DateTime.now().millisecondsSinceEpoch}';
    // Create a new game set with playerX as the first player
    final gameDoc = await _firestore.collection('games').add({
      'board': List.filled(9, ''),
      'currentPlayer': 'X',
      'isGameFull': false,
      'playerX': 'X',
      'playerO': null, // Initially, no second player
      'setName': gameSetName,
    });

    gameId.value = gameDoc.id;
    this.gameSetName.value = gameSetName;
    playerSymbol.value = 'X'; // The creator is playerX

    _listenToGameUpdates();
  }

  Future<void> joinSelectedSet() async {
    if (selectedSet.value.isNotEmpty) {
      final gameSetSnapshot = await _firestore
          .collection('games')
          .where('setName', isEqualTo: selectedSet.value)
          .limit(1)
          .get();

      if (gameSetSnapshot.docs.isNotEmpty) {
        final gameData = gameSetSnapshot.docs.first.data();
        gameId.value = gameSetSnapshot.docs.first.id;
        gameSetName.value = gameSetSnapshot.docs.first['setName'];

        // Check if playerO has joined or not
        if (gameData['playerO'] == null) {
          // If playerO hasn't joined, this player becomes playerO
          await _firestore.collection('games').doc(gameId.value).update({
            'playerO': 'O',
            'isGameFull': true, // Now the game is full
          });
          playerSymbol.value = 'O';
        } else {
          // If playerO has already joined, join as a spectator (optional logic)
          playerSymbol.value = 'X'; // Rejoin as playerX
        }

        _listenToGameUpdates();
      }
    }
  }

  void _listenToGameUpdates() {
    _firestore.collection('games').doc(gameId.value).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        board.value = List<String>.from(data['board']);
        currentPlayer.value = data['currentPlayer'];
        isGameOver.value = checkGameOver(board);
        winner.value = checkWinner(board);
        if (isGameOver.value) {
          updateScores();
        }
      }
    });
  }

  void makeMove(int index) {
    if (board[index] == '' && currentPlayer.value == playerSymbol.value) {
      board[index] = currentPlayer.value;
      updateGameState();
    }
  }

  Future<void> updateGameState() async {
    await _firestore.collection('games').doc(gameId.value).update({
      'board': board,
      'currentPlayer': currentPlayer.value == 'X' ? 'O' : 'X',
    });
  }

  // Function to exit the current game set
  Future<void> exitGame() async {
    if (gameId.value.isNotEmpty) {
      final gameDoc =
          await _firestore.collection('games').doc(gameId.value).get();
      final gameData = gameDoc.data();

      // Remove the player from the game set and update the Firestore
      if (gameData != null) {
        if (playerSymbol.value == 'X') {
          // Remove playerX from the game set
          await _firestore.collection('games').doc(gameId.value).update({
            'playerX': null,
            'isGameFull': false, // Set is no longer full
          });
        } else if (playerSymbol.value == 'O') {
          // Remove playerO from the game set
          await _firestore.collection('games').doc(gameId.value).update({
            'playerO': null,
            'isGameFull': false, // Set is no longer full
          });
        }
      }

      // Reset controller variables
      gameId.value = '';
      gameSetName.value = '';
      playerSymbol.value = '';
      selectedSet.value = '';
      board.value = List.filled(9, '');
    }
  }

  String checkWinner(List<String> board) {
    const winningPositions = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (var positions in winningPositions) {
      if (board[positions[0]] != '' &&
          board[positions[0]] == board[positions[1]] &&
          board[positions[1]] == board[positions[2]]) {
        return board[positions[0]];
      }
    }

    return '';
  }

  bool checkGameOver(List<String> board) {
    return board.contains('') ? false : true;
  }

  void updateScores() {
    if (winner.value == 'X') {
      playerXScore.value++;
    } else if (winner.value == 'O') {
      playerOScore.value++;
    } else {
      draws.value++;
    }
  }

  void resetGame() {
    board.value = List.filled(9, '');
    currentPlayer.value = 'X';
    winner.value = '';
    isGameOver.value = false;
    updateGameState();
  }
}
