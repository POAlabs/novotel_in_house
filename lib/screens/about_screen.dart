import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// About screen with app information and developer credits
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Design colors
  static const Color kDark = Color(0xFF0F172A);
  static const Color kNavy = Color(0xFF1E3A5F);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kLightGrey = Color(0xFF94A3B8);
  static const Color kBlue = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About',
          style: GoogleFonts.inter(
            color: kDark,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Heartist image at the top
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/heartist_image.jpeg',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App Name
            Text(
              'NOVOTEL HOTEL',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: kNavy,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'In-House App',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: kGrey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Version 1.0.0',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kBlue,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // About the App section
            _buildSection(
              title: 'About the App',
              content: 'The Novotel Hotel In-House App is a comprehensive hotel management solution designed to streamline internal operations and enhance staff efficiency. This application enables real-time issue tracking, floor management, and seamless communication between departments.\n\nKey features include:\n• Real-time issue reporting and tracking\n• Floor-by-floor building overview\n• Priority-based task management\n• Department-specific issue filtering\n• Lost & Found management\n• Staff coordination tools',
            ),
            
            const SizedBox(height: 24),
            
            // Purpose section
            _buildSection(
              title: 'Our Mission',
              content: 'To provide hotel staff with an intuitive, efficient, and reliable tool that simplifies daily operations, reduces response times, and ensures exceptional guest experiences through better internal coordination.',
            ),
            
            const SizedBox(height: 40),
            
            // Developer Credits
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kBlue.withOpacity(0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: kBlue.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'DEVELOPED BY',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: kLightGrey,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // POA Labs logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'POA Labs',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: kNavy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.email_outlined, size: 18, color: kBlue),
                        const SizedBox(width: 10),
                        Text(
                          'official.poa.labs@gmail.com',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: kDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Copyright
            Text(
              '© ${DateTime.now().year} POA Labs. All rights reserved.',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: kLightGrey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: kGrey,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
