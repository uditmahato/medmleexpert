import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'subscription_service.dart'; // Updated import

class SubscriptionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Subscribe")),
      body: FutureBuilder<bool>(
        future: isSubscribed(),
        builder: (context, subSnapshot) {
          if (subSnapshot.hasData && subSnapshot.data!) {
            return Center(child: Text("You are already subscribed."));
          }
          return FutureBuilder<List<Package>>(
            future: getSubscriptionPackages(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    Package package = snapshot.data![index];
                    return ListTile(
                      title: Text(
                        package.storeProduct.title,
                      ), // Updated to storeProduct
                      subtitle: Text(
                        package.storeProduct.priceString,
                      ), // Updated
                      onTap: () async {
                        try {
                          CustomerInfo customerInfo =
                              await Purchases.purchasePackage(
                                package,
                              ); // Updated
                          if (customerInfo
                                  .entitlements
                                  .all["premium_access"]
                                  ?.isActive ==
                              true) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          print("Purchase error: $e");
                        }
                      },
                    );
                  },
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          );
        },
      ),
    );
  }
}
