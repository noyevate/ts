// models/vendor_login_response.dart
import 'dart:convert';

VendorLoginResponse vendorLoginResponseFromJson(String str) => VendorLoginResponse.fromJson(json.decode(str));

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
        required this.id, required this.firstName, required this.lastName, this.username,
        required this.email, required this.fcm, required this.verification,
        required this.phone, required this.phoneVerification, required this.userType,
        this.profile, required this.createdAt, required this.updatedAt,
        this.ownedRestaurant, required this.userToken,
    });

    factory VendorLoginResponse.fromJson(Map<String, dynamic> json) => VendorLoginResponse(
        id: json["id"] ?? '',
        firstName: json["first_name"] ?? '',
        lastName: json["last_name"] ?? '',
        username: json["username"],
        email: json["email"] ?? '',
        fcm: json["fcm"] ?? '',
        // FIX: Add a fallback for booleans
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
    // ... other properties

    OwnedRestaurant({
        required this.id, required this.title, required this.imageUrl, required this.pickup,
        this.restaurantFcm, required this.restaurantMail, required this.delivery,
        required this.isAvailabe, /* ... */
    });

    factory OwnedRestaurant.fromJson(Map<String, dynamic> json) => OwnedRestaurant(
        id: json["id"] ?? '',
        title: json["title"] ?? '',
        imageUrl: json["imageUrl"] ?? '',
        // FIX: Add fallbacks for all booleans in the nested object
        pickup: json["pickup"] ?? false,
        restaurantFcm: json["restaurantFcm"],
        restaurantMail: json["restaurantMail"] ?? '',
        delivery: json["delivery"] ?? false,
        isAvailabe: json["isAvailabe"] ?? false,
        // ... parsing for other fields remains the same ...
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

// ... other nested classes like Time and RestaurantCategory remain the same,
// assuming they do not contain boolean fields. If they do, those must also get fallbacks.
