import 'package:cosplay_makeup/data/app_store.dart';
import 'package:cosplay_makeup/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('メインメニューで4つのページを移動できる', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore();
    await store.load();
    await tester.pumpWidget(CosplayMakeupApp(store: store));

    expect(find.text('お気に入りメイク'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('最近更新したメイク'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('最近更新したメイク'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.face_outlined));
    await tester.pumpAndSettle();
    expect(find.text('キャラクターを追加'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();
    expect(find.text('パレットを追加'), findsOneWidget);
    await tester.tap(find.text('単品コスメ'));
    await tester.pumpAndSettle();
    expect(find.text('単品コスメを追加'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();
    expect(find.text('先に「キャラクター」でキャラクターを登録してください。'), findsOneWidget);
  });
}
