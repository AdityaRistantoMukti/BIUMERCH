import 'package:flutter/material.dart';

class CekEmailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image:
                    AssetImage("assets/BGLogin.png"), // Gambar latar belakang
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo in the center
                Container(
                  width: 150,
                  height: 150,
                  margin: const EdgeInsets.only(
                      bottom: 20), // Adjust margin to move the logo up
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors
                        .transparent, // Transparent background for the logo container
                  ),
                  child: Center(
                    child: Image.asset('assets/email.png',
                        height: 100), // Ganti dengan path logo Anda
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                // Text for confirmation
                const Text(
                  "Silahkan Periksa",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Text color adjusted for visibility
                  ),
                ),
                const Text(
                  "Email Anda",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Text color adjusted for visibility
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  "Periksa email Anda untuk konfirmasi ganti password",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white, // Text color adjusted for visibility
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                // Button to finish
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Return to previous screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27ae60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: const Text(
                      "Selesai",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white, // Button text color
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
