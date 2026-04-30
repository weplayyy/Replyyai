enum RoomRole { owner, coOwner, admin, member }

extension RoomRoleX on RoomRole {
  String toRaw() => switch (this) {
        RoomRole.owner => 'owner',
        RoomRole.coOwner => 'co_owner',
        RoomRole.admin => 'admin',
        RoomRole.member => 'member',
      };

  static RoomRole fromRaw(String? r) => switch (r) {
        'owner' => RoomRole.owner,
        'co_owner' => RoomRole.coOwner,
        'admin' => RoomRole.admin,
        _ => RoomRole.member,
      };

  String get label => switch (this) {
        RoomRole.owner => 'Owner',
        RoomRole.coOwner => 'Co-Owner',
        RoomRole.admin => 'Admin',
        RoomRole.member => 'Member',
      };

  // Owner-only powers
  bool get canManageAdmins => this == RoomRole.owner;
  bool get canEditRoom => this == RoomRole.owner;
  bool get canDeleteRoom => this == RoomRole.owner;

  // Moderation powers (still subject to the charm rule on the target)
  bool get canModerate =>
      this == RoomRole.owner ||
      this == RoomRole.coOwner ||
      this == RoomRole.admin;

  bool get canPin => canModerate;
}
