import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FurnitureCard extends StatelessWidget {
  const FurnitureCard({
    super.key,
    required this.image,
    required this.name,
    required this.price,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
    this.company = 'Гэр студи',
    this.has3DModel = false,
  });
  final String image, name, price;
  final String company;
  final bool has3DModel;
  final bool favorite;
  final VoidCallback onFavorite, onTap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Stack(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1.03,
                child: Image.asset(image, fit: BoxFit.cover),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SizedBox(
              width: 30,
              height: 30,
              child: IconButton.filled(
                tooltip: favorite ? 'Хадгалснаас хасах' : 'Хадгалах',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.green,
                  padding: EdgeInsets.zero,
                ),
                onPressed: onFavorite,
                icon: Icon(
                  favorite ? Icons.favorite : Icons.favorite_border,
                  size: 17,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      InkWell(
        onTap: onTap,
        child: Text(name, style: const TextStyle(fontSize: 13)),
      ),
      const SizedBox(height: 5),
      Text(
        price,
        style: const TextStyle(
          color: AppTheme.green,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        '$company · ${has3DModel ? '3D / AR' : '3D загваргүй'}',
        style: const TextStyle(fontSize: 10, color: AppTheme.muted),
      ),
    ],
  );
}
