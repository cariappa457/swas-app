import 'package:flutter/material.dart';
import '../widgets/wave_background.dart';
import '../widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Off-white matching image
      body: Stack(
        children: [
          // The top pink block looking like the image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: ClipPath(
              clipper: _TopWaveClipper(),
              child: Container(
                color: const Color(0xFFFC8BA2), // Soft pink
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    "Profile",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B5262), // Darker text tint
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Avatar
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 2,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.face, size: 80, color: Color(0xFFFA648C)), // Placeholder for avatar
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Name", style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildProfileField("John Doe"),
                      const SizedBox(height: 20),
                      const Text("Email", style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildProfileField("johndoe@placeholder.com"),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: "Log Out",
                        onPressed: () {},
                        buttonVariant: CustomButtonVariant.outlined,
                        icon: Icons.logout_rounded,
                        height: 50,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ),
    );
  }
}

class _TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 100);
    path.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, size.height - 50);
    path.quadraticBezierTo(
        size.width * 0.75, size.height - 100, size.width, size.height - 60);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
