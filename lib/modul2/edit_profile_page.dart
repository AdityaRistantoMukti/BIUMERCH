import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'ganti_password.dart'; 
import 'ganti_email.dart'; 
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  final String username;
  final String email;
  final String phone;
  final String? profileImageUrl;

  const EditProfilePage({super.key, 
    required this.username,
    required this.email,
    required this.phone,
    this.profileImageUrl,
  });

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  File? _profileImage;
  late String userId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
    userId = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<String?> _uploadProfileImage(File image) async {
    try {
      String fileName = 'profile_$userId.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child('profile_images/$fileName');
      UploadTask uploadTask = storageRef.putFile(image);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Failed to upload image: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua field')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? profileImageUrl = widget.profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _uploadProfileImage(_profileImage!);
      }

      Map<String, dynamic> profileData = {
        'username': _usernameController.text,
        'email': _emailController.text,
        'notlp': _phoneController.text,
        if (profileImageUrl != null) 'profilePicture': profileImageUrl,
      };

      await FirebaseFirestore.instance.collection('users').doc(userId).update(profileData);

      Navigator.pop(context, {
        'username': _usernameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'profileImageUrl': profileImageUrl,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan profil: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5), // Shading pada image
                                  spreadRadius: 2,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 55,
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : (widget.profileImageUrl != null
                                      ? NetworkImage(widget.profileImageUrl!)
                                      : null) as ImageProvider<Object>?,
                              child: _profileImage == null && widget.profileImageUrl == null
                                  ? const Icon(Icons.add_a_photo, size: 50, color: Colors.white)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          label: 'Username',
                          controller: _usernameController,
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          label: 'Email',
                          controller: _emailController,
                          readOnly: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => GantiEmailScreen(userId: userId)),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextFormField(
                          label: 'No telpon',
                          controller: _phoneController,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Ganti Password'),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context, null);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(86, 202, 3, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF319F43), 
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    void Function()? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
            shadows: [
              Shadow(
                blurRadius: 2.0,
                color: Colors.grey,
                offset: Offset(1.0, 1.0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.teal, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              fillColor: Colors.grey[200],
              filled: true,
            ),
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
