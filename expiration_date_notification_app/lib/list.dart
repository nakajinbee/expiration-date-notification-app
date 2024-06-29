import 'package:flutter/material.dart';
import 'db.dart';
 

class FoodItemListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dbHelper = DatabaseHelper.instance;
    return Scaffold(
      appBar: AppBar(
        title: Text('食材一覧'),
      ),
      body: FutureBuilder<List<FoodItem>>(
        future: dbHelper.fetchFoodItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('エラーが発生しました'));
          } else {
            return ListView.separated(
              itemCount: snapshot.data?.length ?? 0,
              itemBuilder: (context, index) {
                FoodItem item = snapshot.data![index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('賞味期限: ${item.expirationDate}\n保存方法: ${item.storageMethod}\n保存のコツ: ${item.tipsForSaving}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      await dbHelper.deleteFoodItem(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${item.name}を削除しました'),
                      ));
                      // Refresh the list after deletion
                      (context as Element).reassemble();
                    },
                  ),
                );
              },
              separatorBuilder: (context, index) => Divider(),
            );
          }
        },
      ),
    );
  }
}