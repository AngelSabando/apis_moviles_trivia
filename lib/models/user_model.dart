class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],           // accessing value from key 'id'
      name: json['name'],       // accessing 'name'
      email: json['email'],     // accessing 'email'
    );
  }
}