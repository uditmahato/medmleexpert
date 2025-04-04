import 'package:purchases_flutter/purchases_flutter.dart';

Future<bool> isSubscribed() async {
  CustomerInfo customerInfo = await Purchases.getCustomerInfo(); // Updated
  return customerInfo.entitlements.active.containsKey("premium_access");
}

Future<int?> getRemainingDays() async {
  CustomerInfo customerInfo = await Purchases.getCustomerInfo(); // Updated
  if (customerInfo.entitlements.active.containsKey("premium_access")) {
    DateTime? expirationDate =
        customerInfo.entitlements.active["premium_access"]?.expirationDate;
    if (expirationDate != null) {
      return expirationDate.difference(DateTime.now()).inDays;
    }
  }
  return null;
}

Future<List<Package>> getSubscriptionPackages() async {
  Offerings offerings = await Purchases.getOfferings();
  return offerings.current?.availablePackages ?? [];
}
