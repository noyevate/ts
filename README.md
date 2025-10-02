# ts

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

// models/vendor_login_response.dart
import 'dart.convert';

// Helper function to parse the JSON string.
VendorLoginResponse vendorLoginResponseFromJson(String str) {
  try {
    return VendorLoginResponse.fromJson(json.decode(str));
  } catch (e, s) {
    print("Failed to parse VendorLoginResponse: $e");
    print("Stack Trace: $s");
    // Return an empty/error state object if parsing fails
    return VendorLoginResponse.empty();
  }
}

class VendorLoginResponse {
    final String id;
    final String firstName;
    final String lastName;
    final String? username;
    final String email;
    final String fcm;
    final bool verification;
    final String phone;
    final bool phoneVerification;
    final String userType;
    final String? profile;
    final DateTime createdAt;
    final DateTime updatedAt;
    final OwnedRestaurant? ownedRestaurant;
    final String userToken;

    VendorLoginResponse({
        required this.id,
        required this.firstName,
        required this.lastName,
        this.username,
        required this.email,
        required this.fcm,
        required this.verification,
        required this.phone,
        required this.phoneVerification,
        required this.userType,
        this.profile,
        required this.createdAt,
        required this.updatedAt,
        this.ownedRestaurant,
        required this.userToken,
    });
    
    // Factory for creating a default/error state
    factory VendorLoginResponse.empty() => VendorLoginResponse(
        id: '', firstName: '', lastName: '', email: '', fcm: '', verification: false,
        phone: '', phoneVerification: false, userType: 'Vendor',
        createdAt: DateTime.now(), updatedAt: DateTime.now(), userToken: '',
    );

    factory VendorLoginResponse.fromJson(Map<String, dynamic> json) => VendorLoginResponse(
        id: json["id"] ?? '',
        firstName: json["first_name"] ?? '',
        lastName: json["last_name"] ?? '',
        username: json["username"],
        email: json["email"] ?? '',
        fcm: json["fcm"] ?? '',
        verification: json["verification"] ?? false,
        phone: json["phone"] ?? '',
        phoneVerification: json["phoneVerification"] ?? false,
        userType: json["userType"] ?? '',
        profile: json["profile"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
        ownedRestaurant: json["ownedRestaurant"] == null ? null : OwnedRestaurant.fromJson(json["ownedRestaurant"]),
        userToken: json["userToken"] ?? '',
    );
}

class OwnedRestaurant {
    final String id;
    final String title;
    final String imageUrl;
    final bool pickup;
    final String? restaurantFcm;
    final String restaurantMail;
    final bool delivery;
    final bool isAvailabe;
    final String phone;
    final String? code;
    final String? accountName;
    final String? accountNumber;
    final String? bank;
    final String logoUrl;
    final double rating;
    final String ratingCount;
    final String verification;
    final String verificationMessage;
    final double latitude;
    final double longitude;
    final double latitudeDelta;
    final double longitudeDelta;
    final String address;
    final String addressTitle;
    final List<Time> time;
    final String userId;
    final List<RestaurantCategory>? restaurantCategories;
    final DateTime createdAt;
    final DateTime updatedAt;

    OwnedRestaurant({
        required this.id, required this.title, required this.imageUrl, required this.pickup,
        this.restaurantFcm, required this.restaurantMail, required this.delivery,
        required this.isAvailabe, required this.phone, this.code, this.accountName,
        this.accountNumber, this.bank, required this.logoUrl, required this.rating,
        required this.ratingCount, required this.verification, required this.verificationMessage,
        required this.latitude, required this.longitude, required this.latitudeDelta,
        required this.longitudeDelta, required this.address, required this.addressTitle,
        required this.time, required this.userId, this.restaurantCategories,
        required this.createdAt, required this.updatedAt,
    });

    factory OwnedRestaurant.fromJson(Map<String, dynamic> json) => OwnedRestaurant(
        id: json["id"] ?? '',
        title: json["title"] ?? '',
        imageUrl: json["imageUrl"] ?? '',
        pickup: json["pickup"] ?? false,
        restaurantFcm: json["restaurantFcm"],
        restaurantMail: json["restaurantMail"] ?? '',
        delivery: json["delivery"] ?? false,
        isAvailabe: json["isAvailabe"] ?? false,
        phone: json["phone"] ?? '',
        code: json["code"],
        accountName: json["accountName"],
        accountNumber: json["accountNumber"],
        bank: json["bank"],
        logoUrl: json["logoUrl"] ?? '',
        rating: double.tryParse(json["rating"]?.toString() ?? '0.0') ?? 0.0,
        ratingCount: json["ratingCount"] ?? '0',
        verification: json["verification"] ?? '',
        verificationMessage: json["verificationMessage"] ?? '',
        latitude: json["latitude"]?.toDouble() ?? 0.0,
        longitude: json["longitude"]?.toDouble() ?? 0.0,
        latitudeDelta: json["latitudeDelta"]?.toDouble() ?? 0.0,
        longitudeDelta: json["longitudeDelta"]?.toDouble() ?? 0.0,
        address: json["address"] ?? '',
        addressTitle: json["addressTitle"] ?? '',
        time: json["time"] == null ? [] : List<Time>.from(json["time"].map((x) => Time.fromJson(x))),
        userId: json["userId"] ?? '',
        restaurantCategories: json["restaurant_categories"] == null ? null : List<RestaurantCategory>.from(json["restaurant_categories"].map((x) => RestaurantCategory.fromJson(x))),
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
    );
}

class Time {
    final String day;
    final String open;
    final String close;
    final String orderType;
    final String? menuReadyTime;
    final String? orderCutOffTime;

    Time({
        required this.day, required this.open, required this.close,
        required this.orderType, this.menuReadyTime, this.orderCutOffTime,
    });

    factory Time.fromJson(Map<String, dynamic> json) => Time(
        day: json["day"] ?? '',
        open: json["open"] ?? '',
        close: json["close"] ?? '',
        orderType: json["orderType"] ?? '',
        menuReadyTime: json["menuReadyTime"],
        orderCutOffTime: json["orderCutOffTime"],
    );
}

// You would need to define the 'RestaurantCategory' class as well
class RestaurantCategory {
    // Define properties based on the 'restaurant_categories' object in your JSON
    // For now, let's assume it has 'name' and 'additives'
    final String name;
    // ... other properties

    RestaurantCategory({required this.name});

    factory RestaurantCategory.fromJson(Map<String, dynamic> json) => RestaurantCategory(
        name: json["name"] ?? '',
    );
}
