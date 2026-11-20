class FurnitureCompany {
  const FurnitureCompany({
    required this.id,
    required this.name,
    required this.location,
    required this.cover,
    required this.description,
    required this.address,
    this.phone,
    this.verified = false,
  });
  final String id, name, location, cover, description, address;
  final String? phone;
  final bool verified;
}

const furnitureCompanies = [
  FurnitureCompany(
    id: 'ger-studio',
    name: 'Гэр студи',
    location: 'Улаанбаатар · Хан-Уул',
    cover: 'assets/images/home_living_room.png',
    description: 'Байгалийн материал, энгийн хэлбэрийг эрхэмлэсэн тавилгын студийн жишиг бүртгэл.',
    address: 'Хан-Уул · Жишиг байршил',
  ),
  FurnitureCompany(
    id: 'mod-workshop',
    name: 'Мод урлан',
    location: 'Улаанбаатар · Баянзүрх',
    cover: 'assets/images/bedroom.png',
    description: 'Модон тавилга урлах компанийн жишиг бүртгэл.',
    address: 'Баянзүрх · Жишиг байршил',
  ),
];
