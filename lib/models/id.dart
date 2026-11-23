/// IDの末尾に付ける連番。IDを作るたびに1ずつ増える。
int _idSequence = 0;

/// 重複しないIDを「日時-連番」の形式で作る。
///
/// マスを一度にたくさん作るときは同じミリ秒にIDを作るため、連番も組み合わせる。
String generateId() {
  _idSequence++;
  return '${DateTime.now().millisecondsSinceEpoch}-$_idSequence';
}
