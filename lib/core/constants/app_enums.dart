enum ParkingCategory { all, mall, office, hospital }

enum SlotStatus { available, selected, occupied, unavailable }

enum BookingStatus { upcoming, completed, cancelled }

enum PaymentMethod { upi, card, wallet }

enum UserRole { user, admin }

extension ParkingCategoryLabel on ParkingCategory {
  String get label {
    switch (this) {
      case ParkingCategory.all:
        return 'All';
      case ParkingCategory.mall:
        return 'Mall';
      case ParkingCategory.office:
        return 'Office';
      case ParkingCategory.hospital:
        return 'Hospital';
    }
  }
}

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.wallet:
        return 'Wallet';
    }
  }
}

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
