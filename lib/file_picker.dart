import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerExample extends StatefulWidget {
  const FilePickerExample({super.key});

  @override
  _FilePickerExampleState createState() => _FilePickerExampleState();
}

class _FilePickerExampleState extends State<FilePickerExample> {
  String? _selectedFileName;

  Future<void> _pickFile() async {
    // Memanggil FilePicker untuk memilih satu file
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      // Jika file dipilih, tampilkan nama file
      setState(() {
        _selectedFileName = result.files.single.name;
      });
    } else {
      // Jika pengguna membatalkan picker
      setState(() {
        _selectedFileName = "No file selected.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Picker Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Selected File:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFileName ?? 'No file selected.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _pickFile, // Memanggil fungsi untuk memilih file
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
                child: const Text('Pick a File'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: FilePickerExample(),
  ));
}
