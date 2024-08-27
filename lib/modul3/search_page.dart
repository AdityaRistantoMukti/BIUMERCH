import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biumerch_mobile_app/modul3/landing_page.dart';
import 'package:biumerch_mobile_app/modul3/search_results_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async { 
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('searchHistory') ?? [];
    });
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('searchHistory', _searchHistory);
  }

  Future<void> _trackSearchQuery(String query) async {
    final queryDoc = FirebaseFirestore.instance.collection('searchQueries').doc(query.toLowerCase());
    final snapshot = await queryDoc.get();

    if (snapshot.exists) {
      queryDoc.update({
        'count': FieldValue.increment(1),
        'lastSearch': FieldValue.serverTimestamp(),
      });
    } else {
      queryDoc.set({
        'keyword': query.toLowerCase(),
        'count': 1,
        'lastSearch': FieldValue.serverTimestamp(),
      });
    }
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      setState(() {
        if (!_searchHistory.contains(query)) {
          _searchHistory.add(query);
          _saveSearchHistory();
          _trackSearchQuery(query);
        }
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(query: query),
        ),
      );
      _searchController.clear(); // Clear the search field after performing the search
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(  // This ensures that the content avoids the status bar or notch
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(top: 13.0, left: 8.0),  // Add custom padding if needed
              child: AppBar(
                leadingWidth: 20,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                title: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 1.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Mau cari apa?',
                        suffixIcon: Icon(Icons.search),  // Mengubah dari suffix ke prefix
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),  // Mengubah radius sesuai UI yang diinginkan
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        // filled: true,
                        // fillColor: const Color.fromARGB(255, 246, 244, 244),  // Warna background yang diinginkan
                        hintStyle: TextStyle(
                          color: Colors.grey[600],  // Set hint text color
                        ),
                      ),
                      onSubmitted: _performSearch,
                      onChanged: (query) {
                        if (query.isEmpty) {
                          setState(() {
                            // Optionally clear results or perform other actions
                          });
                        }
                      },
                    ),
                  ),
                ),
                // backgroundColor: Colors.transparent,
                elevation: 0,  // Remove the shadow to make it look like part of the layout
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  if (_searchHistory.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 0.0, left: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Last search:', style: TextStyle(fontSize:16)),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchHistory.clear();
                                _saveSearchHistory();
                              });
                            },
                            child: Text(
                              'Clear All',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView(
                      children: [
                        if (_searchHistory.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ..._searchHistory.map((query) => ListTile(
                                  leading: Icon(Icons.history, color: Colors.grey),
                                  title: Text(query),
                                  onTap: () {
                                    _searchController.text = query;
                                    _performSearch(query);
                                  },
                                  trailing: IconButton(
                                    icon: Icon(Icons.close, color: Colors.grey),
                                    onPressed: () {
                                      setState(() {
                                        _searchHistory.remove(query);
                                        _saveSearchHistory();
                                      });
                                    },
                                  ),
                                )).toList(),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
